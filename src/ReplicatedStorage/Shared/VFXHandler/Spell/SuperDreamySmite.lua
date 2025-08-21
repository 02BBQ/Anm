--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local Shared = ReplicatedStorage.Shared;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local FastCast = require(Shared.Utility.FastCast);

local caster = FastCast.new()
local castBehavior = FastCast.newBehavior()
castBehavior.RaycastParams = Auxiliary.Shared.RayParams.Map;
castBehavior.MaxDistance = 500;
castBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default;
castBehavior.CosmeticBulletContainer = workspace.World.Debris;
castBehavior.CosmeticBulletTemplate = Shared.Assets.Resources.DreamySmite.Projectile;

caster.LengthChanged:Connect(function(cast, segmentOrigin, segmentDirection, length, segmentVelocit, projectile)
	local Model = projectile;
	if Model then
		local bulletLength = Model.Size.Z / 2
		local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
		Model.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
	end
end)
caster.RayPierced:Connect(function(cast, raycastResult, segmentVelocity)
	if raycastResult.Instance and raycastResult.Instance.CanCollide == true then
		local position = raycastResult.Position
		local normal = raycastResult.Normal
		local newNormal = segmentVelocity.Unit - (2 * segmentVelocity.Unit:Dot(normal) * normal)
		cast:SetVelocity(newNormal * segmentVelocity.Magnitude)
		cast:SetPosition(position)
	end
end)
caster.RayHit:Connect(function(cast, raycastResult, segmentVelocity)
	local hitPoint
	if not raycastResult then
		hitPoint = CFrame.new(cast.RayInfo.CosmeticBulletObject.Position);
	else
		hitPoint = CFrame.new(raycastResult.Position, raycastResult.Position+ raycastResult.Normal);
	end

    local VFX = Shared.Assets.Resources.DreamySmite.Hit:Clone();
    VFX.CFrame = hitPoint;
    VFX.Parent = workspace;
    Sound.Spawn("ElectricExplosion", VFX, 3);

	game.Debris:AddItem(VFX, 5);

    for _,Emitter : ParticleEmitter in pairs(VFX:GetDescendants()) do
        if Emitter:IsA("ParticleEmitter") then
            task.spawn(function()
                local EmitCount = Emitter:GetAttribute("EmitCount") or 1
                local EmitDelay = Emitter:GetAttribute("EmitDelay") or nil
                local EmitDuration = Emitter:GetAttribute("EmitDuration") or nil

                if EmitDelay then
                    task.wait(EmitDelay)
                end

                Emitter:Emit(EmitCount)
                
                if EmitDuration then
                    Emitter.Enabled = true
                    task.wait(EmitDuration)
                    Emitter.Enabled = false
                end
            end)
        end
    end
end)

caster.CastTerminating:Connect(function(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject

	if cosmeticBullet ~= nil then
		cosmeticBullet:Destroy()
	end
end)

castBehavior.CanPierceFunction = function(cast, rayResult, segmentVelocity)
	if rayResult.Instance:IsDescendantOf(cast['caster']) then
		return true
	end
	return false
end

local VFX = {};

VFX.start = function(Data)
    local HumanoidRootPart = Data.Origin
    local CF = Data.CF;

    local bullet = caster:Fire(CF.Position, CF.LookVector, Data.Speed, castBehavior)
    bullet['caster'] = Data.Caster.Character.Rig;
end

return VFX;