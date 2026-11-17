-- MoneyTick.luau — every 1 second each player's brainrots pay out:
-- cash += sum of owned rates x rebirth multiplier. Updates the Cash and
-- Income leaderstats and pushes the live HUD numbers to that player only.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local ConveyorSpawner = require(script.Parent.ConveyorSpawner)
local TsunamiEvent = require(script.Parent.TsunamiEvent)
local RebirthSystem = require(script.Parent.RebirthSystem)

local MoneyTick = {}

-- Set by init.server.luau: the Remotes folder (MoneyUpdate).
MoneyTick.Remotes = nil

function MoneyTick.start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(PlayerState.getAllPlayers()) do
				local income = PlayerState.getIncomeRate(player)
				if income > 0 then
					PlayerState.addCash(player, income)
				end
				PlayerState.setIncomeLeaderstat(player, income)
				if MoneyTick.Remotes then
					local remote = MoneyTick.Remotes:FindFirstChild("MoneyUpdate")
					if remote then
						local lockRemaining, lockCooldown = PlayerState.getLockRemaining(player)
						remote:FireClient(player, {
							cash = PlayerState.getCash(player),
							income = income,
							nextSpawn = math.ceil(ConveyorSpawner.getNextSpawnIn()),
							waveIn = math.ceil(TsunamiEvent.getSecondsUntilWave()),
							rebirthReady = RebirthSystem.canRebirth(player),
							rebirths = PlayerState.getRebirths(player),
							multiplier = PlayerState.getMultiplier(player),
							lockRemaining = math.ceil(lockRemaining),
							lockCooldown = math.ceil(lockCooldown),
							ownedCount = PlayerState.getOwnedCount(player),
						})
					end
				end
			end
		end
	end)
end

return MoneyTick
