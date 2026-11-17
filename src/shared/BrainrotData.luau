-- BrainrotData.luau — the cast of Pasar Brainrot: 12 original characters,
-- 5 rarities, all Indonesian-flavoured absurdity. No character, name or asset
-- is copied from Steal a Brainrot or any other game.
-- Server reads this for spawn rolls and prices; client reads it for HUD colours.

local BrainrotData = {}

BrainrotData.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 70, 120),
}

BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

-- id, name, rarity, roll weight, $/s, buy price, body colour, size, accessory kind
BrainrotData.CAST = {
	{ id = "es-teh", name = "Es Teh Manis", rarity = "Common", weight = 22, rate = 4, price = 150, color = Color3.fromRGB(190, 120, 50), size = 3.9, accessory = "straw" },
	{ id = "ayam-geprek", name = "Ayam Geprek", rarity = "Common", weight = 20, rate = 5, price = 200, color = Color3.fromRGB(230, 150, 60), size = 3.9, accessory = "sneakers" },
	{ id = "kucing-oren", name = "Kucing Oren", rarity = "Common", weight = 18, rate = 6, price = 250, color = Color3.fromRGB(240, 140, 40), size = 3.9, accessory = "sunglasses" },
	{ id = "becak-terbang", name = "Becak Terbang", rarity = "Rare", weight = 13, rate = 15, price = 900, color = Color3.fromRGB(80, 200, 200), size = 4.7, accessory = "wings" },
	{ id = "nasi-padang", name = "Nasi Padang Terbang", rarity = "Rare", weight = 12, rate = 18, price = 1200, color = Color3.fromRGB(240, 220, 120), size = 4.7, accessory = "cape" },
	{ id = "komodo-disco", name = "Komodo Disco", rarity = "Epic", weight = 6, rate = 45, price = 3000, color = Color3.fromRGB(90, 160, 90), size = 5.5, accessory = "afro" },
	{ id = "ondel-rave", name = "Ondel-Ondel Rave", rarity = "Epic", weight = 4, rate = 55, price = 4000, color = Color3.fromRGB(255, 120, 180), size = 5.5, accessory = "glowsticks" },
	{ id = "garuda-emas", name = "Garuda Emas", rarity = "Legendary", weight = 2.5, rate = 150, price = 10000, color = Color3.fromRGB(255, 200, 60), size = 6.2, accessory = "crown" },
	{ id = "naga-batik", name = "Naga Batik", rarity = "Legendary", weight = 1.5, rate = 180, price = 12000, color = Color3.fromRGB(120, 60, 160), size = 6.2, accessory = "wings" },
	{ id = "babi-ngepet", name = "Babi Ngepet Bank", rarity = "Mythic", weight = 0.5, rate = 450, price = 30000, color = Color3.fromRGB(230, 180, 200), size = 7.0, accessory = "moneybag" },
	{ id = "raja-sate", name = "Raja Sate", rarity = "Mythic", weight = 0.3, rate = 500, price = 35000, color = Color3.fromRGB(200, 90, 40), size = 7.0, accessory = "crown" },
	{ id = "kuntilanak-kpop", name = "Nyonya Kuntilanak K-Pop", rarity = "Mythic", weight = 0.2, rate = 600, price = 40000, color = Color3.fromRGB(240, 240, 250), size = 7.0, accessory = "mic" },
}

-- Roll one character from the weights above.
function BrainrotData.rollCharacter()
	local total = 0
	for _, row in ipairs(BrainrotData.CAST) do
		total += row.weight
	end
	local roll = math.random() * total
	for _, row in ipairs(BrainrotData.CAST) do
		roll -= row.weight
		if roll <= 0 then
			return row
		end
	end
	return BrainrotData.CAST[1]
end

function BrainrotData.getRarityColor(rarity)
	return BrainrotData.RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
end

return BrainrotData
