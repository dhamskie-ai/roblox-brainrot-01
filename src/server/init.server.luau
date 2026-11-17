-- init.server.luau — bootstrap only: creates the RemoteEvents, wires the
-- modules together, assigns each joining player a corner base, hides the
-- default name tags, then starts every system.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(script.Parent.PlayerState)
local Config = require(ReplicatedStorage.Shared.Config)
local ConveyorSpawner = require(script.Parent.ConveyorSpawner)
local CarryAndPlace = require(script.Parent.CarryAndPlace)
local MoneyTick = require(script.Parent.MoneyTick)
local StealAndLock = require(script.Parent.StealAndLock)
local TsunamiEvent = require(script.Parent.TsunamiEvent)
local ThiefBot = require(script.Parent.ThiefBot)
local RebirthSystem = require(script.Parent.RebirthSystem)

-- RemoteEvents, all under ReplicatedStorage.Remotes.
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

makeRemote("MoneyUpdate") -- server -> one client: cash, income, timers, lock, rebirth
makeRemote("WaveWarning") -- server -> all clients: tsunami warning seconds
makeRemote("ToastMessage") -- server -> one client: short message
makeRemote("SoundEvent") -- server -> one client: "buy" | "wave" | "steal" | "rebirth"
local requestLock = makeRemote("RequestLock") -- client -> server: lock my base
local requestRebirth = makeRemote("RequestRebirth") -- client -> server: rebirth now

-- Wire the shared Remotes folder into every module that toasts or plays sounds.
CarryAndPlace.Remotes = Remotes
MoneyTick.Remotes = Remotes
StealAndLock.Remotes = Remotes
TsunamiEvent.Remotes = Remotes
RebirthSystem.Remotes = Remotes

-- The belt's buy prompt calls CarryAndPlace through this handler.
ConveyorSpawner.buyHandler = CarryAndPlace.buyBrainrot

requestLock.OnServerEvent:Connect(function(player)
	StealAndLock.lockBaseForPlayer(player)
end)

requestRebirth.OnServerEvent:Connect(function(player)
	RebirthSystem.doRebirth(player)
end)

-- Bases are assigned round-robin as players join (4 bases, shared if more).
local nextBase = 0
local function assignBase(player)
	nextBase = (nextBase % 4) + 1
	PlayerState.initPlayer(player, nextBase)
	local spawn = workspace:FindFirstChild("Spawn" .. tostring(nextBase))
	if spawn then
		player.RespawnLocation = spawn
	end
end

local function onCharacterAdded(player, character)
	task.wait(0.5)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Hide the default name tag: only our own labels show.
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

Players.PlayerAdded:Connect(function(player)
	assignBase(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	CarryAndPlace.dropCarried(player)
	CarryAndPlace.clearPlayerPedestals(player)
	PlayerState.removePlayer(player)
end)

-- World signs: Rojo 7.7.1 cannot express UDim2 in default.project.json, so
-- the sign boards are parts in the project and their BillboardGui labels are
-- built here at runtime (board part name -> text, colour, billboard size).
local function buildWorldSigns()
	local signs = {
		{ part = "ConveyorSign", text = "SABUK BRAINROT", color = Color3.fromRGB(255, 217, 51), size = UDim2.new(10, 0, 3, 0) },
		-- FIX (17 Nov 2026): floating beacon label above the belt beam, so
		-- the belt reads from every spawn, even at 60 studs away.
		{ part = "BeltBeacon", text = "▼ SABUK BRAINROT ▼", color = Color3.fromRGB(255, 217, 51), size = UDim2.new(26, 0, 4, 0) },
		{ part = "TitleSign", text = "PASAR BRAINROT", color = Color3.fromRGB(255, 217, 51), size = UDim2.new(18, 0, 3, 0) },
		{ part = "BaseSignRed", text = "BASE MERAH", color = Color3.fromRGB(255, 89, 89), size = UDim2.new(10, 0, 2, 0) },
		{ part = "BaseSignBlue", text = "BASE BIRU", color = Color3.fromRGB(102, 166, 255), size = UDim2.new(10, 0, 2, 0) },
		{ part = "BaseSignGreen", text = "BASE HIJAU", color = Color3.fromRGB(102, 255, 128), size = UDim2.new(10, 0, 2, 0) },
		{ part = "BaseSignYellow", text = "BASE KUNING", color = Color3.fromRGB(255, 217, 51), size = UDim2.new(10, 0, 2, 0) },
		{ part = "ThiefSignSouth", text = "SUDUT MALING", color = Color3.fromRGB(255, 89, 89), size = UDim2.new(6, 0, 1.5, 0) },
	}
	for _, sign in ipairs(signs) do
		local board = workspace:FindFirstChild(sign.part)
		if board then
			local gui = Instance.new("BillboardGui")
			gui.Name = "SignGui"
			gui.Size = sign.size
			gui.AlwaysOnTop = true
			gui.Parent = board
			local label = Instance.new("TextLabel")
			label.Name = "SignText"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = sign.text
			label.TextColor3 = sign.color
			label.TextStrokeTransparency = 0
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.Parent = gui
		end
	end
end

-- Build the world pieces the project JSON does not hold: pedestals + lock posts.
CarryAndPlace.buildBasePedestals()
buildWorldSigns()

-- Start every system.
ConveyorSpawner.start()
MoneyTick.start()
TsunamiEvent.start()
ThiefBot.start()

print("Pasar Brainrot — Curi, Kumpul, Kaya. Server siap.")
