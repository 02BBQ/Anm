local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Auxiliary = require(Shared.Utility.Auxiliary);

local Spell = require(ServerScriptService.Server.Skills.Spell):Extend();
Spell.Name = script.Name;
Spell.CastSign = 0;

function Spell:OnCast(Entity, Args)
	if not Args["held"] then return end;

	local Start = Entity.Animator:Fetch("Fighter/StrongPunch");
	Start:Play();
	
	Auxiliary.Shared.WaitForMarker(Start, "hit");
	
	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(12,12,15);
	hitbox.offset = CFrame.new(0,0,-7);
	hitbox.debug = true;
	hitbox.onHit = function(EnemyEntity)
		EnemyEntity.Combat:TakeDamage({
			Ragdoll = {Duration = 2};
			Knockback = {Velocity = Entity.Character.Root.CFrame.LookVector * 45 + Vector3.new(0,50,0)};
			Damage = 12;
			BlockBreak = true;
		}, Entity);
	end

	hitbox:FireFor(0.1);
end;


return Spell;