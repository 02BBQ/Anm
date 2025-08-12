local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
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
local Damage = require(SSS.Server.Components.Game.DamageManager)

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
	
	Entity.Combat.Combo = 
		tick() >= comboResetTime + Entity.Combat.LastLightAttack and 1 or Entity.Combat.Combo + 1
	
	Entity.Combat.LastLightAttack = tick();
	
	if Entity.Combat.Combo > maxCombo then
		Entity.Combat.Combo = 1;
	end
	
	local name = WeaponInfo.LightAttack.Animation.."/M"..Entity.Combat.Combo;
	print(name)
	local Animation: AnimationTrack = Entity.Animator:Fetch(name);
	Animation:Play();
	
	local LightCancel = Entity.Combat:CreateCancel(1,function()
		Animation:Stop();
		Entity.Combat.Acting = false
	end)
	
	Animation.Stopped:Connect(function()
		LightCancel.Remove();
		if Entity.Combat.Combo >= maxCombo then
			Entity.Cooldowns:Add(SkillName,cooldown)
		end
	end)
	
	Auxiliary.Shared.WaitForMarker(Animation, "Hit");
	
	if LightCancel.Cancelled then
		return;
	end
	
	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.ignore = { Entity.Character.Rig };
	hitbox.size = WeaponInfo.LightAttack.Hitbox.Size;
	hitbox.offset = WeaponInfo.LightAttack.Hitbox.Offset;
	hitbox.Debug = true;
	hitbox.onTouch = function(EnemyEntity)
		print(EnemyEntity);
		Damage({
			victim = EnemyEntity,
			Damage = WeaponInfo.LightAttack.Damage,
			hit_type = WeaponInfo.HitType,
			stun = WeaponInfo.LightAttack.stun;
		})
	end
	
	hitbox:FireFor(0.15);
	
	if WeaponInfo.LightAttack.Endlag then
		task.wait(WeaponInfo.LightAttack.Endlag);
	end
	
	Entity.Combat.Acting = false
	
	
	
	
	
	--local now = tick()
	---- 시간 안에 누르면 콤보 이어감
	--if now - CharacterValues.LMBPrevious <= comboResetTime then
	--	CharacterValues.Combo += 1;
	--else
	--	CharacterValues.Combo = 1;
	--end
	--CharacterValues.LMBPrevious = tick()

	--if CharacterValues.Combo > maxCombo then
	--	CharacterValues.Combo = 1;
	--end
	--CharacterValues.CanBeCancelled = true
	--CharacterValues.Acting = true
	--Functions.MakeSfx(Assets.Sounds.M1Swings.M1,Character.HumanoidRootPart,true,3);
	--local Animation
	--if not Character:GetAttribute("Weapon") then
	--	Animation = Humanoid.Animator:LoadAnimation(Animations["Melee_M1"]["M"..CharacterValues.Combo])
	--else
	--	Animation = Humanoid.Animator:LoadAnimation(Animations[Character:GetAttribute("Weapon")]["M"..CharacterValues.Combo])
	--end
	--Animation.Name = "M1"
	--StopPlayingAnimations(Humanoid,"M1")

	--Animation:Play()
	--if Character:GetAttribute("Weapon") then
	--	Animation:AdjustSpeed(WeaponData.SwingSpeed)
	--end
	--Cancel = CharacterValues.Changed("CanBeCancelled", function()
	--	Cancel:Disconnect()

	--	Animation:Stop()
	--end)

	--local M1Con M1Con = Animation:GetMarkerReachedSignal("Hit"):Connect(function()
	--	Cancel:Disconnect()
	--	M1Con:Disconnect()
	--	local Data = {
	--		Chr = Character;
	--		Origin = Character.HumanoidRootPart;
	--		Size = Vector3.new(5.5,5.5,8);
	--		Distance = CFrame.new(0,0,-4);
	--		I = 4;
	--		HitType = "Blunt";
	--		Ragdoll = 0;
	--		VelDur = 0.12;
	--		Vel = 12;
	--		Damage = 3;
	--		Stun = 0.4;
	--	}

	--	if Character:GetAttribute("Weapon") then
	--		Data.HitType = WeaponData.HitType;
	--		Data.Damage = WeaponData.M1Dmg;
	--	end
	--	if CharacterValues.Combo > 3 then
	--		Data.Ragdoll = 1.2;
	--	end
	--	Hitbox.Create(Data)
	--end)

	--local ReducedSpeed = (Character:GetAttribute("WalkSpeed")/1.4)
	--CharacterControls.ReduceSpeed(Character,ReducedSpeed,0.25)

	--if CharacterValues.Combo > 3 then
	--	CharacterControls.AddCooldown(Character,SkillName,1.6)
	--end

	--task.wait(0.4)
	--CharacterValues.Acting = false
end