-- SPDX-License-Identifier: MIT
-- BrainrotFactory.luau — builds one brainrot character Model from a
-- BrainrotData row: blocky body, head, eyes, one accessory, and a billboard
-- showing its name, rarity and $/s. Size scales with rarity tier.
-- Mutation (Emas / Pelangi) changes the look and multiplies rate and price.
-- FIX #4: famous Italian brainrot cast; billboard rebuilt so labels never
-- overlap (fixed TextSize, no TextScaled, MaxDistance, not AlwaysOnTop).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
if not Shared then
	error("[PasarBrainrot] ReplicatedStorage.Shared tidak ditemukan (10 dtk)")
end
local Config = require(Shared.Config)
local BrainrotData = require(Shared.BrainrotData)

local BrainrotFactory = {}

function BrainrotFactory.rollMutation()
	local roll = math.random()
	if roll < Config.MUTATION_RAINBOW_CHANCE then
		return "Pelangi"
	elseif roll < Config.MUTATION_RAINBOW_CHANCE + Config.MUTATION_GOLD_CHANCE then
		return "Emas"
	end
	return "Normal"
end

function BrainrotFactory.getMutationMultiplier(mutation)
	if mutation == "Emas" then
		return 2
	elseif mutation == "Pelangi" then
		return 3
	end
	return 1
end

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- FIX #2: weldTo mem-parent part LANGSUNG ke model (bukan via body.Parent,
-- yang hilang diam-diam bila body belum ter-parent saat dipanggil).
local function weldTo(model, body, part, offsetCFrame)
	part.CFrame = body.CFrame * offsetCFrame
	part.Parent = model
	local weld = Instance.new("Weld")
	weld.Part0 = body
	weld.Part1 = part
	weld.C0 = offsetCFrame
	weld.Parent = body
end

