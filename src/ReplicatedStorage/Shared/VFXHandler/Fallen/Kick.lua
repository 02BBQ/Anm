--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");

local Shared = ReplicatedStorage.Shared;
local FXParent = workspace.World.Debris;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local Assets = Shared.Assets.Resources.Fallen;

local VFX = {};

VFX.start = function(Data)
    local Root = Data.Origin
	local Humanoid: Humanoid? = Data.Caster.Character.Humanoid;
	
	local Animation: AnimationTrack;
	
	for _,v: AnimationTrack in pairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
		if v.Animation.AnimationId == Data.ID then
			Animation = v;
		end
	end
	
	if not Animation then return end;

	local jumpMaid = Auxiliary.Maid.new();
	
	local bp: BodyPosition = Auxiliary.Shared.CreatePosition(Root, {MaxForce = Vector3.one * 1e6});
	jumpMaid:AddTask(bp);
	bp.Position = Root.Position + (Root.CFrame.LookVector * -11 + Vector3.new(0,14,0))*2;
	bp.P = 5000;
	bp.D = 600;

	local fx = Auxiliary.Shared.BindFX(jumpMaid, Assets.Jump);
	fx:PivotTo(Root.CFrame * CFrame.new(0,-2.2,0));
	fx:ScaleTo(2);
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	local smoke = Auxiliary.Shared.BindFX(jumpMaid, Assets.Smoke);
	smoke:PivotTo(Root.CFrame * CFrame.new(0,-2.2,0));
	smoke:ScaleTo(2);
	smoke.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(smoke);

	Auxiliary.Shared.WaitForMarker(Animation, "kick")
	bp:Destroy();
	
	local meshVFX = Auxiliary.Maid.new();
	
	local part = Assets.nothing:Clone();
	part.CFrame = Root.CFrame * CFrame.new(0,0,-3) * CFrame.Angles(0,0,math.pi/2);
	part.Parent = workspace.World.Debris;
	
	local meshes2: Model = Auxiliary.Shared.BindFX(meshVFX, Auxiliary.MeshEmitter.StartMeshEmitter(
		part,
		Assets.Disdzxmantle
		));
	
	Auxiliary.Shared.BindFX(meshVFX,part);
	
	local fx = Auxiliary.Shared.BindFX(meshVFX, Assets.SpaceDistortion);
	fx:PivotTo(part.CFrame * CFrame.new(0,0,-3));
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);
	
	task.delay(5,function()
		meshVFX:Destroy();
	end)
end

return VFX;