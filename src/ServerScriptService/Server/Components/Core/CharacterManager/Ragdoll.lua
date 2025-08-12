--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Shared = ReplicatedStorage.Shared;


local Auxiliary = require(Shared.Utility.Auxiliary);

--//Constants
local attachmentCFrames = {
	["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
	["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
	["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
	["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
}

local ragdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

--//Module
local Ragdoll = {};

local function createColliderPart(part: BasePart, Entity)
	if not part then return end
	local rp = Instance.new("Part")
	rp.Name = "ColliderPart"
	rp.Size = part.Size*.7;
	rp.Massless = true			
	rp.CFrame = part.CFrame
	rp.Transparency = 1
	rp.CollisionGroup = (Entity.Character._CanCollide and 'Ragdoll') or 'Nothing';

	local wc = Instance.new("WeldConstraint")
	wc.Part0 = rp
	wc.Part1 = part

	wc.Parent = rp
	rp.Parent = part

	if Entity.Player then
		rp:SetNetworkOwner(Entity.Player);
	end;
end

function replaceJoints(Character, Entity)
	if not Character or not Character:IsDescendantOf(workspace.Alive) then return end;

	local Humanoid = Character:FindFirstChildOfClass('Humanoid');
	local HRP = Character:FindFirstChild('HumanoidRootPart');

	for _, motor in pairs(Character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			if not attachmentCFrames[motor.Name] then return end
			motor.Enabled = false;
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame = attachmentCFrames[motor.Name][1]
			a1.CFrame = attachmentCFrames[motor.Name][2]

			a0.Name = "RagdollAttachment"
			a1.Name = "RagdollAttachment"

			createColliderPart(motor.Part1, Entity)
			motor.Part1.CollisionGroup = 'Ragdoll';

			local b = Instance.new("BallSocketConstraint")
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Name = "RagdollConstraint"

			b.LimitsEnabled = true
			b.TwistLimitsEnabled = false
			b.MaxFrictionTorque = 0
			b.Restitution = 0
			b.UpperAngle = 45
			b.TwistLowerAngle = -45
			b.TwistUpperAngle = 45

			if motor.Name == "Neck" then
				b.TwistLimitsEnabled = true
				b.TwistLowerAngle = -70
				b.TwistUpperAngle = 70
			end

			a0.Parent = motor.Part0
			a1.Parent = motor.Part1
			b.Parent = motor.Parent
		end
	end
	Humanoid.AutoRotate = false --> Disabling AutoRotate prevents the Character rotating in first person or Shift-Lock
end

function resetJoints(Character: Model, Entity)
	if not Character or not Character:IsDescendantOf(workspace.Alive) then return end;

	local Humanoid = Character:FindFirstChildOfClass('Humanoid');
	local HRP = Character:FindFirstChild('HumanoidRootPart');

	if Humanoid.Health < 1 then return end
	for _, instance in pairs(Character:GetDescendants()) do
		if ragdollInstanceNames[instance.Name] then
			instance:Destroy()
		end

		if instance:IsA("Motor6D") then
			instance.Enabled = true;
		end

		if instance:IsA('BasePart') then
			instance.CollisionGroup = 'Entity';
		end
	end

	Humanoid.AutoRotate = true 
end;

Ragdoll.UpdateRagdoll = function(Entity, Absolute: boolean?)
	local Bool;

	if Absolute then
		Entity.Character.RagdollQueue = {};
		Bool = false;
	else
		Bool = #Entity.Character.RagdollQueue ~= 0;
	end;

	if not Entity.Character.Alive and not Bool then return end;
	--if Entity.Character.Ragdolled == Bool then return end;

	Entity.Character.Humanoid.AutoRotate = not Bool;
	Entity.Character.Ragdolled = Bool;
	Entity.Character.Rig:SetAttribute('Ragdolled', Bool);
	Entity.Character.Root.RootJoint.Enabled = Bool;

	--if Bool then
	--	Entity.Character.RagdollMovement = Entity.Combat:ChangeMobility({
	--		Speed = 0;
	--		Jump = 0;
	--	});

	--	Network:Send('Combat', {Effect = 'Ragdolled', Victim = Entity.Character.Rig});
	--else
	--	Entity.Character.RagdollMovement.Remove();
	--	Entity.Character.RagdollMovement = nil;
	--end;

	if not Bool then
		local HRP = Entity.Character.Rig.HumanoidRootPart;

		task.spawn(function()
			local RootCFr: CFrame = Entity.Character.Root.CFrame;

			local GroundRay = workspace:Raycast(RootCFr.Position+Vector3.new(0,2,0), Vector3.yAxis*-7, Auxiliary.Shared.RayParams.Map);
			if not GroundRay then return end;

			local UprightCFr: CFrame = CFrame.new(RootCFr.Position) * CFrame.fromOrientation(0,Entity.Character.Root.Orientation.Y,0);
			Entity.Character.Root.CFrame = (UprightCFr - UprightCFr.Position) + (GroundRay.Position + Vector3.new(0,2,0));
		end);
	end;

	--if Entity.Player then
	--	Network:Send('Ragdoll', {Bool=Bool}, false, Entity.Player);
	--else
		local Torso = Entity.Character.Rig:FindFirstChild('Torso');
		local Humanoid = Entity.Character.Humanoid;

		local function Push()
			if not Torso then return end;
			Torso:ApplyImpulse(Torso.CFrame.LookVector * -100);
		end;

		if Bool then
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false);
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true);
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true);
			Humanoid.PlatformStand = true;
			Push();
		else
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true);
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false);
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false);

			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp);
			Humanoid.PlatformStand = false;
		end;
	--end;

	if Bool then
		replaceJoints(Entity.Character.Rig, Entity);
	else
		resetJoints(Entity.Character.Rig, Entity);
	end;
end;

Ragdoll.Ragdoll = function(Entity, Bool: boolean, Absolute: boolean?)
	if Bool then
		assert(not Absolute, debug.traceback("Can't create ragdoll with absolute parameter!"));
		table.insert(Entity.Character.RagdollQueue, Bool);
	else
		Auxiliary.Shared.RemoveFirstValue(Entity.Character.RagdollQueue);
	end;

	task.spawn(Ragdoll.UpdateRagdoll, Entity, Absolute);
end;

return Ragdoll