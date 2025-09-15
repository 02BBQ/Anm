local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;
local Auxiliary = require(Shared.Utility.Auxiliary);

local Spell = require(script.Parent.Parent.Spell):Extend();
Spell.Name = script.Name;

function Spell:OnCast(Entity, Args)
	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(20,20,20);
	hitbox.offset = CFrame.new(0,0,-10);
	hitbox.debug = false;
	hitbox.onHit = function(EnemyEntity)
		EnemyEntity.Combat:TakeDamage({Damage = 25}, Entity);
	end

	hitbox:FireFor(0.7);

	Entity.VFX:Fire("HemoSaint/CrimsonBlitz", {Action = "start"});
end;


return Spell;