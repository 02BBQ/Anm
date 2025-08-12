--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local SoundService = game:GetService('SoundService');
local Debris =game:GetService('Debris');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local SoundFolder: Folder = Shared.Assets.Sounds;
local Effects: Folder = workspace:WaitForChild('World'):WaitForChild('Debris');

local Auxiliary = require(Shared.Utility.Auxiliary);

export type SoundObject = {
	Destroyed: boolean;
	OnDestroy: BindableEvent;
	Sound: Sound;
};

export type SoundProperties = {
	Pitch: number?;
	Volume: number?;
};

--//Module
local SoundHandler = {};
SoundHandler.__type = 'SoundObject';
SoundHandler._Cached = {};
SoundHandler._Loaded = false;

function SoundHandler:Cache()
	SoundHandler._Cached = {};
	for _,Sound: Sound in SoundFolder:GetDescendants() do
		if not Sound:IsA('Sound') then continue end;
		SoundHandler._Cached[Auxiliary.Shared.GetPath(Sound, SoundFolder)] = Sound;
	end;
	SoundHandler._Loaded = true;
end;

function SoundHandler:Fetch(Path: string)
	return SoundHandler._Cached[Path];
end;

SoundHandler.Spawn = function(SoundPath: string | Sound, Holder: Instance | Vector3 | nil, Duration: number?, SoundProperties: SoundProperties?, SoundGroup: string?, Debug: boolean?)
	local TargetSound = (typeof(SoundPath) == 'string' and SoundHandler:Fetch(SoundPath)) or SoundPath;
	assert(typeof(TargetSound) == 'Instance', debug.traceback('Could not find sound '..SoundPath..'!'));
	
	if SoundProperties ~= nil then
		assert(typeof(SoundProperties) == 'table', debug.traceback('Sound properties parameter must be a table!'));
	end;
	
	if Debug ~= nil then
		assert(typeof(Debug) == 'boolean', debug.traceback('Debug parameter is not a boolean!'));
	end;
	
	SoundProperties = SoundProperties or {};
	
	local HoldingPart;
	local Cloned: Sound = TargetSound:Clone();
	if SoundProperties.Pitch then
		Cloned.PlaybackSpeed = SoundProperties.Pitch;
	end;
	
	if SoundProperties.Volume then
		Cloned.Volume = SoundProperties.Volume * 1.7;
	else
		Cloned.Volume = Cloned.Volume * 1.7
	end;
	
	if Cloned:GetAttribute("OverrideVolume") then
		Cloned.Volume = Cloned:GetAttribute("OverrideVolume")
	end
	
	if typeof(Holder) == 'Instance' then
		Cloned.Parent = Holder;
	elseif typeof(Holder) == 'Vector3' then
		HoldingPart = Instance.new('Part');
		HoldingPart.Anchored, HoldingPart.CanCollide = true, false;
		HoldingPart.Transparency = 1;
		HoldingPart.Size = Vector3.one;
		
		if Debug then
			HoldingPart.Color = Color3.new(1,0,0);
			HoldingPart.Transparency = 0.5;
		end;
		
		HoldingPart.Position = Holder;
		
		HoldingPart.Name = TargetSound.Name;
		HoldingPart.Parent = Effects;	
		Cloned.Parent = HoldingPart;
	elseif Holder == nil then
		Cloned.Parent = SoundService;
	end;
	
	local SoundObject = {
		Destroyed = false;
		OnDestroy = Instance.new('BindableEvent');
		Sound=Cloned;	
	};
	
	if SoundGroup then
		Cloned.SoundGroup = SoundService[SoundGroup];
	end;
		
	SoundObject.Destroy = function()
		if SoundObject.Destroyed then
			return;
		end;
		
		SoundObject.Destroyed = true;
		Cloned:Destroy();
		SoundObject.OnDestroy:Fire();
		if HoldingPart then
			HoldingPart:Destroy();
		end;
		
		Debris:AddItem(SoundObject.OnDestroy, 10);
	end;
	
	Cloned:Play();
	if Duration then
		task.delay(Duration, SoundObject.Destroy);
	end;
	
	return SoundObject;
end;

return SoundHandler;