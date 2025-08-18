local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage.Shared;
local Assets = Shared.Assets;

local itemInfo = 
{
    -- Weapons
    ["SuperDreamySword"] = {
        Description = "A sword that dreams of being a legendary weapon.",
        Type = "Weapon",
        Rarity = "Legendary",
    },
    -- Scrolls
    ["Scroll Of SuperDreamySmite"] = {
        Description = "Learn Smite",
        Type = "Trinket",
        Rarity = "Common",
    },
};

return itemInfo;