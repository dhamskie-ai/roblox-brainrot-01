-- SPDX-License-Identifier: MIT
-- BrainrotFactory (Fix #6): organic brainrot silhouettes.
-- The Body is no longer a plain cube: every character is built from
-- Ball / Cylinder / Wedge / CornerWedge parts welded to the Body, with
-- its signature features enlarged ~1.5-2x over v17 so it reads from
-- across the plaza. Face direction is local +Z; the spawner orients
-- the model (faceEast) for the west-to-east belt.
-- PrimaryPart stays "Body" at CFrame (0, size/2, 0), axis-aligned.
-- Attributes: CharId, Rarity, Mutation, Rate, Price, BodySize.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local GOLD_COLOR = Color3.fromRGB(255, 205, 40)
local DARK = Color3.fromRGB(30, 30, 30)
local WHITE = Color3.fromRGB(240, 240, 240)

local Ball = Enum.PartType.Ball
local Cylinder = Enum.PartType.Cylinder
local Wedge = Enum.PartType.Wedge

-- makePart(name, size, color, material, shape): Anchored, non-colliding
-- part with smooth top/bottom faces. Default material SmoothPlastic;
-- pass a PartType for organic shapes (Ball / Cylinder / Wedge /
-- CornerWedge). Behaviour preserved from v16/v17.
local function makePart(name, size, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	return part
end

-- weldTo(model, body, part, offsetCFrame): place the part relative to
-- the Body and weld it there. Behaviour preserved from v16/v17.
local function weldTo(model, body, part, offsetCFrame)
	part.CFrame = body.CFrame * offsetCFrame
	part.Parent = model
	local weld = Instance.new("Weld")
	weld.Part0 = body
	weld.Part1 = part
	weld.C0 = offsetCFrame
	weld.Parent = body
end

-- Convenience: make + weld in one call. Offsets are Vector3/CFrame
-- values already scaled by the row size at the call site.
local function addPart(model, body, name, size, color, offset, material, shape)
	local part = makePart(name, size, color, material, shape)
	weldTo(model, body, part, offset)
	return part
end

-- Two dark ball eyes on the +Z face. y/z/spread/eyeSize are studs.
local function addEyes(model, body, y, z, spread, eyeSize)
	local e = eyeSize or 0.09
	addPart(model, body, "EyeL", Vector3.new(e, e, e), DARK, CFrame.new(-spread, y, z), nil, Ball)
	addPart(model, body, "EyeR", Vector3.new(e, e, e), DARK, CFrame.new(spread, y, z), nil, Ball)
end

-- A cylinder segment running from p1 to p2 (offsets relative to the
-- Body centre). Cylinder's long axis is X, so the offset orients local
-- X along p1 -> p2 via a lookAt frame.
local function addCylBetween(model, body, name, p1, p2, diameter, color, material)
	local mid = (p1 + p2) / 2
	local len = (p2 - p1).Magnitude
	local part = makePart(name, Vector3.new(len, diameter, diameter), color, material, Cylinder)
	weldTo(model, body, part, CFrame.new(mid, p2) * CFrame.Angles(0, math.rad(90), 0))
	return part
end

-- One function, one branch per row.id. Unknown ids fall through to a
-- plain cube + eyes. All offsets are relative to the Body centre and
-- already multiplied by s (the row size) at the call site.
local function buildShape(model, body, row, size)
	local s = size
	local id = row.id

	if id == "tung-tung-sahur" then
		-- BATANG KAYU: horizontal log (cylinder axis is X already).
		addPart(model, body, "Log", Vector3.new(1.4 * s, 0.55 * s, 0.55 * s), Color3.fromRGB(150, 100, 50), CFrame.new(0, 0.05 * s, 0), nil, Cylinder)
		addPart(model, body, "LogRingA", Vector3.new(0.06 * s, 0.5 * s, 0.5 * s), Color3.fromRGB(120, 80, 40), CFrame.new(0.62 * s, 0.05 * s, 0), nil, Cylinder)
		addPart(model, body, "LogRingB", Vector3.new(0.06 * s, 0.5 * s, 0.5 * s), Color3.fromRGB(120, 80, 40), CFrame.new(-0.62 * s, 0.05 * s, 0), nil, Cylinder)
		-- Face on the +X end cap.
		addPart(model, body, "EyeL", Vector3.new(0.09 * s, 0.09 * s, 0.09 * s), DARK, CFrame.new(0.72 * s, 0.18 * s, -0.13 * s), nil, Ball)
		addPart(model, body, "EyeR", Vector3.new(0.09 * s, 0.09 * s, 0.09 * s), DARK, CFrame.new(0.72 * s, 0.18 * s, 0.13 * s), nil, Ball)
		addPart(model, body, "Mouth", Vector3.new(0.05 * s, 0.07 * s, 0.22 * s), DARK, CFrame.new(0.72 * s, -0.02 * s, 0))
		-- PENTUNGAN BESAR: long tilted club.
		addPart(model, body, "Club", Vector3.new(1.2 * s, 0.35 * s, 0.35 * s), Color3.fromRGB(120, 80, 40), CFrame.new(-0.42 * s, 0.18 * s, 0.2 * s) * CFrame.Angles(0, 0, math.rad(25)), nil, Cylinder)
		-- Two short wooden legs.
		addPart(model, body, "LegL", Vector3.new(0.3 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(120, 80, 40), CFrame.new(-0.2 * s, -0.35 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "LegR", Vector3.new(0.3 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(120, 80, 40), CFrame.new(0.2 * s, -0.35 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)

	elseif id == "tralalero" then
		-- HIU biru: ball body stretched along Z.
		addPart(model, body, "SharkBody", Vector3.new(0.8 * s, 0.7 * s, 1.5 * s), Color3.fromRGB(60, 140, 220), CFrame.new(0, 0.05 * s, 0), nil, Ball)
		addPart(model, body, "DorsalFin", Vector3.new(0.45 * s, 0.55 * s, 0.8 * s), Color3.fromRGB(40, 110, 190), CFrame.new(0, 0.5 * s, -0.15 * s), nil, Wedge)
		addPart(model, body, "TailFinTop", Vector3.new(0.15 * s, 0.9 * s, 0.7 * s), Color3.fromRGB(40, 110, 190), CFrame.new(0, 0.2 * s, -0.95 * s), nil, Wedge)
		addPart(model, body, "TailFinLow", Vector3.new(0.15 * s, 0.6 * s, 0.5 * s), Color3.fromRGB(40, 110, 190), CFrame.new(0, -0.15 * s, -0.9 * s), nil, Wedge)
		addPart(model, body, "Belly", Vector3.new(0.6 * s, 0.35 * s, 1.1 * s), WHITE, CFrame.new(0, -0.18 * s, 0.1 * s), nil, Ball)
		addPart(model, body, "FinL", Vector3.new(0.4 * s, 0.1 * s, 0.5 * s), Color3.fromRGB(40, 110, 190), CFrame.new(-0.45 * s, -0.1 * s, 0.3 * s), nil, Wedge)
		addPart(model, body, "FinR", Vector3.new(0.4 * s, 0.1 * s, 0.5 * s), Color3.fromRGB(40, 110, 190), CFrame.new(0.45 * s, -0.1 * s, 0.3 * s), nil, Wedge)
		addPart(model, body, "LegL", Vector3.new(0.3 * s, 0.13 * s, 0.13 * s), Color3.fromRGB(40, 110, 190), CFrame.new(-0.2 * s, -0.35 * s, 0.05 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "LegR", Vector3.new(0.3 * s, 0.13 * s, 0.13 * s), Color3.fromRGB(40, 110, 190), CFrame.new(0.2 * s, -0.35 * s, 0.05 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "SneakerL", Vector3.new(0.3 * s, 0.18 * s, 0.5 * s), WHITE, CFrame.new(-0.2 * s, -0.42 * s, 0.2 * s), nil, Ball)
		addPart(model, body, "SneakerR", Vector3.new(0.3 * s, 0.18 * s, 0.5 * s), WHITE, CFrame.new(0.2 * s, -0.42 * s, 0.2 * s), nil, Ball)
		addEyes(model, body, 0.22 * s, 0.7 * s, 0.17 * s, 0.1 * s)
		addPart(model, body, "Mouth", Vector3.new(0.3 * s, 0.06 * s, 0.05 * s), DARK, CFrame.new(0, -0.02 * s, 0.74 * s))

	elseif id == "brr-patapim" then
		-- MONYET: brown ball body, long nose, little tree, curled tail.
		addPart(model, body, "Belly", Vector3.new(0.5 * s, 0.55 * s, 0.3 * s), Color3.fromRGB(200, 160, 110), CFrame.new(0, -0.05 * s, 0.35 * s), nil, Ball)
		addPart(model, body, "Nose", Vector3.new(1.0 * s, 0.35 * s, 0.35 * s), Color3.fromRGB(170, 120, 70), CFrame.new(0, 0.05 * s, 0.75 * s) * CFrame.Angles(0, math.rad(90), 0), nil, Cylinder)
		addPart(model, body, "NoseTip", Vector3.new(0.32 * s, 0.32 * s, 0.32 * s), Color3.fromRGB(140, 95, 55), CFrame.new(0, 0.05 * s, 1.25 * s), nil, Ball)
		addPart(model, body, "NostrilL", Vector3.new(0.06 * s, 0.06 * s, 0.06 * s), DARK, CFrame.new(-0.07 * s, 0.08 * s, 1.38 * s), nil, Ball)
		addPart(model, body, "NostrilR", Vector3.new(0.06 * s, 0.06 * s, 0.06 * s), DARK, CFrame.new(0.07 * s, 0.08 * s, 1.38 * s), nil, Ball)
		addEyes(model, body, 0.32 * s, 0.38 * s, 0.18 * s, 0.1 * s)
		addPart(model, body, "EarL", Vector3.new(0.22 * s, 0.22 * s, 0.22 * s), Color3.fromRGB(140, 95, 55), CFrame.new(-0.42 * s, 0.25 * s, -0.05 * s), nil, Ball)
		addPart(model, body, "EarR", Vector3.new(0.22 * s, 0.22 * s, 0.22 * s), Color3.fromRGB(140, 95, 55), CFrame.new(0.42 * s, 0.25 * s, -0.05 * s), nil, Ball)
		-- POHON kecil di samping.
		addPart(model, body, "Trunk", Vector3.new(0.6 * s, 0.16 * s, 0.16 * s), Color3.fromRGB(120, 80, 40), CFrame.new(0.55 * s, -0.2 * s, -0.25 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Canopy", Vector3.new(0.6 * s, 0.55 * s, 0.6 * s), Color3.fromRGB(60, 160, 70), CFrame.new(0.55 * s, 0.2 * s, -0.25 * s), nil, Ball)
		addPart(model, body, "CanopyTop", Vector3.new(0.35 * s, 0.35 * s, 0.35 * s), Color3.fromRGB(70, 180, 80), CFrame.new(0.7 * s, 0.35 * s, -0.3 * s), nil, Ball)
		-- Ekor melengkung dari ball-ball kecil.
		addPart(model, body, "Tail1", Vector3.new(0.16 * s, 0.16 * s, 0.16 * s), Color3.fromRGB(140, 95, 55), CFrame.new(-0.45 * s, -0.2 * s, -0.35 * s), nil, Ball)
		addPart(model, body, "Tail2", Vector3.new(0.16 * s, 0.16 * s, 0.16 * s), Color3.fromRGB(140, 95, 55), CFrame.new(-0.58 * s, 0.02 * s, -0.42 * s), nil, Ball)
		addPart(model, body, "Tail3", Vector3.new(0.16 * s, 0.16 * s, 0.16 * s), Color3.fromRGB(140, 95, 55), CFrame.new(-0.52 * s, 0.28 * s, -0.38 * s), nil, Ball)

	elseif id == "lirili-larila" then
		-- KAKTUS-GAJAH: upright cactus column + elephant head + long trunk.
		addPart(model, body, "Cactus", Vector3.new(1.0 * s, 0.6 * s, 0.6 * s), Color3.fromRGB(80, 180, 90), CFrame.new(0, 0, -0.15 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "SpikeL1", Vector3.new(0.14 * s, 0.22 * s, 0.14 * s), Color3.fromRGB(140, 230, 140), CFrame.new(-0.32 * s, 0.2 * s, -0.15 * s), nil, Wedge)
		addPart(model, body, "SpikeR1", Vector3.new(0.14 * s, 0.22 * s, 0.14 * s), Color3.fromRGB(140, 230, 140), CFrame.new(0.32 * s, 0.2 * s, -0.15 * s), nil, Wedge)
		addPart(model, body, "SpikeL2", Vector3.new(0.14 * s, 0.22 * s, 0.14 * s), Color3.fromRGB(140, 230, 140), CFrame.new(-0.32 * s, -0.2 * s, -0.15 * s), nil, Wedge)
		addPart(model, body, "SpikeR2", Vector3.new(0.14 * s, 0.22 * s, 0.14 * s), Color3.fromRGB(140, 230, 140), CFrame.new(0.32 * s, -0.2 * s, -0.15 * s), nil, Wedge)
		addPart(model, body, "ArmL", Vector3.new(0.4 * s, 0.16 * s, 0.16 * s), Color3.fromRGB(80, 180, 90), CFrame.new(-0.35 * s, -0.1 * s, -0.15 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "ArmR", Vector3.new(0.4 * s, 0.16 * s, 0.16 * s), Color3.fromRGB(80, 180, 90), CFrame.new(0.35 * s, -0.1 * s, -0.15 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "ElephantHead", Vector3.new(0.55 * s, 0.55 * s, 0.55 * s), Color3.fromRGB(170, 175, 180), CFrame.new(0, 0.35 * s, 0.35 * s), nil, Ball)
		addPart(model, body, "EarL", Vector3.new(0.35 * s, 0.45 * s, 0.12 * s), Color3.fromRGB(150, 155, 160), CFrame.new(-0.35 * s, 0.35 * s, 0.3 * s), nil, Ball)
		addPart(model, body, "EarR", Vector3.new(0.35 * s, 0.45 * s, 0.12 * s), Color3.fromRGB(150, 155, 160), CFrame.new(0.35 * s, 0.35 * s, 0.3 * s), nil, Ball)
		-- BELALAI PANJANG: two cylinders descending toward +Z.
		addCylBetween(model, body, "Trunk1", Vector3.new(0, 0.3 * s, 0.55 * s), Vector3.new(0, -0.05 * s, 0.8 * s), 0.22 * s, Color3.fromRGB(150, 155, 160))
		addCylBetween(model, body, "Trunk2", Vector3.new(0, -0.05 * s, 0.8 * s), Vector3.new(0, -0.3 * s, 0.92 * s), 0.18 * s, Color3.fromRGB(150, 155, 160))
		addEyes(model, body, 0.45 * s, 0.58 * s, 0.15 * s, 0.1 * s)

	elseif id == "chimpanzini" then
		-- SIMPANSE + PISANG BESAR melengkung (3 segmen, total ~1.5s).
		addPart(model, body, "Face", Vector3.new(0.5 * s, 0.45 * s, 0.25 * s), Color3.fromRGB(200, 160, 110), CFrame.new(0, 0.05 * s, 0.38 * s), nil, Ball)
		addEyes(model, body, 0.18 * s, 0.5 * s, 0.14 * s, 0.09 * s)
		addPart(model, body, "EarL", Vector3.new(0.28 * s, 0.28 * s, 0.28 * s), Color3.fromRGB(140, 95, 55), CFrame.new(-0.45 * s, 0.15 * s, 0), nil, Ball)
		addPart(model, body, "EarR", Vector3.new(0.28 * s, 0.28 * s, 0.28 * s), Color3.fromRGB(140, 95, 55), CFrame.new(0.45 * s, 0.15 * s, 0), nil, Ball)
		addCylBetween(model, body, "Banana1", Vector3.new(0.35 * s, -0.3 * s, 0.45 * s), Vector3.new(0.58 * s, 0.05 * s, 0.6 * s), 0.28 * s, Color3.fromRGB(250, 220, 60))
		addCylBetween(model, body, "Banana2", Vector3.new(0.58 * s, 0.05 * s, 0.6 * s), Vector3.new(0.45 * s, 0.38 * s, 0.55 * s), 0.28 * s, Color3.fromRGB(250, 220, 60))
		addCylBetween(model, body, "Banana3", Vector3.new(0.45 * s, 0.38 * s, 0.55 * s), Vector3.new(0.12 * s, 0.5 * s, 0.5 * s), 0.28 * s, Color3.fromRGB(250, 220, 60))
		addPart(model, body, "BananaTip", Vector3.new(0.16 * s, 0.16 * s, 0.16 * s), Color3.fromRGB(120, 80, 40), CFrame.new(0.12 * s, 0.5 * s, 0.5 * s), nil, Ball)
		addPart(model, body, "ArmL", Vector3.new(0.5 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(140, 95, 55), CFrame.new(-0.48 * s, -0.15 * s, 0.15 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "ArmR", Vector3.new(0.5 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(140, 95, 55), CFrame.new(0.48 * s, -0.15 * s, 0.15 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "FootL", Vector3.new(0.2 * s, 0.2 * s, 0.2 * s), Color3.fromRGB(140, 95, 55), CFrame.new(-0.2 * s, -0.42 * s, 0.1 * s), nil, Ball)
		addPart(model, body, "FootR", Vector3.new(0.2 * s, 0.2 * s, 0.2 * s), Color3.fromRGB(140, 95, 55), CFrame.new(0.2 * s, -0.42 * s, 0.1 * s), nil, Ball)

	elseif id == "boneca" then
		-- KATAK di atas BAN BESAR.
		addPart(model, body, "Tire", Vector3.new(0.35 * s, 1.6 * s, 1.6 * s), Color3.fromRGB(40, 40, 40), CFrame.new(0, -0.3 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Hub", Vector3.new(0.5 * s, 0.5 * s, 0.5 * s), Color3.fromRGB(120, 120, 120), CFrame.new(0, -0.3 * s, 0), nil, Ball)
		addPart(model, body, "FrogBody", Vector3.new(0.8 * s, 0.65 * s, 0.8 * s), Color3.fromRGB(90, 200, 110), CFrame.new(0, 0.18 * s, 0), nil, Ball)
		addPart(model, body, "Belly", Vector3.new(0.5 * s, 0.4 * s, 0.25 * s), Color3.fromRGB(170, 240, 180), CFrame.new(0, 0.05 * s, 0.35 * s), nil, Ball)
		addPart(model, body, "EyeL", Vector3.new(0.28 * s, 0.28 * s, 0.28 * s), WHITE, CFrame.new(-0.22 * s, 0.45 * s, 0.18 * s), nil, Ball)
		addPart(model, body, "EyeR", Vector3.new(0.28 * s, 0.28 * s, 0.28 * s), WHITE, CFrame.new(0.22 * s, 0.45 * s, 0.18 * s), nil, Ball)
		addPart(model, body, "PupilL", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), DARK, CFrame.new(-0.22 * s, 0.47 * s, 0.3 * s), nil, Ball)
		addPart(model, body, "PupilR", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), DARK, CFrame.new(0.22 * s, 0.47 * s, 0.3 * s), nil, Ball)
		addPart(model, body, "Mouth", Vector3.new(0.4 * s, 0.06 * s, 0.05 * s), DARK, CFrame.new(0, 0.08 * s, 0.4 * s))
		addPart(model, body, "LegL", Vector3.new(0.3 * s, 0.3 * s, 0.3 * s), Color3.fromRGB(90, 200, 110), CFrame.new(-0.42 * s, -0.02 * s, 0.1 * s), nil, Ball)
		addPart(model, body, "LegR", Vector3.new(0.3 * s, 0.3 * s, 0.3 * s), Color3.fromRGB(90, 200, 110), CFrame.new(0.42 * s, -0.02 * s, 0.1 * s), nil, Ball)

	elseif id == "bombardiro" then
		-- BUAYA-PESAWAT: fuselage cylinder along Z, croc snout, wide wings.
		addPart(model, body, "Fuselage", Vector3.new(1.3 * s, 0.7 * s, 0.7 * s), Color3.fromRGB(70, 150, 80), CFrame.new(0, 0.1 * s, 0) * CFrame.Angles(0, math.rad(90), 0), nil, Cylinder)
		addPart(model, body, "Belly", Vector3.new(0.5 * s, 0.3 * s, 0.9 * s), Color3.fromRGB(150, 220, 150), CFrame.new(0, -0.15 * s, 0), nil, Ball)
		addPart(model, body, "Head", Vector3.new(0.6 * s, 0.6 * s, 0.6 * s), Color3.fromRGB(70, 150, 80), CFrame.new(0, 0.15 * s, 0.7 * s), nil, Ball)
		addPart(model, body, "Snout", Vector3.new(0.5 * s, 0.35 * s, 0.9 * s), Color3.fromRGB(60, 130, 70), CFrame.new(0, 0.05 * s, 1.0 * s), nil, Wedge)
		addPart(model, body, "ToothL", Vector3.new(0.08 * s, 0.14 * s, 0.14 * s), WHITE, CFrame.new(-0.18 * s, -0.15 * s, 0.85 * s), nil, Wedge)
		addPart(model, body, "ToothR", Vector3.new(0.08 * s, 0.14 * s, 0.14 * s), WHITE, CFrame.new(0.18 * s, -0.15 * s, 0.85 * s), nil, Wedge)
		addPart(model, body, "ToothC", Vector3.new(0.08 * s, 0.14 * s, 0.14 * s), WHITE, CFrame.new(0, -0.15 * s, 1.2 * s), nil, Wedge)
		addPart(model, body, "EyeL", Vector3.new(0.14 * s, 0.14 * s, 0.14 * s), DARK, CFrame.new(-0.2 * s, 0.42 * s, 0.72 * s), nil, Ball)
		addPart(model, body, "EyeR", Vector3.new(0.14 * s, 0.14 * s, 0.14 * s), DARK, CFrame.new(0.2 * s, 0.42 * s, 0.72 * s), nil, Ball)
		-- SAYAP LEBAR ke +-X, ujung miring ke atas.
		addPart(model, body, "WingL", Vector3.new(1.2 * s, 0.12 * s, 0.8 * s), Color3.fromRGB(60, 130, 70), CFrame.new(-0.85 * s, 0.15 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(-12)), nil, Wedge)
		addPart(model, body, "WingR", Vector3.new(1.2 * s, 0.12 * s, 0.8 * s), Color3.fromRGB(60, 130, 70), CFrame.new(0.85 * s, 0.15 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(12)), nil, Wedge)
		addPart(model, body, "Tail", Vector3.new(0.4 * s, 0.3 * s, 0.5 * s), Color3.fromRGB(60, 130, 70), CFrame.new(0, 0.2 * s, -0.85 * s), nil, Wedge)
		-- BALING-BALING BESAR: two thin crossing blades in front of the snout.
		addPart(model, body, "PropBladeV", Vector3.new(0.14 * s, 1.1 * s, 0.06 * s), Color3.fromRGB(80, 80, 80), CFrame.new(0, 0.1 * s, 1.5 * s), Enum.Material.Metal)
		addPart(model, body, "PropBladeH", Vector3.new(1.1 * s, 0.14 * s, 0.06 * s), Color3.fromRGB(80, 80, 80), CFrame.new(0, 0.1 * s, 1.5 * s), Enum.Material.Metal)
		addPart(model, body, "PropHub", Vector3.new(0.2 * s, 0.2 * s, 0.2 * s), Color3.fromRGB(60, 60, 60), CFrame.new(0, 0.1 * s, 1.5 * s), nil, Ball)

	elseif id == "garuda-emas" then
		-- BURUNG EMAS: gold ball body, wings spread wide, crown, flat tail.
		addPart(model, body, "Chest", Vector3.new(0.7 * s, 0.6 * s, 0.5 * s), Color3.fromRGB(255, 220, 100), CFrame.new(0, -0.05 * s, 0.25 * s), nil, Ball)
		addPart(model, body, "WingL", Vector3.new(1.8 * s, 0.12 * s, 0.9 * s), Color3.fromRGB(255, 200, 60), CFrame.new(-1.15 * s, 0.25 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(-18)), Enum.Material.Metal, Wedge)
		addPart(model, body, "WingR", Vector3.new(1.8 * s, 0.12 * s, 0.9 * s), Color3.fromRGB(255, 200, 60), CFrame.new(1.15 * s, 0.25 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(18)), Enum.Material.Metal, Wedge)
		addPart(model, body, "Head", Vector3.new(0.45 * s, 0.45 * s, 0.45 * s), Color3.fromRGB(255, 200, 60), CFrame.new(0, 0.35 * s, 0.4 * s), nil, Ball)
		addPart(model, body, "Beak", Vector3.new(0.18 * s, 0.18 * s, 0.4 * s), Color3.fromRGB(255, 150, 40), CFrame.new(0, 0.3 * s, 0.68 * s), nil, Wedge)
		addPart(model, body, "EyeL", Vector3.new(0.09 * s, 0.09 * s, 0.09 * s), DARK, CFrame.new(-0.14 * s, 0.45 * s, 0.58 * s), nil, Ball)
		addPart(model, body, "EyeR", Vector3.new(0.09 * s, 0.09 * s, 0.09 * s), DARK, CFrame.new(0.14 * s, 0.45 * s, 0.58 * s), nil, Ball)
		-- Mahkota metal gold.
		addPart(model, body, "Crown", Vector3.new(0.18 * s, 0.4 * s, 0.4 * s), GOLD_COLOR, CFrame.new(0, 0.62 * s, 0.38 * s) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Cylinder)
		addPart(model, body, "CrownSpikeL", Vector3.new(0.1 * s, 0.18 * s, 0.1 * s), GOLD_COLOR, CFrame.new(-0.12 * s, 0.78 * s, 0.38 * s), Enum.Material.Metal, Wedge)
		addPart(model, body, "CrownSpikeC", Vector3.new(0.1 * s, 0.18 * s, 0.1 * s), GOLD_COLOR, CFrame.new(0, 0.8 * s, 0.38 * s), Enum.Material.Metal, Wedge)
		addPart(model, body, "CrownSpikeR", Vector3.new(0.1 * s, 0.18 * s, 0.1 * s), GOLD_COLOR, CFrame.new(0.12 * s, 0.78 * s, 0.38 * s), Enum.Material.Metal, Wedge)
		-- Ekor 3 wedge pipih di -Z.
		addPart(model, body, "TailL", Vector3.new(0.25 * s, 0.08 * s, 0.8 * s), Color3.fromRGB(255, 200, 60), CFrame.new(-0.28 * s, 0.05 * s, -0.7 * s), Enum.Material.Metal, Wedge)
		addPart(model, body, "TailC", Vector3.new(0.25 * s, 0.08 * s, 0.8 * s), Color3.fromRGB(255, 200, 60), CFrame.new(0, 0.05 * s, -0.75 * s), Enum.Material.Metal, Wedge)
		addPart(model, body, "TailR", Vector3.new(0.25 * s, 0.08 * s, 0.8 * s), Color3.fromRGB(255, 200, 60), CFrame.new(0.28 * s, 0.05 * s, -0.7 * s), Enum.Material.Metal, Wedge)
		addPart(model, body, "LegL", Vector3.new(0.25 * s, 0.12 * s, 0.12 * s), Color3.fromRGB(200, 150, 40), CFrame.new(-0.18 * s, -0.4 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "LegR", Vector3.new(0.25 * s, 0.12 * s, 0.12 * s), Color3.fromRGB(200, 150, 40), CFrame.new(0.18 * s, -0.4 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)

	elseif id == "ballerina" then
		-- BALERINA + CANGKIR: tan torso, wide pink tutu, cappuccino cup head.
		addPart(model, body, "Torso", Vector3.new(0.9 * s, 0.5 * s, 0.5 * s), Color3.fromRGB(220, 180, 140), CFrame.new(0, -0.05 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Tutu", Vector3.new(0.25 * s, 1.8 * s, 1.8 * s), Color3.fromRGB(255, 220, 235), CFrame.new(0, -0.1 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "CupHead", Vector3.new(0.45 * s, 0.5 * s, 0.5 * s), Color3.fromRGB(240, 220, 190), CFrame.new(0, 0.5 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Foam", Vector3.new(0.4 * s, 0.4 * s, 0.4 * s), Color3.fromRGB(250, 240, 220), CFrame.new(0, 0.72 * s, 0), nil, Ball)
		addPart(model, body, "CupHandle", Vector3.new(0.05 * s, 0.3 * s, 0.05 * s), Color3.fromRGB(240, 220, 190), CFrame.new(0.28 * s, 0.5 * s, 0.1 * s))
		addPart(model, body, "EyeL", Vector3.new(0.07 * s, 0.07 * s, 0.07 * s), DARK, CFrame.new(-0.12 * s, 0.55 * s, 0.26 * s), nil, Ball)
		addPart(model, body, "EyeR", Vector3.new(0.07 * s, 0.07 * s, 0.07 * s), DARK, CFrame.new(0.12 * s, 0.55 * s, 0.26 * s), nil, Ball)
		addPart(model, body, "ArmL", Vector3.new(0.45 * s, 0.11 * s, 0.11 * s), Color3.fromRGB(220, 180, 140), CFrame.new(-0.32 * s, 0.2 * s, 0.1 * s) * CFrame.Angles(0, 0, math.rad(-50)), nil, Cylinder)
		addPart(model, body, "ArmR", Vector3.new(0.45 * s, 0.11 * s, 0.11 * s), Color3.fromRGB(220, 180, 140), CFrame.new(0.32 * s, 0.2 * s, 0.1 * s) * CFrame.Angles(0, 0, math.rad(50)), nil, Cylinder)
		addPart(model, body, "ShoeL", Vector3.new(0.16 * s, 0.1 * s, 0.35 * s), Color3.fromRGB(255, 220, 235), CFrame.new(-0.15 * s, -0.46 * s, 0.18 * s), nil, Wedge)
		addPart(model, body, "ShoeR", Vector3.new(0.16 * s, 0.1 * s, 0.35 * s), Color3.fromRGB(255, 220, 235), CFrame.new(0.15 * s, -0.46 * s, 0.18 * s), nil, Wedge)

	elseif id == "trippi-troppi" then
		-- IKAN-BERUANG: orange fish body, fins, bear ears + muzzle.
		addPart(model, body, "FishBody", Vector3.new(0.8 * s, 0.75 * s, 1.4 * s), Color3.fromRGB(240, 130, 60), CFrame.new(0, 0.05 * s, 0), nil, Ball)
		addPart(model, body, "Belly", Vector3.new(0.55 * s, 0.35 * s, 0.9 * s), Color3.fromRGB(250, 230, 200), CFrame.new(0, -0.2 * s, 0.05 * s), nil, Ball)
		addPart(model, body, "DorsalFin", Vector3.new(0.4 * s, 0.5 * s, 0.7 * s), Color3.fromRGB(220, 110, 40), CFrame.new(0, 0.5 * s, -0.15 * s), nil, Wedge)
		addPart(model, body, "TailFin", Vector3.new(0.15 * s, 0.8 * s, 0.6 * s), Color3.fromRGB(220, 110, 40), CFrame.new(0, 0.15 * s, -0.9 * s), nil, Wedge)
		addPart(model, body, "FinL", Vector3.new(0.35 * s, 0.1 * s, 0.45 * s), Color3.fromRGB(220, 110, 40), CFrame.new(-0.48 * s, -0.1 * s, 0.2 * s), nil, Wedge)
		addPart(model, body, "FinR", Vector3.new(0.35 * s, 0.1 * s, 0.45 * s), Color3.fromRGB(220, 110, 40), CFrame.new(0.48 * s, -0.1 * s, 0.2 * s), nil, Wedge)
		addPart(model, body, "BearEarL", Vector3.new(0.3 * s, 0.3 * s, 0.3 * s), Color3.fromRGB(150, 100, 60), CFrame.new(-0.3 * s, 0.45 * s, 0.45 * s), nil, Ball)
		addPart(model, body, "BearEarR", Vector3.new(0.3 * s, 0.3 * s, 0.3 * s), Color3.fromRGB(150, 100, 60), CFrame.new(0.3 * s, 0.45 * s, 0.45 * s), nil, Ball)
		addPart(model, body, "Muzzle", Vector3.new(0.4 * s, 0.3 * s, 0.3 * s), Color3.fromRGB(200, 160, 110), CFrame.new(0, -0.05 * s, 0.68 * s), nil, Ball)
		addPart(model, body, "Nose", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), DARK, CFrame.new(0, 0.02 * s, 0.85 * s), nil, Ball)
		addEyes(model, body, 0.25 * s, 0.62 * s, 0.16 * s, 0.1 * s)

	elseif id == "cappuccino-assassino" then
		-- CANGKIR NINJA: tall cup, dark headband + ribbon tails, big katana.
		addPart(model, body, "Cup", Vector3.new(0.95 * s, 0.75 * s, 0.75 * s), Color3.fromRGB(90, 60, 40), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Coffee", Vector3.new(0.1 * s, 0.6 * s, 0.6 * s), Color3.fromRGB(60, 35, 20), CFrame.new(0, 0.48 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Headband", Vector3.new(0.18 * s, 0.8 * s, 0.8 * s), Color3.fromRGB(40, 40, 50), CFrame.new(0, 0.3 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Ribbon1", Vector3.new(0.05 * s, 0.5 * s, 0.12 * s), Color3.fromRGB(150, 40, 40), CFrame.new(-0.38 * s, 0.15 * s, -0.42 * s) * CFrame.Angles(0, 0, math.rad(20)))
		addPart(model, body, "Ribbon2", Vector3.new(0.05 * s, 0.5 * s, 0.12 * s), Color3.fromRGB(150, 40, 40), CFrame.new(-0.45 * s, -0.05 * s, -0.45 * s) * CFrame.Angles(0, 0, math.rad(-15)))
		addPart(model, body, "EyeL", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), WHITE, CFrame.new(-0.14 * s, 0.32 * s, 0.4 * s), nil, Ball)
		addPart(model, body, "EyeR", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), WHITE, CFrame.new(0.14 * s, 0.32 * s, 0.4 * s), nil, Ball)
		addPart(model, body, "PupilL", Vector3.new(0.06 * s, 0.06 * s, 0.06 * s), DARK, CFrame.new(-0.14 * s, 0.32 * s, 0.46 * s), nil, Ball)
		addPart(model, body, "PupilR", Vector3.new(0.06 * s, 0.06 * s, 0.06 * s), DARK, CFrame.new(0.14 * s, 0.32 * s, 0.46 * s), nil, Ball)
		addPart(model, body, "CupHandle", Vector3.new(0.05 * s, 0.3 * s, 0.05 * s), Color3.fromRGB(60, 40, 25), CFrame.new(-0.42 * s, 0.05 * s, 0.1 * s))
		-- KATANA BESAR: metal wedge blade, tilted at the side.
		local bladeRot = CFrame.Angles(0, math.rad(15), 0) * CFrame.Angles(0, 0, math.rad(40))
		addPart(model, body, "KatanaBlade", Vector3.new(1.2 * s, 0.08 * s, 0.22 * s), Color3.fromRGB(200, 210, 220), CFrame.new(0.55 * s, 0.15 * s, 0.15 * s) * bladeRot, Enum.Material.Metal, Wedge)
		addPart(model, body, "KatanaGuard", Vector3.new(0.06 * s, 0.25 * s, 0.25 * s), GOLD_COLOR, CFrame.new(0.12 * s, -0.22 * s, 0.15 * s) * bladeRot, Enum.Material.Metal)
		addPart(model, body, "KatanaHandle", Vector3.new(0.3 * s, 0.1 * s, 0.1 * s), Color3.fromRGB(40, 40, 40), CFrame.new(0.02 * s, -0.32 * s, 0.15 * s) * bladeRot, nil, Cylinder)

	elseif id == "frigo-camelo" then
		-- KULKAS-UNTA: the fridge IS the (box) Body; wedge trim breaks
		-- the silhouette, camel neck + head rise at +Z, big hump on top.
		addPart(model, body, "Door", Vector3.new(0.5 * s, 0.4 * s, 0.03 * s), Color3.fromRGB(170, 200, 220), CFrame.new(0, 0.15 * s, 0.32 * s))
		addPart(model, body, "DoorHandle", Vector3.new(0.05 * s, 0.3 * s, 0.05 * s), Color3.fromRGB(120, 130, 140), CFrame.new(0.2 * s, 0.15 * s, 0.35 * s))
		addPart(model, body, "TrimL", Vector3.new(0.14 * s, 0.2 * s, 0.14 * s), Color3.fromRGB(180, 200, 215), CFrame.new(-0.28 * s, 0.42 * s, 0.28 * s), nil, Wedge)
		addPart(model, body, "TrimR", Vector3.new(0.14 * s, 0.2 * s, 0.14 * s), Color3.fromRGB(180, 200, 215), CFrame.new(0.28 * s, 0.42 * s, 0.28 * s), nil, Wedge)
		addCylBetween(model, body, "CamelNeck", Vector3.new(0, 0.42 * s, 0.1 * s), Vector3.new(0, 0.68 * s, 0.5 * s), 0.28 * s, Color3.fromRGB(210, 180, 130))
		addPart(model, body, "CamelHead", Vector3.new(0.35 * s, 0.35 * s, 0.35 * s), Color3.fromRGB(210, 180, 130), CFrame.new(0, 0.7 * s, 0.55 * s), nil, Ball)
		addPart(model, body, "CamelSnout", Vector3.new(0.16 * s, 0.16 * s, 0.32 * s), Color3.fromRGB(190, 160, 110), CFrame.new(0, 0.64 * s, 0.78 * s), nil, Wedge)
		addPart(model, body, "CamelEyeL", Vector3.new(0.07 * s, 0.07 * s, 0.07 * s), DARK, CFrame.new(-0.11 * s, 0.76 * s, 0.68 * s), nil, Ball)
		addPart(model, body, "CamelEyeR", Vector3.new(0.07 * s, 0.07 * s, 0.07 * s), DARK, CFrame.new(0.11 * s, 0.76 * s, 0.68 * s), nil, Ball)
		addPart(model, body, "CamelEarL", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), Color3.fromRGB(210, 180, 130), CFrame.new(-0.18 * s, 0.82 * s, 0.5 * s), nil, Ball)
		addPart(model, body, "CamelEarR", Vector3.new(0.12 * s, 0.12 * s, 0.12 * s), Color3.fromRGB(210, 180, 130), CFrame.new(0.18 * s, 0.82 * s, 0.5 * s), nil, Ball)
		addPart(model, body, "Hump", Vector3.new(0.7 * s, 0.5 * s, 0.7 * s), Color3.fromRGB(210, 180, 130), CFrame.new(0, 0.6 * s, -0.15 * s), nil, Ball)
		addPart(model, body, "FootL", Vector3.new(0.14 * s, 0.06 * s, 0.14 * s), Color3.fromRGB(60, 60, 60), CFrame.new(-0.2 * s, -0.47 * s, 0.22 * s))
		addPart(model, body, "FootR", Vector3.new(0.14 * s, 0.06 * s, 0.14 * s), Color3.fromRGB(60, 60, 60), CFrame.new(0.2 * s, -0.47 * s, 0.22 * s))

	elseif id == "vaca-saturno" then
		-- SAPI + CINCIN SATURNUS BESAR (flat gold ring, tilted ~20 deg).
		addPart(model, body, "CowBody", Vector3.new(0.85 * s, 0.8 * s, 1.2 * s), Color3.fromRGB(235, 235, 240), CFrame.new(0, 0.05 * s, 0), nil, Ball)
		addPart(model, body, "PatchL", Vector3.new(0.4 * s, 0.3 * s, 0.55 * s), Color3.fromRGB(30, 30, 30), CFrame.new(0.38 * s, 0.15 * s, -0.15 * s), nil, Ball)
		addPart(model, body, "PatchR", Vector3.new(0.4 * s, 0.3 * s, 0.55 * s), Color3.fromRGB(30, 30, 30), CFrame.new(-0.35 * s, 0.0 * s, 0.3 * s), nil, Ball)
		addPart(model, body, "PatchTop", Vector3.new(0.35 * s, 0.25 * s, 0.4 * s), Color3.fromRGB(30, 30, 30), CFrame.new(-0.1 * s, 0.3 * s, -0.35 * s), nil, Ball)
		addPart(model, body, "SaturnRing", Vector3.new(0.12 * s, 2.0 * s, 2.0 * s), Color3.fromRGB(255, 210, 90), CFrame.new(0, 0.05 * s, 0) * (CFrame.Angles(math.rad(20), 0, 0) * CFrame.Angles(0, 0, math.rad(90))), Enum.Material.Metal, Cylinder)
		addPart(model, body, "CowHead", Vector3.new(0.55 * s, 0.55 * s, 0.55 * s), Color3.fromRGB(235, 235, 240), CFrame.new(0, 0.3 * s, 0.65 * s), nil, Ball)
		addPart(model, body, "Muzzle", Vector3.new(0.35 * s, 0.25 * s, 0.25 * s), Color3.fromRGB(245, 200, 200), CFrame.new(0, 0.18 * s, 0.9 * s), nil, Ball)
		addPart(model, body, "HornL", Vector3.new(0.1 * s, 0.25 * s, 0.1 * s), Color3.fromRGB(240, 230, 200), CFrame.new(-0.25 * s, 0.6 * s, 0.6 * s), nil, Wedge)
		addPart(model, body, "HornR", Vector3.new(0.1 * s, 0.25 * s, 0.1 * s), Color3.fromRGB(240, 230, 200), CFrame.new(0.25 * s, 0.6 * s, 0.6 * s), nil, Wedge)
		addPart(model, body, "EarL", Vector3.new(0.28 * s, 0.18 * s, 0.12 * s), Color3.fromRGB(235, 235, 240), CFrame.new(-0.35 * s, 0.35 * s, 0.6 * s), nil, Ball)
		addPart(model, body, "EarR", Vector3.new(0.28 * s, 0.18 * s, 0.12 * s), Color3.fromRGB(235, 235, 240), CFrame.new(0.35 * s, 0.35 * s, 0.6 * s), nil, Ball)
		addEyes(model, body, 0.42 * s, 0.85 * s, 0.16 * s, 0.09 * s)
		addPart(model, body, "LegFL", Vector3.new(0.25 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(235, 235, 240), CFrame.new(-0.25 * s, -0.38 * s, 0.35 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "LegFR", Vector3.new(0.25 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(235, 235, 240), CFrame.new(0.25 * s, -0.38 * s, 0.35 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "LegBL", Vector3.new(0.25 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(235, 235, 240), CFrame.new(-0.25 * s, -0.38 * s, -0.35 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "LegBR", Vector3.new(0.25 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(235, 235, 240), CFrame.new(0.25 * s, -0.38 * s, -0.35 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "Udder", Vector3.new(0.3 * s, 0.2 * s, 0.3 * s), Color3.fromRGB(245, 200, 200), CFrame.new(0, -0.35 * s, -0.2 * s), nil, Ball)
		addPart(model, body, "Tail", Vector3.new(0.5 * s, 0.08 * s, 0.08 * s), Color3.fromRGB(30, 30, 30), CFrame.new(0, -0.2 * s, -0.65 * s) * CFrame.Angles(0, 0, math.rad(90)), nil, Cylinder)
		addPart(model, body, "TailTuft", Vector3.new(0.14 * s, 0.14 * s, 0.14 * s), Color3.fromRGB(30, 30, 30), CFrame.new(0, -0.45 * s, -0.65 * s), nil, Ball)

	else
		-- Unknown id: plain cube + eyes.
		addPart(model, body, "FallbackCube", Vector3.new(0.7 * s, 0.7 * s, 0.7 * s), row.color or Color3.fromRGB(150, 150, 150), CFrame.new(0, 0, 0))
		addEyes(model, body, 0.1 * s, 0.36 * s, 0.15 * s, 0.08 * s)
	end
end

-- Billboard (Fix #6): smaller (160x80) so labels stop stacking when
-- characters crowd the belt; staggered vertically by the id's byte sum
-- so neighbours sit at different heights. 4 labels, fractions of the
-- billboard height: name 0-0.34, rarity 0.34-0.58, rate 0.58-0.79,
-- price 0.79-1.0.
local function addBillboard(model, body, row, size)
	local gui = Instance.new("BillboardGui")
	gui.Name = "InfoBillboard"
	gui.Size = UDim2.new(0, 160, 0, 80)
	gui.MaxDistance = 35
	gui.AlwaysOnTop = false
	local sum = 0
	local id = row.id or ""
	for i = 1, #id do
		sum += string.byte(id, i)
	end
	local stagger = 0
	if sum % 2 == 0 then
		stagger = size * 0.28
	end
	gui.StudsOffsetWorldSpace = Vector3.new(0, size * 1.15 + stagger, 0)
	gui.Parent = body

	local function addLabel(name, text, textSize, textColor, posY, height)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(1, 0, height, 0)
		label.Position = UDim2.new(0, 0, posY, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = textColor
		label.TextStrokeTransparency = 0
		label.TextScaled = false
		label.TextSize = textSize
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Font = Enum.Font.GothamBold
		label.Parent = gui
		return label
	end

	addLabel("Name", row.name or row.id or "Brainrot", 13, WHITE, 0, 0.34)
	addLabel("Rarity", row.rarity or "Common", 11, BrainrotData.getRarityColor(row.rarity), 0.34, 0.24)
	addLabel("Rate", "$" .. tostring(row.rate or 0) .. "/s", 11, Color3.fromRGB(120, 255, 140), 0.58, 0.21)
	addLabel("Price", "$" .. tostring(row.price or 0), 12, Color3.fromRGB(255, 217, 51), 0.79, 0.21)
end

local function applyMutation(model, body, mutation)
	if mutation == "Emas" then
		body.Color = GOLD_COLOR
		body.Material = Enum.Material.Metal
	elseif mutation == "Pelangi" then
		task.spawn(function()
			local hue = 0
			while model.Parent ~= nil do
				for _, part in ipairs(model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromHSV(hue, 0.8, 1)
					end
				end
				hue += 0.05
				task.wait(0.2)
			end
		end)
	end
end

function BrainrotFactory.rollMutation()
	local roll = math.random()
	if roll < Config.MUTATION_RAINBOW_CHANCE then
		return "Pelangi"
	elseif roll < Config.MUTATION_RAINBOW_CHANCE + Config.MUTATION_GOLD_CHANCE then
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

function BrainrotFactory.buildBrainrotModel(row, mutation)
	row = row or BrainrotData.CAST[1]
	local size = row.size or 4
	mutation = mutation or BrainrotFactory.rollMutation()

	local model = Instance.new("Model")
	model.Name = row.name or row.id or "Brainrot"

	-- PrimaryPart: axis-aligned, CFrame (0, size/2, 0), no rotation.
	-- Ball core in the row colour; the fridge is the one box Body.
	local bodySize = Vector3.new(size * 0.8, size * 0.8, size * 0.8)
	local bodyShape = Ball
	local bodyColor = row.color or Color3.fromRGB(150, 150, 150)
	if row.id == "frigo-camelo" then
		bodySize = Vector3.new(size * 0.62, size * 0.95, size * 0.62)
		bodyShape = Enum.PartType.Block
		bodyColor = Color3.fromRGB(200, 220, 235)
	end
	local body = makePart("Body", bodySize, bodyColor, nil, bodyShape)
	body.CFrame = CFrame.new(0, size / 2, 0)
	body.Parent = model
	model.PrimaryPart = body

	model:SetAttribute("CharId", row.id)
	model:SetAttribute("Rarity", row.rarity)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rate", row.rate)
	model:SetAttribute("Price", row.price)
	model:SetAttribute("BodySize", size)

	local ok = pcall(buildShape, model, body, row, size)
	if not ok then
		-- Fallback: simple cube + eyes; the model must never throw.
		addPart(model, body, "FallbackCube", Vector3.new(size * 0.7, size * 0.7, size * 0.7), bodyColor, CFrame.new(0, 0, 0))
		addEyes(model, body, size * 0.1, size * 0.36, size * 0.15, size * 0.08)
	end

	applyMutation(model, body, mutation)
	addBillboard(model, body, row, size)
	return model
end

return BrainrotFactory
