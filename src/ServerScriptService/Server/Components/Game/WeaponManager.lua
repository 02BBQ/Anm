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

local WeaponModels = Storage.WeaponModel;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Attribute = require(Shared.Utility.Attribute);
local Wiki = require(Shared.Wiki);
local Skills = require(ServerScriptService.Server.Skills);
local WeaponInfo = Wiki.WeaponInfo;

local WeaponManager = {}
WeaponManager.__index = WeaponManager;

WeaponManager.__tostring = function(self )
	return self._weapon or "N/A";
end;

WeaponManager.new = function(Character)
	local self = setmetatable({
		Parent = Character;
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

function WeaponManager:Equip(name)
	local CharacterValues = Attribute(self.Parent.Rig);
	local Info = WeaponInfo[name];
	if CharacterValues.Equipped then return end; 
	if not Info then return end;
	local CharacterManager = self.Parent;

	if self._weapon then
		self._weapon = nil;
	end

	CharacterValues.Equipped = true;

	--self._weapon = require(ServerScriptService.Server.Weapon[self.Parent.Character.Weapon]).new(self.Parent);
	self._weapon = name;

	local WeaponModelBase = WeaponModels[self._weapon];
	if WeaponModelBase then 
		local WeaponModel = WeaponModelBase:Clone();
		for i,limb in pairs(WeaponModel:GetChildren()) do
			print(limb);
			local Handle = limb:FindFirstChildOfClass("MeshPart") or limb:FindFirstChildOfClass("Part");
			Handle:FindFirstChildOfClass("Motor6D").Part1 = CharacterManager.Rig[limb.Name];
			self._weaponModel = WeaponModel
		end
		WeaponModel.Parent = CharacterManager.Rig;
	end;

	-- local equipAnimID = Info.Anim.Equip;
	-- if equipAnimID then
	-- 	local Animation = Instance.new("Animation");
	-- 	Animation.AnimationId = equipAnimID;
	-- 	local AnimationTrack = CharacterManager.Rig.Humanoid:LoadAnimation(Animation);
	-- 	AnimationTrack:Play();
	-- 	AnimationTrack.Stopped:Wait();
	-- 	Animation:Destroy();
	-- end;

	-- local idleAnimID = Info.Anim.Idle;
	-- if idleAnimID then
	-- 	local Animation = Instance.new("Animation"); Animation.AnimationId = idleAnimID;
	-- 	local AnimationTrack = CharacterManager.Rig.Humanoid:LoadAnimation(Animation);
	-- 	AnimationTrack:Play();
	-- 	AnimationTrack.Stopped:Connect(function()	
	-- 		Animation:Destroy();
	-- 	end);

	-- 	self._animTracks["Idle"] = AnimationTrack;
	-- end;
end; 

function WeaponManager:LightAttack(Entity, Args)
	-- 무기가 없으면 기본 주먹 사용
	local LightAttackSkill = Skills["Universal/LightAttack"];
	LightAttackSkill({Caster = self.Parent.Parent,Args = Args});
	return;
end

function WeaponManager:Critical(Entity, Args)
	if not self._weapon then return end;
	self._weapon:Critical(Args);	
end

function WeaponManager:Unequip() 
	local CharacterValues = Attribute(self.Parent.Rig);
	local Info = WeaponInfo[self._weapon];
	if not CharacterValues.Equipped then return end;
	if not Info then return end;
	local CharacterManager = self.Parent;

	-- local equipAnimID = Info.Anim.Unequip;
	-- if equipAnimID then
	-- 	local Animation = Instance.new("Animation");
	-- 	Animation.AnimationId = equipAnimID;
	-- 	local AnimationTrack = CharacterManager.Rig.Humanoid:LoadAnimation(Animation);
	-- 	AnimationTrack:Play();
	-- 	AnimationTrack.Stopped:Wait();
	-- 	Animation:Destroy();
	-- end;

	-- self._weapon:Destroy();
	if self._weapon then
		self._weapon = nil;
	end

	if self._weaponModel then
		self._weaponModel:Destroy();
	end;

	if self._animTracks["Idle"] then
		self._animTracks["Idle"]:Stop();
	end;

	CharacterValues.Equipped = false;
end;

function WeaponManager:Destroy()
	pcall(self.Unequip, self)
	self = nil;
end;

return WeaponManager
