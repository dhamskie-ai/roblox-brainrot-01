-- SPDX-License-Identifier: MIT
-- BrainrotFactory.luau
-- Builds recognizable brainrot models from plain parts.
-- Shapes verified for all 13 CAST rows: each character has its
-- own silhouette + colors + at least 2 far-visible signature
-- features, so it reads as its character from belt distance.
-- No generic block-humanoid body: the old "cube body + ball
-- head + 2 eyes" block is gone; every id gets its own branch
-- in buildShape (unknown id -> plain cube + eyes).
-- Faces/eyes look toward local +Z; the belt runs west (-38)
-- to east (+38). PrimaryPart "Body" stays axis-aligned at
-- CFrame (0, size/2, 0). Cylinder parts: long axis is X; flat
-- horizontal discs use CFrame.Angles(0, 0, math.rad(90)).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
if Shared == nil then
	error("[BrainrotFactory] Shared folder not found in ReplicatedStorage")
end
local Config = require(Shared.Config)
local BrainrotData = require(Shared.BrainrotData)

local BrainrotFactory = {}

local DARK = Color3.fromRGB(20, 20, 20)
local WHITE = Color3.fromRGB(255, 255, 255)

-- makePart(name, size, color, material): Anchored, no collision,
-- smooth top/bottom, default SmoothPlastic.
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

-- weldTo(model, body, part, offsetCFrame): part.CFrame is set from
-- body.CFrame * offsetCFrame, parented to the model, welded to the
-- body with C0 = offsetCFrame.
local function weldTo(model, body, part, offsetCFrame)
	part.CFrame = body.CFrame * offsetCFrame
	part.Parent = model
	local weld = Instance.new("Weld")
	weld.Part0 = body
	weld.Part1 = part
	weld.C0 = offsetCFrame
	weld.Parent = body
	return weld
end

-- Convenience: make a (possibly shaped) part and weld it in.
local function add(model, body, name, size, color, offset, shape, material)
	local part = makePart(name, size, color, material)
	if shape ~= nil then
		part.Shape = shape
	end
	weldTo(model, body, part, offset)
	return part
end

-- Two dark ball eyes on the +Z face.
local function addEyes(model, body, y, z, dx, r, color)
	for _, sx in ipairs({ -1, 1 }) do
		add(model, body, "Eye", Vector3.new(r, r, r), color or DARK,
			CFrame.new(sx * dx, y, z), Enum.PartType.Ball)
	end
end

function BrainrotFactory.rollMutation()
	local roll = math.random()
	local rainbowChance = Config.MUTATION_RAINBOW_CHANCE or 0
	local goldChance = Config.MUTATION_GOLD_CHANCE or 0
	if roll < rainbowChance then
		return "Pelangi"
	elseif roll < rainbowChance + goldChance then
		return "Emas"
	else
		return "Normal"
	end
end

function BrainrotFactory.getMutationMultiplier(mutation)
	if mutation == "Emas" then
		return 2
	elseif mutation == "Pelangi" then
		return 3
	else
		return 1
	end
end

local function makeLabel(parent, name, posY, sizeY, text, color, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, sizeY, 0)
	label.Position = UDim2.new(0, 0, posY, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.TextScaled = false
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

local function buildBillboard(model, body, row, size, displayName, rate, price)
	local id = row.id or ""
	local byteSum = 0
	for i = 1, #id do
		byteSum = byteSum + string.byte(id, i)
	end
	local stagger = 0
	if byteSum % 2 == 0 then
		stagger = size * 0.28
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 200, 0, 100)
	billboard.MaxDistance = 45
	billboard.AlwaysOnTop = false
	billboard.StudsOffsetWorldSpace = Vector3.new(0, size * 1.15 + stagger, 0)
	billboard.Adornee = body
	billboard.Parent = body
	makeLabel(billboard, "Name", 0, 0.34, displayName, WHITE, 16)
	makeLabel(billboard, "Rarity", 0.34, 0.24, row.rarity or "Common",
		BrainrotData.getRarityColor(row.rarity), 13)
	makeLabel(billboard, "Rate", 0.58, 0.21, "$" .. tostring(rate) .. "/dtk",
		Color3.fromRGB(120, 255, 140), 13)
	makeLabel(billboard, "Price", 0.79, 0.21, "BELI $" .. tostring(price),
		Color3.fromRGB(255, 217, 51), 14)
end

