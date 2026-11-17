-- CarryAndPlace.luau — buy a brainrot off the belt, carry it above your
-- head, place it on one of your base's 8 pedestals, sell it back for half
-- price. Also builds the pedestals, the base lock posts and their prompts
-- at runtime, and refreshes each pedestal's prompts and $/s sign.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
if not Shared then
	error("[PasarBrainrot] ReplicatedStorage.Shared tidak ditemukan (10 dtk)")
end
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local ConveyorSpawner = require(script.Parent.ConveyorSpawner)

local CarryAndPlace = {}

-- Set by init.server.luau: the Remotes folder (ToastMessage, SoundEvent).
CarryAndPlace.Remotes = nil

local pedestals = {} -- pedestals[baseIndex][slot] = pedestal table
local BASE_FOLDER = nil

local function toast(player, message)
	if CarryAndPlace.Remotes then
		local remote = CarryAndPlace.Remotes:FindFirstChild("ToastMessage")
		if remote then
			remote:FireClient(player, message)
		end
	end
end

local function playSound(player, kind)
	if CarryAndPlace.Remotes then
		local remote = CarryAndPlace.Remotes:FindFirstChild("SoundEvent")
		if remote then
			remote:FireClient(player, kind)
		end
	end
end

local function makePedestalPart(base, slot, position)
	local part = Instance.new("Part")
	part.Name = "Pedestal_" .. tostring(base) .. "_" .. tostring(slot)
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(1, 3, 3)
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	part.Color = Color3.fromRGB(230, 225, 210)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = BASE_FOLDER

	local sign = Instance.new("BillboardGui")
	sign.Name = "PedestalSign"
	sign.Size = UDim2.fromOffset(110, 28)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	sign.AlwaysOnTop = true
	sign.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "SignLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "KOSONG"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = sign
	return part
end

local function makePrompt(parent, actionText, objectText, holdDuration)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = 7
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = parent
	return prompt
end

-- Refreshes one pedestal's prompts and $/s sign after any change.
-- FIX #2: direct indexing (part.PedestalSign.SignLabel) throws and kills
-- the caller if the sign ever failed to build — use FindFirstChild.
function CarryAndPlace.refreshPedestal(baseIndex, slot)
	local pedestal = pedestals[baseIndex] and pedestals[baseIndex][slot]
	if not pedestal then
		return
	end
	local record = pedestal.record
	local sign = pedestal.part:FindFirstChild("PedestalSign")
	local label = sign and sign:FindFirstChild("SignLabel")
	if label then
		if record then
			label.Text = "$" .. tostring(record.rate) .. "/dtk"
		else
			label.Text = "KOSONG"
		end
	end
	if record then
		pedestal.placePrompt.Enabled = false
		pedestal.sellPrompt.Enabled = true
		pedestal.stealPrompt.Enabled = true
	else
		pedestal.placePrompt.Enabled = true
		pedestal.sellPrompt.Enabled = false
		pedestal.stealPrompt.Enabled = false
	end
end

function CarryAndPlace.getPedestal(baseIndex, slot)
	return pedestals[baseIndex] and pedestals[baseIndex][slot] or nil
end

