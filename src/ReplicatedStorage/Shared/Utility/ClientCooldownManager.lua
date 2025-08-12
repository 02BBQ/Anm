--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Shared : Folder = ReplicatedStorage.Shared;
local SharedComponents : Folder = Shared.Components;

local Network = require(SharedComponents.Networking.Network);
local Signal = require(SharedComponents.Utility.Signal);

--//Module
local CooldownManager = {};
CooldownManager.__index = CooldownManager;

CooldownManager.new = function(Entity: Player)
	local self = setmetatable({
		
		Parent = Entity;
		OnCooldown = {};
		
	}, CooldownManager);
	
	return self;
end;

function CooldownManager:Add(SkillName: string, Duration: number?)
	local Prev = self.OnCooldown[SkillName];
	if SkillName == "Dash" and game.ReplicatedStorage.WorldSettings.NoDashcooldowns.Value == true then
		Duration = 0.1;
	end
	
	
	if Duration then
		local EndTime = os.clock()+Duration;
		self.OnCooldown[SkillName] = EndTime;
	else
		self.OnCooldown[SkillName] = true;
	end;
	
	local function CheckCondition()
		local CurrentValue = self.OnCooldown[SkillName];
		if typeof(CurrentValue) == 'number' then
			return os.clock() >= self.OnCooldown[SkillName];
		else
			return not self.OnCooldown[SkillName];
		end;
	end;
	
	task.spawn(function()
		if Prev then return end;
		repeat task.wait(0.1) until CheckCondition();
		self.OnCooldown[SkillName] = nil;
	end);
end;

function CooldownManager:Stop(SkillName: string)
	self.OnCooldown[SkillName] = nil;
end;

function CooldownManager:Destroy()
	
end;

return CooldownManager;