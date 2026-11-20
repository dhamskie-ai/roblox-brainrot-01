-- SPDX-License-Identifier: MIT
-- Config.luau — every tuning number of Pasar Brainrot in one place.
-- Server and client both read this; nothing else hardcodes a number.

local Config = {}

-- Conveyor belt (west -> east, middle of the plaza)
Config.SPAWN_INTERVAL_S = 3 -- FIX #4: was 6 — busier belt
Config.BELT_SPEED = 4 -- studs per second
Config.BELT_START_X = -38
Config.BELT_END_X = 38
Config.BELT_Y = 2 -- top surface of the belt (FIX #2: belt raised 1 -> 2.5 studs tall)
Config.BELT_Z = 0
Config.BELT_MAX_MODELS = 7 -- FIX #4: max brainrots walking the belt at once
Config.INITIAL_SPAWN_OFFSETS = { 0, 10, 20, 30, 40, 50 } -- FIX #4: 6 on the belt at server start (was 3)

-- Money
Config.START_CASH = 250
Config.SELL_REFUND = 0.5 -- selling a brainrot returns half its buy price
Config.BASE_SLOTS = 8

-- Mutations (rolled when a brainrot spawns)
Config.MUTATION_GOLD_CHANCE = 0.04 -- Emas: 2x rate and price
Config.MUTATION_RAINBOW_CHANCE = 0.01 -- Pelangi: 3x rate and price

-- Tsunami wave
Config.WAVE_INTERVAL_S = 90
Config.WAVE_WARN_S = 10
Config.WAVE_SWEEP_S = 6

-- Stealing and base lock
Config.LOCK_DURATION_S = 30
Config.LOCK_COOLDOWN_S = 60
Config.STEAL_HOLD_S = 2

-- Rebirth
Config.REBIRTH_THRESHOLD = 100000 -- lifetime earned needed
Config.REBIRTH_MULTIPLIER = 1.25
Config.REBIRTH_MAX = 5

-- Thief bots
Config.THIEF_BOTS = 2
Config.BOT_STEAL_HOLD_S = 2
Config.BOT_DESPAWN_S = 10

-- Plaza and bases: 4 corner bases, colour coded, 24x24 platforms
Config.PLAZA_HALF = 60
Config.BASE_SIZE = 24
Config.BASES = {
	{ name = "Merah", color = Color3.fromRGB(220, 60, 60), pos = Vector3.new(-42, 0, -42) },
	{ name = "Biru", color = Color3.fromRGB(60, 120, 220), pos = Vector3.new(42, 0, -42) },
	{ name = "Hijau", color = Color3.fromRGB(60, 200, 90), pos = Vector3.new(-42, 0, 42) },
	{ name = "Kuning", color = Color3.fromRGB(240, 200, 40), pos = Vector3.new(42, 0, 42) },
}

-- Thief bots run to these edge markers with a stolen brainrot
Config.BOT_CORNERS = {
	Vector3.new(0, 0, 56),
	Vector3.new(0, 0, -56),
}

return Config
