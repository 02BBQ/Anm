--//Variables
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService('RunService');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

local Bridge = require(Shared.Package.BridgeNet2);
local SharedCooldowns = require(script.SharedCooldowns);

local function FindShared(SkillName: string)
	for _,v in SharedCooldowns do
		local Ind = table.find(v, SkillName);
		if Ind then
			return v[(Ind == 1 and 2) or 1], v[3];
		end;
	end;
end;

--//Module
local CooldownManager = {};
CooldownManager.__index = CooldownManager;

CooldownManager.new = function(Entity: {})
	local self = setmetatable({
		
		Parent = Entity;
		OnCooldown = {};
		
		Toggled = {};
		
		Disabled = false;
		
	}, CooldownManager);
	
	return self;
end;

function CooldownManager:Add(SkillName: string, Duration: number?, Absolute: boolean?, Unlinked: boolean?)
	if self.Disabled and not Absolute then --or (game.ReplicatedStorage.WorldSettings.NoDashcooldowns.Value and SkillName == "Dash") and not Absolute then
		return;
	end;
	
	if not Unlinked then
		local LinkedSkill, Factor = FindShared(SkillName);
		if LinkedSkill then
			self:Add(LinkedSkill, Duration*Factor, false, true);
		end;
	end;
	
	local Prev = self.OnCooldown[SkillName];
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
		if Prev then
			return
		end;
		
		repeat
			task.wait();	
		until CheckCondition();
		
		self:Reset(SkillName);
		--self.OnCooldown[SkillName] = nil;
	end);
	
	if self.Parent.Player and Duration then
		--Network:Send('Cooldown', {Skill = SkillName, Duration = Duration}, false, self.Parent.Player);
	end;
end;

function CooldownManager:Reset(Target: string?)
	if not Target then
		for v in self.OnCooldown do
			self:_Stop(v);
		end;
	else
		self:_Stop(Target);
	end;
end;

function CooldownManager:_Stop(SkillName: string)
	self.OnCooldown[SkillName] = nil;
	if self.Parent.Player then
		--Network:Send('Cooldown', {Skill = SkillName, Reset = true}, false, self.Parent.Player);
	end;
end;

function CooldownManager:Disable(SkillName: string)
	local Tab = self.Toggled[SkillName];
	if not Tab then
		self.Toggled[SkillName] = {};
		Tab = self.Toggled[SkillName];
	end;
	
	table.insert(Tab, true);
	if self.Parent.Player then
		--Network:Send('SkillToggled', {Skill = SkillName, State = true}, false, self.Parent.Player);
	end;
end;

function CooldownManager:Enable(SkillName: string)
	local Tab = self.Toggled[SkillName];
	if not Tab then
		return;
	end;
	
	if #Tab <= 1 then
		self.Toggled[SkillName] = nil;
	else
		table.remove(Tab, 1);
	end;
	
	if not self.Toggled[SkillName] and self.Parent.Player then
		--Network:Send('SkillToggled', {Skill = SkillName}, false, self.Parent.Player);
	end;
end;

function CooldownManager:Destroy()
	self = nil;
end;

return CooldownManager;