local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService("ServerStorage");

local Storage = ServerStorage.Storage;
local Accs = Storage.Assets.Accessories;

local Setup = {};

Setup.Priority = 1;

Setup.Initialize = function(Entity)
    local character = Entity.Character;
    local rig = character.Rig;
    
    if not rig then return end

    local ac = Accs:Clone();
    character.AccessoriesFolder = ac;
    for _,v in pairs(ac:GetChildren()) do
        local limb = rig:FindFirstChild(v.Name);
        if limb then
            local weld = Instance.new("Weld");
            weld.Part0 = v;
            weld.Part1 = limb;
            weld.Parent = v;
        else
            v:Destroy();
        end
    end
    ac.Parent = rig;
end

return Setup;