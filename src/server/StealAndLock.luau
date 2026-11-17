-- StealAndLock.luau — stealing a brainrot off another player's pedestal
-- (hold E 2 s on the pedestal; thief bots use the same function) and the
-- base lock: 30 s locked, 60 s cooldown after it ends. All checks are
-- server-side; a locked base refuses the steal with a "TERKUNCI!" toast.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local CarryAndPlace = require(script.Parent.CarryAndPlace)

local StealAndLock = {}

-- Set by init.server.luau: the Remotes folder (ToastMessage, SoundEvent).
StealAndLock.Remotes = nil

local function toast(player, message)
	if StealAndLock.Remotes then
		local remote = StealAndLock.Remotes:FindFirstChild("ToastMessage")
		if remote then
			remote:FireClient(player, message)
		end
	end
end

local function playSound(player, kind)
	if StealAndLock.Remotes then
		local remote = StealAndLock.Remotes:FindFirstChild("SoundEvent")
		if remote then
			remote:FireClient(player, kind)
		end
	end
end

-- Finds which player owns a base (bases are assigned round-robin on join).
function StealAndLock.getBaseOwner(baseIndex)
	for _, player in ipairs(PlayerState.getAllPlayers()) do
		if PlayerState.getBaseIndex(player) == baseIndex then
			return player
		end
	end
	return nil
end

function StealAndLock.isBaseLocked(baseIndex)
	local owner = StealAndLock.getBaseOwner(baseIndex)
	if not owner then
		return false
	end
	return PlayerState.isBaseLocked(owner)
end

-- Steals the brainrot on a pedestal. stealer is a Player, or nil for a bot
-- (bots call tryStealBrainrotForBot instead). Returns the model, or nil.
function StealAndLock.tryStealBrainrot(stealer, baseIndex, slot)
	local owner = StealAndLock.getBaseOwner(baseIndex)
	if not owner then
		return nil
	end
	if stealer == owner then
		if stealer then
			toast(stealer, "Itu pedestalmu sendiri!")
		end
		return nil
	end
	if PlayerState.isBaseLocked(owner) then
		if stealer then
			toast(stealer, "TERKUNCI! Base ini sedang dikunci.")
			playSound(stealer, "steal")
		end
		return nil
	end
	local pedestal = CarryAndPlace.getPedestal(baseIndex, slot)
	if not pedestal or not pedestal.record then
		return nil
	end
	local model = CarryAndPlace.takeOwnedBrainrot(baseIndex, slot)
	PlayerState.clearOwnedSlot(owner, slot)
	if stealer then
		local state = PlayerState.get(stealer)
		if state and state.carried then
			-- Already carrying: drop it first, then carry the stolen one.
			CarryAndPlace.dropCarried(stealer)
		end
		local character = stealer.Character
		local head = character and character:FindFirstChild("Head")
		if head then
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end
			local body = model.PrimaryPart
			body.CFrame = head.CFrame * CFrame.new(0, 3.2, 0)
			local weld = Instance.new("Weld")
			weld.Name = "CarryWeld"
			weld.Part0 = head
			weld.Part1 = body
			weld.C0 = CFrame.new(0, 3.2, 0)
			weld.Parent = head
			PlayerState.setCarried(stealer, model)
		end
		toast(owner, "Brainrot-mu dicuri " .. stealer.Name .. "!")
		toast(stealer, "Berhasil mencuri " .. model.Name .. "!")
		playSound(stealer, "steal")
	end
	return model
end

-- A thief bot steals: same checks, but the bot carries the model away
-- instead of a player. Returns the model, or nil.
function StealAndLock.tryStealBrainrotForBot(baseIndex, slot)
	local owner = StealAndLock.getBaseOwner(baseIndex)
	if not owner then
		return nil
	end
	if PlayerState.isBaseLocked(owner) then
		return nil
	end
	local pedestal = CarryAndPlace.getPedestal(baseIndex, slot)
	if not pedestal or not pedestal.record then
		return nil
	end
	local model = CarryAndPlace.takeOwnedBrainrot(baseIndex, slot)
	PlayerState.clearOwnedSlot(owner, slot)
	toast(owner, "MALING! Bot mencuri brainrot dari basemu!")
	return model
end

-- Locks the calling player's own base. Called from the HUD button and the
-- lock post prompt. Returns true on success.
function StealAndLock.lockBaseForPlayer(player)
	local ok, reason = PlayerState.lockBase(player)
	if ok then
		toast(player, "Base dikunci 30 detik!")
		playSound(player, "buy")
	elseif reason == "cooldown" then
		local _, cooldown = PlayerState.getLockRemaining(player)
		toast(player, "Kunci cooldown: " .. tostring(math.ceil(cooldown)) .. " dtk lagi")
	elseif reason == "already-locked" then
		toast(player, "Basemu sudah terkunci!")
	end
	return ok
end

return StealAndLock
