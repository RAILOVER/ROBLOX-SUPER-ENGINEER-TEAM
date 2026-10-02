--!strict
-- Generateur pseudo-aleatoire deterministe (mulberry32, etat 32 bits). Pas de Random.new : meme seed => meme
-- suite sous Lune et sous Roblox. Toute arithmetique reste sous 2^53 (multiplication 32 bits par moities).

local Types = require(script.Parent.Parent.Types.Combat)

type Rng = Types.Rng
type Impl = { state: number }

local MOD = 4294967296 -- 2^32

local Rng = {}
Rng.__index = Rng

local function mul32(a: number, b: number): number
	local ah, al = a // 65536, a % 65536
	local bh, bl = b // 65536, b % 65536
	return (al * bl + ((ah * bl + al * bh) % 65536) * 65536) % MOD
end

local function nextUint32(self: Impl): number
	self.state = (self.state + 0x6D2B79F5) % MOD
	local z = self.state
	z = mul32(bit32.bxor(z, bit32.rshift(z, 15)), bit32.bor(z, 1))
	local mixed = mul32(bit32.bxor(z, bit32.rshift(z, 7)), bit32.bor(z, 61))
	z = bit32.bxor(z, (z + mixed) % MOD)
	return bit32.bxor(z, bit32.rshift(z, 14))
end

function Rng.new(seed: number): Rng
	local impl: Impl = { state = math.floor(seed) % MOD }
	return (setmetatable(impl, Rng) :: any) :: Rng
end

-- Nombre dans [0, 1) ou dans [min, max) si les bornes sont donnees.
function Rng.NextNumber(self: Impl, min: number?, max: number?): number
	local u = nextUint32(self) / MOD
	if min ~= nil and max ~= nil then
		return min + u * (max - min)
	end
	return u
end

-- Entier dans [min, max] inclus.
function Rng.NextInteger(self: Impl, min: number, max: number): number
	assert(max >= min, "Rng.NextInteger : max < min")
	local u = nextUint32(self) / MOD
	return min + math.floor(u * (max - min + 1))
end

function Rng.Clone(self: Impl): Rng
	return Rng.new(self.state)
end

return Rng
