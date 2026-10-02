--!strict
-- Tactiques automatiques (R-M1-50 a R-M1-53). Priorite : Garde > Duo > Competence > Attaque (le Mega Combo est
-- gere par CombatSim avant l'action, R-M1-20).

local Types = require(script.Parent.Parent.Types.Combat)
local Effects = require(script.Parent.Effects)
local Status = require(script.Parent.Status)
local Targeting = require(script.Parent.Targeting)

type State = Types.State
type Unit = Types.Unit
type SkillDef = Types.SkillDef

local Tactics = {}

export type Decision = { kind: "Guard" | "Duo" | "Skill" | "Attack", partner: Unit? }

local DEFENSIVE_EFFECTS =
	{ TauntShield = true, Heal = true, HealEnergy = true } :: { [string]: boolean }

-- Une competence est defensive si elle vise le lanceur ou un allie (Bouclier, Provocation, soin).
function Tactics.isDefensive(skill: SkillDef): boolean
	return skill.target == "self"
		or skill.target == "allyLowestHp"
		or skill.target == "allies"
		or DEFENSIVE_EFFECTS[skill.effectId] == true
end

-- R-M1-51 (Prudent) : la competence defensive passe avant l'offensive ; les autres tactiques gardent l'ordre.
function Tactics.chooseSkill(skills: { SkillDef }, tactic: Types.Tactic): SkillDef?
	if #skills == 0 then
		return nil
	end
	if tactic == "Prudent" then
		for _, skill in skills do
			if Tactics.isDefensive(skill) then
				return skill
			end
		end
	end
	return skills[1]
end

local function healerAlive(state: State, unit: Unit): boolean
	for _, ally in Targeting.aliveAllies(state, unit, false) do
		if ally.class == "Soigneur" then
			return true
		end
	end
	return false
end

-- R-M1-19 : partenaire de Duo disponible, sinon nil.
function Tactics.duoPartner(state: State, unit: Unit): Unit?
	local team = Status.teamOf(state, unit)
	local combat = state.config.Combat
	if not Effects.hasEffect(team, "LienDAmour") or unit.energy < combat.duoEnergyCost then
		return nil
	end
	for _, ally in team.units do
		if
			ally ~= unit
			and ally.alive
			and table.find(unit.duoPartners, ally.slug)
			and not Status.hasControl(ally)
			and ally.energy >= combat.duoEnergyCost
		then
			return ally
		end
	end
	return nil
end

-- R-M1-51 : un Soigneur garde sa competence tant qu'aucun allie (lui compris) n'est sous le seuil.
function Tactics.wantsSkill(state: State, unit: Unit): boolean
	if unit.energy < unit.skillCost then
		return false
	end
	if unit.class ~= "Soigneur" then
		return true
	end
	local threshold = state.config.Combat.tactics[unit.tactic].healerHoldsSkillAboveAllyHp
	if threshold <= 0 then
		return true
	end
	for _, ally in Targeting.aliveAllies(state, unit, true) do
		if ally.hp / ally.hpMax < threshold then
			return true
		end
	end
	return false
end

-- R-M1-50 : Garde sous le seuil de la tactique, si Prudent ou si un Soigneur allie est vivant.
function Tactics.wantsGuard(state: State, unit: Unit): boolean
	local t = state.config.Combat.tactics[unit.tactic]
	if unit.hp / unit.hpMax >= t.guardBelowHp then
		return false
	end
	return unit.tactic == "Prudent" or healerAlive(state, unit)
end

function Tactics.decide(state: State, unit: Unit): Decision
	if Tactics.wantsGuard(state, unit) then
		return { kind = "Guard" }
	end
	local partner = Tactics.duoPartner(state, unit)
	if partner then
		return { kind = "Duo", partner = partner }
	end
	if Tactics.wantsSkill(state, unit) then
		return { kind = "Skill" }
	end
	return { kind = "Attack" }
end

return Tactics
