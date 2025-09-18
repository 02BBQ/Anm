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

	Auxiliary.Shared.Invis(Data.Caster.Character.Rig, true);

	Auxiliary.Shared.WaitForMarker(Animation, "tp");

	Auxiliary.Shared.Invis(Data.Caster.Character.Rig, false);
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

	local slashMaid = Auxiliary.Maid.new();

	local Model = Auxiliary.Shared.BindFX(slashMaid, Assets.Highlighter);
	Model.Parent = FXParent;

	local cancelled = false

	task.spawn(function()
		while not cancelled do
			local slash = Assets.Cleave:Clone();
			slash.CFrame = Root.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0,0,seed:NextNumber(-math.pi, math.pi));
			slash.Parent = Model;

			local Dark = Assets.Dark:Clone();
			Dark.Parent = game.Lighting;
			local t = TweenService:Create(Dark, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
				Brightness = 0;
			}); t:Play();
			t.Completed:Connect(function()
				Dark:Destroy();
			end)

			TweenService:Create(slash, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
				CFrame = slash.CFrame * CFrame.new(0, 0, -5),
			}):Play();


			local Tween = TweenService:Create(slash, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(.3,35,.3),
			}); Tween:Play();
			Tween.Completed:Connect(function()
				slash:Destroy();

				local p = Assets.Cleave:Clone();
				p.CFrame = slash.CFrame * CFrame.new(0, 0, -23);
				p.Parent = Model;

				local t = TweenService:Create(p, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
					CFrame = p.CFrame * CFrame.new(0, 0, -5),
					Size = Vector3.new(0,38,0),
				}); t:Play();
				t.Completed:Connect(function()
					p:Destroy();
				end)
			end)

			task.wait(0.1);
		end
	end);

	Animation.Stopped:Wait();

	cancelled = true;
	task.delay(3, function()
		slashMaid:Destroy();
	end)
end

return VFX;