-- Main.server.luau — bootstrap only: creates the RemoteEvents and the
-- ServerStatus diagnostic FIRST, then requires every system module inside
-- pcall, wires them together, assigns each joining player a corner base,
-- hides the default name tags, then starts every system.
--
-- FIX #3 (18 Nov 2026): the old init.server.luau DIED AT REQUIRE TIME.
-- Rojo turns a folder holding init.server.luau into a Script named after
-- the folder, so ServerScriptService.Server WAS the init script itself —
-- and its `require(script.Parent.PlayerState)` looked for PlayerState
-- under ServerScriptService, where it does not exist. The very first
-- require threw, the script died before the Remotes folder existed, and
-- no MoneyUpdate ever reached any client (empty belt, "Menunggu server..."
-- forever). The fix: this file is Main.server.luau, so the Server folder
-- stays a Folder, Main is a normal Script inside it, and script.Parent is
-- the folder holding every module. Remotes + ServerStatus are now created
-- BEFORE any require, every require is pcall-wrapped, and a 5 s heartbeat
-- keeps ServerStatus fresh so the client's HUD line proves the server is
-- alive (or names the first error).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes FIRST — before any require can fail. A client that finds this
-- folder knows the server script is at least alive.
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

-- ServerStatus: the one diagnostic the client can read. "OK ..." + a
-- heartbeat timestamp while the core loop is healthy; the FIRST
-- require/start error while it is broken. The client shows this line on
-- the HUD, so the next screenshot names the server's state.
local ServerStatus = Instance.new("StringValue")
ServerStatus.Name = "ServerStatus"
ServerStatus.Value = "BOOT: Remotes dibuat, memuat modul..."
ServerStatus.Parent = ReplicatedStorage

local firstError = nil
local function setStatus(text)
	pcall(function()
		ServerStatus.Value = text
	end)
end
local function recordError(stage, err)
	warn("[PasarBrainrot] " .. stage .. " gagal: " .. tostring(err))
	if not firstError then
		firstError = stage .. ": " .. tostring(err)
	end
end

local function safeRequire(name, fn)
	local ok, mod = pcall(fn)
	if not ok then
		recordError("require " .. name, mod)
		return nil
	end
	return mod
end

-- Shared is part of the place file, so this returns at once; the 10 s
-- timeout only stops a hang if it ever failed to replicate.
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
	recordError("require Shared", "ReplicatedStorage.Shared tidak ditemukan (10 dtk)")
end

local PlayerState = safeRequire("PlayerState", function()
	return require(script.Parent.PlayerState)
end)
local Config = nil
if Shared then
	Config = safeRequire("Config", function()
		return require(Shared.Config)
	end)
end
local ConveyorSpawner = safeRequire("ConveyorSpawner", function()
	return require(script.Parent.ConveyorSpawner)
end)
local CarryAndPlace = safeRequire("CarryAndPlace", function()
	return require(script.Parent.CarryAndPlace)
end)
local MoneyTick = safeRequire("MoneyTick", function()
	return require(script.Parent.MoneyTick)
end)
local StealAndLock = safeRequire("StealAndLock", function()
	return require(script.Parent.StealAndLock)
end)
local TsunamiEvent = safeRequire("TsunamiEvent", function()
	return require(script.Parent.TsunamiEvent)
end)
local ThiefBot = safeRequire("ThiefBot", function()
	return require(script.Parent.ThiefBot)
end)
local RebirthSystem = safeRequire("RebirthSystem", function()
	return require(script.Parent.RebirthSystem)
end)

-- Wire the shared Remotes folder into every module that toasts or plays sounds.
if CarryAndPlace then
	CarryAndPlace.Remotes = Remotes
end
if MoneyTick then
	MoneyTick.Remotes = Remotes
end
if StealAndLock then
	StealAndLock.Remotes = Remotes
end
if TsunamiEvent then
	TsunamiEvent.Remotes = Remotes
end
if RebirthSystem then
	RebirthSystem.Remotes = Remotes
end

-- The belt's buy prompt calls CarryAndPlace through this handler.
if ConveyorSpawner and CarryAndPlace then
	ConveyorSpawner.buyHandler = CarryAndPlace.buyBrainrot
end

requestLock.OnServerEvent:Connect(function(player)
	if StealAndLock then
		StealAndLock.lockBaseForPlayer(player)
	end
end)

