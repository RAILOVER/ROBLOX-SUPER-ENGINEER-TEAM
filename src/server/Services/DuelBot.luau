--!strict
-- Adversaire serveur du duel (spec M1-duel-minimal §5). Toute la decision est dans le module pur
-- src/shared/Duel/BotPolicy.luau (teste sous Lune) ; ce fichier ne fait que porter la memoire du bot et son delai
-- de reflexion (D-M1-24 : Pret apres botThinkSeconds = 3 s, valeur a ajouter dans Config.Duel).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BotPolicy = require(ReplicatedStorage.Shared.Duel.BotPolicy)
local Types = require(ReplicatedStorage.Shared.Types.Duel)

type Config = typeof(require(ReplicatedStorage.Shared.Config))
type State = Types.State

export type Bot = { brain: BotPolicy.Brain, playedRound: number }

local DuelBot = {}

DuelBot.THINK_SECONDS = BotPolicy.THINK_SECONDS
DuelBot.DISPLAY_NAME = "Bot"

function DuelBot.new(seed: number): Bot
	return { brain = BotPolicy.newBrain(seed), playedRound = 0 }
end

-- Joue la Preparation courante si le bot n'a pas encore joue cette manche et que son delai est ecoule.
function DuelBot.update(
	config: Config,
	state: State,
	seatIndex: number,
	bot: Bot,
	elapsedSeconds: number
): boolean
	if
		state.phase ~= "Preparation"
		or bot.playedRound == state.round
		or elapsedSeconds < DuelBot.THINK_SECONDS
	then
		return false
	end
	bot.playedRound = state.round
	BotPolicy.play(config, state, seatIndex, bot.brain)
	return true
end

return DuelBot
