--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local AnimationsFolder: Folder = Shared.Assets.Animations;

local Auxiliary = require(Shared.Utility.Auxiliary);
local TroveClass = require(Shared.Utility.Trove);

--//Module
local AnimatorManager = {};
AnimatorManager.__index = AnimatorManager;

AnimatorManager.new = function(Entity: {})
	local self = setmetatable({

		Loaded = {};
		
		_Trove = TroveClass.new();
		_SpeedCache = {};

		_SpeedMultiplier = 1;

		Parent = Entity;

	}, AnimatorManager);
	
	self._Trove:Connect(RunService.Heartbeat, function()
		if not self.Parent.Character.Rig or not self.Parent.Character.Rig:IsDescendantOf(workspace.Entities) then return end;

		for _,v: AnimationTrack in self.Loaded do
			if v.IsPlaying and not v.Animation:GetAttribute('IgnoreActive') then
				self.Parent.Character:SetAttribute('AnimationActive', true);
				return;
			end;
		end;

		self.Parent.Character:SetAttribute('AnimationActive', nil);
	end);

	return self;
end;

function AnimatorManager:Cache()
	self.Loaded = {};

	for _,Anim: Animation? in AnimationsFolder:GetDescendants() do
		if not Anim:IsA('Animation') then
			continue;
		end;

		local Track: AnimationTrack = self.Parent.Character.Animator:LoadAnimation(Anim);
		local TrackIndex = Auxiliary.Shared.GetPath(Anim, AnimationsFolder);

		self.Loaded[TrackIndex] = Track;
		Anim:SetAttribute('ServerTrack', true);

		if Anim:GetAttribute('Priority') then
			Track.Priority = Enum.AnimationPriority[Anim:GetAttribute('Priority')];
		end;
	end;
end;

function AnimatorManager:GetCurrentTrack(ServerTrack: AnimationTrack)
	for _,v: AnimationTrack in self.Parent.Character.Animator:GetPlayingAnimationTracks() do
		if not v then
			continue;
		end;
		if v.Animation.AnimationId == ServerTrack.Animation.AnimationId then
			return v;
		end;
	end;
end;

function AnimatorManager:FindTrackById(Searching)
	for _,v: AnimationTrack in self.Loaded do
		if v.Animation.AnimationId == Searching then
			return v;
		end;
	end;
end;

function AnimatorManager:Fetch(Path: string, Direct: boolean?)
	return self.Loaded[Path];
end;

function AnimatorManager:StopAllTracks(FadeTime: number?, Exceptions: {string})
	for _,v: AnimationTrack in self.Parent.Character.Animator:GetPlayingAnimationTracks() do
		if Exceptions and table.find(Exceptions, v.Animation.Name) then continue end;
		v:Stop(FadeTime);
	end;
end;

function AnimatorManager:Destroy()
	self._Trove:Destroy();
end;

return AnimatorManager;