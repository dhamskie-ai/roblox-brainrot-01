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
			local pivot = model:GetPivot()
			local x = pivot.Position.X + Config.BELT_SPEED * 0.1
			if x >= Config.BELT_END_X then
				ConveyorSpawner.removeFromBelt(model)
				model:Destroy()
				return
			end
			faceEast(model, x)
			task.wait(0.1)
		end
	end)
end

function ConveyorSpawner.spawnNextBrainrot()
	local row = BrainrotData.rollCharacter()
	local mutation = BrainrotFactory.rollMutation()
	local model = BrainrotFactory.buildBrainrotModel(row, mutation)
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
	faceEast(model, Config.BELT_START_X)
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
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
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
	nextSpawnAt = os.clock() + 2
	task.spawn(function()
		while true do
			local waitFor = nextSpawnAt - os.clock()
			if waitFor > 0 then
				task.wait(waitFor)
			end
			nextSpawnAt = os.clock() + Config.SPAWN_INTERVAL_S
			ConveyorSpawner.spawnNextBrainrot()
		end
	end)
end

return ConveyorSpawner
