# Pasar Brainrot — Curi, Kumpul, Kaya — make.fun `roblox-brainrot-01`

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/dhamskie-ai/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/dhamskie-ai/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Entered in the [make.fun bounty](https://make.fun/bounty/roblox-brainrot-01) "Make the best AI Roblox brainrot game" ($1,000 over the top 50).

A bright night-market plaza in Roblox's 3D world. Brainrot characters parade along a central conveyor belt
("Sabuk Brainrot"). Walk up, buy one, carry it over your head to your own base, and place it on a pedestal —
it earns money every second. Richer brainrots cost more and pay more. Two threats force a dash home: a
tsunami wave that sweeps the plaza every 90 seconds, and thief bots that try to steal brainrots off pedestals.
Lock your base, or chase the thief down and tag it to get your brainrot back. Earn $100,000 in a lifetime to
rebirth for a permanent +25% money multiplier.

## The cast — 12 original characters, 5 rarities

Common: Es Teh Manis, Ayam Geprek, Kucing Oren. Rare: Becak Terbang, Nasi Padang Terbang. Epic: Komodo Disco,
Ondel-Ondel Rave. Legendary: Garuda Emas, Naga Batik. Mythic: Babi Ngepet Bank, Raja Sate, Nyonya Kuntilanak
K-Pop. Every spawn has a 5% chance of a mutation: Emas (gold, 2x $/s) or Pelangi (rainbow, 3x $/s).

## Play

Play it on Roblox: https://www.roblox.com/games/93903442181463 (place 93903442181463, universe 9874149559).

- **Beli:** walk up to a brainrot on the belt, hold **E** (or tap on mobile). Starting cash $250.
- **Bawa & letakkan:** carry it above your head to your base, hold **E** on an empty pedestal.
- **Jual:** hold **E** on your own occupied pedestal — 50% of the buy price back.
- **Curi:** hold **E** for 2 s on another player's pedestal — unless their base is locked.
- **Kunci base:** the KUNCI button (bottom-right) or the lock post on your base — safe for 30 s, 60 s cooldown.
- **Tsunami:** every 90 s a 10 s warning, then a wave wall sweeps the plaza. Carrying outside your base when
  it hits drops the brainrot back onto the belt.
- **Rebirth:** at $100,000 lifetime earned the REBIRTH button appears — reset cash and brainrots for +25% income.

## Build & publish

```bash
./bin/rojo build default.project.json --output game.rbxl   # Rojo 7.7.1 (in roblox-game-01's bin/)
python3 <roblox.py> publish 9874149559 93903442181463 game.rbxl  # Open Cloud, key "Bubu Publish"
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts       # writes out/dossier.json
```

`main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/`
and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes `/output/dossier.json`
with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.

## Layout

- `default.project.json` — Rojo project: plaza 120x120, conveyor, 4 corner bases, stalls, lanterns, fountain,
  bright dusk lighting (ClockTime 17.5, Ambient 0.62, Brightness 3).
- `src/shared/Config.luau` — every tuning number in one place.
- `src/shared/BrainrotData.luau` — the 12-character cast table + rarity weights and colours.
- `src/server/` — `init.server.luau` (bootstrap), `BrainrotFactory`, `ConveyorSpawner`, `CarryAndPlace`,
  `MoneyTick`, `StealAndLock`, `TsunamiEvent`, `ThiefBot`, `RebirthSystem`, `PlayerState` (all player state).
- `src/client/Game.client.luau` — HUD (cash, income, next spawn, wave banner, lock/rebirth buttons, toasts).
- `screenshots/` — 4 gameplay captures from the phone (1-thumbnail, 2-conveyor, 3-base, 4-wave); the first by
  name is the game's thumbnail on Roblox.
- `PLAY.json` — the published place link. `TOUR.json` — one step per screenshot (shot 4 calls `triggerWave`).

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.
