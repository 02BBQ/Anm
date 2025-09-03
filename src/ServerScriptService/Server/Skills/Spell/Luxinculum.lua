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

	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(10,10,50);
	hitbox.offset = CFrame.new(0,0,-25);
	hitbox.debug = true;
    hitbox.single = true;
	hitbox.onHit = function(EnemyEntity)
        Entity.VFX:Fire("Luxinculum", {Action = "start", Target = EnemyEntity:GetClientEntity()});
        task.delay(0.3, function()
            local bp = Auxiliary.Shared.CreatePosition(EnemyEntity.Character.Root);
            bp.Position = (Entity.Character.Root.CFrame * CFrame.new(0,0,-3)).p;
            EnemyEntity.Combat:TakeDamage({Damage = 25}, Entity);
        end)
	end

	hitbox:Fire();
end;


return Spell;