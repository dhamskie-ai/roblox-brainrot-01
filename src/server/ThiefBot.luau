-- SPDX-License-Identifier: MIT
-- ThiefBot.luau — 2 thief bots roam the plaza so the game has tension
-- even with one human player. A bot picks a random occupied pedestal,
-- walks there with PathfindingService, holds 2 s to steal, then runs to
-- its corner. If a player touches the bot while it carries, it drops the
-- brainrot back onto the belt. A stolen brainrot despawns after 10 s.

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
if not Shared then
	error("[PasarBrainrot] ReplicatedStorage.Shared tidak ditemukan (10 dtk)")
end
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local StealAndLock = require(script.Parent.StealAndLock)
local CarryAndPlace = require(script.Parent.CarryAndPlace)
local ConveyorSpawner = require(script.Parent.ConveyorSpawner)

local ThiefBot = {}

local bots = {}

local function makePart(name, size, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- A simple blocky humanoid: HumanoidRootPart + Torso + Head + limbs, welded.
local function buildBotModel(name, color, spawnPos)
	local model = Instance.new("Model")
	model.Name = name

	local root = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), color)
	root.CFrame = CFrame.new(spawnPos + Vector3.new(0, 3, 0))
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root

	local torso = makePart("Torso", Vector3.new(2, 2, 1), color)
	torso.CFrame = root.CFrame * CFrame.new(0, 2, 0)
	torso.Parent = model
	local torsoWeld = Instance.new("Weld")
	torsoWeld.Part0 = root
	torsoWeld.Part1 = torso
	torsoWeld.C0 = CFrame.new(0, 2, 0)
	torsoWeld.Parent = root

	local head = makePart("Head", Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(40, 40, 40))
	head.Shape = Enum.PartType.Ball
	head.CFrame = root.CFrame * CFrame.new(0, 3.7, 0)
	head.Parent = model
	local headWeld = Instance.new("Weld")
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.C0 = CFrame.new(0, 1.7, 0)
	headWeld.Parent = torso

	for _, side in ipairs({ -1, 1 }) do
		local arm = makePart("Arm", Vector3.new(1, 2, 1), color)
		arm.CFrame = root.CFrame * CFrame.new(side * 1.5, 2, 0)
		arm.Parent = model
		local armWeld = Instance.new("Weld")
		armWeld.Part0 = torso
		armWeld.Part1 = arm
		armWeld.C0 = CFrame.new(side * 1.5, 0, 0)
		armWeld.Parent = torso

		local leg = makePart("Leg", Vector3.new(1, 2, 1), Color3.fromRGB(30, 30, 30))
		leg.CFrame = root.CFrame * CFrame.new(side * 0.5, -2, 0)
		leg.Parent = model
		local legWeld = Instance.new("Weld")
		legWeld.Part0 = root
		legWeld.Part1 = leg
		legWeld.C0 = CFrame.new(side * 0.5, -2, 0)
		legWeld.Parent = root
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = 12
	humanoid.Parent = model

	-- FIX #4: MALING! label is NOT AlwaysOnTop any more, hides beyond
	-- 60 studs, fixed TextSize — it used to balloon over the HUD/server
	-- status bar whenever a bot walked near the camera. The steal itself
	-- is still announced via the toast channel (StealAndLock.toast).
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(70, 20)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	billboard.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "MALING!"
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextStrokeTransparency = 0
	label.TextScaled = false
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	model.Parent = workspace
	return model
end

