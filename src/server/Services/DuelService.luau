--!strict
-- Service du duel TFT (T-0011) : cree les RemoteEvent decrits par DuelRemotes, garde chaque requete (RemoteGuard +
-- schema pur de DuelRemotes + siege + phase + cooldown 100 ms), place les joueurs dans un DuelMatch (2 humains ou
-- humain + DuelBot) et pousse DuelState / CombatLog / DuelEnded. Le client n'envoie que des intentions : jamais d'or,
-- de degats ni de resultat. Une requete invalide est ignoree et comptee, jamais une erreur serveur.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DuelRemotes = require(ReplicatedStorage.Shared.Remotes.DuelRemotes)
local Rng = require(ReplicatedStorage.Shared.Combat.Rng)
local RemoteGuard = require(script.Parent.Parent.Remotes.RemoteGuard)
local DuelBot = require(script.Parent.DuelBot)
local DuelMatch = require(script.Parent.DuelMatch)

type Match = DuelMatch.Match
type SeatRef = { match: Match, seatIndex: number }

local DuelService = {}

-- Attente d'un 2e humain quand le serveur compte au moins 2 joueurs ; sinon le bot remplace sans file (spec §6).
DuelService.LOBBY_SECONDS = 5

local remotes: { [string]: RemoteEvent } = {}
local seatByUser: { [number]: SeatRef } = {}
local waiting: Player? = nil
local invalidTotal = 0
local seedRng = Rng.new(math.floor(os.clock() * 1000) % 1000000)
local seedCounter = 0

local function nextSeed(): number
	seedCounter += 1
	return seedRng:NextInteger(1, 2 ^ 30) + seedCounter
end

local function send(match: Match, seatIndex: number, remoteName: string, payload: any): ()
	local seat = match.state.seats[seatIndex]
	if seat.kind ~= "human" then
		return
	end
	local player = Players:GetPlayerByUserId(seat.userId)
	local remote = remotes[remoteName]
	if player and remote then
		remote:FireClient(player, payload)
	end
end

local function onEnded(match: Match): ()
	for _, seat in match.state.seats do
		local ref = seatByUser[seat.userId]
		if ref and ref.match == match then
			seatByUser[seat.userId] = nil
		end
	end
end

local function startMatch(players: { Player }): ()
	local seatDefs: { DuelMatch.SeatDef } = {}
	for _, player in players do
		table.insert(
			seatDefs,
			{ kind = "human" :: "human", userId = player.UserId, displayName = player.DisplayName }
		)
	end
	if #seatDefs == 1 then
		table.insert(
			seatDefs,
			{ kind = "bot" :: "bot", userId = 0, displayName = DuelBot.DISPLAY_NAME }
		)
	end
	local match: Match
	match = DuelMatch.new(Config, nextSeed(), seatDefs, {
		send = function(seatIndex, remoteName, payload)
			send(match, seatIndex, remoteName, payload)
		end,
		onEnded = onEnded,
	})
	for index, player in players do
		seatByUser[player.UserId] = { match = match, seatIndex = index }
	end
	task.spawn(DuelMatch.run, match)
end

local function joinDuel(player: Player): ()
	local existing = seatByUser[player.UserId]
	if existing then
		-- reconnexion (D-M1-20) : le siege est conserve, on renvoie la vue courante
		existing.match.ghostSince[existing.seatIndex] = nil
		DuelMatch.broadcast(existing.match)
		return
	end
	if waiting == player then
		return
	end
	if waiting ~= nil and waiting.Parent ~= nil then
		local other = waiting :: Player
		waiting = nil
		startMatch({ other, player })
		return
	end
	if #Players:GetPlayers() >= 2 then
		waiting = player
		task.delay(DuelService.LOBBY_SECONDS, function()
			if waiting == player and player.Parent ~= nil then
				waiting = nil
				startMatch({ player })
			end
		end)
		return
	end
	startMatch({ player })
end

local function reject(player: Player, label: string): ()
	invalidTotal += 1
	RemoteGuard.strike(player, label)
	local ref = seatByUser[player.UserId]
	if ref then
		ref.match.state.seats[ref.seatIndex].invalidRequests += 1
	end
end

-- Garde complete d'une requete client puis execution via DuelMatch.handle (phase verifiee par DuelState).
local function onClientRemote(name: string, player: Player, ...: unknown): ()
	local contract = DuelRemotes.clientToServer[name]
	local args = table.pack(...)
	if args.n > #contract.args or not DuelRemotes.validateArgs(name, args) then
		reject(player, `DuelService.{name} args`)
		return
	end
	if not RemoteGuard.cooldown(player, `Duel.{name}`, DuelRemotes.COOLDOWN_SECONDS) then
		reject(player, `DuelService.{name} cooldown`)
		return
	end
	if name == "JoinDuel" then
		joinDuel(player)
		return
	end
	local ref = seatByUser[player.UserId]
	if ref == nil then
		reject(player, `DuelService.{name} no_seat`)
		return
	end
	if contract.phase ~= nil and ref.match.state.phase ~= contract.phase then
		reject(player, `DuelService.{name} phase`)
		return
	end
	local result = DuelMatch.handle(ref.match, ref.seatIndex, name, { ... })
	if not result.ok then
		RemoteGuard.strike(player, `DuelService.{name} {result.reason or "refused"}`)
		invalidTotal += 1
	end
end

local function onPlayerRemoving(player: Player): ()
	RemoteGuard.forget(player)
	if waiting == player then
		waiting = nil
	end
	local ref = seatByUser[player.UserId]
	if ref == nil then
		return
	end
	local match = ref.match
	local since = os.clock()
	match.ghostSince[ref.seatIndex] = since
	task.delay(Config.Duel.ghostAfterSeconds, function()
		if match.ghostSince[ref.seatIndex] == since and match.state.phase ~= "Fin" then
			DuelMatch.forfeit(match, ref.seatIndex)
			seatByUser[player.UserId] = nil
		end
	end)
end

function DuelService.invalidRequests(): number
	return invalidTotal
end

function DuelService.start(): ()
	local folder = Instance.new("Folder")
	folder.Name = DuelRemotes.FOLDER
	for _, name in DuelRemotes.clientOrder do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		remote.OnServerEvent:Connect(function(player: Player, ...: unknown)
			onClientRemote(name, player, ...)
		end)
		remotes[name] = remote
	end
	for _, name in DuelRemotes.serverToClient do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		remotes[name] = remote
	end
	folder.Parent = ReplicatedStorage
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return DuelService