-- Builds 8 pedestals per base (2 rows of 4) plus a lock post, from Config.BASES.
-- FIX #2: one base's build runs in its own pcall — a failure on one base
-- cannot stop the other three from being built.
local function buildOneBase(baseIndex, base)
	pedestals[baseIndex] = {}
	local center = base.pos
	local slot = 0
	-- FIX #2: columns 7 studs apart (was 5) — a Mythic body is 7.0 studs
	-- wide, so two Mythics side by side now only just touch, never overlap.
	for _, rowZ in ipairs({ -6, 6 }) do
		for _, colX in ipairs({ -10.5, -3.5, 3.5, 10.5 }) do
			slot += 1
			local pos = Vector3.new(center.X + colX, 1.5, center.Z + rowZ)
			local part = makePedestalPart(baseIndex, slot, pos)
			local pedestal = {
				baseIndex = baseIndex,
				slot = slot,
				part = part,
				record = nil,
			}
			pedestal.placePrompt = makePrompt(part, "Letakkan", "Brainrot di kepalamu", 0.5)
			pedestal.sellPrompt = makePrompt(part, "Jual", "50% harga beli kembali", 0.5)
			pedestal.stealPrompt = makePrompt(part, "Curi!", "Tahan 2 detik", Config.STEAL_HOLD_S)
			pedestal.placePrompt.Triggered:Connect(function(player)
				CarryAndPlace.placeOnPedestal(player, baseIndex, slot)
			end)
			pedestal.sellPrompt.Triggered:Connect(function(player)
				CarryAndPlace.sellBrainrot(player, baseIndex, slot)
			end)
			pedestal.stealPrompt.Triggered:Connect(function(player)
				local StealAndLock = require(script.Parent.StealAndLock)
				StealAndLock.tryStealBrainrot(player, baseIndex, slot)
			end)
			pedestals[baseIndex][slot] = pedestal
			CarryAndPlace.refreshPedestal(baseIndex, slot)
		end
	end

	-- Lock post at the base's outer corner: hold E to lock the base 30 s.
	local lockPost = Instance.new("Part")
	lockPost.Name = "LockPost_" .. tostring(baseIndex)
	lockPost.Size = Vector3.new(1, 3, 1)
	lockPost.Position = Vector3.new(center.X + 10, 2.5, center.Z + 10)
	lockPost.Color = base.color
	lockPost.Material = Enum.Material.Neon
	lockPost.Anchored = true
	lockPost.Parent = BASE_FOLDER
	local lockPrompt = makePrompt(lockPost, "Kunci Base", "Aman 30 detik", 0.5)
	lockPrompt.Triggered:Connect(function(player)
		local StealAndLock = require(script.Parent.StealAndLock)
		StealAndLock.lockBaseForPlayer(player)
	end)
end

function CarryAndPlace.buildBasePedestals()
	BASE_FOLDER = Instance.new("Folder")
	BASE_FOLDER.Name = "Bases"
	BASE_FOLDER.Parent = workspace

	for baseIndex, base in ipairs(Config.BASES) do
		local ok, err = pcall(buildOneBase, baseIndex, base)
		if not ok then
			warn("[PasarBrainrot] buildBasePedestals gagal untuk base " .. tostring(baseIndex) .. ": " .. tostring(err))
		end
	end
end

