-- PlayerState.luau — the one place that holds every player's state:
-- cash, lifetime earned, rebirths, multiplier, carried brainrot, owned
-- pedestals, base assignment and base lock. Every other server module
-- reads and writes player state through here, never its own copy.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
if not Shared then
	error("[PasarBrainrot] ReplicatedStorage.Shared tidak ditemukan (10 dtk)")
end
local Config = require(Shared.Config)

local PlayerState = {}

local players = {} -- [Player] = state table

function PlayerState.initPlayer(player, baseIndex)
	local state = {
		cash = Config.START_CASH,
		lifetimeEarned = 0,
		rebirths = 0,
		multiplier = 1,
		baseIndex = baseIndex,
		carried = nil, -- Model the player carries above their head, or nil
		owned = {}, -- [pedestalSlot] = { model, row, mutation, rate, price }
		lockedUntil = 0, -- os.clock() timestamp, 0 = not locked
		lockCooldownUntil = 0,
	}
	players[player] = state

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = state.cash
	cashValue.Parent = leaderstats

	local incomeValue = Instance.new("IntValue")
	incomeValue.Name = "Income"
	incomeValue.Value = 0
	incomeValue.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats

	state.leaderstats = leaderstats
	return state
end

function PlayerState.removePlayer(player)
	local state = players[player]
	if state then
		if state.carried and state.carried.Parent then
			state.carried:Destroy()
		end
		players[player] = nil
	end
end

function PlayerState.get(player)
	return players[player]
end

function PlayerState.getAllPlayers()
	local list = {}
	for player, _ in pairs(players) do
		table.insert(list, player)
	end
	return list
end

function PlayerState.getCash(player)
	local state = players[player]
	return state and state.cash or 0
end

-- Adds cash; positive amounts also count toward lifetime earned (rebirth progress).
function PlayerState.addCash(player, amount)
	local state = players[player]
	if not state then
		return
	end
	state.cash += amount
	if amount > 0 then
		state.lifetimeEarned += amount
	end
	local cashValue = state.leaderstats:FindFirstChild("Cash")
	if cashValue then
		cashValue.Value = state.cash
	end
end

function PlayerState.spendCash(player, amount)
	local state = players[player]
	if not state or state.cash < amount then
		return false
	end
	state.cash -= amount
	local cashValue = state.leaderstats:FindFirstChild("Cash")
	if cashValue then
		cashValue.Value = state.cash
	end
	return true
end

function PlayerState.getIncomeRate(player)
	local state = players[player]
	if not state then
		return 0
	end
	local total = 0
	for _, record in pairs(state.owned) do
		total += record.rate
	end
	return math.floor(total * state.multiplier + 0.5)
end

function PlayerState.getMultiplier(player)
	local state = players[player]
	return state and state.multiplier or 1
end

function PlayerState.getLifetimeEarned(player)
	local state = players[player]
	return state and state.lifetimeEarned or 0
end

function PlayerState.getRebirths(player)
	local state = players[player]
	return state and state.rebirths or 0
end

function PlayerState.getBaseIndex(player)
	local state = players[player]
	return state and state.baseIndex or 1
end

function PlayerState.getCarried(player)
	local state = players[player]
	return state and state.carried or nil
end

function PlayerState.setCarried(player, model)
	local state = players[player]
	if state then
		state.carried = model
	end
end

function PlayerState.setOwned(player, slot, record)
	local state = players[player]
	if state then
		state.owned[slot] = record
	end
end

function PlayerState.clearOwnedSlot(player, slot)
	local state = players[player]
	if state then
		state.owned[slot] = nil
	end
end

function PlayerState.clearOwned(player)
	local state = players[player]
	if state then
		state.owned = {}
	end
end

function PlayerState.getOwned(player)
	local state = players[player]
	return state and state.owned or {}
end

function PlayerState.getOwnedCount(player)
	local state = players[player]
	if not state then
		return 0
	end
	local count = 0
	for _, _ in pairs(state.owned) do
		count += 1
	end
	return count
end

-- Every occupied pedestal in the game, for the thief bots.
function PlayerState.getAllOwnedPedestals()
	local list = {}
	for player, state in pairs(players) do
		for slot, record in pairs(state.owned) do
			table.insert(list, { owner = player, baseIndex = state.baseIndex, slot = slot, record = record })
		end
	end
	return list
end

function PlayerState.isBaseLocked(player)
	local state = players[player]
	return state and os.clock() < state.lockedUntil or false
end

function PlayerState.getLockRemaining(player)
	local state = players[player]
	if not state then
		return 0, 0
	end
	local now = os.clock()
	return math.max(0, state.lockedUntil - now), math.max(0, state.lockCooldownUntil - now)
end

-- Locks the player's base for LOCK_DURATION_S. Returns true, or false + reason.
function PlayerState.lockBase(player)
	local state = players[player]
	if not state then
		return false, "no-state"
	end
	local now = os.clock()
	if now < state.lockedUntil then
		return false, "already-locked"
	end
	if now < state.lockCooldownUntil then
		return false, "cooldown"
	end
	state.lockedUntil = now + Config.LOCK_DURATION_S
	state.lockCooldownUntil = state.lockedUntil + Config.LOCK_COOLDOWN_S
	return true
end

-- Rebirth reset: cash back to start, brainrots cleared by the caller,
-- rebirths +1, multiplier x1.25. Returns the new multiplier.
function PlayerState.applyRebirth(player)
	local state = players[player]
	if not state then
		return 1
	end
	state.cash = Config.START_CASH
	state.lifetimeEarned = 0
	state.rebirths += 1
	state.multiplier *= Config.REBIRTH_MULTIPLIER
	state.carried = nil
	local cashValue = state.leaderstats:FindFirstChild("Cash")
	if cashValue then
		cashValue.Value = state.cash
	end
	local rebirthValue = state.leaderstats:FindFirstChild("Rebirths")
	if rebirthValue then
		rebirthValue.Value = state.rebirths
	end
	return state.multiplier
end

function PlayerState.setIncomeLeaderstat(player, income)
	local state = players[player]
	if not state then
		return
	end
	local incomeValue = state.leaderstats:FindFirstChild("Income")
	if incomeValue then
		incomeValue.Value = income
	end
end

return PlayerState
