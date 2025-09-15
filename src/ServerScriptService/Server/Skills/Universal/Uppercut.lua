local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;
local Server = ServerScriptService.Server;

local Wiki = require(Shared.Wiki);
local Attribute = require(Shared.Utility.Attribute);
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

local WeaponInfos = Wiki.WeaponInfo;

return function(Params)
	local Args = Params.Args;

	local Entity = Params.Caster;
	local Character = Entity.Character;

	if Entity.Cooldowns.OnCooldown["Uppercut"] then return end;
	if not Character.Rig:GetAttribute("Dashing") then return end;
	--if not Entity.Combat._Active then return end;
	if Args.held then return end;
	Entity.Cooldowns:Add("Uppercut", 3);

	Entity.Combat:Active(false);
	
	local Start: AnimationTrack = Entity.Animator:Fetch("Universal/Uppercut");
	Start:Play();
	
	Auxiliary.Shared.WaitForMarker(Start, "hitreg");

	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(12,12,15);
	hitbox.offset = CFrame.new(0,0,-7);
	hitbox.debug = true;
	hitbox.onHit = function(EnemyEntity)
		local DamageData = {
			Damage = 10;
			Sound = "Hit/Punch"..math.random(1,3);
			Knockback = {Velocity = Entity.Character.Root.CFrame.LookVector * 20 + Vector3.new(0,75 ,0), Duration = 0.25};
			Ragdoll = {Duration = 2};
		}
		EnemyEntity.Combat:TakeDamage(DamageData, Entity);
	end

	hitbox:Fire();

	Entity.Combat:Active(true);

end