local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage.Shared;
local Assets = Shared.Assets;

local itemInfo = 
{
    -- Weapons
    ["TesterSword"] = {
        Description = "A sword that dreams of being a legendary weapon.",
        Type = "Weapon",
        Rarity = "Legendary",
    },
    -- Scrolls
    ["Scroll Of SuperDreamySmite"] = {
        Description = "Learn SuperDreamySmite",
        Type = "Trinket",
        Rarity = "Common",
    },
};

return itemInfo;