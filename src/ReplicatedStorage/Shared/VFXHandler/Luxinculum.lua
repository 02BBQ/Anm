--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");

local Shared = ReplicatedStorage.Shared;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local Assets = Shared.Assets.Resources;

local VFX = {};

VFX.start = function(Data)
    local target = Data.Target;
    local targetRig = target.Character.Rig;
    local targetRoot = target.Character.Root;

    local root = Data.Origin;
    local beam: BasePart = Assets.Luxinculum.Light:Clone();
    beam.Weld.Part0 = Data.Caster.Character.Root;
    beam.Parent = workspace.World.Debris;
    -- beam.End.CFrame = CFrame.new(0,0,-3);
    local elapsed = 0;
    local dur = 0.3;

    local tasks = {};

    tasks.Chain = task.spawn(function()
        while true do
            local dt = RunService.PreRender:Wait();
            if not beam:IsDescendantOf(workspace) then 
                tasks.Chain:Disconnect();
                return;
            end
    
            elapsed = elapsed + dt / dur; -- math.clamp(elapsed + dt / dur, 0, 1);
            
            local look = (targetRoot.Position - root.Position).Unit;
            local dist = (targetRoot.Position - root.Position).Magnitude;
            
            local endCF = root.Position:Lerp(targetRoot.Position, math.clamp(elapsed, 0, 1));
            endCF = CFrame.new(endCF, endCF + look);
    
            for _,Beam: Beam in pairs(beam:GetChildren()) do
                if Beam:IsA("Beam") then
                    Beam.CurveSize0 = -dist * math.sin(math.pi*((1 - elapsed*1)^ 2)*2)/4;
                    Beam.CurveSize1 = dist * math.sin(math.pi*((1 - elapsed*1)^ 2)*2)/3;
                end
            end
    
            beam.End.WorldCFrame = endCF;
            beam.Start.WorldCFrame = CFrame.new(root.Position, root.Position + look);
        end
    end)

    task.delay(dur, function()
        for _,Beam: Beam in pairs(beam:GetChildren()) do
            if Beam:IsA("Beam") then
                TweenService:Create(Beam, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                    Width0 = 0; 
                    Width1 = 0;
                }):Play();
            end
        end
        task.delay(dur, function()
            task.cancel(tasks.Chain);
            tasks.Chain = nil;        
        end);
    end)
end

return VFX;