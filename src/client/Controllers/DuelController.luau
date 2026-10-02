--!strict
-- Lien client <-> DuelService (T-0012). Le client AFFICHE et DEMANDE : il envoie des intentions et garde le dernier
-- etat confirme par le serveur. Aucune valeur de gameplay (or, prix, PV, degats, XP, niveau, resultat) n'est calculee
-- ici. Si le serveur ignore ou refuse une intention, rien n'est a defaire : l'UI se redessine sur le prochain
-- DuelState. Les remotes sont decouverts en iterant DuelRemotes.clientToServer / serverToClient, jamais recopies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DuelRemotes = require(ReplicatedStorage.Shared.Remotes.DuelRemotes)
local Types = require(ReplicatedStorage.Shared.Types.Duel)

export type ClientView = Types.ClientView
export type CombatLogPayload = Types.CombatLogPayload
export type DuelEndedPayload = Types.DuelEndedPayload
export type Tactic = Types.Tactic

type Listener<T> = (T) -> ()
type Disconnect = () -> ()

local REMOTES_WAIT_SECONDS = 15

local DuelController = {}

local sendRemotes: { [string]: RemoteEvent } = {}
local connections: { RBXScriptConnection } = {}
local stateListeners: { Listener<ClientView> } = {}
local logListeners: { Listener<CombatLogPayload> } = {}
local endedListeners: { Listener<DuelEndedPayload> } = {}

-- Dernier etat confirme par le serveur (la seule source de verite de l'UI).
local confirmedView: ClientView? = nil
local confirmedLog: CombatLogPayload? = nil
local ended: DuelEndedPayload? = nil
local stateVersion = 0
local lastSentAt: { [string]: number } = {}

local function addListener<T>(list: { Listener<T> }, listener: Listener<T>): Disconnect
	table.insert(list, listener)
	return function()
		local index = table.find(list, listener)
		if index then
			table.remove(list, index)
		end
	end
end

local function emit<T>(list: { Listener<T> }, payload: T)
	for _, listener in table.clone(list) do
		local ok, err = pcall(listener, payload)
		if not ok then
			warn(`[DuelController] listener en erreur : {err}`)
		end
	end
end

local receivers: { [string]: (any) -> () } = {
	DuelState = function(view: any)
		if type(view) ~= "table" then
			return
		end
		confirmedView = view :: ClientView
		stateVersion += 1
		emit(stateListeners, confirmedView :: ClientView)
	end,
	CombatLog = function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		confirmedLog = payload :: CombatLogPayload
		emit(logListeners, confirmedLog :: CombatLogPayload)
	end,
	DuelEnded = function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		ended = payload :: DuelEndedPayload
		emit(endedListeners, ended :: DuelEndedPayload)
	end,
}

-- Attend ReplicatedStorage.DuelRemotes (cree par DuelService) et branche chaque RemoteEvent du contrat.
function DuelController.start(): boolean
	local folder = ReplicatedStorage:WaitForChild(DuelRemotes.FOLDER, REMOTES_WAIT_SECONDS)
	if folder == nil then
		warn(`[DuelController] dossier {DuelRemotes.FOLDER} absent apres {REMOTES_WAIT_SECONDS} s`)
		return false
	end
	for name in DuelRemotes.clientToServer do
		local remote = folder:WaitForChild(name, REMOTES_WAIT_SECONDS)
		if remote and remote:IsA("RemoteEvent") then
			sendRemotes[name] = remote
		else
			warn(`[DuelController] remote client->serveur {name} absent`)
		end
	end
	for _, name in DuelRemotes.serverToClient do
		local remote = folder:WaitForChild(name, REMOTES_WAIT_SECONDS)
		local receiver = receivers[name]
		if remote and remote:IsA("RemoteEvent") and receiver then
			table.insert(connections, remote.OnClientEvent:Connect(receiver))
		else
			warn(`[DuelController] remote serveur->client {name} absent`)
		end
	end
	return true
end

function DuelController.stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	table.clear(sendRemotes)
end

-- Envoie une intention nommee dans le contrat. Retourne false si le remote manque ou si le cooldown contractuel
-- (DuelRemotes.COOLDOWN_SECONDS) n'est pas ecoule : le serveur l'aurait ignoree de toute facon.
function DuelController.send(name: string, ...: any): boolean
	local remote = sendRemotes[name]
	if remote == nil then
		warn(`[DuelController] intention inconnue ou non branchee : {name}`)
		return false
	end
	local now = os.clock()
	local last = lastSentAt[name]
	if last ~= nil and now - last < DuelRemotes.COOLDOWN_SECONDS then
		return false
	end
	lastSentAt[name] = now
	remote:FireServer(...)
	return true
end

-- Intentions du contrat (DuelRemotes.clientToServer). Les arguments sont transmis tels quels : le serveur valide.
function DuelController.join(): boolean
	return DuelController.send("JoinDuel")
end

function DuelController.buyShopSlot(slot: number): boolean
	return DuelController.send("BuyShopSlot", slot)
end

function DuelController.reroll(): boolean
	return DuelController.send("Reroll")
end

function DuelController.buyXp(): boolean
	return DuelController.send("BuyXp")
end

function DuelController.placeUnit(instanceId: string, row: number, col: number): boolean
	return DuelController.send("PlaceUnit", instanceId, row, col)
end

function DuelController.benchUnit(instanceId: string): boolean
	return DuelController.send("BenchUnit", instanceId)
end

function DuelController.sellUnit(instanceId: string): boolean
	return DuelController.send("SellUnit", instanceId)
end

function DuelController.setTactic(tactic: Tactic, instanceId: string?): boolean
	return DuelController.send("SetTactic", tactic, instanceId)
end

function DuelController.orderFocus(cell: number): boolean
	return DuelController.send("OrderFocus", cell)
end

function DuelController.ready(): boolean
	return DuelController.send("Ready")
end

-- Lecture de l'etat confirme ------------------------------------------------------------------------------

function DuelController.getView(): ClientView?
	return confirmedView
end

function DuelController.getCombatLog(): CombatLogPayload?
	return confirmedLog
end

function DuelController.getEnded(): DuelEndedPayload?
	return ended
end

-- Compteur incremente a chaque DuelState recu : un affichage optimiste note la version au depart et s'annule
-- des qu'une version superieure arrive sans confirmer l'intention (DragDrop).
function DuelController.getStateVersion(): number
	return stateVersion
end

-- Vrai si l'intention `name` est acceptee dans la phase courante d'apres le contrat (affichage grise sinon).
-- C'est une lecture du contrat, pas une decision : le serveur reste juge.
function DuelController.isIntentOpen(name: string): boolean
	local def = DuelRemotes.clientToServer[name]
	if def == nil or sendRemotes[name] == nil then
		return false
	end
	if def.phase == nil then
		return true
	end
	local view = confirmedView
	return view ~= nil and view.phase == def.phase
end

function DuelController.onState(listener: Listener<ClientView>): Disconnect
	return addListener(stateListeners, listener)
end

function DuelController.onCombatLog(listener: Listener<CombatLogPayload>): Disconnect
	return addListener(logListeners, listener)
end

function DuelController.onEnded(listener: Listener<DuelEndedPayload>): Disconnect
	return addListener(endedListeners, listener)
end

return DuelController
