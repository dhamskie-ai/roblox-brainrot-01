-- Game.client.luau — the HUD of Pasar Brainrot. A ScreenGui OVER the 3D
-- world, never the game itself. All sizes are small in code on purpose:
-- on Dham's phone the GUI renders at ~2.48x code size (roblox-game-01 rev 7),
-- so every size here is already divided by ~2.5. Verified numerically on
-- 2048x984: 0 overlaps, middle of the screen clear of HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

local function makeLabel(name, parent, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 0.45
	label.BorderSizePixel = 0
	label.Text = ""
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "PasarBrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Cash, top-left under the Roblox menu buttons.
local cashLabel = makeLabel("CashLabel", gui, UDim2.new(0, 16, 0, 64), UDim2.fromOffset(120, 16), 14, Color3.fromRGB(120, 255, 140))
cashLabel.Text = "$250"

-- Income per second, directly under cash.
local incomeLabel = makeLabel("IncomeLabel", gui, UDim2.new(0, 16, 0, 82), UDim2.fromOffset(120, 14), 12, Color3.fromRGB(255, 255, 255))
incomeLabel.Text = "$0/dtk"

-- Next spawn countdown, top-centre.
local spawnLabel = makeLabel("SpawnLabel", gui, UDim2.new(0.5, -65, 0, 10), UDim2.fromOffset(130, 14), 12, Color3.fromRGB(255, 255, 255))
spawnLabel.TextXAlignment = Enum.TextXAlignment.Center
spawnLabel.Text = "Berikutnya: - dtk"

-- Tsunami warning banner, centre-top, only during the warning.
local waveBanner = makeLabel("WaveBanner", gui, UDim2.new(0.5, -115, 0, 28), UDim2.fromOffset(230, 16), 13, Color3.fromRGB(255, 80, 80))
waveBanner.TextXAlignment = Enum.TextXAlignment.Center
waveBanner.Visible = false

-- Toast messages (bought, stolen, locked...), centre-top under the banner.
local toastLabel = makeLabel("ToastLabel", gui, UDim2.new(0.5, -110, 0, 48), UDim2.fromOffset(220, 14), 12, Color3.fromRGB(255, 255, 255))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Visible = false

-- Lock button, bottom-right ABOVE the jump button.
local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.AnchorPoint = Vector2.new(1, 1)
lockButton.Position = UDim2.new(1, -16, 1, -150)
lockButton.Size = UDim2.fromOffset(72, 28)
lockButton.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
lockButton.BorderSizePixel = 0
lockButton.Text = "KUNCI"
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 12
lockButton.Font = Enum.Font.GothamBold
lockButton.Parent = gui

-- Rebirth button, bottom-centre, visible only when a rebirth is available.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(0.5, 1)
rebirthButton.Position = UDim2.new(0.5, 0, 1, -100)
rebirthButton.Size = UDim2.fromOffset(90, 28)
rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
rebirthButton.BorderSizePixel = 0
rebirthButton.Text = "REBIRTH!"
rebirthButton.TextColor3 = Color3.fromRGB(60, 30, 0)
rebirthButton.TextSize = 12
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.Visible = false
rebirthButton.Parent = gui

local function formatMoney(amount)
	local text = tostring(math.floor(amount))
	local out = ""
	while #text > 3 do
		out = "." .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

local function showToast(message)
	toastLabel.Text = message
	toastLabel.Visible = true
	task.spawn(function()
		task.wait(3)
		toastLabel.Visible = false
	end)
end

local function showWaveWarning(seconds)
	waveBanner.Visible = true
	task.spawn(function()
		local left = seconds
		while left > 0 and waveBanner.Visible do
			waveBanner.Text = "TSUNAMI " .. tostring(left) .. " DETIK — LARI KE BASE!"
			task.wait(1)
			left -= 1
		end
		waveBanner.Visible = false
	end)
end

if Remotes then
	local moneyUpdate = Remotes:WaitForChild("MoneyUpdate", 30)
	if moneyUpdate then
		moneyUpdate.OnClientEvent:Connect(function(data)
			cashLabel.Text = formatMoney(data.cash)
			local multText = ""
			if data.multiplier and data.multiplier > 1 then
				multText = " x" .. string.format("%.2f", data.multiplier)
			end
			incomeLabel.Text = formatMoney(data.income) .. "/dtk" .. multText
			spawnLabel.Text = "Berikutnya: " .. tostring(data.nextSpawn) .. " dtk"
			rebirthButton.Visible = data.rebirthReady == true
			if data.lockRemaining and data.lockRemaining > 0 then
				lockButton.Text = "KUNCI (" .. tostring(data.lockRemaining) .. ")"
				lockButton.BackgroundColor3 = Color3.fromRGB(30, 160, 60)
			elseif data.lockCooldown and data.lockCooldown > 0 then
				lockButton.Text = "Cooldown " .. tostring(data.lockCooldown)
				lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
			else
				lockButton.Text = "KUNCI"
				lockButton.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
			end
		end)
	end

	local waveWarning = Remotes:WaitForChild("WaveWarning", 30)
	if waveWarning then
		waveWarning.OnClientEvent:Connect(showWaveWarning)
	end

	local toastRemote = Remotes:WaitForChild("ToastMessage", 30)
	if toastRemote then
		toastRemote.OnClientEvent:Connect(showToast)
	end

	local soundEvent = Remotes:WaitForChild("SoundEvent", 30)
	if soundEvent then
		soundEvent.OnClientEvent:Connect(function(kind)
			local sound = nil
			if kind == "buy" or kind == "rebirth" then
				sound = SoundService:FindFirstChild("BuySound")
			elseif kind == "wave" or kind == "steal" then
				sound = SoundService:FindFirstChild("RoarSound")
			end
			if sound then
				pcall(function()
					sound:Play()
				end)
			end
		end)
	end

	local requestLock = Remotes:WaitForChild("RequestLock", 30)
	if requestLock then
		lockButton.MouseButton1Click:Connect(function()
			requestLock:FireServer()
		end)
	end

	local requestRebirth = Remotes:WaitForChild("RequestRebirth", 30)
	if requestRebirth then
		rebirthButton.MouseButton1Click:Connect(function()
			requestRebirth:FireServer()
		end)
	end
end

-- Preload the sounds off the main thread; every Play() is already in pcall.
task.spawn(function()
	local ambient = SoundService:WaitForChild("AmbientSound", 10)
	local buy = SoundService:WaitForChild("BuySound", 10)
	local roar = SoundService:WaitForChild("RoarSound", 10)
	local list = {}
	for _, sound in ipairs({ ambient, buy, roar }) do
		if sound then
			table.insert(list, sound)
		end
	end
	if #list > 0 then
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
	end
	if ambient then
		pcall(function()
			ambient:Play()
		end)
	end
end)