-- One accessory per kind. FIX #4 adds: club, tree, cactus, banana, frog,
-- tutu, fish, katana, camel, rings. Unknown kind = no-op.
local function buildAccessory(model, body, kind, size, bodyColor)
	local s = size -- body edge length, used to scale the accessory
	if kind == "straw" then
		local straw = makePart("Straw", Vector3.new(0.25, s * 0.9, 0.25), Color3.fromRGB(255, 80, 120))
		weldTo(model, body, straw, CFrame.new(s * 0.25, s * 0.85, 0) * CFrame.Angles(0, 0, math.rad(20)))
	elseif kind == "sneakers" then
		for _, side in ipairs({ -1, 1 }) do
			local shoe = makePart("Sneaker", Vector3.new(s * 0.35, s * 0.22, s * 0.55), Color3.fromRGB(240, 240, 240))
			weldTo(model, body, shoe, CFrame.new(side * s * 0.28, -s * 0.6, s * 0.1))
		end
	elseif kind == "sunglasses" then
		local glasses = makePart("Sunglasses", Vector3.new(s * 0.7, s * 0.2, s * 0.15), Color3.fromRGB(20, 20, 20), Enum.Material.Neon)
		weldTo(model, body, glasses, CFrame.new(0, s * 0.55, s * 0.32))
	elseif kind == "wings" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = makePart("Wing", Vector3.new(s * 0.7, s * 0.12, s * 0.5), Color3.fromRGB(255, 255, 255))
			weldTo(model, body, wing, CFrame.new(side * s * 0.7, s * 0.15, -s * 0.1) * CFrame.Angles(0, 0, side * math.rad(25)))
		end
	elseif kind == "cape" then
		local cape = makePart("Cape", Vector3.new(s * 0.9, s * 0.9, s * 0.12), Color3.fromRGB(160, 30, 30))
		weldTo(model, body, cape, CFrame.new(0, -s * 0.1, -s * 0.55))
	elseif kind == "afro" then
		local afro = makePart("Afro", Vector3.new(s * 0.9, s * 0.5, s * 0.9), Color3.fromRGB(40, 20, 10))
		afro.Shape = Enum.PartType.Ball
		weldTo(model, body, afro, CFrame.new(0, s * 0.85, 0))
		local ball = makePart("DiscoBall", Vector3.new(s * 0.35, s * 0.35, s * 0.35), Color3.fromRGB(200, 220, 255), Enum.Material.Metal)
		ball.Shape = Enum.PartType.Ball
		weldTo(model, body, ball, CFrame.new(s * 0.55, s * 0.7, s * 0.2))
	elseif kind == "glowsticks" then
		for _, side in ipairs({ -1, 1 }) do
			local stick = makePart("Glowstick", Vector3.new(s * 0.12, s * 0.6, s * 0.12), Color3.fromRGB(80, 255, 160), Enum.Material.Neon)
			weldTo(model, body, stick, CFrame.new(side * s * 0.6, s * 0.2, s * 0.15) * CFrame.Angles(0, 0, side * math.rad(30)))
		end
	elseif kind == "crown" then
		local crown = makePart("Crown", Vector3.new(s * 0.55, s * 0.3, s * 0.55), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)
		weldTo(model, body, crown, CFrame.new(0, s * 0.95, 0))
	elseif kind == "moneybag" then
		local bag = makePart("MoneyBag", Vector3.new(s * 0.5, s * 0.55, s * 0.4), Color3.fromRGB(120, 200, 90))
		bag.Shape = Enum.PartType.Ball
		weldTo(model, body, bag, CFrame.new(s * 0.55, -s * 0.2, s * 0.25))
	elseif kind == "mic" then
		local mic = makePart("Mic", Vector3.new(s * 0.18, s * 0.6, s * 0.18), Color3.fromRGB(60, 60, 60))
		weldTo(model, body, mic, CFrame.new(s * 0.6, s * 0.1, s * 0.2))
		local micHead = makePart("MicHead", Vector3.new(s * 0.3, s * 0.3, s * 0.3), Color3.fromRGB(255, 120, 200))
		micHead.Shape = Enum.PartType.Ball
		weldTo(model, body, micHead, CFrame.new(s * 0.6, s * 0.45, s * 0.2))
	elseif kind == "club" then
		local club = makePart("Club", Vector3.new(s * 0.28, s * 1.0, s * 0.28), Color3.fromRGB(120, 80, 40))
		weldTo(model, body, club, CFrame.new(s * 0.55, s * 0.1, s * 0.15) * CFrame.Angles(0, 0, math.rad(-25)))
	elseif kind == "tree" then
		local trunk = makePart("TreeTrunk", Vector3.new(s * 0.22, s * 0.7, s * 0.22), Color3.fromRGB(120, 80, 40))
		weldTo(model, body, trunk, CFrame.new(0, s * 0.85, 0))
		local canopy = makePart("TreeTop", Vector3.new(s * 0.7, s * 0.5, s * 0.7), Color3.fromRGB(60, 160, 70))
		canopy.Shape = Enum.PartType.Ball
		weldTo(model, body, canopy, CFrame.new(0, s * 1.2, 0))
	elseif kind == "cactus" then
		local spike = makePart("CactusSpike", Vector3.new(s * 0.25, s * 0.7, s * 0.25), Color3.fromRGB(40, 140, 60))
		weldTo(model, body, spike, CFrame.new(0, s * 0.85, 0))
		for _, side in ipairs({ -1, 1 }) do
			local arm = makePart("CactusArm", Vector3.new(s * 0.18, s * 0.4, s * 0.18), Color3.fromRGB(40, 140, 60))
			weldTo(model, body, arm, CFrame.new(side * s * 0.45, s * 0.5, 0))
		end
	elseif kind == "banana" then
		local peel = makePart("Banana", Vector3.new(s * 0.28, s * 0.75, s * 0.28), Color3.fromRGB(250, 220, 60))
		weldTo(model, body, peel, CFrame.new(s * 0.5, s * 0.25, s * 0.1) * CFrame.Angles(0, 0, math.rad(30)))
		local tip = makePart("BananaTip", Vector3.new(s * 0.16, s * 0.16, s * 0.16), Color3.fromRGB(120, 80, 40))
		weldTo(model, body, tip, CFrame.new(s * 0.72, s * 0.62, s * 0.1))
	elseif kind == "frog" then
		local frogHead = makePart("FrogHead", Vector3.new(s * 0.55, s * 0.4, s * 0.55), Color3.fromRGB(70, 190, 90))
		frogHead.Shape = Enum.PartType.Ball
		weldTo(model, body, frogHead, CFrame.new(0, s * 0.85, 0))
		for _, side in ipairs({ -1, 1 }) do
			local eye = makePart("FrogEye", Vector3.new(s * 0.16, s * 0.16, s * 0.16), Color3.fromRGB(255, 255, 255))
			eye.Shape = Enum.PartType.Ball
			weldTo(model, body, eye, CFrame.new(side * s * 0.18, s * 1.05, s * 0.2))
		end
	elseif kind == "tutu" then
		local tutu = makePart("Tutu", Vector3.new(s * 1.15, s * 0.12, s * 1.15), Color3.fromRGB(255, 220, 235))
		tutu.Shape = Enum.PartType.Cylinder
		weldTo(model, body, tutu, CFrame.new(0, -s * 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local cup = makePart("CappuccinoCup", Vector3.new(s * 0.4, s * 0.35, s * 0.4), Color3.fromRGB(240, 220, 190))
		weldTo(model, body, cup, CFrame.new(0, s * 0.9, 0))
	elseif kind == "fish" then
		local tail = makePart("FishTail", Vector3.new(s * 0.12, s * 0.5, s * 0.45), Color3.fromRGB(255, 150, 60))
		weldTo(model, body, tail, CFrame.new(0, s * 0.1, -s * 0.6) * CFrame.Angles(math.rad(20), 0, 0))
		local fin = makePart("FishFin", Vector3.new(s * 0.12, s * 0.4, s * 0.35), Color3.fromRGB(255, 150, 60))
		weldTo(model, body, fin, CFrame.new(0, s * 0.7, -s * 0.05))
	elseif kind == "katana" then
		local blade = makePart("Katana", Vector3.new(s * 0.1, s * 0.9, s * 0.18), Color3.fromRGB(200, 210, 220), Enum.Material.Metal)
		weldTo(model, body, blade, CFrame.new(-s * 0.45, s * 0.2, -s * 0.3) * CFrame.Angles(0, 0, math.rad(35)))
		local handle = makePart("KatanaHandle", Vector3.new(s * 0.12, s * 0.3, s * 0.12), Color3.fromRGB(40, 30, 30))
		weldTo(model, body, handle, CFrame.new(-s * 0.68, s * 0.6, -s * 0.3) * CFrame.Angles(0, 0, math.rad(35)))
	elseif kind == "camel" then
		for _, side in ipairs({ -1, 1 }) do
			local hump = makePart("CamelHump", Vector3.new(s * 0.35, s * 0.35, s * 0.35), Color3.fromRGB(210, 180, 130))
			hump.Shape = Enum.PartType.Ball
			weldTo(model, body, hump, CFrame.new(side * s * 0.22, s * 0.85, 0))
		end
		local neck = makePart("CamelNeck", Vector3.new(s * 0.2, s * 0.6, s * 0.2), Color3.fromRGB(210, 180, 130))
		weldTo(model, body, neck, CFrame.new(0, s * 0.7, s * 0.35))
	elseif kind == "rings" then
		local ring = makePart("SaturnRing", Vector3.new(s * 1.35, s * 0.1, s * 1.35), Color3.fromRGB(255, 210, 90), Enum.Material.Metal)
		ring.Shape = Enum.PartType.Cylinder
		weldTo(model, body, ring, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local moon = makePart("Moon", Vector3.new(s * 0.18, s * 0.18, s * 0.18), Color3.fromRGB(200, 200, 210))
		moon.Shape = Enum.PartType.Ball
		weldTo(model, body, moon, CFrame.new(s * 0.7, s * 0.25, 0))
	end
end

-- FIX #4: per-character silhouette extras (visual only — PrimaryPart,
-- BodySize attribute and all numbers stay exactly as in the row).
local function buildShapeExtras(model, body, row, size)
	local s = size
	if row.id == "tralalero" then
		local fin = makePart("DorsalFin", Vector3.new(s * 0.12, s * 0.5, s * 0.4), Color3.fromRGB(30, 90, 160))
		weldTo(model, body, fin, CFrame.new(0, s * 0.75, -s * 0.1) * CFrame.Angles(math.rad(-20), 0, 0))
		local tail = makePart("TailFin", Vector3.new(s * 0.1, s * 0.45, s * 0.5), Color3.fromRGB(30, 90, 160))
		weldTo(model, body, tail, CFrame.new(0, s * 0.1, -s * 0.6))
	elseif row.id == "bombardiro" then
		local snout = makePart("Snout", Vector3.new(s * 0.4, s * 0.25, s * 0.45), Color3.fromRGB(50, 120, 60))
		weldTo(model, body, snout, CFrame.new(0, s * 0.05, s * 0.6))
	end
end

-- Builds the Model. The caller sets its position with PivotTo and parents it.
-- Returns the model; its attributes carry CharId, Rarity, Mutation, Rate, Price.
-- FIX #2: never throws on any row/mutation — nil row falls back to CAST[1],
-- missing fields get safe defaults, and a failing accessory cannot kill the
-- model (verified by audit for all 12 CAST rows x 3 mutations).
function BrainrotFactory.buildBrainrotModel(row, mutation)
	if type(row) ~= "table" then
		row = BrainrotData.CAST[1]
	end
	mutation = mutation or "Normal"
	local mult = BrainrotFactory.getMutationMultiplier(mutation)
	local size = tonumber(row.size) or 3
	local rate = tonumber(row.rate) or 0
	local price = tonumber(row.price) or 0
	local displayName = row.name or "Brainrot"
	if mutation ~= "Normal" then
		displayName = mutation .. " " .. displayName
	end

	local model = Instance.new("Model")
	model.Name = displayName

	local bodyColor = row.color or Color3.fromRGB(200, 200, 200)
	local bodyMaterial = Enum.Material.SmoothPlastic
	if mutation == "Emas" then
		bodyColor = Color3.fromRGB(255, 205, 40)
		bodyMaterial = Enum.Material.Metal
	end

	local body = makePart("Body", Vector3.new(size, size, size), bodyColor, bodyMaterial)
	body.CFrame = CFrame.new(0, size / 2, 0)
	body.Parent = model
	model.PrimaryPart = body

	local headSize = size * 0.62
	local head = makePart("Head", Vector3.new(headSize, headSize, headSize), bodyColor, bodyMaterial)
	head.Shape = Enum.PartType.Ball
	weldTo(model, body, head, CFrame.new(0, size * 0.72, 0))

	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(size * 0.14, size * 0.18, size * 0.08), Color3.fromRGB(20, 20, 20))
		weldTo(model, body, eye, CFrame.new(side * size * 0.16, size * 0.78, size * 0.32))
	end

	local accOk, accErr = pcall(buildAccessory, model, body, row.accessory, size, bodyColor)
	if not accOk then
		warn("[PasarBrainrot] accessory gagal (" .. tostring(row.accessory) .. "): " .. tostring(accErr))
	end

	local shapeOk, shapeErr = pcall(buildShapeExtras, model, body, row, size)
	if not shapeOk then
		warn("[PasarBrainrot] shape extras gagal (" .. tostring(row.id) .. "): " .. tostring(shapeErr))
	end

	-- FIX #4: billboard rebuilt — 200x100, fixed TextSize (no TextScaled),
	-- MaxDistance 60, NOT AlwaysOnTop: labels can no longer balloon over
	-- the HUD or overlap each other when the camera is close.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(200, 100)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, size * 1.15, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.34)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = false
	nameLabel.TextSize = 16
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.fromScale(0, 0.34)
	rarityLabel.Size = UDim2.fromScale(1, 0.24)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = row.rarity or "Common"
	rarityLabel.TextColor3 = BrainrotData.getRarityColor(row.rarity)
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextScaled = false
	rarityLabel.TextSize = 13
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.fromScale(0, 0.58)
	rateLabel.Size = UDim2.fromScale(1, 0.21)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "$" .. tostring(rate * mult) .. "/dtk"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextScaled = false
	rateLabel.TextSize = 13
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = billboard

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Position = UDim2.fromScale(0, 0.79)
	priceLabel.Size = UDim2.fromScale(1, 0.21)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "BELI $" .. tostring(price * mult)
	priceLabel.TextColor3 = Color3.fromRGB(255, 217, 51)
	priceLabel.TextStrokeTransparency = 0
	priceLabel.TextScaled = false
	priceLabel.TextSize = 14
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = billboard

	model:SetAttribute("CharId", row.id or "unknown")
	model:SetAttribute("Rarity", row.rarity or "Common")
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rate", rate * mult)
	model:SetAttribute("Price", price * mult)
	model:SetAttribute("BodySize", size)

	if mutation == "Pelangi" then
		task.spawn(function()
			local hue = 0
			while model.Parent do
				hue = (hue + 0.05) % 1
				local rainbow = Color3.fromHSV(hue, 0.8, 1)
				body.Color = rainbow
				head.Color = rainbow
				task.wait(0.2)
			end
		end)
	end

	return model
end

return BrainrotFactory
