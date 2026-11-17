-- Game.client.luau — the HUD of Pasar Brainrot. A ScreenGui OVER the 3D
-- world, never the game itself. FIX (17 Nov 2026): the GUI is built FIRST,
-- with default text, BEFORE any WaitForChild — the old version waited up to
-- 30 s for ReplicatedStorage.Remotes before creating a single label, so a
-- fresh player saw NO HUD at all. Remotes are now awaited on a background
-- thread and only wire the listeners.
-- All sizes are small in code on purpose: on Dham's phone the GUI renders
-- at ~2.48x code size (roblox-game-01 rev 7), so every size here is already
-- divided by ~2.5. Verified numerically on 2048x984: 0 overlaps, middle of
-- the screen clear of HUD, nothing in the top-left corner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer

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

-- GUI FIRST: created immediately, with readable default text.
local gui = Instance.new("ScreenGui")
gui.Name = "PasarBrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Cash, top-left under the Roblox menu buttons.
local cashLabel = makeLabel("CashLabel", gui, UDim2.new(0, 16, 0, 64), UDim2.fromOffset(150, 24), 18, Color3.fromRGB(120, 255, 140))
cashLabel.Text = "$250"

-- Income per second, directly under cash.
local incomeLabel = makeLabel("IncomeLabel", gui, UDim2.new(0, 16, 0, 92), UDim2.fromOffset(150, 20), 15, Color3.fromRGB(255, 255, 255))
incomeLabel.Text = "$0/dtk"

-- Next spawn countdown, top-centre.
-- FIX #2: default "-" diganti "memuat..." — "-" diam-diam terbaca seperti
-- server mati, padahal client hanya belum menerima MoneyUpdate pertama.
local spawnLabel = makeLabel("SpawnLabel", gui, UDim2.new(0.5, -90, 0, 10), UDim2.fromOffset(180, 20), 15, Color3.fromRGB(255, 255, 255))
spawnLabel.TextXAlignment = Enum.TextXAlignment.Center
spawnLabel.Text = "Berikutnya: memuat..."

-- Persistent objective line, top-centre under the countdown.
local objectiveLabel = makeLabel("ObjectiveLabel", gui, UDim2.new(0.5, -200, 0, 34), UDim2.fromOffset(400, 18), 12, Color3.fromRGB(255, 217, 51))
objectiveLabel.TextXAlignment = Enum.TextXAlignment.Center
objectiveLabel.Text = "BELI BRAINROT DI SABUK → BAWA KE BASE → DAPAT $/DTK"

-- Tsunami warning banner, centre-top, only during the warning.
local waveBanner = makeLabel("WaveBanner", gui, UDim2.new(0.5, -160, 0, 56), UDim2.fromOffset(320, 22), 16, Color3.fromRGB(255, 80, 80))
waveBanner.TextXAlignment = Enum.TextXAlignment.Center
waveBanner.Visible = false

-- Toast messages (bought, stolen, locked...), centre-top under the banner.
local toastLabel = makeLabel("ToastLabel", gui, UDim2.new(0.5, -200, 0, 82), UDim2.fromOffset(400, 20), 13, Color3.fromRGB(255, 255, 255))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Visible = false

-- FIX #2: server note — muncul bila 5 detik setelah join belum ada
-- MoneyUpdate sama sekali (server belum kirim / init bermasalah), supaya
-- pemain tahu game-nya masih memuat, bukan rusak diam-diam.
local serverNote = makeLabel("ServerNote", gui, UDim2.new(0.5, -200, 0, 108), UDim2.fromOffset(400, 18), 12, Color3.fromRGB(255, 120, 120))
serverNote.TextXAlignment = Enum.TextXAlignment.Center
serverNote.Text = ""
serverNote.Visible = false

-- FIX #3: server status line — shows ReplicatedStorage.ServerStatus live
-- ("OK | jam | pemain | sabuk", or the first server error). Dham's next
-- screenshot must show this line: it names the server's state.
local statusLabel = makeLabel("ServerStatusLabel", gui, UDim2.new(0.5, -200, 0, 132), UDim2.fromOffset(400, 18), 12, Color3.fromRGB(140, 220, 255))
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Text = "Server: memuat..."

