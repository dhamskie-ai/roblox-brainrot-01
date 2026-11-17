-- ConveyorSpawner.luau — the Sabuk Brainrot: every SPAWN_INTERVAL_S a
-- brainrot appears at the west end of the belt, walks east at BELT_SPEED,
-- and despawns at the east end if nobody buys it. Buying is a ProximityPrompt
-- (hold E 0.5 s, or tap on mobile); the buy itself lives in CarryAndPlace,
-- wired in by init.server.luau as ConveyorSpawner.buyHandler.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local BrainrotData = require(Shared.BrainrotData)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local ConveyorSpawner = {}

-- Set by init.server.luau: function(player, model) — the buy.
ConveyorSpawner.buyHandler = nil

local beltModels = {} -- [Model] = true while it walks the belt
local nextSpawnAt = 0

local function faceEast(model, x)
	if not model or not model.PrimaryPart then
		return
	end
	local size = model:GetAttribute("BodySize") or 2
	model:PivotTo(CFrame.new(x, Config.BELT_Y + size / 2, Config.BELT_Z) * CFrame.Angles(0, math.rad(90), 0))
end

function ConveyorSpawner.isOnBelt(model)
	return beltModels[model] == true
end

function ConveyorSpawner.getNextSpawnIn()
	return math.max(0, nextSpawnAt - os.clock())
end

function ConveyorSpawner.getBeltCount()
	local count = 0
	for _, _ in pairs(beltModels) do
		count += 1
	end
	return count
end

-- Walks one model along the belt until it is bought, returned, or reaches
-- the east end (then it despawns).
local function walkBelt(model)
	task.spawn(function()
		while model.Parent and beltModels[model] do
			-- FIX #2: GetPivot throw bila model dihancurkan antar-tick —
			-- tangkap, jangan matikan thread jalan ini.
			local pivotOk, pivot = pcall(function()
				return model:GetPivot()
			end)
			if not pivotOk then
				return
			end
			local x = pivot.Position.X + Config.BELT_SPEED * 0.1
			if x >= Config.BELT_END_X then
				ConveyorSpawner.removeFromBelt(model)
				model:Destroy()
				return
			end
			-- FIX #2: satu langkah jalan yang throw (mis. model hancur di
			-- tengah jalan) tidak boleh mematikan thread jalan ini.
			local ok, err = pcall(faceEast, model, x)
			if not ok then
				warn("[PasarBrainrot] walkBelt gagal: " .. tostring(err))
				return
			end
			task.wait(0.1)
		end
	end)
end

function ConveyorSpawner.spawnNextBrainrot(startX)
	local row = BrainrotData.rollCharacter()
	local mutation = BrainrotFactory.rollMutation()
	-- FIX #2: satu roll/model yang gagal build tidak boleh melempar ke
	-- pemanggil (start() / loop timer) — kembalikan nil saja.
	local ok, model = pcall(BrainrotFactory.buildBrainrotModel, row, mutation)
	if not ok or typeof(model) ~= "Instance" or not model.PrimaryPart then
		warn("[PasarBrainrot] buildBrainrotModel gagal: " .. tostring(model))
		return nil
	end
	model.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Beli"
	prompt.ObjectText = model.Name .. " — $" .. tostring(model:GetAttribute("Price"))
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if ConveyorSpawner.buyHandler then
			ConveyorSpawner.buyHandler(player, model)
		end
	end)

	beltModels[model] = true
	faceEast(model, startX or Config.BELT_START_X)
	walkBelt(model)
	return model
end

-- A dropped or stolen brainrot goes back to the west end and walks again.
function ConveyorSpawner.returnToBelt(model)
	if not model.Parent then
		return
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	local prompt = primary:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Beli"
		prompt.ObjectText = model.Name .. " — $" .. tostring(model:GetAttribute("Price"))
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 8
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = model.PrimaryPart
		prompt.Triggered:Connect(function(player)
			if ConveyorSpawner.buyHandler then
				ConveyorSpawner.buyHandler(player, model)
			end
		end)
	end
	prompt.Enabled = true
	beltModels[model] = true
	faceEast(model, Config.BELT_START_X)
	walkBelt(model)
end

function ConveyorSpawner.removeFromBelt(model)
	beltModels[model] = nil
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end
end

function ConveyorSpawner.start()
	-- FIX (17 Nov 2026): three brainrots are ON the belt the moment the
	-- server starts (spaced 12 studs apart), so the first player never
	-- joins to an empty belt. The regular 6 s timer starts after them.
	-- FIX #2: tiap spawn awal dalam pcall sendiri — satu roll gagal tidak
	-- boleh membatalkan dua spawn lainnya atau mematikan init.
	for _, offset in ipairs({ 0, 12, 24 }) do
		local ok, err = pcall(ConveyorSpawner.spawnNextBrainrot, Config.BELT_START_X + offset)
		if not ok then
			warn("[PasarBrainrot] spawn awal gagal: " .. tostring(err))
		end
	end
	nextSpawnAt = os.clock() + Config.SPAWN_INTERVAL_S
	task.spawn(function()
		while true do
			local waitFor = nextSpawnAt - os.clock()
			if waitFor > 0 then
				task.wait(waitFor)
			end
			nextSpawnAt = os.clock() + Config.SPAWN_INTERVAL_S
			-- FIX #2: satu spawn yang throw tidak boleh membunuh loop
			-- timer selamanya — spawn berikutnya tetap jalan 6 dtk lagi.
			local ok, err = pcall(ConveyorSpawner.spawnNextBrainrot)
			if not ok then
				warn("[PasarBrainrot] spawn timer gagal: " .. tostring(err))
			end
		end
	end)
end

return ConveyorSpawner
