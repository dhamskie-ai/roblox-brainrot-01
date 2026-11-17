-- RebirthSystem.luau — when a player's lifetime earned reaches
-- REBIRTH_THRESHOLD, the HUD shows a REBIRTH button. Rebirth resets cash
-- and brainrots and grants a permanent +25% money multiplier (stacks up to
-- 5 rebirths) plus a golden aura on the player.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local CarryAndPlace = require(script.Parent.CarryAndPlace)

local RebirthSystem = {}

-- Set by init.server.luau: the Remotes folder (ToastMessage, SoundEvent).
RebirthSystem.Remotes = nil

function RebirthSystem.canRebirth(player)
	local state = PlayerState.get(player)
	if not state then
		return false
	end
	return state.lifetimeEarned >= Config.REBIRTH_THRESHOLD and state.rebirths < Config.REBIRTH_MAX
end

function RebirthSystem.doRebirth(player)
	if not RebirthSystem.canRebirth(player) then
		return false
	end
	CarryAndPlace.dropCarried(player)
	CarryAndPlace.clearPlayerPedestals(player)
	local multiplier = PlayerState.applyRebirth(player)

	-- Golden aura: a warm light and sparkles on the character.
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local light = Instance.new("PointLight")
			light.Name = "RebirthAura"
			light.Color = Color3.fromRGB(255, 215, 0)
			light.Brightness = 2
			light.Range = 12
			light.Parent = root
			local sparkles = Instance.new("Sparkles")
			sparkles.Name = "RebirthSparkles"
			sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
			sparkles.Parent = root
		end
	end

	if RebirthSystem.Remotes then
		local toastRemote = RebirthSystem.Remotes:FindFirstChild("ToastMessage")
		if toastRemote then
			toastRemote:FireClient(player, "REBIRTH! Penghasilan x" .. string.format("%.2f", multiplier))
		end
		local soundRemote = RebirthSystem.Remotes:FindFirstChild("SoundEvent")
		if soundRemote then
			soundRemote:FireClient(player, "rebirth")
		end
	end
	return true
end

return RebirthSystem
