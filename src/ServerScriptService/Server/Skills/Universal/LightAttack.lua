local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Server = ServerScriptService.Server;

local Wiki = require(Shared.Wiki);
local Attribute = require(Shared.Utility.Attribute);
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

local WeaponInfos = Wiki.WeaponInfo;

local maxCombo = 5;
local comboResetTime = 1.2;

return function(Params)
	local Args = Params.Args;

	local Entity = Params.Caster;
	local Character = Entity.Character;

	if Entity.Cooldowns.OnCooldown["LightAttack"] then return end;
	if not Entity.Combat:CanUse() then return end;
	if Args.held then return end;
    
    local WeaponInfo = WeaponInfos[Character._weapon or "Fist"];
	
	if tick() >= comboResetTime + Entity.Combat.ComboTick then
		Entity.Combat.Combo = 1
	end

	Entity.Combat:Active(false);

	Entity.Combat.ComboTick = tick();

	if Entity.Combat.Combo > maxCombo then
		Entity.Combat.Combo = 1;
	end

	local name = string.format("%s/%s",WeaponInfo.Animation, Entity.Combat.Combo);
	local Animation: AnimationTrack = Entity.Animator:Fetch(name);
	Animation:Play();
    Animation:AdjustSpeed(WeaponInfo.SwingSpeed or 1);
	
	local LightCancel = Entity.Combat:CreateCancel(1,function()
		Animation:Stop();
	end)

    Entity.Combat.Combo += 1

	Animation.Stopped:Connect(function()
		LightCancel.Remove();
		if Entity.Combat.Combo > maxCombo then
			Entity.Cooldowns:Add("LightAttack", comboResetTime)
		end
	end)

	Auxiliary.Shared.WaitForMarker(Animation, "hitreg");
	
	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.ignore = { Entity.Character.Rig };
	hitbox.size = WeaponInfo.Size;
	hitbox.offset = WeaponInfo.Offset;
	hitbox.Debug = true;
	hitbox.onTouch = function(EnemyEntity)
		print(EnemyEntity);
	end

	hitbox:FireFor(0.03);
	
	Sound.Spawn(WeaponInfo.SwingSounds[math.random(1,#WeaponInfo.SwingSounds)], Entity.Character.Root, 1, {
		["Pitch"] = math.random(9,11)/10;
	})

	if LightCancel.Cancelled then
		return;
	end

	Entity.Combat:Active(true);
end