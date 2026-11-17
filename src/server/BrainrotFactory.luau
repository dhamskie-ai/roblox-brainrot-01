-- BrainrotFactory.luau — builds one brainrot character Model from a
-- BrainrotData row: blocky body, head, eyes, one accessory, and a billboard
-- showing its name, rarity and $/s. Size scales with rarity tier.
-- Mutation (Emas / Pelangi) changes the look and multiplies rate and price.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
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

local function weldTo(body, part, offsetCFrame)
	part.CFrame = body.CFrame * offsetCFrame
	part.Parent = body.Parent
	local weld = Instance.new("Weld")
	weld.Part0 = body
	weld.Part1 = part
	weld.C0 = offsetCFrame
	weld.Parent = body
end

-- One accessory per kind: a straw, sneakers, sunglasses, wings, a cape,
-- an afro, glowsticks, a crown, a money bag or a mic.
local function buildAccessory(body, kind, size, bodyColor)
	local s = size -- body edge length, used to scale the accessory
	if kind == "straw" then
		local straw = makePart("Straw", Vector3.new(0.25, s * 0.9, 0.25), Color3.fromRGB(255, 80, 120))
		weldTo(body, straw, CFrame.new(s * 0.25, s * 0.85, 0) * CFrame.Angles(0, 0, math.rad(20)))
	elseif kind == "sneakers" then
		for _, side in ipairs({ -1, 1 }) do
			local shoe = makePart("Sneaker", Vector3.new(s * 0.35, s * 0.22, s * 0.55), Color3.fromRGB(240, 240, 240))
			weldTo(body, shoe, CFrame.new(side * s * 0.28, -s * 0.6, s * 0.1))
		end
	elseif kind == "sunglasses" then
		local glasses = makePart("Sunglasses", Vector3.new(s * 0.7, s * 0.2, s * 0.15), Color3.fromRGB(20, 20, 20), Enum.Material.Neon)
		weldTo(body, glasses, CFrame.new(0, s * 0.55, s * 0.32))
	elseif kind == "wings" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = makePart("Wing", Vector3.new(s * 0.7, s * 0.12, s * 0.5), Color3.fromRGB(255, 255, 255))
			weldTo(body, wing, CFrame.new(side * s * 0.7, s * 0.15, -s * 0.1) * CFrame.Angles(0, 0, side * math.rad(25)))
		end
	elseif kind == "cape" then
		local cape = makePart("Cape", Vector3.new(s * 0.9, s * 0.9, s * 0.12), Color3.fromRGB(160, 30, 30))
		weldTo(body, cape, CFrame.new(0, -s * 0.1, -s * 0.55))
	elseif kind == "afro" then
		local afro = makePart("Afro", Vector3.new(s * 0.9, s * 0.5, s * 0.9), Color3.fromRGB(40, 20, 10))
		afro.Shape = Enum.PartType.Ball
		weldTo(body, afro, CFrame.new(0, s * 0.85, 0))
		local ball = makePart("DiscoBall", Vector3.new(s * 0.35, s * 0.35, s * 0.35), Color3.fromRGB(200, 220, 255), Enum.Material.Metal)
		ball.Shape = Enum.PartType.Ball
		weldTo(body, ball, CFrame.new(s * 0.55, s * 0.7, s * 0.2))
	elseif kind == "glowsticks" then
		for _, side in ipairs({ -1, 1 }) do
			local stick = makePart("Glowstick", Vector3.new(s * 0.12, s * 0.6, s * 0.12), Color3.fromRGB(80, 255, 160), Enum.Material.Neon)
			weldTo(body, stick, CFrame.new(side * s * 0.6, s * 0.2, s * 0.15) * CFrame.Angles(0, 0, side * math.rad(30)))
		end
	elseif kind == "crown" then
		local crown = makePart("Crown", Vector3.new(s * 0.55, s * 0.3, s * 0.55), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)
		weldTo(body, crown, CFrame.new(0, s * 0.95, 0))
	elseif kind == "moneybag" then
		local bag = makePart("MoneyBag", Vector3.new(s * 0.5, s * 0.55, s * 0.4), Color3.fromRGB(120, 200, 90))
		bag.Shape = Enum.PartType.Ball
		weldTo(body, bag, CFrame.new(s * 0.55, -s * 0.2, s * 0.25))
	elseif kind == "mic" then
		local mic = makePart("Mic", Vector3.new(s * 0.18, s * 0.6, s * 0.18), Color3.fromRGB(60, 60, 60))
		weldTo(body, mic, CFrame.new(s * 0.6, s * 0.1, s * 0.2))
		local micHead = makePart("MicHead", Vector3.new(s * 0.3, s * 0.3, s * 0.3), Color3.fromRGB(255, 120, 200))
		micHead.Shape = Enum.PartType.Ball
		weldTo(body, micHead, CFrame.new(s * 0.6, s * 0.45, s * 0.2))
	end
end

-- Builds the Model. The caller sets its position with PivotTo and parents it.
-- Returns the model; its attributes carry CharId, Rarity, Mutation, Rate, Price.
function BrainrotFactory.buildBrainrotModel(row, mutation)
	local mult = BrainrotFactory.getMutationMultiplier(mutation)
	local size = row.size
	local displayName = row.name
	if mutation ~= "Normal" then
		displayName = mutation .. " " .. row.name
	end

	local model = Instance.new("Model")
	model.Name = displayName

	local bodyColor = row.color
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
	weldTo(body, head, CFrame.new(0, size * 0.72, 0))
	head.Parent = model

	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(size * 0.14, size * 0.18, size * 0.08), Color3.fromRGB(20, 20, 20))
		weldTo(body, eye, CFrame.new(side * size * 0.16, size * 0.78, size * 0.32))
		eye.Parent = model
	end

	buildAccessory(body, row.accessory, size, bodyColor)

	-- Billboard: name, rarity colour, $/s — readable from across the plaza.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(140, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, size * 0.95, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.fromScale(0, 0.4)
	rarityLabel.Size = UDim2.fromScale(1, 0.3)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = row.rarity
	rarityLabel.TextColor3 = BrainrotData.getRarityColor(row.rarity)
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.fromScale(0, 0.7)
	rateLabel.Size = UDim2.fromScale(1, 0.3)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "$" .. tostring(row.rate * mult) .. "/dtk"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = billboard

	model:SetAttribute("CharId", row.id)
	model:SetAttribute("Rarity", row.rarity)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rate", row.rate * mult)
	model:SetAttribute("Price", row.price * mult)
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