-- Walks the bot's humanoid to targetPos with PathfindingService. Recomputes
-- if the target moved >6 studs or the bot is stuck ~1.5 s (roblox-game-01
-- rev-5 recipe). Returns true when the bot arrives.
-- FIX #2: recompute depth is capped at 3 — the old unbounded recursion
-- could stack-overflow if a bot got permanently stuck.
local function moveBotTo(bot, targetPos, depth)
	depth = depth or 0
	local humanoid = bot.model:FindFirstChildOfClass("Humanoid")
	local root = bot.model.PrimaryPart
	if not humanoid or not root then
		return false
	end
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = false,
	})
	local ok, _ = pcall(function()
		path:ComputeAsync(root.Position, targetPos)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		humanoid:MoveTo(targetPos)
		local finished = humanoid.MoveToFinished:Wait(3)
		return finished
	end
	local waypoints = path:GetWaypoints()
	for _, waypoint in ipairs(waypoints) do
		if not bot.model.Parent then
			return false
		end
		humanoid:MoveTo(waypoint.Position)
		local reached = false
		local conn
		conn = humanoid.MoveToFinished:Connect(function(result)
			reached = result
		end)
		local waited = 0
		while not reached and waited < 3 do
			task.wait(0.1)
			waited += 0.1
		end
		conn:Disconnect()
		if not reached then
			if depth >= 3 then
				return false
			end
			return moveBotTo(bot, targetPos, depth + 1) -- stuck: recompute the path
		end
	end
	return true
end

local function dropStolen(bot)
	if not bot.carried then
		return
	end
	local model = bot.carried
	bot.carried = nil
	local head = bot.model:FindFirstChild("Head")
	if head then
		local weld = head:FindFirstChild("CarryWeld")
		if weld then
			weld:Destroy()
		end
	end
	if model.Parent then
		ConveyorSpawner.returnToBelt(model)
	end
end

local function botBrain(bot)
	task.spawn(function()
		while bot.model.Parent do
			-- FIX #2: satu iterasi otak bot yang throw tidak boleh
			-- mematikan bot selamanya — tangkap, warn, lanjut loop.
			local ok, err = pcall(function()
				task.wait(2 + math.random() * 3)
				local owned = PlayerState.getAllOwnedPedestals()
				if #owned == 0 then
					-- Nothing to steal: wander to a random plaza spot.
					local wander = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
					moveBotTo(bot, wander)
				else
					local target = owned[math.random(1, #owned)]
					local pedestal = CarryAndPlace.getPedestal(target.baseIndex, target.slot)
					if pedestal then
						local dest = pedestal.part.Position + Vector3.new(0, 1, 0)
						local arrived = moveBotTo(bot, dest)
						if arrived and pedestal.record then
							task.wait(Config.BOT_STEAL_HOLD_S)
							if pedestal.record then
								local model = StealAndLock.tryStealBrainrotForBot(target.baseIndex, target.slot)
								if model then
									-- Carry it above the bot's head and run to the corner.
									for _, part in ipairs(model:GetDescendants()) do
										if part:IsA("BasePart") then
											part.Anchored = false
										end
									end
									local head = bot.model:FindFirstChild("Head")
									if head then
										local body = model.PrimaryPart
										if body then
											-- FIX #2: tinggi bawa ikut ukuran model (lihat CarryAndPlace).
											local carryY = (model:GetAttribute("BodySize") or 2) / 2 + 2.2
											body.CFrame = head.CFrame * CFrame.new(0, carryY, 0)
											local weld = Instance.new("Weld")
											weld.Name = "CarryWeld"
											weld.Part0 = head
											weld.Part1 = body
											weld.C0 = CFrame.new(0, carryY, 0)
											weld.Parent = head
											bot.carried = model
										end
									end
									moveBotTo(bot, bot.corner)
									task.wait(Config.BOT_DESPAWN_S)
									if bot.carried then
										local stolen = bot.carried
										bot.carried = nil
										if stolen.Parent then
											stolen:Destroy()
										end
									end
								end
							end
						end
					end
				end
			end)
			if not ok then
				warn("[PasarBrainrot] botBrain gagal: " .. tostring(err))
			end
		end
	end)
end

function ThiefBot.start()
	for i = 1, Config.THIEF_BOTS do
		-- FIX #2: satu bot yang gagal build tidak boleh membatalkan bot lain.
		local ok, err = pcall(function()
			local corner = Config.BOT_CORNERS[i] or Config.BOT_CORNERS[1]
			local spawnPos = Vector3.new(corner.X, 0, corner.Z)
			local color = Color3.fromRGB(60, 60, 60)
			local model = buildBotModel("Maling" .. tostring(i), color, spawnPos)
			local bot = { model = model, corner = corner, carried = nil }
			table.insert(bots, bot)

			-- Touching a carrying bot makes it drop the brainrot.
			local torso = model:FindFirstChild("Torso")
			if torso then
				torso.Touched:Connect(function(hit)
					if not bot.carried then
						return
					end
					local character = hit.Parent
					local player = character and Players:GetPlayerFromCharacter(character)
					if player then
						dropStolen(bot)
					end
				end)
			end

			botBrain(bot)
		end)
		if not ok then
			warn("[PasarBrainrot] ThiefBot " .. tostring(i) .. " gagal start: " .. tostring(err))
		end
	end
end

return ThiefBot
