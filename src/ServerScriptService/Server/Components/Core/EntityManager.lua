--//Variables
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerStorage = game:GetService("ServerStorage");

local Components = ServerScriptService.Server.Components
local EntityTemplates = ServerStorage
local Storage = ServerStorage.Storage;

local ProfileHandler = require(Components.Data.ProfileHandler);
local CombatManager = require(Components.Game.CombatManager);
local CharacterManager = require(Components.Core.CharacterManager);
local VFXManager = require(Components.Game.VFXManager);
local CooldownManager = require(Components.ServerUtility.CooldownManager);
local AnimatorManager = require(ReplicatedStorage.Shared.Utility.Animator);

local Hitbox = require(Components.ServerUtility.Hitbox);

local Trove = require(ReplicatedStorage.Shared.Utility.Trove)

--//Module
local Entities = {};
Entities.__index = Entities; 
Entities.__tostring = function(self )
	return self.Name;
end;

local LEADERSTATS_INSTANCES = {
	[1] = 'Kills';
	[2] = 'Join';
};

export type Entity = {
	Player: Player?;
}

Entities.Stored = {};
Entities.new = function(PresetInfo, PlayerObject: Player?)
	local self = setmetatable({
		
		_Connections = {};
		_Class = 'Entity';
		_Trove = Trove.new();

		EffectReplicator = nil;

		Name = 'N/A';
		
		Valid = true;
		Ready = false;

		IsAlive = true;
		
		Player = PlayerObject;
		
	}, Entities);
	
	if self.Player then
		self.ProfileHolder = ProfileHandler.new(PlayerObject);
	end;
	
	self.Data = (self.ProfileHolder and self.ProfileHolder.Data);
	if not self.Data then
		self.Data = {};
		PresetInfo = PresetInfo or {};
		for i,v in ProfileHandler.Constants.DataTemplate do
			self.Data[i] = PresetInfo[i] or v;
		end;
	end;
	
	self.Animator = self._Trove:Add(AnimatorManager.new(self));
	self.Character = self._Trove:Add(CharacterManager.new(self));
	self.VFX = self._Trove:Add(VFXManager.new(self));
	
	self.Combat = (CombatManager.new(self));
	self.Cooldowns = (CooldownManager.new(self));
	
	if self.Player then
		self.Leaderstats = Instance.new('Folder');
		self.Leaderstats.Parent = self.Player;
		
		self.Leaderstats.Name = 'leaderstats';
		
		for i = 1,#LEADERSTATS_INSTANCES do
			local InstName = LEADERSTATS_INSTANCES[i];
			Instance.new('NumberValue', self.Leaderstats).Name = InstName;
		end;
		
		self:UpdateLeaderstats();
		self.Name = self.Player.DisplayName or self.Player.Name;
	end;
	
	self.Ready = true;
	self.Stored[self] = true;
	
	return self;
end;

function Entities:CreateHitbox()
	return Hitbox.new(self);
end;

function Entities:SetRace(race)
	self.Data.Race = race;
end

function Entities:GetClientEntity()
	return {
		Player = self.Parent.Player;
		Character = {
			Humanoid = self.Parent.Character.Humanoid;
			Root = self.Parent.Character.Root;
			Rig = self.Parent.Character.Rig;	
		};
	};
end;

Entities.Spawn = function(TemplateName: Model)
	local Template = EntityTemplates:FindFirstChild(TemplateName);
	assert(TemplateName, 'Template was not found!');

	local NewEntity = Entities.new();
	NewEntity.Character.Template = Template;
	NewEntity.Character.Rig = Template : Clone();

	return NewEntity;
end;

function Entities:HandleCharacter(effectReplicator)
	self.EffectReplicator = effectReplicator;
	self.Character:InitCharacter();
end

function Entities:UpdateLeaderstats()
	self.Leaderstats['Kills'].Value = 0;
	--self.Leaderstats['Join'].Value = self.Data.TimesVisited + 1;
end;

function Entities:Destroy()
	for _,v: RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;

	_G.RemoveReplicator(self.Player or self.Character.Rig);

	self.ProfileHolder:Clean();
	self._Trove:Destroy();
	
	self.Character:Destroy()

	self.Valid = false;
	self.Stored[self] = nil;
end;

function Entities.Find(Inst: (Player | Model))
	local CheckingMethods = {
		Player = function(v)
			return v.Player == Inst;
		end;
		Character = function(v)
			if not v.Character then return end;
			return v.Character.Rig == Inst;
		end;
	};

	local Method = (Inst:IsA('Player') and 'Player') or (Inst:IsA('Model') and 'Character');
	local MethodFunc = CheckingMethods[Method];

	assert(MethodFunc, 'Search method not found! Did you pass an instance?');

	for v in Entities.Stored do
		local Result = MethodFunc(v);
		if Result then return v end;
	end;
end;


return Entities;