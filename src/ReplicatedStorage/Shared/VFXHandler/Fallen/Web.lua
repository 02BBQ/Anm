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
local DebrisFolder = workspace.World.Debris;

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

	Auxiliary.Shared.WaitForMarker(Animation, "start");

    local secondMaid = Auxiliary.Maid.new();

    local web = Auxiliary.Shared.BindFX(secondMaid, Assets.Webs);
    web:PivotTo(Root.CFrame);
    web.Parent = DebrisFolder

    Auxiliary.Shared.PlayAttachment(web.First);

    task.delay(10, function()
        secondMaid:Destroy();
    end)

    Auxiliary.Shared.WaitForMarker(Animation, "hitreg");
    Auxiliary.Shared.PlayAttachment(web.Smokes);
end

return VFX;