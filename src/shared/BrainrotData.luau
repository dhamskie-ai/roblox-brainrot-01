-- SPDX-License-Identifier: MIT
-- BrainrotData.luau
-- Data 13 karakter brainrot (total weight 100.2).
-- Bentuk dikenali: setiap baris punya field `shape` yang
-- dipakai BrainrotFactory.buildShape untuk membangun model
-- dari part biasa (Part/Wedge/Ball/Cylinder) dengan siluet
-- + warna + ciri khas sendiri, bukan manusia balok generik.
-- Nilai ekonomi (weight/rate/price/size) PERSIS v16.
-- Total weight 100.2 (tetap); field `shape` dipakai factory,
-- field `accessory` dipertahankan apa adanya (kompatibilitas).
-- Rarity: Common < Uncommon < Rare < Epic < Mythic.
-- rollCharacter(): total weight, roll acak, fallback CAST[1].
-- getRarityColor(): fallback putih bila rarity tak dikenal.

local BrainrotData = {}

BrainrotData.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(80, 200, 90),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Mythic = Color3.fromRGB(255, 70, 120),
}

BrainrotData.RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Mythic" }

BrainrotData.CAST = {
	{ id = "tung-tung-sahur", name = "Tung Tung Sahur", rarity = "Common", weight = 22, rate = 4, price = 150, color = Color3.fromRGB(150, 100, 50), size = 3.9, accessory = "club", shape = "log" },
	{ id = "tralalero", name = "Tralalero Tralala", rarity = "Common", weight = 20, rate = 5, price = 200, color = Color3.fromRGB(60, 140, 220), size = 3.9, accessory = "sneakers", shape = "shark" },
	{ id = "brr-patapim", name = "Brr Brr Patapim", rarity = "Common", weight = 18, rate = 6, price = 250, color = Color3.fromRGB(170, 120, 70), size = 3.9, accessory = "tree", shape = "monkey-tree" },
	{ id = "lirili-larila", name = "Lirili Larila", rarity = "Uncommon", weight = 13, rate = 15, price = 900, color = Color3.fromRGB(80, 180, 90), size = 4.7, accessory = "cactus", shape = "cactus-elephant" },
	{ id = "chimpanzini", name = "Chimpanzini Bananini", rarity = "Uncommon", weight = 12, rate = 18, price = 1200, color = Color3.fromRGB(240, 210, 60), size = 4.7, accessory = "banana", shape = "chimp-banana" },
	{ id = "boneca", name = "Boneca Ambalabu", rarity = "Uncommon", weight = 6, rate = 45, price = 3000, color = Color3.fromRGB(90, 200, 110), size = 5.5, accessory = "frog", shape = "frog-tire" },
	{ id = "bombardiro", name = "Bombardiro Crocodilo", rarity = "Rare", weight = 4, rate = 55, price = 4000, color = Color3.fromRGB(70, 150, 80), size = 5.5, accessory = "wings", shape = "croc-plane" },
	{ id = "garuda-emas", name = "Garuda Emas", rarity = "Mythic", weight = 2.5, rate = 150, price = 10000, color = Color3.fromRGB(255, 200, 60), size = 6.2, accessory = "crown", shape = "golden-bird" },
	{ id = "ballerina", name = "Ballerina Cappuccina", rarity = "Rare", weight = 1.5, rate = 180, price = 12000, color = Color3.fromRGB(220, 180, 140), size = 6.2, accessory = "tutu", shape = "ballerina-cup" },
	{ id = "trippi-troppi", name = "Trippi Troppi", rarity = "Rare", weight = 0.5, rate = 450, price = 30000, color = Color3.fromRGB(240, 130, 60), size = 7.0, accessory = "fish", shape = "fish-bear" },
	{ id = "cappuccino-assassino", name = "Cappuccino Assassino", rarity = "Epic", weight = 0.3, rate = 500, price = 35000, color = Color3.fromRGB(90, 60, 40), size = 7.0, accessory = "katana", shape = "ninja-cup" },
	{ id = "frigo-camelo", name = "Frigo Camelo", rarity = "Epic", weight = 0.2, rate = 600, price = 40000, color = Color3.fromRGB(200, 220, 235), size = 7.0, accessory = "camel", shape = "fridge-camel" },
	{ id = "vaca-saturno", name = "La Vaca Saturno Saturnita", rarity = "Mythic", weight = 0.2, rate = 600, price = 40000, color = Color3.fromRGB(235, 235, 240), size = 7.0, accessory = "rings", shape = "cow-saturn" },
}

function BrainrotData.getRarityColor(rarity)
	return BrainrotData.RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
end

function BrainrotData.rollCharacter()
	local total = 0
	for _, row in ipairs(BrainrotData.CAST) do
		total = total + row.weight
	end
	local roll = math.random() * total
	local acc = 0
	for _, row in ipairs(BrainrotData.CAST) do
		acc = acc + row.weight
		if roll <= acc then
			return row
		end
	end
	return BrainrotData.CAST[1]
end

return BrainrotData
