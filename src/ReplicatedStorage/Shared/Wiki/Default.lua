local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage.Shared;
local Assets = Shared.Assets;

local Default = 
{
    ["Combat"] = {
        DashDuration = 0.5;

        BaseSpeed = 26,
        BaseJumpHeight = 25,

        -- WallCling settings
        WallClingDetectionRange = 3,        
        WallClingDuration = 3,              
        WallClingDecrease = 10,             
        WallClingBackBoost = 25,            
        WallClingUpBoost = 50,              
        WallClingCooldown = 0.5,            
        WallClingJumpCooldown = 0.075,      
    };
};

return Default;