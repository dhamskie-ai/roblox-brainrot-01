-- TsunamiEvent.luau — every WAVE_INTERVAL_S a tsunami sweeps the plaza:
-- a 10 s warning (banner + siren on every client), then a tall wave wall
-- sweeps west to east over ~6 s. A player caught outside their own base
-- while carrying drops the brainrot back onto the belt. On base = safe.
-- triggerWave() is the TOUR.json hook for screenshot 4.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
if not Shared then
	error("[PasarBrainrot] ReplicatedStorage.Shared tidak ditemukan (10 dtk)")
end
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local CarryAndPlace = require(script.Parent.CarryAndPlace)

local TsunamiEvent = {}

-- Set by init.server.luau: the Remotes folder (WaveWarning, ToastMessage, SoundEvent).
TsunamiEvent.Remotes = nil

local waveActive = false
local nextWaveAt = 0
local waveWall = nil

local function getWaveWall()
	if waveWall and waveWall.Parent then
		return waveWall
	end
	waveWall = workspace:FindFirstChild("WaveWall")
	return waveWall
end

local function isOnOwnBase(player)
	local state = PlayerState.get(player)
	if not state then
		return true
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return true
	end
	local base = Config.BASES[state.baseIndex]
	local pos = root.Position
	return math.abs(pos.X - base.pos.X) <= 13 and math.abs(pos.Z - base.pos.Z) <= 13
end

local function broadcastWaveWarning(seconds)
	if TsunamiEvent.Remotes then
		local remote = TsunamiEvent.Remotes:FindFirstChild("WaveWarning")
		if remote then
			remote:FireAllClients(seconds)
		end
	end
end

local function sweepPlazaWave()
	local wall = getWaveWall()
	if wall then
		wall.Transparency = 0.35
		wall.Position = Vector3.new(-Config.PLAZA_HALF - 5, 12, 0)
	end
	local steps = math.floor(Config.WAVE_SWEEP_S / 0.1)
	for step = 1, steps do
		local x = -Config.PLAZA_HALF - 5 + (2 * Config.PLAZA_HALF + 10) * (step / steps)
		if wall then
			wall.Position = Vector3.new(x, 12, 0)
		end
		-- Anyone carrying outside their base drops the brainrot.
		for _, player in ipairs(PlayerState.getAllPlayers()) do
			local state = PlayerState.get(player)
			if state and state.carried and not isOnOwnBase(player) then
				CarryAndPlace.dropCarried(player)
				if TsunamiEvent.Remotes then
					local toastRemote = TsunamiEvent.Remotes:FindFirstChild("ToastMessage")
					if toastRemote then
						toastRemote:FireClient(player, "Tsunami menyapu brainrot-mu!")
					end
					local soundRemote = TsunamiEvent.Remotes:FindFirstChild("SoundEvent")
					if soundRemote then
						soundRemote:FireClient(player, "wave")
					end
				end
			end
		end
		task.wait(0.1)
	end
	if wall then
		wall.Transparency = 1
		wall.Position = Vector3.new(-Config.PLAZA_HALF - 80, 12, 0)
	end
end

-- One full wave: warn, then sweep. warnSeconds is 10 in the normal cycle,
-- 3 when triggered by hand (TOUR.json).
local function runWave(warnSeconds)
	if waveActive then
		return
	end
	waveActive = true
	broadcastWaveWarning(warnSeconds)
	task.wait(warnSeconds)
	sweepPlazaWave()
	nextWaveAt = os.clock() + Config.WAVE_INTERVAL_S
	waveActive = false
end

-- TOUR.json hook: fires a wave now (short 3 s warning so reviewers see it).
function TsunamiEvent.triggerWave()
	task.spawn(function()
		runWave(3)
	end)
end

function TsunamiEvent.getSecondsUntilWave()
	if nextWaveAt == 0 then
		return Config.WAVE_INTERVAL_S
	end
	return math.max(0, nextWaveAt - os.clock())
end

function TsunamiEvent.start()
	nextWaveAt = os.clock() + Config.WAVE_INTERVAL_S
	task.spawn(function()
		while true do
			local waitFor = nextWaveAt - os.clock()
			if waitFor > 0 then
				task.wait(waitFor)
			end
			if not waveActive then
				-- FIX #2: satu wave yang throw tidak boleh membunuh loop 90 dtk.
				local ok, err = pcall(runWave, Config.WAVE_WARN_S)
				if not ok then
					warn("[PasarBrainrot] wave gagal: " .. tostring(err))
					waveActive = false
					nextWaveAt = os.clock() + Config.WAVE_INTERVAL_S
				end
			end
		end
	end)
end

return TsunamiEvent
