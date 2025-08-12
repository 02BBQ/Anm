local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared;
local InfoModules = ReplicatedStorage.Shared.InfoModules
local CharacterControls = require(InfoModules.CharacterControls)
local Attribute = require(InfoModules.Attribute)
local Animations = ReplicatedStorage.Shared.Assets.Animations
local Functions = require(ReplicatedStorage.Shared.SystemModules.Functions)
local Assets = ReplicatedStorage.Shared.Assets
local WeaponsInfo = require(ReplicatedStorage.Shared.WeaponsInfo)
local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary);

local lastClickTime = 0
local maxCombo = 4
local comboResetTime = 1
local cooldown = 1;

return function(Params)
	local SkillName = script.Name;

	local Entity = Params.Caster;
	local Character = Entity.Character;
	local CharacterValues = Attribute(Character);
	local Humanoid = Character.Humanoid;

	if Entity.Cooldowns.OnCooldown[SkillName] then return end;
	if not Entity.Combat:IsActive() then return end;
	
	Entity.Combat.Acting = true;

	-- 공격 시작
	local WeaponInfo : WeaponsInfo.weaponInfo = WeaponsInfo[Character.Rig:GetAttribute("Weapon") or "Fist"]


	local name = WeaponInfo.Critical.Animation;
	
	local Animation: AnimationTrack = Entity.Animator:Fetch(name);
	Animation:Play();

	local LightCancel = Entity.Combat:CreateCancel(1,function()
		Animation:Stop();
		Entity.Combat.Acting = false
	end)

	Animation.Stopped:Connect(function()
		LightCancel.Remove();
		Entity.Cooldowns:Add(SkillName,cooldown)
	end)

	Auxiliary.Shared.WaitForMarker(Animation, "Hit");

	if LightCancel.Cancelled then
		return;
	end

	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.ignore = { Entity.Character.Rig };
	hitbox.size = WeaponInfo.Critical.Hitbox.Size;
	hitbox.offset = WeaponInfo.Critical.Hitbox.Offset;
	hitbox.Debug = true;
	hitbox.onTouch = function(EnemyEntity)
		print(EnemyEntity);
	end

	hitbox:Fire();

	if WeaponInfo.Critical.Endlag then
		task.wait(WeaponInfo.Critical.Endlag);
	end

	Entity.Combat.Acting = false
end