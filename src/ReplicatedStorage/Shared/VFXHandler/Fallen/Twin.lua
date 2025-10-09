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

	local rootFX: Model = Auxiliary.Shared.BindFX(VFXMaid, Assets.CharacterFX);
	rootFX.CFrame = Root.CFrame;
	rootFX.Weld.Part0 = Root;
	rootFX.Parent = FXParent;

	task.delay(7, function()
		VFXMaid:Destroy();
	end)
	
	Auxiliary.Shared.PlayAttachment(rootFX.Charge);
	
	Auxiliary.Shared.WaitForMarker(Animation, "vfx1");

	-- Auxiliary.Shared.PlayAttachment(rootFX.ChargeFinish);

	local claw2: Model = Auxiliary.Shared.BindFX(VFXMaid, Assets.Slash);
	claw2.CFrame = Root.CFrame;
	claw2.Weld.Part0 = Root;
	claw2.Weld.C0 *= CFrame.Angles(0,math.rad(-110),0);
	claw2.Parent = FXParent;

	for _, beam in pairs(claw2:GetDescendants()) do
		if beam:IsA("Beam") then
			local Tween = TweenService:Create(beam, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
				Width0 = 0;
				Width1 = 0;
			});
			Tween:Play();
		end
	end

	task.delay(0.3, function()
		claw2:Destroy();
	end)

	local c1 c1 = RunService.RenderStepped:Connect(function(deltaTime)
		if not claw2 or not claw2:IsDescendantOf(workspace) then c1:Disconnect(); return; end;
		claw2.Weld.C0 *= CFrame.Angles(0,math.pi*4*deltaTime,0);
	end)

	Auxiliary.Shared.WaitForMarker(Animation, "first");

	Auxiliary.Shared.PlayAttachment(rootFX.RootEmit);

	local fx = Auxiliary.Shared.BindFX(VFXMaid, Assets.Dash);
	fx.CFrame = Root.CFrame;
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);
	
	local fx = Auxiliary.Shared.BindFX(VFXMaid, Assets.FirstTwin);
	fx:PivotTo(Root.CFrame);
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	local Tween = TweenService:Create(fx.SpaceDistortion, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {CFrame = fx.SpaceDistortion.CFrame * CFrame.new(0,0,-20);});
	Tween:Play();
	
	local speed = Instance.new("NumberValue");
	speed.Value = 120;
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

	Auxiliary.Shared.WaitForMarker(Animation, "firstend");

	Auxiliary.Shared.PlayAttachment(rootFX.Finish);

	Auxiliary.Shared.WaitForMarker(Animation, "second");

	Auxiliary.Shared.PlayAttachment(rootFX.RootEmit);

	local fx = Auxiliary.Shared.BindFX(VFXMaid, Assets.Dash);
	fx.CFrame = Root.CFrame;
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	local claw2: Model = Auxiliary.Shared.BindFX(VFXMaid, Assets.Slash2);
	claw2.CFrame = Root.CFrame;
	claw2.Weld.Part0 = Root;
	claw2.Weld.C0 *= CFrame.Angles(0,math.rad(-150),0);
	claw2.Parent = FXParent;

	for _, beam in pairs(claw2:GetDescendants()) do
		if beam:IsA("Beam") then
			local Tween = TweenService:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
				Width0 = 0;
				Width1 = 0;
			});
			Tween:Play();
		end
	end

	task.delay(0.3, function()
		claw2:Destroy();
	end)

	local c1 c1 = RunService.RenderStepped:Connect(function(deltaTime)
		if not claw2 or not claw2:IsDescendantOf(workspace) then c1:Disconnect(); return; end;
		claw2.Weld.C0 *= CFrame.Angles(0,math.pi*7*deltaTime,0);
	end)


	local fx = Auxiliary.Shared.BindFX(VFXMaid, Assets.SecondTwin);
	fx:PivotTo(Root.CFrame);
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	local Tween = TweenService:Create(fx.SpaceDistortion, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {CFrame = fx.SpaceDistortion.CFrame * CFrame.new(0,0,-20);});
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