requestRebirth.OnServerEvent:Connect(function(player)
	if RebirthSystem then
		RebirthSystem.doRebirth(player)
	end
end)

-- Bases are assigned round-robin as players join (4 bases, shared if more).
local nextBase = 0
local function assignBase(player)
	nextBase = (nextBase % 4) + 1
	if PlayerState then
		PlayerState.initPlayer(player, nextBase)
	end
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
	-- FIX #3: one player's bad init must never kill the handler for the
	-- next player (or the whole bootstrap) — caught here, warned, counted.
	local ok, err = pcall(assignBase, player)
	if not ok then
		recordError("initPlayer " .. player.Name, err)
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if CarryAndPlace then
		CarryAndPlace.dropCarried(player)
		CarryAndPlace.clearPlayerPedestals(player)
	end
	if PlayerState then
		PlayerState.removePlayer(player)
	end
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
		local ok, err = pcall(function()
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
		end)
		if not ok then
			warn("[PasarBrainrot] buildWorldSigns gagal untuk " .. sign.part .. ": " .. tostring(err))
		end
	end
end

-- FIX #2 (17 Nov 2026): startup antipetir. Setiap build/start jalan dalam
-- pcall-nya sendiri dengan warn(), jadi satu sistem yang gagal TIDAK BOLEH
-- mematikan init atau sistem sesudahnya. MoneyTick start PALING DULU:
-- detak MoneyUpdate 1 detik adalah heartbeat HUD, dan sabuk / tsunami /
-- bot tidak boleh menghalanginya walau mereka gagal total.
-- FIX #3: a nil module (failed require) is recorded, not called.
local function safeStart(name, fn)
	if not fn then
		recordError(name, "modul tidak termuat, start dilewati")
		return false
	end
	local ok, err = pcall(fn)
	if not ok then
		recordError(name, err)
	end
	return ok
end

-- Build the world pieces the project JSON does not hold: pedestals + lock posts.
if CarryAndPlace then
	safeStart("buildBasePedestals", CarryAndPlace.buildBasePedestals)
else
	recordError("buildBasePedestals", "CarryAndPlace tidak termuat")
end
safeStart("buildWorldSigns", buildWorldSigns)

-- Start every system. MoneyTick first — its 1 s MoneyUpdate is the HUD's
-- heartbeat; the belt, the wave and the bots must never block it.
local moneyTickOk = false
if MoneyTick then
	moneyTickOk = safeStart("MoneyTick", MoneyTick.start)
else
	recordError("MoneyTick", "modul tidak termuat")
end
if ConveyorSpawner then
	safeStart("ConveyorSpawner", ConveyorSpawner.start)
else
	recordError("ConveyorSpawner", "modul tidak termuat")
end
if TsunamiEvent then
	safeStart("TsunamiEvent", TsunamiEvent.start)
else
	recordError("TsunamiEvent", "modul tidak termuat")
end
if ThiefBot then
	safeStart("ThiefBot", ThiefBot.start)
else
	recordError("ThiefBot", "modul tidak termuat")
end

-- The core loop is PlayerState + MoneyTick + ConveyorSpawner. Only when all
-- three are up does the heartbeat report OK; otherwise ServerStatus names
-- the first error, so the client's HUD line tells the truth either way.
local coreOk = PlayerState ~= nil and moneyTickOk and ConveyorSpawner ~= nil

-- FIX #3 heartbeat: every 5 s refresh ServerStatus with a live timestamp
-- plus player and belt counts, so the HUD line proves the server is alive
-- (not just booted once). A partial failure stays visible after the OK.
task.spawn(function()
	while true do
		task.wait(5)
		if coreOk then
			local playerCount = 0
			local beltCount = 0
			pcall(function()
				playerCount = #PlayerState.getAllPlayers()
			end)
			pcall(function()
				beltCount = ConveyorSpawner.getBeltCount()
			end)
			local text = "OK | " .. os.date("%H:%M:%S") .. " | pemain: " .. tostring(playerCount) .. " | sabuk: " .. tostring(beltCount)
			if firstError then
				text = text .. " | rusak: " .. firstError
			end
			setStatus(text)
		else
			setStatus("ERROR " .. (firstError or "server gagal start"))
		end
	end
end)

if coreOk then
	setStatus("OK | server siap | " .. os.date("%H:%M:%S"))
else
	setStatus("ERROR " .. (firstError or "server gagal start"))
end

print("Pasar Brainrot — Curi, Kumpul, Kaya. Server siap.")
