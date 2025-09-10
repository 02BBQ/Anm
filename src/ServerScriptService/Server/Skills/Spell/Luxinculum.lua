local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Auxiliary = require(Shared.Utility.Auxiliary);

local Spell = require(ServerScriptService.Server.Skills.Spell):Extend();
Spell.Name = script.Name;
Spell.CastSign = 2;

function Spell:OnCast(Entity, Args)
    if not Args["held"] then return end;
	local Character = Entity.Character;
	
	local Start = Entity.Animator:Fetch("Spell/Luxin");
	Start:Play();
	
	Auxiliary.Shared.WaitForMarker(Start,"cast")

	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(30,30,70);
	hitbox.offset = CFrame.new(0,0,-25);
	hitbox.debug = true;
    hitbox.single = true;
	hitbox.onHit = function(EnemyEntity)
        Entity.VFX:Fire("Luxinculum", {Action = "start", Target = EnemyEntity:GetClientEntity()});
		Auxiliary.Shared.WaitForMarker(Start,"pull")
        local bp = Auxiliary.Shared.CreatePosition(EnemyEntity.Character.Root);
        bp.P = 80000;
        bp.Position = (Entity.Character.Root.CFrame * CFrame.new(0,0,-3)).p;
        game.Debris:AddItem(bp, 0.3);
        EnemyEntity.Combat:TakeDamage({Damage = 10}, Entity);
	end

	hitbox:Fire();
end;


return Spell;