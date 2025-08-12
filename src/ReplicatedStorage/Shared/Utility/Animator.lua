--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService("RunService")

local Shared  = ReplicatedStorage.Shared;
local AnimationsFolder  = ReplicatedStorage.Shared.Assets.Animations;

local Auxiliary = require(Shared.Utility.Auxiliary);

--//Module
local AnimatorManager = {};
AnimatorManager.__index = AnimatorManager;

function AnimatorManager.new(Entity)
	local self = setmetatable({
		Loaded = {};
		AnimationLibrary = {}; -- 추가: Animation 원본 객체 저장용
		Animator = RunService:IsClient() and Entity.Character.Humanoid.Animator or Entity;
	}, AnimatorManager);

	return self;
end;

type AnimatorManager = typeof(AnimatorManager.new(...))

function AnimatorManager:Cache()
	self:Destroy()

	local Loading = RunService:IsClient() and {'Universal'} or {'Universal'};

	-- for _, MovesetName: string in Loading do
	-- local AnimationFolder = AnimationsFolder:FindFirstChild(MovesetName);

	for _, Anim: Animation in AnimationsFolder:GetDescendants() do
		if not Anim:IsA('Animation') then continue end;

		local Animator = (RunService:IsClient() and self.Animator or self.Animator.Character.Animator);
		local Track : AnimationTrack = Animator:LoadAnimation(Anim);
		local Path = Auxiliary.Shared.GetPath(Anim, AnimationsFolder)

		self.Loaded[Path] = Track;
		self.AnimationLibrary[Path] = Anim; -- 추가: Animation 객체 저장

		if Anim:GetAttribute('Priority') then
			Track.Priority = Enum.AnimationPriority[Anim:GetAttribute('Priority')];
		end;
	end;
	-- end;
end;


function AnimatorManager:Fetch(Path: string)
	-- if #self.Loaded == 0 then return self:Cache() end
	return self.Loaded[Path];
end;

-- 매번 새로운 Track 생성
function AnimatorManager:Load(Path: string)
	local Anim = self.AnimationLibrary[Path]
	if not Anim then return nil end

	local Animator = (RunService:IsClient() and self.Animator or self.Animator.Character.Animator);
	local NewTrack = Animator:LoadAnimation(Anim)

	if Anim:GetAttribute('Priority') then
		NewTrack.Priority = Enum.AnimationPriority[Anim:GetAttribute('Priority')];
	end

	return NewTrack
end;

function AnimatorManager:Destroy()
	for Path, Anim : AnimationTrack in self.Loaded do
		Anim:Destroy(); 
		self.Loaded[Path] = nil
	end
	self.AnimationLibrary = {};
end;

function AnimatorManager:StopAllAnimations(Exceptions, FadeTime: number?)
	for _, Anim : AnimationTrack in self.Loaded do
		if Exceptions and table.find(Exceptions, Anim.Animation.Name) then 
			continue 
		end;

		Anim:Stop(FadeTime);
	end;
end;

return AnimatorManager;
