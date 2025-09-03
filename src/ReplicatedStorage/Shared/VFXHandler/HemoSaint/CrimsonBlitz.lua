--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");

local Shared = ReplicatedStorage.Shared;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local Assets = Shared.Assets.Resources.Crimson;

local VFX = {};

-- Creates shockwave visual effects for a ball based on its velocity
-- function ballShockwave(target, attachmentPart, customShockwave)
--     local lastUpdateTime = time() + 0.1
--     local currentShockwave = nil
    
--     -- Main render loop connection
--     local renderConnection = RunService.PreRender:Connect(function()
--         -- Check if ball still exists in the game
--         if not target:IsDescendantOf(game) then
--             return
--         end
        
--         -- Get ball velocity if it exists
--         if not target:FindFirstChild("velocity") then 
--             return 
--         end
        
--         local velocity = target.velocity.Value
--         local speed = velocity.Magnitude
        
--         -- Handle persistent shockwave for high speeds (>130)
--         if speed > 130 then
--             if not currentShockwave then
--                 -- Create shockwave effect
--                 if customShockwave then
--                     currentShockwave = customShockwave:Clone()
--                 else
--                     currentShockwave = ReplicatedStorage.Resources.shockwave:Clone()
--                 end
                
--                 -- Attach shockwave to the specified part
--                 currentShockwave.Weld.Part0 = attachmentPart
--                 currentShockwave.Parent = attachmentPart
--             end
--         else
--             -- Remove shockwave if speed drops below threshold
--             if currentShockwave then
--                 currentShockwave:Destroy()
--                 currentShockwave = nil
--             end
--         end
        
--         -- Throttle updates to every 0.1 seconds
--         local currentTime = time()
--         if lastUpdateTime > currentTime then
--             return
--         end
--         lastUpdateTime = currentTime + 0.1
        
--         -- Create animated shockwave burst for moderate speeds (≥100)
--         if speed >= 100 then
--             local ballPosition = target.Value.Position
            
--             -- Clone and position the shockwave effect
--             local shockwaveBurst = ReplicatedStorage.Resources.ballShockwave:Clone()
--             shockwaveBurst.Parent = workspace.Effects
            
--             -- Orient shockwave in direction of movement (rotated 180 degrees)
--             local lookDirection = CFrame.lookAt(ballPosition, ballPosition + velocity)
--             shockwaveBurst:PivotTo(lookDirection * CFrame.Angles(0, math.pi, 0))
            
--             -- Schedule cleanup after 0.1 seconds
--             Debris:AddItem(shockwaveBurst, 0.1)
            
--             -- Animate the shockwave components
--             local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            
--             -- Rotate the main part
--             TweenService:Create(shockwaveBurst['2'], tweenInfo, {
--                 CFrame = shockwaveBurst['2'].CFrame * CFrame.Angles(0, 0.8726646259971648, 0)
--             }):Play()
            
--             -- Scale up the mesh
--             TweenService:Create(shockwaveBurst['2'].w1m, tweenInfo, {
--                 Scale = Vector3.new(5.59299, 5, 5.49700)
--             }):Play()
            
--             -- Fade out the main visual
--             TweenService:Create(shockwaveBurst['2'].w1d, tweenInfo, {
--                 Transparency = 1
--             }):Play()
            
--             -- Scale the secondary mesh
--             TweenService:Create(shockwaveBurst['1'].Mesh, tweenInfo, {
--                 Scale = Vector3.new(0.48199, 0.02999, 0.02999)
--             }):Play()
            
--             -- Fade out the decal
--             TweenService:Create(shockwaveBurst['1'].Decal, tweenInfo, {
--                 Transparency = 1
--             }):Play()
--         end
--     end)
    
--     -- Clean up connections when ball is removed from game
--     local ancestryConnection
--     ancestryConnection = target.AncestryChanged:Once(function()
--         if renderConnection then
--             renderConnection:Disconnect()
--         end
--         if ancestryConnection then
--             ancestryConnection:Disconnect()
--         end
--     end)
    
--     -- Automatic cleanup after 1 second as fallback
--     task.delay(1, function()
--         if ancestryConnection then
--             ancestryConnection:Disconnect()
--         end
--     end)
    
--     task.delay(1, function()
--         if renderConnection then
--             renderConnection:Disconnect()
--         end
--     end)
-- end

function Shockwave(root)
    local ShockConnection;
    
    local function spawnShockwave()
        local shockwaveBurst = Shared.Assets.Resources.Crimson.redShockwave:Clone();
        shockwaveBurst:PivotTo(root.CFrame * CFrame.Angles(0, math.pi, 0));
        shockwaveBurst.Parent = workspace.World.Debris;

        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out);
                
        -- Rotate the main part
        TweenService:Create(shockwaveBurst['2'], tweenInfo, {
            CFrame = shockwaveBurst['2'].CFrame * CFrame.Angles(0, 0.8726646259971648, 0)
        }):Play()
        
        -- Scale up the mesh
        TweenService:Create(shockwaveBurst['2'].w1m, tweenInfo, {
            Scale = Vector3.new(5.59299, 5, 5.49700) * 5;
        }):Play()
        
        -- Fade out the main visual
        TweenService:Create(shockwaveBurst['2'].w1d, tweenInfo, {
            Transparency = 1
        }):Play()
        
        -- Scale the secondary mesh
        TweenService:Create(shockwaveBurst['1'].Mesh, tweenInfo, {
            Scale = Vector3.new(0.48199, 0.02999, 0.02999) * 5;
        }):Play()
        
        -- Fade out the decal
        TweenService:Create(shockwaveBurst['1'].Decal, tweenInfo, {
            Transparency = 1
        }):Play()
    end

    local interval = 0.04;
    local lastTick = 0;

    ShockConnection = RunService.PreRender:Connect(function(deltaTimeRender)
        if not root:IsDescendantOf(workspace) then
            if ShockConnection then
                ShockConnection:Disconnect();
                ShockConnection = nil;
            end
            return;
        end

        if lastTick + interval < tick() then
            lastTick = tick();
            spawnShockwave();
        end
    end)

    return ShockConnection;
end

VFX.start = function(Data)
    local Root = Data.Origin
    local Projectile = Assets.Projectile:Clone();

    local ShockConnection = Shockwave(Root);

    local BodyVelocity = Auxiliary.Shared.CreateVelocity(Root, {MaxForce = Vector3.new(1e6, 1e6, 1e6)});
    BodyVelocity.Velocity = Root.CFrame.LookVector*100;

    Projectile:PivotTo(Root.CFrame * CFrame.new(0, 0, -4));
    Projectile.Parent = workspace.World.Debris;

    local tasks = {};

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
                task.spawn(function() 
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
        ShockConnection:Disconnect();
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
            Projectile:PivotTo(Root.CFrame * CFrame.new(0, 0, -4));
            BodyVelocity.Velocity = Root.CFrame.LookVector*150;
        end
    end)
end

return VFX;