local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Auxiliary = require(Shared.Utility.Auxiliary);

local Spell = require(script.Parent):Extend();

local FastCast = require(Shared.Utility.FastCast);

local Caster = FastCast.new()
local CastBehavior = FastCast.newBehavior()
CastBehavior.RaycastParams = Auxiliary.Shared.RayParams.Map;
CastBehavior.MaxDistance = 500
CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default

Caster.LengthChanged:Connect(function(cast, segmentOrigin, segmentDirection, length, segmentVelocity)
	local Model = cast['bullet'];
	if Model then
		local bulletLength = Model.Size.Z / 2
		local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
		Model.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
	end
end)
Caster.RayPierced:Connect(function(cast, raycastResult, segmentVelocity)
	if raycastResult.Instance and raycastResult.Instance.CanCollide == true then
		local position = raycastResult.Position
		local normal = raycastResult.Normal
		local newNormal = segmentVelocity.Unit - (2 * segmentVelocity.Unit:Dot(normal) * normal)
		cast:SetVelocity(newNormal * segmentVelocity.Magnitude)
		cast:SetPosition(position)
	end
end)
Caster.RayHit:Connect(function(cast, raycastResult, segmentVelocity)
	local hitPoint
	if not raycastResult then
		cast:GetPosition();
	else
		hitPoint = raycastResult.Position
	end
end)

Caster.CastTerminating:Connect(function(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject

	if cosmeticBullet ~= nil then
		cosmeticBullet:Destroy()
	end
end)

Spell.RayPierce = function(cast, rayResult, segmentVelocity)
	if rayResult.Instance:IsDescendantOf(cast['caster']) then
		return true
	end
	return false
end
CastBehavior.CanPierceFunction = Spell.RayPierce
 


function Spell:OnCast(Entity, Args)
	local CF = CFrame.new(Entity.Character.Root.Position, Args.mousePos);
	local Bullet = Caster:Fire(CF.Position, CF.LookVector, 300, CastBehavior)
    Bullet['caster'] = Entity.Character.Rig;

    Entity.VFX:Fire("Spell/SuperDreamySmite", {
        Action = "start",
        Origin = Entity.Character.Root,
        CF = CF,
        Speed = 300,
    })
end;
 
return Spell;