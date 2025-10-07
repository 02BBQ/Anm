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
local seed = Random.new();

local _highlightCache = {};

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

	local firstMaid = Auxiliary.Maid.new();
	local VFXMaid = Auxiliary.Maid.new();

	local fx = Auxiliary.Shared.BindFX(VFXMaid, Assets.BSlam2);
	fx.CFrame = Root.CFrame;
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	Auxiliary.Shared.WaitForMarker(Animation, "first");
	
	local fx = Auxiliary.Shared.BindFX(VFXMaid, Assets.FirstTwin);
	fx:PivotTo(Root.CFrame);
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	task.delay(10, function()
		VFXMaid:Destroy();
	end)

	local Tween = TweenService:Create(fx.SpaceDistortion, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {CFrame = fx.SpaceDistortion.CFrame * CFrame.new(0,0,-15);});
	Tween:Play();
	
	local speed = Instance.new("NumberValue");
	speed.Value = 100;
	firstMaid:AddTask(speed);

	local bv: BodyVelocity;
	bv = Auxiliary.Shared.CreateVelocity(Root, {MaxForce = Vector3.new(40000,0,40000)});
	firstMaid:AddTask(bv);

	local run run = RunService.PreRender:Connect(function(dt)
		if not bv:IsDescendantOf(workspace) or not speed then bv:Destroy(); run:Disconnect(); return end;
		bv.Velocity = Root.CFrame.LookVector * speed.Value;
	end)

	local Tween = TweenService:Create(speed, TweenInfo.new(0.5), {Value = 0});
	Tween:Play();
	Tween.Completed:Connect(function(playbackState)
		firstMaid:Destroy();
	end)

	Auxiliary.Shared.WaitForMarker(Animation, "second");

	local fx = Auxiliary.Shared.BindFX(VFXMaid, Assets.SecondTwin);
	fx:PivotTo(Root.CFrame);
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	local Tween = TweenService:Create(fx.SpaceDistortion, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {CFrame = fx.SpaceDistortion.CFrame * CFrame.new(0,0,-15);});
	Tween:Play();

	firstMaid:Destroy();

	local secondMaid = Auxiliary.Maid.new();

	local speed = Instance.new("NumberValue");
	speed.Value = 100;
	secondMaid:AddTask(speed);

	local bv: BodyVelocity;
	bv = Auxiliary.Shared.CreateVelocity(Root, {MaxForce = Vector3.new(40000,0,40000)});
	secondMaid:AddTask(bv);

	local run run = RunService.PreRender:Connect(function(dt)
		if not bv:IsDescendantOf(workspace) or not speed then bv:Destroy(); run:Disconnect(); return end;
		bv.Velocity = Root.CFrame.LookVector * speed.Value;
	end)

	local Tween = TweenService:Create(speed, TweenInfo.new(0.5), {Value = 0});
	Tween:Play();
	Tween.Completed:Connect(function(playbackState)
		secondMaid:Destroy();
	end)
end

return VFX;