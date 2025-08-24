--//Variable
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local HttpService = game:GetService('HttpService');
local ServerStorage = game:GetService('ServerStorage')
local Debris = game:GetService('Debris');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Server = ServerScriptService.Server;
local Storage = ServerStorage.Storage;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Attribute = require(Shared.Utility.Attribute);
local Wiki = require(Shared.Wiki);
local WeaponInfo = Wiki.WeaponInfo;

local WeaponManager = {}
WeaponManager.__index = WeaponManager;

WeaponManager.__tostring = function(self )
	return self._weapon or "N/A";
end;

WeaponManager.new = function(Entity)
	local self = setmetatable({
		Parent = Entity;
		Equipped = false;
		_weaponModel = nil;
		_weapon = nil;

		_animTracks = {};
	}, WeaponManager);
	
	self:Initialize();
	
	return self;
end;

function WeaponManager:Initialize()
	--if not WeaponInfo[self.Parent.Character.Weapon] then return end;
end;

function WeaponManager:ToggleEquip()
	if self.Equipped then
		self:Unequip();
	else
		self:Equip();
	end;
end;

function WeaponManager:Equip()
	if self.Equipped then return end; 
	if not WeaponInfo[self.Parent.Character.Weapon] then return end;
	local CharacterManager = self.Parent.Character;
	local Info = WeaponInfo[self.Parent.Character.Weapon];

	if self._weapon then
		self._weapon = nil;
	end
	
	Debris:AddItem(self._weaponModel, 0);
	
	self.Equipped = self.Parent.Character.Weapon;
	CharacterManager.Rig:SetAttribute("Equipped", self.Equipped);

	self._weapon = require(ServerScriptService.Server.Weapon[self.Parent.Character.Weapon]).new(self.Parent);
	
	-- local WeaponModelBase = WeaponModels[self.Parent.Character.Weapon];
	-- if WeaponModelBase then 
	-- 	local WeaponModel = WeaponModelBase:Clone();
	-- 	for i,limb in pairs(WeaponModel:GetChildren()) do
	-- 		local Handle = limb:FindFirstChildOfClass("BasePart") or limb:FindFirstChildOfClass("Part");
	-- 		Handle:FindFirstChildOfClass("Motor6D").Part0 = CharacterManager.Rig[limb.Name];
	-- 		self._weaponModel = WeaponModel
	-- 	end
	-- 	WeaponModel.Parent = CharacterManager.Rig;
	-- end;

	local equipAnimID = Info.Anim.Equip;
	if equipAnimID then
		local effect = self.Parent.EffectReplicator:CreateEffect("UsingMove");
		local Animation = Instance.new("Animation");
		Animation.AnimationId = equipAnimID;
		local AnimationTrack = CharacterManager.Rig.Humanoid:LoadAnimation(Animation);
		AnimationTrack:Play();
		AnimationTrack.Stopped:Wait();
		Animation:Destroy();
		effect:Destroy();
	end;

	local idleAnimID = Info.Anim.Idle;
	if idleAnimID then
		local Animation = Instance.new("Animation"); Animation.AnimationId = idleAnimID;
		local AnimationTrack = CharacterManager.Rig.Humanoid:LoadAnimation(Animation);
		AnimationTrack:Play();
		AnimationTrack.Stopped:Connect(function()	
			Animation:Destroy();
		end);

		self._animTracks["Idle"] = AnimationTrack;
	end;
end; 

function WeaponManager:LightAttack(Entity, Args)
	-- 무기가 없으면 기본 주먹 사용
	if not self._weapon then
		local Skills = require(ServerScriptService.Server.Skills);
		local LightAttackSkill = Skills["Universal/LightAttack"];
		LightAttackSkill({Caster = self.Parent.Parent,Args = Args});
		return;
	end;
	self._weapon:LightAttack({Caster = self.Parent.Parent,Args = Args});	
end

function WeaponManager:Critical(Entity, Args)
	if not self._weapon then return end;
	self._weapon:Critical(Args);	
end

function WeaponManager:Unequip() 
	if not self.Equipped then return end;
	if not WeaponInfo[self.Parent.Character.Weapon] then return end;
	local CharacterManager = self.Parent.Character;
	local Info = WeaponInfo[self.Parent.Character.Weapon];

	local equipAnimID = Info.Anim.Unequip;
	if equipAnimID then
		local effect = self.Parent.EffectReplicator:CreateEffect("UsingMove");
		local Animation = Instance.new("Animation");
		Animation.AnimationId = equipAnimID;
		local AnimationTrack = CharacterManager.Rig.Humanoid:LoadAnimation(Animation);
		AnimationTrack:Play();
		AnimationTrack.Stopped:Wait();
		Animation:Destroy();
		effect:Destroy();
	end;

	self._weapon:Destroy();
	if self._weapon then
		self._weapon = nil;
	end

	-- if self._weaponModel then
	-- 	self._weaponModel:Destroy();
	-- end;

	if self._animTracks["Idle"] then
		self._animTracks["Idle"]:Stop();
	end;

	self.Equipped = nil;
	CharacterManager.Rig:SetAttribute("Equipped", self.Equipped);
end;

function WeaponManager:Destroy()
	pcall(self.Unequip, self)
	self = nil;
end;

return WeaponManager