-- One branch per character id. `s` is the row's size; the body
-- (PrimaryPart) is the main axis-aligned mass, everything else
-- is welded to it. Unknown id -> plain cube + eyes.
local function buildShape(model, body, row, size)
	local s = size
	local id = row.id or ""

	if id == "tung-tung-sahur" then
		-- BATANG KAYU HORIZONTAL: long log, face at the +X end,
		-- big tilted club, two little wooden feet.
		body.Size = Vector3.new(1.4 * s, 0.55 * s, 0.55 * s)
		body.Color = Color3.fromRGB(150, 100, 50)
		for _, sz in ipairs({ -1, 1 }) do
			add(model, body, "Eye", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), DARK,
				CFrame.new(0.68 * s, 0.08 * s, sz * 0.13 * s), Enum.PartType.Ball)
		end
		add(model, body, "Mouth", Vector3.new(0.06 * s, 0.08 * s, 0.22 * s), DARK,
			CFrame.new(0.7 * s, -0.1 * s, 0))
		add(model, body, "Club", Vector3.new(0.25 * s, 1.0 * s, 0.25 * s),
			Color3.fromRGB(120, 80, 40),
			CFrame.new(-0.45 * s, 0.35 * s, 0.32 * s) * CFrame.Angles(0, 0, math.rad(35)))
		add(model, body, "ClubKnob", Vector3.new(0.32 * s, 0.32 * s, 0.32 * s),
			Color3.fromRGB(120, 80, 40),
			CFrame.new(-0.74 * s, 0.78 * s, 0.32 * s), Enum.PartType.Ball)
		add(model, body, "BarkRing", Vector3.new(0.06 * s, 0.57 * s, 0.57 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(0.3 * s, 0, 0))
		add(model, body, "BarkRing2", Vector3.new(0.06 * s, 0.57 * s, 0.57 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(-0.3 * s, 0, 0))
		add(model, body, "FootL", Vector3.new(0.2 * s, 0.25 * s, 0.2 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(-0.4 * s, -0.38 * s, 0))
		add(model, body, "FootR", Vector3.new(0.2 * s, 0.25 * s, 0.2 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(0.4 * s, -0.38 * s, 0))

	elseif id == "tralalero" then
		-- HIU biru: long body, dorsal fin, vertical tail fin,
		-- white belly, legs + white sneakers, eyes at the +Z nose.
		body.Size = Vector3.new(0.8 * s, 0.7 * s, 1.5 * s)
		body.Color = Color3.fromRGB(60, 140, 220)
		add(model, body, "DorsalFin", Vector3.new(0.08 * s, 0.5 * s, 0.6 * s),
			Color3.fromRGB(40, 110, 190),
			CFrame.new(0, 0.5 * s, -0.15 * s) * CFrame.Angles(math.rad(-25), 0, 0))
		add(model, body, "TailFin", Vector3.new(0.5 * s, 0.7 * s, 0.08 * s),
			Color3.fromRGB(40, 110, 190), CFrame.new(0, 0.1 * s, -0.85 * s))
		add(model, body, "TailFin2", Vector3.new(0.7 * s, 0.08 * s, 0.3 * s),
			Color3.fromRGB(40, 110, 190), CFrame.new(0, 0.15 * s, -0.85 * s))
		add(model, body, "FinL", Vector3.new(0.4 * s, 0.08 * s, 0.35 * s),
			Color3.fromRGB(40, 110, 190),
			CFrame.new(-0.55 * s, -0.1 * s, 0.15 * s) * CFrame.Angles(0, 0, math.rad(-20)))
		add(model, body, "FinR", Vector3.new(0.4 * s, 0.08 * s, 0.35 * s),
			Color3.fromRGB(40, 110, 190),
			CFrame.new(0.55 * s, -0.1 * s, 0.15 * s) * CFrame.Angles(0, 0, math.rad(20)))
		add(model, body, "Belly", Vector3.new(0.6 * s, 0.3 * s, 1.0 * s),
			Color3.fromRGB(220, 240, 255), CFrame.new(0, -0.25 * s, 0.1 * s))
		for _, sx in ipairs({ -1, 1 }) do
			add(model, body, "EyeWhite", Vector3.new(0.18 * s, 0.18 * s, 0.18 * s), WHITE,
				CFrame.new(sx * 0.18 * s, 0.15 * s, 0.72 * s), Enum.PartType.Ball)
			add(model, body, "Pupil", Vector3.new(0.09 * s, 0.09 * s, 0.09 * s), DARK,
				CFrame.new(sx * 0.18 * s, 0.15 * s, 0.8 * s), Enum.PartType.Ball)
			add(model, body, "Leg", Vector3.new(0.18 * s, 0.25 * s, 0.18 * s),
				Color3.fromRGB(40, 110, 190), CFrame.new(sx * 0.2 * s, -0.38 * s, 0.2 * s))
			add(model, body, "Sneaker", Vector3.new(0.24 * s, 0.12 * s, 0.42 * s), WHITE,
				CFrame.new(sx * 0.2 * s, -0.45 * s, 0.28 * s))
		end

	elseif id == "brr-patapim" then
		-- MONYET HIDUNG PANJANG: round brown body, long nose
		-- jutting +Z, little tree at its side, curved tail.
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(0.9 * s, 0.9 * s, 0.9 * s)
		body.Color = Color3.fromRGB(170, 120, 70)
		add(model, body, "Nose", Vector3.new(0.25 * s, 0.5 * s, 0.7 * s),
			Color3.fromRGB(200, 160, 110), CFrame.new(0, -0.05 * s, 0.6 * s))
		for _, sx in ipairs({ -1, 1 }) do
			add(model, body, "Nostril", Vector3.new(0.07 * s, 0.07 * s, 0.07 * s), DARK,
				CFrame.new(sx * 0.06 * s, 0.05 * s, 0.95 * s), Enum.PartType.Ball)
		end
		addEyes(model, body, 0.25 * s, 0.4 * s, 0.2 * s, 0.13 * s)
		add(model, body, "EarL", Vector3.new(0.22 * s, 0.22 * s, 0.22 * s),
			Color3.fromRGB(200, 160, 110), CFrame.new(-0.45 * s, 0.15 * s, 0), Enum.PartType.Ball)
		add(model, body, "EarR", Vector3.new(0.22 * s, 0.22 * s, 0.22 * s),
			Color3.fromRGB(200, 160, 110), CFrame.new(0.45 * s, 0.15 * s, 0), Enum.PartType.Ball)
		add(model, body, "Trunk", Vector3.new(0.15 * s, 0.8 * s, 0.15 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(0.7 * s, 0, -0.25 * s))
		add(model, body, "Canopy", Vector3.new(0.6 * s, 0.6 * s, 0.6 * s),
			Color3.fromRGB(60, 160, 70), CFrame.new(0.7 * s, 0.55 * s, -0.25 * s), Enum.PartType.Ball)
		add(model, body, "Canopy2", Vector3.new(0.4 * s, 0.4 * s, 0.4 * s),
			Color3.fromRGB(80, 180, 90), CFrame.new(0.88 * s, 0.35 * s, -0.25 * s), Enum.PartType.Ball)
		add(model, body, "Tail", Vector3.new(0.12 * s, 0.4 * s, 0.12 * s),
			Color3.fromRGB(140, 95, 55),
			CFrame.new(-0.45 * s, -0.2 * s, -0.4 * s) * CFrame.Angles(math.rad(30), 0, 0))
		add(model, body, "TailTip", Vector3.new(0.12 * s, 0.35 * s, 0.12 * s),
			Color3.fromRGB(140, 95, 55),
			CFrame.new(-0.5 * s, 0.1 * s, -0.52 * s) * CFrame.Angles(math.rad(70), 0, 0))
		add(model, body, "FootL", Vector3.new(0.2 * s, 0.2 * s, 0.25 * s),
			Color3.fromRGB(140, 95, 55), CFrame.new(-0.2 * s, -0.42 * s, 0.1 * s))
		add(model, body, "FootR", Vector3.new(0.2 * s, 0.2 * s, 0.25 * s),
			Color3.fromRGB(140, 95, 55), CFrame.new(0.2 * s, -0.42 * s, 0.1 * s))

	elseif id == "lirili-larila" then
		-- KAKTUS-GAJAH: tall green cactus column with spikes,
		-- elephant head up front, long trunk, big flat ears.
		body.Size = Vector3.new(0.6 * s, 1.0 * s, 0.6 * s)
		body.Color = Color3.fromRGB(80, 180, 90)
		add(model, body, "SpikeL", Vector3.new(0.1 * s, 0.1 * s, 0.1 * s),
			Color3.fromRGB(200, 255, 200), CFrame.new(-0.32 * s, 0.2 * s, 0))
		add(model, body, "SpikeR", Vector3.new(0.1 * s, 0.1 * s, 0.1 * s),
			Color3.fromRGB(200, 255, 200), CFrame.new(0.32 * s, -0.2 * s, 0.1 * s))
		add(model, body, "SpikeF", Vector3.new(0.1 * s, 0.1 * s, 0.1 * s),
			Color3.fromRGB(200, 255, 200), CFrame.new(0, 0.3 * s, 0.32 * s))
		add(model, body, "ArmL", Vector3.new(0.35 * s, 0.12 * s, 0.12 * s),
			Color3.fromRGB(70, 160, 80), CFrame.new(-0.45 * s, 0.1 * s, 0))
		add(model, body, "ArmR", Vector3.new(0.35 * s, 0.12 * s, 0.12 * s),
			Color3.fromRGB(70, 160, 80), CFrame.new(0.45 * s, 0.1 * s, 0))
		add(model, body, "Head", Vector3.new(0.5 * s, 0.5 * s, 0.5 * s),
			Color3.fromRGB(190, 170, 170), CFrame.new(0, 0.32 * s, 0.35 * s), Enum.PartType.Ball)
		add(model, body, "Trunk", Vector3.new(0.16 * s, 0.65 * s, 0.16 * s),
			Color3.fromRGB(180, 160, 160),
			CFrame.new(0, 0.02 * s, 0.6 * s) * CFrame.Angles(math.rad(25), 0, 0))
		add(model, body, "EarL", Vector3.new(0.08 * s, 0.4 * s, 0.35 * s),
			Color3.fromRGB(220, 180, 180), CFrame.new(-0.3 * s, 0.32 * s, 0.3 * s))
		add(model, body, "EarR", Vector3.new(0.08 * s, 0.4 * s, 0.35 * s),
			Color3.fromRGB(220, 180, 180), CFrame.new(0.3 * s, 0.32 * s, 0.3 * s))
		addEyes(model, body, 0.4 * s, 0.58 * s, 0.12 * s, 0.1 * s)
		add(model, body, "TuskL", Vector3.new(0.06 * s, 0.06 * s, 0.25 * s), WHITE,
			CFrame.new(-0.15 * s, 0.15 * s, 0.55 * s))
		add(model, body, "TuskR", Vector3.new(0.06 * s, 0.06 * s, 0.25 * s), WHITE,
			CFrame.new(0.15 * s, 0.15 * s, 0.55 * s))
		add(model, body, "FootL", Vector3.new(0.2 * s, 0.2 * s, 0.2 * s),
			Color3.fromRGB(70, 160, 80), CFrame.new(-0.18 * s, -0.42 * s, 0))
		add(model, body, "FootR", Vector3.new(0.2 * s, 0.2 * s, 0.2 * s),
			Color3.fromRGB(70, 160, 80), CFrame.new(0.18 * s, -0.42 * s, 0))

	elseif id == "chimpanzini" then
		-- SIMPANSE + PISANG BESAR: brown chimp body and head,
		-- huge yellow banana tilted across the front (main cue).
		body.Size = Vector3.new(0.7 * s, 0.8 * s, 0.55 * s)
		body.Color = Color3.fromRGB(120, 80, 40)
		add(model, body, "Head", Vector3.new(0.5 * s, 0.5 * s, 0.5 * s),
			Color3.fromRGB(170, 120, 70), CFrame.new(0, 0.55 * s, 0.1 * s), Enum.PartType.Ball)
		add(model, body, "Muzzle", Vector3.new(0.3 * s, 0.18 * s, 0.15 * s),
			Color3.fromRGB(210, 180, 140), CFrame.new(0, 0.48 * s, 0.36 * s))
		addEyes(model, body, 0.62 * s, 0.32 * s, 0.12 * s, 0.11 * s)
		add(model, body, "EarL", Vector3.new(0.2 * s, 0.2 * s, 0.2 * s),
			Color3.fromRGB(170, 120, 70), CFrame.new(-0.28 * s, 0.58 * s, 0.05 * s), Enum.PartType.Ball)
		add(model, body, "EarR", Vector3.new(0.2 * s, 0.2 * s, 0.2 * s),
			Color3.fromRGB(170, 120, 70), CFrame.new(0.28 * s, 0.58 * s, 0.05 * s), Enum.PartType.Ball)
		add(model, body, "Banana", Vector3.new(0.28 * s, 0.95 * s, 0.28 * s),
			Color3.fromRGB(250, 220, 60),
			CFrame.new(0.5 * s, 0.05 * s, 0.35 * s) * CFrame.Angles(math.rad(15), 0, math.rad(-35)))
		add(model, body, "BananaTip", Vector3.new(0.14 * s, 0.14 * s, 0.14 * s),
			Color3.fromRGB(120, 80, 40),
			CFrame.new(0.77 * s, 0.44 * s, 0.35 * s), Enum.PartType.Ball)
		add(model, body, "Belly", Vector3.new(0.4 * s, 0.4 * s, 0.1 * s),
			Color3.fromRGB(210, 180, 140), CFrame.new(0, -0.05 * s, 0.28 * s))
		add(model, body, "ArmL", Vector3.new(0.15 * s, 0.5 * s, 0.15 * s),
			Color3.fromRGB(120, 80, 40),
			CFrame.new(-0.42 * s, 0, 0.05 * s) * CFrame.Angles(0, 0, math.rad(15)))
		add(model, body, "ArmR", Vector3.new(0.15 * s, 0.5 * s, 0.15 * s),
			Color3.fromRGB(120, 80, 40),
			CFrame.new(0.42 * s, 0, 0.05 * s) * CFrame.Angles(0, 0, math.rad(-15)))
		add(model, body, "LegL", Vector3.new(0.2 * s, 0.3 * s, 0.2 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(-0.18 * s, -0.4 * s, 0))
		add(model, body, "LegR", Vector3.new(0.2 * s, 0.3 * s, 0.2 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(0.18 * s, -0.4 * s, 0))

	elseif id == "boneca" then
		-- KATAK di atas BAN: round green frog with big white eyes
		-- on top, sitting on a big black tire.
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(0.85 * s, 0.7 * s, 0.85 * s)
		body.Color = Color3.fromRGB(90, 200, 110)
		add(model, body, "Tire", Vector3.new(0.25 * s, 1.3 * s, 1.3 * s),
			Color3.fromRGB(30, 30, 30),
			CFrame.new(0, -0.38 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
		add(model, body, "TireHub", Vector3.new(0.27 * s, 0.5 * s, 0.5 * s),
			Color3.fromRGB(120, 120, 120),
			CFrame.new(0, -0.38 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
		for _, sx in ipairs({ -1, 1 }) do
			add(model, body, "EyeWhite", Vector3.new(0.28 * s, 0.28 * s, 0.28 * s), WHITE,
				CFrame.new(sx * 0.2 * s, 0.42 * s, 0.25 * s), Enum.PartType.Ball)
			add(model, body, "Pupil", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), DARK,
				CFrame.new(sx * 0.2 * s, 0.45 * s, 0.38 * s), Enum.PartType.Ball)
			add(model, body, "Leg", Vector3.new(0.3 * s, 0.15 * s, 0.4 * s),
				Color3.fromRGB(80, 180, 100), CFrame.new(sx * 0.45 * s, -0.3 * s, 0.1 * s))
		end
		add(model, body, "Mouth", Vector3.new(0.4 * s, 0.05 * s, 0.06 * s), DARK,
			CFrame.new(0, -0.05 * s, 0.42 * s))
		add(model, body, "Belly", Vector3.new(0.5 * s, 0.35 * s, 0.1 * s),
			Color3.fromRGB(180, 255, 180), CFrame.new(0, -0.1 * s, 0.4 * s))
		add(model, body, "Spot", Vector3.new(0.15 * s, 0.15 * s, 0.15 * s),
			Color3.fromRGB(40, 140, 70), CFrame.new(0.15 * s, 0.3 * s, -0.2 * s), Enum.PartType.Ball)

	elseif id == "bombardiro" then
		-- BUAYA-PESAWAT: green fuselage along Z, crocodile snout
		-- with teeth at +Z, wide wings, propeller at the nose.
		body.Size = Vector3.new(0.7 * s, 0.6 * s, 1.4 * s)
		body.Color = Color3.fromRGB(70, 150, 80)
		add(model, body, "Snout", Vector3.new(0.5 * s, 0.35 * s, 0.7 * s),
			Color3.fromRGB(50, 120, 60), CFrame.new(0, -0.05 * s, 0.9 * s))
		for _, sz in ipairs({ 0.75, 1.0 }) do
			add(model, body, "ToothL", Vector3.new(0.08 * s, 0.1 * s, 0.08 * s), WHITE,
				CFrame.new(-0.2 * s, -0.22 * s, sz * s))
			add(model, body, "ToothR", Vector3.new(0.08 * s, 0.1 * s, 0.08 * s), WHITE,
				CFrame.new(0.2 * s, -0.22 * s, sz * s))
		end
		for _, sx in ipairs({ -1, 1 }) do
			add(model, body, "EyeWhite", Vector3.new(0.16 * s, 0.16 * s, 0.16 * s), WHITE,
				CFrame.new(sx * 0.18 * s, 0.28 * s, 0.75 * s), Enum.PartType.Ball)
			add(model, body, "Pupil", Vector3.new(0.08 * s, 0.08 * s, 0.08 * s), DARK,
				CFrame.new(sx * 0.18 * s, 0.36 * s, 0.75 * s), Enum.PartType.Ball)
		end
		add(model, body, "WingL", Vector3.new(1.0 * s, 0.08 * s, 0.5 * s),
			Color3.fromRGB(235, 240, 235), CFrame.new(-0.85 * s, 0.1 * s, -0.1 * s))
		add(model, body, "WingR", Vector3.new(1.0 * s, 0.08 * s, 0.5 * s),
			Color3.fromRGB(235, 240, 235), CFrame.new(0.85 * s, 0.1 * s, -0.1 * s))
		add(model, body, "TailFin", Vector3.new(0.08 * s, 0.5 * s, 0.4 * s),
			Color3.fromRGB(50, 120, 60), CFrame.new(0, 0.25 * s, -0.8 * s))
		add(model, body, "Canopy", Vector3.new(0.4 * s, 0.2 * s, 0.4 * s),
			Color3.fromRGB(120, 200, 255), CFrame.new(0, 0.35 * s, -0.2 * s))
		add(model, body, "PropHub", Vector3.new(0.15 * s, 0.15 * s, 0.15 * s),
			Color3.fromRGB(60, 60, 60), CFrame.new(0, -0.05 * s, 1.3 * s), Enum.PartType.Ball)
		add(model, body, "PropV", Vector3.new(0.1 * s, 0.9 * s, 0.06 * s),
			Color3.fromRGB(60, 60, 60), CFrame.new(0, -0.05 * s, 1.32 * s))
		add(model, body, "PropH", Vector3.new(0.9 * s, 0.1 * s, 0.06 * s),
			Color3.fromRGB(60, 60, 60), CFrame.new(0, -0.05 * s, 1.32 * s))
		add(model, body, "WheelL", Vector3.new(0.15 * s, 0.25 * s, 0.15 * s),
			Color3.fromRGB(40, 40, 40), CFrame.new(-0.25 * s, -0.4 * s, 0.3 * s))
		add(model, body, "WheelR", Vector3.new(0.15 * s, 0.25 * s, 0.15 * s),
			Color3.fromRGB(40, 40, 40), CFrame.new(0.25 * s, -0.4 * s, 0.3 * s))

	elseif id == "garuda-emas" then
		-- BURUNG EMAS: golden body and head, wings spread wide
		-- and tilted up, metal crown, three-part tail fan.
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(0.7 * s, 0.8 * s, 0.6 * s)
		body.Color = Color3.fromRGB(255, 200, 60)
		add(model, body, "Head", Vector3.new(0.45 * s, 0.45 * s, 0.45 * s),
			Color3.fromRGB(255, 200, 60), CFrame.new(0, 0.5 * s, 0.15 * s), Enum.PartType.Ball)
		add(model, body, "Beak", Vector3.new(0.15 * s, 0.12 * s, 0.3 * s),
			Color3.fromRGB(255, 140, 40), CFrame.new(0, 0.48 * s, 0.42 * s))
		addEyes(model, body, 0.55 * s, 0.35 * s, 0.12 * s, 0.1 * s)
		add(model, body, "WingL", Vector3.new(1.1 * s, 0.08 * s, 0.5 * s),
			Color3.fromRGB(255, 200, 60),
			CFrame.new(-0.8 * s, 0.3 * s, 0) * CFrame.Angles(0, 0, math.rad(-25)), Enum.Material.Metal)
		add(model, body, "WingR", Vector3.new(1.1 * s, 0.08 * s, 0.5 * s),
			Color3.fromRGB(255, 200, 60),
			CFrame.new(0.8 * s, 0.3 * s, 0) * CFrame.Angles(0, 0, math.rad(25)), Enum.Material.Metal)
		add(model, body, "WingTipL", Vector3.new(0.3 * s, 0.06 * s, 0.4 * s),
			Color3.fromRGB(255, 170, 30),
			CFrame.new(-1.35 * s, 0.55 * s, 0) * CFrame.Angles(0, 0, math.rad(-25)))
		add(model, body, "WingTipR", Vector3.new(0.3 * s, 0.06 * s, 0.4 * s),
			Color3.fromRGB(255, 170, 30),
			CFrame.new(1.35 * s, 0.55 * s, 0) * CFrame.Angles(0, 0, math.rad(25)))
		add(model, body, "Crown", Vector3.new(0.4 * s, 0.12 * s, 0.4 * s),
			Color3.fromRGB(255, 205, 40), CFrame.new(0, 0.78 * s, 0.15 * s), nil, Enum.Material.Metal)
		for _, sx in ipairs({ -0.12, 0, 0.12 }) do
			add(model, body, "CrownSpike", Vector3.new(0.08 * s, 0.2 * s, 0.08 * s),
				Color3.fromRGB(255, 205, 40), CFrame.new(sx * s, 0.9 * s, 0.15 * s), nil, Enum.Material.Metal)
		end
		add(model, body, "TailC", Vector3.new(0.18 * s, 0.06 * s, 0.6 * s),
			Color3.fromRGB(255, 170, 30), CFrame.new(0, -0.15 * s, -0.55 * s))
		add(model, body, "TailL", Vector3.new(0.18 * s, 0.06 * s, 0.6 * s),
			Color3.fromRGB(255, 170, 30),
			CFrame.new(-0.2 * s, -0.15 * s, -0.55 * s) * CFrame.Angles(0, math.rad(20), 0))
		add(model, body, "TailR", Vector3.new(0.18 * s, 0.06 * s, 0.6 * s),
			Color3.fromRGB(255, 170, 30),
			CFrame.new(0.2 * s, -0.15 * s, -0.55 * s) * CFrame.Angles(0, math.rad(-20), 0))
		add(model, body, "LegL", Vector3.new(0.12 * s, 0.3 * s, 0.12 * s),
			Color3.fromRGB(255, 170, 30), CFrame.new(-0.15 * s, -0.4 * s, 0.1 * s))
		add(model, body, "LegR", Vector3.new(0.12 * s, 0.3 * s, 0.12 * s),
			Color3.fromRGB(255, 170, 30), CFrame.new(0.15 * s, -0.4 * s, 0.1 * s))

	elseif id == "ballerina" then
		-- BALERINA + CANGKIR: tan body, wide pink tutu disc at
		-- the waist, cappuccino-cup head with foam, pointe legs.
		body.Size = Vector3.new(0.55 * s, 0.7 * s, 0.45 * s)
		body.Color = Color3.fromRGB(220, 180, 140)
		add(model, body, "Tutu", Vector3.new(0.12 * s, 1.15 * s, 1.15 * s),
			Color3.fromRGB(255, 220, 235),
			CFrame.new(0, -0.12 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
		add(model, body, "Bodice", Vector3.new(0.5 * s, 0.25 * s, 0.4 * s),
			Color3.fromRGB(255, 180, 210), CFrame.new(0, 0.2 * s, 0))
		add(model, body, "CupHead", Vector3.new(0.5 * s, 0.45 * s, 0.45 * s),
			Color3.fromRGB(240, 220, 190),
			CFrame.new(0, 0.62 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
		add(model, body, "Foam", Vector3.new(0.3 * s, 0.3 * s, 0.3 * s),
			Color3.fromRGB(250, 240, 220), CFrame.new(0, 0.92 * s, 0), Enum.PartType.Ball)
		add(model, body, "CupHandle", Vector3.new(0.12 * s, 0.22 * s, 0.08 * s),
			Color3.fromRGB(240, 220, 190), CFrame.new(0.28 * s, 0.62 * s, 0))
		addEyes(model, body, 0.65 * s, 0.23 * s, 0.1 * s, 0.09 * s)
		add(model, body, "Smile", Vector3.new(0.16 * s, 0.04 * s, 0.04 * s), DARK,
			CFrame.new(0, 0.55 * s, 0.23 * s))
		add(model, body, "ArmL", Vector3.new(0.5 * s, 0.1 * s, 0.1 * s),
			Color3.fromRGB(220, 180, 140),
			CFrame.new(-0.5 * s, 0.15 * s, 0) * CFrame.Angles(0, 0, math.rad(-20)))
		add(model, body, "ArmR", Vector3.new(0.5 * s, 0.1 * s, 0.1 * s),
			Color3.fromRGB(220, 180, 140),
			CFrame.new(0.5 * s, 0.15 * s, 0) * CFrame.Angles(0, 0, math.rad(20)))
		add(model, body, "LegL", Vector3.new(0.12 * s, 0.5 * s, 0.12 * s),
			Color3.fromRGB(220, 180, 140), CFrame.new(-0.12 * s, -0.35 * s, 0))
		add(model, body, "LegR", Vector3.new(0.12 * s, 0.5 * s, 0.12 * s),
			Color3.fromRGB(220, 180, 140), CFrame.new(0.12 * s, -0.35 * s, 0))
		add(model, body, "ShoeL", Vector3.new(0.14 * s, 0.1 * s, 0.25 * s),
			Color3.fromRGB(255, 180, 210), CFrame.new(-0.12 * s, -0.48 * s, 0.05 * s))
		add(model, body, "ShoeR", Vector3.new(0.14 * s, 0.1 * s, 0.25 * s),
			Color3.fromRGB(255, 180, 210), CFrame.new(0.12 * s, -0.48 * s, 0.05 * s))

	elseif id == "trippi-troppi" then
		-- IKAN-BERUANG: orange fish body, tail + dorsal fins,
		-- brown bear ears on top, little bear snout at +Z.
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(0.8 * s, 0.7 * s, 1.0 * s)
		body.Color = Color3.fromRGB(240, 130, 60)
		add(model, body, "TailFin", Vector3.new(0.08 * s, 0.6 * s, 0.5 * s),
			Color3.fromRGB(220, 100, 40), CFrame.new(0, 0.05 * s, -0.65 * s))
		add(model, body, "TailFin2", Vector3.new(0.5 * s, 0.08 * s, 0.4 * s),
			Color3.fromRGB(220, 100, 40), CFrame.new(0, 0.05 * s, -0.65 * s))
		add(model, body, "DorsalFin", Vector3.new(0.08 * s, 0.4 * s, 0.5 * s),
			Color3.fromRGB(220, 100, 40),
			CFrame.new(0, 0.45 * s, -0.1 * s) * CFrame.Angles(math.rad(-20), 0, 0))
		add(model, body, "FinL", Vector3.new(0.35 * s, 0.08 * s, 0.3 * s),
			Color3.fromRGB(220, 100, 40), CFrame.new(-0.5 * s, -0.05 * s, 0.1 * s))
		add(model, body, "FinR", Vector3.new(0.35 * s, 0.08 * s, 0.3 * s),
			Color3.fromRGB(220, 100, 40), CFrame.new(0.5 * s, -0.05 * s, 0.1 * s))
		add(model, body, "EarL", Vector3.new(0.25 * s, 0.25 * s, 0.25 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(-0.25 * s, 0.42 * s, 0.25 * s), Enum.PartType.Ball)
		add(model, body, "EarR", Vector3.new(0.25 * s, 0.25 * s, 0.25 * s),
			Color3.fromRGB(120, 80, 40), CFrame.new(0.25 * s, 0.42 * s, 0.25 * s), Enum.PartType.Ball)
		add(model, body, "Snout", Vector3.new(0.3 * s, 0.3 * s, 0.3 * s),
			Color3.fromRGB(210, 180, 140), CFrame.new(0, -0.05 * s, 0.5 * s), Enum.PartType.Ball)
		add(model, body, "Nose", Vector3.new(0.1 * s, 0.1 * s, 0.1 * s), DARK,
			CFrame.new(0, 0, 0.65 * s), Enum.PartType.Ball)
		addEyes(model, body, 0.15 * s, 0.45 * s, 0.18 * s, 0.12 * s)
		add(model, body, "Stripe", Vector3.new(0.84 * s, 0.08 * s, 0.2 * s),
			Color3.fromRGB(200, 90, 30), CFrame.new(0, 0.1 * s, -0.2 * s))

	elseif id == "cappuccino-assassino" then
		-- CANGKIR NINJA: cream mug (cylinder, axis X), coffee
		-- disc on the +X face, dark ninja headband + ribbons,
		-- katana tilted at its side. PrimaryPart stays unrotated.
		body.Shape = Enum.PartType.Cylinder
		body.Size = Vector3.new(0.6 * s, 0.75 * s, 0.75 * s)
		body.Color = Color3.fromRGB(240, 225, 200)
		add(model, body, "Saucer", Vector3.new(0.1 * s, 0.95 * s, 0.95 * s),
			Color3.fromRGB(250, 250, 250),
			CFrame.new(0, -0.42 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
		add(model, body, "Coffee", Vector3.new(0.06 * s, 0.6 * s, 0.6 * s),
			Color3.fromRGB(90, 60, 40), CFrame.new(0.3 * s, 0, 0), Enum.PartType.Cylinder)
		add(model, body, "Handle", Vector3.new(0.1 * s, 0.3 * s, 0.1 * s),
			Color3.fromRGB(230, 210, 180), CFrame.new(-0.36 * s, 0, 0))
		add(model, body, "Headband", Vector3.new(0.62 * s, 0.16 * s, 0.78 * s),
			Color3.fromRGB(40, 40, 55), CFrame.new(0, 0.28 * s, 0))
		add(model, body, "Knot", Vector3.new(0.16 * s, 0.16 * s, 0.16 * s),
			Color3.fromRGB(40, 40, 55), CFrame.new(0, 0.28 * s, -0.42 * s), Enum.PartType.Ball)
		add(model, body, "RibbonL", Vector3.new(0.12 * s, 0.5 * s, 0.04 * s),
			Color3.fromRGB(40, 40, 55),
			CFrame.new(-0.1 * s, 0.05 * s, -0.55 * s) * CFrame.Angles(math.rad(15), 0, 0))
		add(model, body, "RibbonR", Vector3.new(0.12 * s, 0.5 * s, 0.04 * s),
			Color3.fromRGB(40, 40, 55),
			CFrame.new(0.1 * s, 0.05 * s, -0.55 * s) * CFrame.Angles(math.rad(15), 0, 0))
		for _, sx in ipairs({ -1, 1 }) do
			add(model, body, "EyeWhite", Vector3.new(0.14 * s, 0.14 * s, 0.14 * s), WHITE,
				CFrame.new(sx * 0.15 * s, 0.05 * s, 0.36 * s), Enum.PartType.Ball)
			add(model, body, "Pupil", Vector3.new(0.07 * s, 0.07 * s, 0.07 * s), DARK,
				CFrame.new(sx * 0.15 * s, 0.05 * s, 0.42 * s), Enum.PartType.Ball)
			add(model, body, "Brow", Vector3.new(0.18 * s, 0.05 * s, 0.05 * s), DARK,
				CFrame.new(sx * 0.15 * s, 0.18 * s, 0.4 * s) * CFrame.Angles(0, 0, math.rad(sx * -20)))
		end
		add(model, body, "Katana", Vector3.new(0.1 * s, 1.0 * s, 0.04 * s),
			Color3.fromRGB(200, 210, 220),
			CFrame.new(0.55 * s, 0.1 * s, 0.15 * s) * CFrame.Angles(0, 0, math.rad(-30)), nil, Enum.Material.Metal)
		add(model, body, "KatanaGuard", Vector3.new(0.16 * s, 0.06 * s, 0.08 * s),
			Color3.fromRGB(255, 205, 40),
			CFrame.new(0.42 * s, -0.12 * s, 0.15 * s) * CFrame.Angles(0, 0, math.rad(-30)), nil, Enum.Material.Metal)
		add(model, body, "KatanaGrip", Vector3.new(0.1 * s, 0.3 * s, 0.06 * s),
			Color3.fromRGB(40, 40, 55),
			CFrame.new(0.32 * s, -0.3 * s, 0.15 * s) * CFrame.Angles(0, 0, math.rad(-30)))

	elseif id == "frigo-camelo" then
		-- KULKAS-UNTA: tall white fridge with door split +
		-- handles, camel hump on top, neck leaning up to +Z
		-- with a camel head.
		body.Size = Vector3.new(0.7 * s, 1.0 * s, 0.6 * s)
		body.Color = Color3.fromRGB(200, 220, 235)
		add(model, body, "DoorSplit", Vector3.new(0.7 * s, 0.04 * s, 0.02 * s),
			Color3.fromRGB(150, 170, 190), CFrame.new(0, 0.1 * s, 0.31 * s))
		add(model, body, "HandleTop", Vector3.new(0.06 * s, 0.4 * s, 0.06 * s),
			Color3.fromRGB(150, 170, 190), CFrame.new(0.25 * s, 0.15 * s, 0.32 * s))
		add(model, body, "HandleBottom", Vector3.new(0.06 * s, 0.4 * s, 0.06 * s),
			Color3.fromRGB(150, 170, 190), CFrame.new(0.25 * s, -0.3 * s, 0.32 * s))
		add(model, body, "Hump", Vector3.new(0.4 * s, 0.4 * s, 0.4 * s),
			Color3.fromRGB(210, 180, 130), CFrame.new(0, 0.58 * s, -0.15 * s), Enum.PartType.Ball)
		add(model, body, "Neck", Vector3.new(0.25 * s, 0.45 * s, 0.25 * s),
			Color3.fromRGB(210, 180, 130),
			CFrame.new(0, 0.55 * s, 0.3 * s) * CFrame.Angles(math.rad(35), 0, 0))
		add(model, body, "CamelHead", Vector3.new(0.28 * s, 0.22 * s, 0.4 * s),
			Color3.fromRGB(210, 180, 130), CFrame.new(0, 0.75 * s, 0.5 * s))
		add(model, body, "Muzzle", Vector3.new(0.2 * s, 0.15 * s, 0.15 * s),
			Color3.fromRGB(230, 205, 160), CFrame.new(0, 0.7 * s, 0.72 * s))
		addEyes(model, body, 0.8 * s, 0.68 * s, 0.1 * s, 0.08 * s)
		add(model, body, "FootL", Vector3.new(0.15 * s, 0.08 * s, 0.15 * s),
			Color3.fromRGB(120, 130, 140), CFrame.new(-0.25 * s, -0.48 * s, 0.2 * s))
		add(model, body, "FootR", Vector3.new(0.15 * s, 0.08 * s, 0.15 * s),
			Color3.fromRGB(120, 130, 140), CFrame.new(0.25 * s, -0.48 * s, 0.2 * s))

	elseif id == "vaca-saturno" then
		-- SAPI + CINCIN SATURNUS: white cow body with black
		-- spots, tilted gold Saturn ring around it, cow head
		-- with horns, four legs, tail with dark tuft.
		body.Size = Vector3.new(0.8 * s, 0.7 * s, 1.1 * s)
		body.Color = Color3.fromRGB(235, 235, 240)
		add(model, body, "Ring", Vector3.new(0.08 * s, 1.35 * s, 1.35 * s),
			Color3.fromRGB(255, 210, 90),
			CFrame.new(0, 0.05 * s, 0) * CFrame.Angles(math.rad(20), 0, math.rad(90)),
			Enum.PartType.Cylinder, Enum.Material.Metal)
		add(model, body, "SpotL", Vector3.new(0.06 * s, 0.2 * s, 0.3 * s), DARK,
			CFrame.new(-0.41 * s, 0.1 * s, 0.2 * s))
		add(model, body, "SpotR", Vector3.new(0.06 * s, 0.2 * s, 0.3 * s), DARK,
			CFrame.new(0.41 * s, -0.1 * s, -0.3 * s))
		add(model, body, "SpotTop", Vector3.new(0.25 * s, 0.06 * s, 0.3 * s), DARK,
			CFrame.new(0.1 * s, 0.36 * s, 0))
		add(model, body, "Head", Vector3.new(0.45 * s, 0.4 * s, 0.4 * s),
			Color3.fromRGB(235, 235, 240), CFrame.new(0, 0.15 * s, 0.68 * s))
		add(model, body, "Muzzle", Vector3.new(0.35 * s, 0.2 * s, 0.15 * s),
			Color3.fromRGB(255, 180, 190), CFrame.new(0, 0.05 * s, 0.9 * s))
		add(model, body, "NostrilL", Vector3.new(0.06 * s, 0.06 * s, 0.06 * s), DARK,
			CFrame.new(-0.08 * s, 0.05 * s, 0.98 * s), Enum.PartType.Ball)
		add(model, body, "NostrilR", Vector3.new(0.06 * s, 0.06 * s, 0.06 * s), DARK,
			CFrame.new(0.08 * s, 0.05 * s, 0.98 * s), Enum.PartType.Ball)
		add(model, body, "HornL", Vector3.new(0.08 * s, 0.25 * s, 0.08 * s),
			Color3.fromRGB(240, 220, 180),
			CFrame.new(-0.2 * s, 0.42 * s, 0.65 * s) * CFrame.Angles(0, 0, math.rad(25)))
		add(model, body, "HornR", Vector3.new(0.08 * s, 0.25 * s, 0.08 * s),
			Color3.fromRGB(240, 220, 180),
			CFrame.new(0.2 * s, 0.42 * s, 0.65 * s) * CFrame.Angles(0, 0, math.rad(-25)))
		add(model, body, "EarL", Vector3.new(0.2 * s, 0.12 * s, 0.08 * s),
			Color3.fromRGB(255, 200, 200), CFrame.new(-0.32 * s, 0.2 * s, 0.65 * s))
		add(model, body, "EarR", Vector3.new(0.2 * s, 0.12 * s, 0.08 * s),
			Color3.fromRGB(255, 200, 200), CFrame.new(0.32 * s, 0.2 * s, 0.65 * s))
		addEyes(model, body, 0.25 * s, 0.88 * s, 0.14 * s, 0.11 * s)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				add(model, body, "Leg", Vector3.new(0.18 * s, 0.3 * s, 0.18 * s),
					Color3.fromRGB(235, 235, 240),
					CFrame.new(sx * 0.22 * s, -0.4 * s, sz * 0.35 * s))
			end
		end
		add(model, body, "Udder", Vector3.new(0.3 * s, 0.15 * s, 0.3 * s),
			Color3.fromRGB(255, 180, 190), CFrame.new(0, -0.38 * s, 0))
		add(model, body, "Tail", Vector3.new(0.08 * s, 0.5 * s, 0.08 * s),
			Color3.fromRGB(235, 235, 240),
			CFrame.new(0, -0.1 * s, -0.6 * s) * CFrame.Angles(math.rad(20), 0, 0))
		add(model, body, "TailTuft", Vector3.new(0.14 * s, 0.14 * s, 0.14 * s), DARK,
			CFrame.new(0, -0.35 * s, -0.7 * s), Enum.PartType.Ball)

	else
		-- Unknown id: plain cube + eyes, never throw.
		body.Size = Vector3.new(0.6 * s, 0.7 * s, 0.6 * s)
		body.Color = row.color or Color3.fromRGB(200, 200, 200)
		addEyes(model, body, 0.1 * s, 0.31 * s, 0.15 * s, 0.12 * s)
	end
end

function BrainrotFactory.buildBrainrotModel(row, mutation)
	row = row or BrainrotData.CAST[1]
	local size = row.size or 3
	local rate = row.rate or 0
	local price = row.price or 0
	local displayBase = row.name or "Brainrot"
	if type(mutation) ~= "string"
		or (mutation ~= "Normal" and mutation ~= "Emas" and mutation ~= "Pelangi") then
		mutation = "Normal"
	end
	local mult = BrainrotFactory.getMutationMultiplier(mutation)
	local effRate = rate * mult
	local effPrice = price * mult
	local displayName = displayBase
	if mutation ~= "Normal" then
		displayName = mutation .. " " .. displayBase
	end

	local model = Instance.new("Model")
	model.Name = displayName

	local body = makePart("Body",
		Vector3.new(0.6 * size, 0.7 * size, 0.6 * size),
		row.color or Color3.fromRGB(200, 200, 200))
	body.CFrame = CFrame.new(0, size / 2, 0)
	body.Parent = model
	model.PrimaryPart = body

	local ok, err = pcall(function()
		buildShape(model, body, row, size)
	end)
	if not ok then
		warn("[BrainrotFactory] buildShape failed for " .. tostring(row.id) .. ": " .. tostring(err))
		body.Size = Vector3.new(0.6 * size, 0.7 * size, 0.6 * size)
		body.Color = row.color or Color3.fromRGB(200, 200, 200)
		body.Shape = Enum.PartType.Block
		body.Material = Enum.Material.SmoothPlastic
		addEyes(model, body, 0.1 * size, 0.31 * size, 0.15 * size, 0.12 * size)
	end

	if mutation == "Emas" then
		body.Color = Color3.fromRGB(255, 205, 40)
		body.Material = Enum.Material.Metal
	elseif mutation == "Pelangi" then
		task.spawn(function()
			local hue = 0
			while model.Parent ~= nil do
				for _, desc in ipairs(model:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Color = Color3.fromHSV(hue, 0.8, 1)
					end
				end
				hue = (hue + 0.05) % 1
				task.wait(0.2)
			end
		end)
	end

	model:SetAttribute("CharId", row.id or "tung-tung-sahur")
	model:SetAttribute("Rarity", row.rarity or "Common")
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rate", effRate)
	model:SetAttribute("Price", effPrice)
	model:SetAttribute("BodySize", size)

	buildBillboard(model, body, row, size, displayName, effRate, effPrice)

	return model
end

return BrainrotFactory