-- Buys the brainrot off the belt: checks cash, deducts, welds it above the
-- player's head. Called from the belt brainrot's ProximityPrompt.
function CarryAndPlace.buyBrainrot(player, model)
	if not model.Parent or not ConveyorSpawner.isOnBelt(model) then
		return
	end
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if state.carried then
		toast(player, "Kamu sudah membawa satu brainrot!")
		return
	end
	local price = model:GetAttribute("Price") or 0
	if state.cash < price then
		toast(player, "Uang kurang! Butuh $" .. tostring(price))
		return
	end
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	-- FIX #2: cek PrimaryPart SEBELUM uang dipotong (dulu ceknya sesudah
	-- spendCash — body nil = uang hilang, brainrot tak didapat).
	local body = model.PrimaryPart
	if not body then
		return
	end
	if not PlayerState.spendCash(player, price) then
		return
	end
	ConveyorSpawner.removeFromBelt(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	-- FIX #2: carry height scales with the model — a Mythic body is 7.0
	-- studs wide, so the fixed 3.2 offset buried it in the player's head.
	local carryY = (model:GetAttribute("BodySize") or 2) / 2 + 2.2
	body.CFrame = head.CFrame * CFrame.new(0, carryY, 0)
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = body
	weld.C0 = CFrame.new(0, carryY, 0)
	weld.Parent = head
	PlayerState.setCarried(player, model)
	playSound(player, "buy")
	toast(player, "Dibeli: " .. model.Name .. " — bawa ke basemu!")
end

-- Drops whatever the player carries back onto the belt (wave hit, tag, leave).
function CarryAndPlace.dropCarried(player)
	local state = PlayerState.get(player)
	if not state or not state.carried then
		return
	end
	local model = state.carried
	local character = player.Character
	if character then
		local weld = character:FindFirstChild("Head") and character.Head:FindFirstChild("CarryWeld")
		if weld then
			weld:Destroy()
		end
	end
	PlayerState.setCarried(player, nil)
	if model.Parent then
		ConveyorSpawner.returnToBelt(model)
	end
end

-- Places the carried brainrot on an empty pedestal of the player's own base.
function CarryAndPlace.placeOnPedestal(player, baseIndex, slot)
	local state = PlayerState.get(player)
	local pedestal = CarryAndPlace.getPedestal(baseIndex, slot)
	if not state or not pedestal then
		return
	end
	if pedestal.record then
		toast(player, "Pedestal ini sudah terisi!")
		return
	end
	if state.baseIndex ~= baseIndex then
		toast(player, "Itu base pemain lain!")
		return
	end
	local model = state.carried
	if not model or not model.Parent then
		toast(player, "Bawa dulu brainrot dari sabuk!")
		return
	end
	local character = player.Character
	if character then
		local weld = character:FindFirstChild("Head") and character.Head:FindFirstChild("CarryWeld")
		if weld then
			weld:Destroy()
		end
	end
	PlayerState.setCarried(player, nil)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	local size = model:GetAttribute("BodySize") or 2
	local base = Config.BASES[baseIndex]
	local yaw = math.atan2(-base.pos.X, -base.pos.Z)
	model:PivotTo(
		CFrame.new(pedestal.part.Position + Vector3.new(0, 0.5 + size / 2 + 0.05, 0))
			* CFrame.Angles(0, yaw, 0)
	)
	local record = {
		model = model,
		rowId = model:GetAttribute("CharId"),
		rate = model:GetAttribute("Rate"),
		price = model:GetAttribute("Price"),
	}
	pedestal.record = record
	PlayerState.setOwned(player, slot, record)
	CarryAndPlace.refreshPedestal(baseIndex, slot)
	playSound(player, "buy")
	toast(player, model.Name .. " mulai menghasilkan $" .. tostring(record.rate) .. "/dtk!")
end

-- Sells the brainrot on your own pedestal back for half its buy price.
function CarryAndPlace.sellBrainrot(player, baseIndex, slot)
	local state = PlayerState.get(player)
	local pedestal = CarryAndPlace.getPedestal(baseIndex, slot)
	if not state or not pedestal or not pedestal.record then
		return
	end
	if state.baseIndex ~= baseIndex then
		toast(player, "Itu bukan pedestalmu!")
		return
	end
	local record = pedestal.record
	local refund = math.floor(record.price * Config.SELL_REFUND + 0.5)
	pedestal.record = nil
	PlayerState.clearOwnedSlot(player, slot)
	if record.model.Parent then
		record.model:Destroy()
	end
	PlayerState.addCash(player, refund)
	CarryAndPlace.refreshPedestal(baseIndex, slot)
	playSound(player, "buy")
	toast(player, "Terjual! +$" .. tostring(refund))
end

-- Removes one owned brainrot without refund (rebirth, steal). Returns the model.
function CarryAndPlace.takeOwnedBrainrot(baseIndex, slot)
	local pedestal = CarryAndPlace.getPedestal(baseIndex, slot)
	if not pedestal or not pedestal.record then
		return nil
	end
	local record = pedestal.record
	pedestal.record = nil
	CarryAndPlace.refreshPedestal(baseIndex, slot)
	return record.model
end

function CarryAndPlace.clearPlayerPedestals(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	for slot, record in pairs(PlayerState.getOwned(player)) do
		local pedestal = CarryAndPlace.getPedestal(state.baseIndex, slot)
		if pedestal then
			pedestal.record = nil
			CarryAndPlace.refreshPedestal(state.baseIndex, slot)
		end
		if record.model.Parent then
			record.model:Destroy()
		end
	end
	PlayerState.clearOwned(player)
end

return CarryAndPlace
