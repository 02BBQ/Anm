--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local Shared = ReplicatedStorage.Shared;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local Assets = Shared.Assets.Resources.Crimson;

local VFX = {};

VFX.start = function(Data)
    local Root = Data.Origin
    local Projectile = Assets.Projectile:Clone();

    local BodyVelocity = Auxiliary.Shared.CreateVelocity(Root, {MaxForce = Vector3.new(1e6, 1e6, 1e6)});
    BodyVelocity.Velocity = Root.CFrame.LookVector*100;

    Projectile:PivotTo(Root.CFrame * CFrame.new(0, 0, -2));
    Projectile.Parent = workspace.World.Debris;

    local tasks = {};

    for _, Beam: Beam in Projectile:GetDescendants() do
        if Beam:IsA("Beam") then
            TweenService:Create(Beam, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                TextureSpeed = -0.1
            }):Play();
            if not Beam:IsDescendantOf(Projectile.Beams.BeamsCheck) then continue end;
            local _ = Beam.Attachment0;
            local att = Beam.Attachment1;
            TweenService:Create(att, TweenInfo.new(0.85, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
                CFrame = att.CFrame * CFrame.new(0, 0, -45)
            }):Play();
            TweenService:Create(Beam, TweenInfo.new(0.85, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
                Width0 = 0;
                Width1 = 0;
            }):Play();
        end;
    end;

    tasks.Tween = task.spawn(function()
        for _, Beam in Projectile.Circles:GetDescendants() do
            if Beam:IsA("Beam") then
                local l_Attachment0_5 = Beam.Attachment0;
                local l_Attachment1_5 = Beam.Attachment1;
                TweenService:Create(l_Attachment1_5, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    CFrame = l_Attachment1_5.CFrame * CFrame.new(0, 0, -15)
                }):Play();
                TweenService:Create(l_Attachment0_5, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    CFrame = l_Attachment0_5.CFrame * CFrame.new(0, 0, -15)
                }):Play();
                task.spawn(function() --[[ Line: 463 ]]
                    -- upvalues: v77 (ref), v93 (copy)
                    TweenService:Create(Beam, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        Width0 = 0;
                        Width1 = 0; 
                    }):Play();
                end);
                task.wait(0.075);
            end;
        end;
    end)

    task.delay(0.625, function() --[[ Line: 532 ]]
        -- upvalues: v97 (ref), l_TweenService_0 (ref), v82 (ref)
        for _, instance: Beam | Decal | BasePart in pairs(Projectile:GetDescendants()) do
            if instance:IsA("Decal") or instance:IsA("BasePart") then
                TweenService:Create(instance, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
                    Transparency = 1
                }):Play();
            elseif instance:IsA("Beam") then
                TweenService:Create(instance, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Width0 = 0, 
                    Width1 = 0
                }):Play();
            elseif instance:IsA("ParticleEmitter") then
                instance.Enabled = false;
            elseif instance:IsA("Trail") then
                instance.Enabled = false;
            end;
        end;
        game.Debris:AddItem(Projectile, 1);
        BodyVelocity:Destroy();
        task.delay(0.3, function()
            task.cancel(tasks.Spin);
            task.cancel(tasks.Tween);
            tasks.Spin = nil;
            tasks.Tween = nil;        
        end);
    end);

    local minSpeed = 2
    local Speed = 4;

    tasks.Spin = task.spawn(function()
        while true do
            local dt = RunService.RenderStepped:Wait();
            Speed = math.max(Speed- dt*1.5, minSpeed);
            Projectile.Beams.Beams.CFrame *= CFrame.Angles(0, 0, math.pi*dt*-Speed);
            Projectile.Trails.Trails.CFrame *= CFrame.Angles(0, 0, math.pi*dt*Speed);

            -- Projectile:PivotTo(Projectile:GetPivot() * CFrame.new(0, 0, -150*dt));
            Projectile:PivotTo(Root.CFrame);
            BodyVelocity.Velocity = Root.CFrame.LookVector*150;
        end
    end)
end

return VFX;