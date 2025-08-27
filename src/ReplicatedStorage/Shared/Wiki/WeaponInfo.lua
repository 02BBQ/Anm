local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage.Shared;
local Assets = Shared.Assets;

local itemInfo = 
{
    ["Fist"] = {
        Animation = "Weapons/Fist";
        SwingSounds = {
            "fistswing";
        };

        Damage = 8;
        SwingSpeed = 1.1;

        LightAttack = nil;
        Critical = "Fist";

        Size = Vector3.new(7,7,7);
        Offset = CFrame.new(0, 0, -3.5);

        Endlag = 0;
    };
    ["TesterSword"] = {
        Animation = "Weapons/Sword";
        SwingSounds = {
            "fistswing";
        };

        Damage = 125;
        SwingSpeed = 3;

        LightAttack = nil;
        Critical = "Fist";

        Size = Vector3.new(7,7,8);
        Offset = CFrame.new(0, 0, -4);

        Endlag = 0;
    }
};

return itemInfo;