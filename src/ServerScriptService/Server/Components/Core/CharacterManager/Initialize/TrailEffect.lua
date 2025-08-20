local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Setup = {};

Setup.Name = "TrailEffect";
Setup.Priority = 1; -- 낮을수록 먼저 실행

Setup.Initialize = function(Entity)
    local character = Entity.Character;
    local rig = character.Rig;
    
    if not rig then return end

    local trails = rig:FindFirstChild("Trails") or Instance.new("Folder", rig);
    trails.Name = "Trails";
    
    for _, limb in pairs(rig:GetChildren()) do
        if not limb:IsA("BasePart") then continue end;
        if not string.find(limb.Name, "Arm") and not string.find(limb.Name, "Leg") then
            continue; -- 팔이나 다리가 아닌 경우는 무시
        end

        local trail = ReplicatedStorage.Shared.Assets.Resources.LimbTrail:Clone();
        
        trail.Motor6D.Part0 = limb;
        trail.Parent = trails;
    end
end

return Setup;