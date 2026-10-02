--!strict
-- Roster BATTLEROT par lots (brief §7.4). Les fichiers L*.luau sont generes par tools/gen_roster.py; ce module les
-- fusionne et les fige. Un slug ne peut appartenir qu'a un lot. Stats : gabarit de classe (Combat.luau) x coefficient
-- de rarete (Rarities.luau) x statOverrides (±15 % max).

export type UnitDef = {
	name: string,
	rarity: string,
	arena: number,
	families: { string },
	subRole: string?,
	class: string,
	category: string,
	skillId: string,
	aura: string?,
	statOverrides: { [string]: number },
	duoPartners: { string },
	lot: string,
}

type RawUnit = {
	name: string,
	rarity: string,
	arena: number,
	families: { string },
	subRole: string?,
	class: string,
	category: string,
	skillId: string,
	aura: string?,
	statOverrides: { [string]: number },
	duoPartners: { string },
}

local lots: { [string]: { [string]: RawUnit } } = {
	L0 = {},
}

for slug, unit in require(script.L0Brainrot) :: { [string]: RawUnit } do
	lots.L0[slug] = unit
end
for slug, unit in require(script.L0Tentafruit) :: { [string]: RawUnit } do
	assert(lots.L0[slug] == nil, `slug duplique dans le lot L0 : {slug}`)
	lots.L0[slug] = unit
end

local units: { [string]: UnitDef } = {}
local order: { string } = {}
for lotName, lot in lots do
	for slug, raw in lot do
		assert(units[slug] == nil, `slug present dans deux lots : {slug}`)
		local unit: UnitDef = {
			name = raw.name,
			rarity = raw.rarity,
			arena = raw.arena,
			families = table.freeze(table.clone(raw.families)),
			subRole = raw.subRole,
			class = raw.class,
			category = raw.category,
			skillId = raw.skillId,
			aura = raw.aura,
			statOverrides = table.freeze(table.clone(raw.statOverrides)),
			duoPartners = table.freeze(table.clone(raw.duoPartners)),
			lot = lotName,
		}
		units[slug] = table.freeze(unit)
		table.insert(order, slug)
	end
end
table.sort(order)

return table.freeze({
	units = table.freeze(units),
	slugs = table.freeze(order),
})