-- Lock button, bottom-right ABOVE the jump button.
local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.AnchorPoint = Vector2.new(1, 1)
lockButton.Position = UDim2.new(1, -16, 1, -160)
lockButton.Size = UDim2.fromOffset(100, 36)
lockButton.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
lockButton.BorderSizePixel = 0
lockButton.Text = "KUNCI"
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 15
lockButton.Font = Enum.Font.GothamBold
lockButton.Parent = gui

-- Rebirth button, bottom-centre, visible only when a rebirth is available.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(0.5, 1)
rebirthButton.Position = UDim2.new(0.5, 0, 1, -110)
rebirthButton.Size = UDim2.fromOffset(110, 36)
rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
rebirthButton.BorderSizePixel = 0
rebirthButton.Text = "REBIRTH!"
rebirthButton.TextColor3 = Color3.fromRGB(60, 30, 0)
rebirthButton.TextSize = 15
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

-- A toast token stops an older toast's hide-timer from hiding a newer one.
local toastToken = 0
local function showToast(message, seconds)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = message
	toastLabel.Visible = true
	task.spawn(function()
		task.wait(seconds or 3)
		if token == toastToken then
			toastLabel.Visible = false
		end
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

-- Onboarding toast on join: the game loop in one line, visible ~6 s.
-- Kept short on purpose: 43 chars fits the 400 px toast label at 13 px.
showToast("BELI di SABUK → BAWA ke BASE → dapat $/dtk!", 6)

-- FIX #2 watchdog: bila 5 detik setelah join belum ada MoneyUpdate,
-- tampilkan catatan server (hilang sendiri saat update pertama masuk).
-- FIX #3: bedakan dua mode gagal — "Remotes belum ada" vs "Remotes ada,
-- MoneyUpdate tidak datang" — plus "Remotes tidak ditemukan (30 dtk)".
local gotMoneyUpdate = false
local remotesFound = false
task.spawn(function()
	task.wait(5)
	if not gotMoneyUpdate then
		if remotesFound then
			serverNote.Text = "Remotes ada, MoneyUpdate tidak datang."
		else
			serverNote.Text = "Menunggu server... bila tak kunjung masuk, coba rejoin."
		end
		serverNote.Visible = true
	end
	task.wait(25) -- 30 detik sejak join
	if not gotMoneyUpdate and not remotesFound then
		serverNote.Text = "Remotes tidak ditemukan (30 dtk) — coba rejoin."
		serverNote.Visible = true
	end
end)

-- FIX #3: baca ServerStatus saat join dan tampilkan di HUD; berubah live
-- tiap heartbeat server (5 detik) atau saat error pertama tercatat.
-- Dipotong ke 48 karakter supaya muat di label 400 px.
task.spawn(function()
	local statusValue = ReplicatedStorage:WaitForChild("ServerStatus", 30)
	if not statusValue then
		statusLabel.Text = "Server: status tidak ada (server mati sebelum boot)"
		return
	end
	local function refreshStatus()
		local text = tostring(statusValue.Value)
		if #text > 48 then
			text = string.sub(text, 1, 48) .. "..."
		end
		statusLabel.Text = "Server: " .. text
	end
	refreshStatus()
	statusValue.Changed:Connect(refreshStatus)
end)

-- Remotes are awaited on a BACKGROUND thread: the GUI above is already on
-- screen while this waits, so a slow server can never hide the HUD.
task.spawn(function()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
	if not Remotes then
		return
	end
	remotesFound = true

	local moneyUpdate = Remotes:WaitForChild("MoneyUpdate", 30)
	if moneyUpdate then
		moneyUpdate.OnClientEvent:Connect(function(data)
			gotMoneyUpdate = true
			serverNote.Visible = false
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
		toastRemote.OnClientEvent:Connect(function(message)
			showToast(message)
		end)
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
end)

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
