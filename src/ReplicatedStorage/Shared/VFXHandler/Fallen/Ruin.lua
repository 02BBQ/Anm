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

	local Symbol = Assets.Symbol:Clone();
	Symbol.CFrame = Data.Caster.Character.Root.CFrame * CFrame.new(0, -2, 0);
	Symbol.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(Symbol);
	game.Debris:AddItem(Symbol, 5);
end

VFX.invis = function(Data)
    local Root = Data.Origin
	local Humanoid: Humanoid? = Data.Caster.Character.Humanoid;
	
	local Animation: AnimationTrack;
	
	for _,v: AnimationTrack in pairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
		if v.Animation.AnimationId == Data.ID then
			Animation = v;
		end
	end
	
	if not Animation then return end;

	local flashstep = Assets.flashstep:Clone();
	flashstep.CFrame = Data.Caster.Character.Root.CFrame;
	flashstep.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(flashstep);
	game.Debris:AddItem(flashstep, 5);

	Auxiliary.Shared.Invis(Data.Caster.Character.Rig, true);

	TweenService:Create(workspace.CurrentCamera,TweenInfo.new(0.3), {FieldOfView = workspace.CurrentCamera.FieldOfView+30}):Play();

	Auxiliary.Shared.WaitForMarker(Animation, "tp");

	Auxiliary.Shared.Invis(Data.Caster.Character.Rig, false);

	local Zoom = TweenService:Create(workspace.CurrentCamera,TweenInfo.new(1.5), {FieldOfView = workspace.CurrentCamera.FieldOfView-30}); Zoom:Play();

	Animation.Stopped:Wait();

	Zoom:Cancel();
	Zoom:Destroy();

	TweenService:Create(workspace.CurrentCamera,TweenInfo.new(0.1), {FieldOfView = 70}):Play();
end

VFX.slash = function(Data)
	local Root = Data.Origin
	local Humanoid: Humanoid? = Data.Caster.Character.Humanoid;

	local Animation: AnimationTrack;
	
	for _,v: AnimationTrack in pairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
		if v.Animation.AnimationId == Data.ID then
			Animation = v;
		end
	end
	
	if not Animation then return end;

	local Model = _highlightCache[Data.UID] or nil;
	if not Model then
		Model = Assets.Highlighter:Clone();
		Model.Parent = FXParent;
		_highlightCache[Data.UID] = Model;
	end;

	local cancelled = false

	local HandTip = Assets.HandSpark:Clone();
	HandTip.CFrame = Data.Caster.Character.Rig["Left Arm"].CFrame * CFrame.new(0, -0.9, 0);
	HandTip.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(HandTip);
	game.Debris:AddItem(HandTip, 5);

	local SkyShatter = Assets.SkyShatter:Clone();
	SkyShatter.CFrame = CFrame.new(Root.Position, Root.Position - Data.dir)
	 * CFrame.new(0, 0, -3)
	SkyShatter.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(SkyShatter);
	game.Debris:AddItem(SkyShatter, 5);

	local slash = Assets.Cleave:Clone();
	local angle = seed:NextNumber(-math.pi, math.pi);
	slash.CFrame = CFrame.new(Root.Position, Root.Position - Data.dir)
	 * CFrame.new(0, 0, -3) * CFrame.Angles(0,0,angle);
	slash.Parent = Model;

	local Dark = Assets.Dark:Clone();
	Dark.Parent = game.Lighting;
	local t = TweenService:Create(Dark, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
		Brightness = 0;
	}); t:Play();
	t.Completed:Connect(function()
		Dark:Destroy();
	end)

	local CFTween = TweenService:Create(slash, TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
		CFrame = slash.CFrame * CFrame.new(0, 0, -5),
	}); CFTween:Play();

	local Tween = TweenService:Create(slash, TweenInfo.new(0.075, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Size = Vector3.new(.3,35,.3),
	}); Tween:Play();
	CFTween.Completed:Connect(function()
		
		local p = slash:Clone();
		slash:Destroy();
		p.CFrame = CFrame.new(Data.goal.Position, Data.goal.Position + Data.dir) * CFrame.Angles(0,math.pi,angle) * CFrame.new(0,0,4)
		p.Parent = Model;

		local t = TweenService:Create(p, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
			CFrame = p.CFrame * CFrame.new(0, 0, -2.75),
			Size = Vector3.new(0,43,0),
		}); t:Play();
		t.Completed:Connect(function()
			p:Destroy();
		end)
	end)

	Animation.Stopped:Wait();

	cancelled = true;
	task.delay(1, function()
		if not _highlightCache[Data.UID]  then return end;
		_highlightCache[Data.UID]:Destroy();
		_highlightCache[Data.UID] = nil;
	end)
end

return VFX;