--!strict
-- M-C-06 : chaque module de src/shared/Combat fait au plus 400 lignes et commence par --!strict.

local fs = require("@lune/fs")

describe("CombatSim taille des modules (M-C-06)", function()
	it("M-C-06 : src/shared/Combat/*.luau <= 400 lignes, --!strict en ligne 1", function()
		local count = 0
		for _, name in fs.readDir("src/shared/Combat") do
			if not string.match(name, "%.luau$") then
				continue
			end
			local source = fs.readFile(`src/shared/Combat/{name}`)
			local lines = 0
			for _ in string.gmatch(source, "[^\n]*\n?") do
				lines += 1
			end
			expect(lines <= 401).toBe(true)
			expect(string.sub(source, 1, 9)).toBe("--!strict")
			count += 1
		end
		expect(count >= 9).toBe(true)
	end)
end)
