local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Auxiliary = require(Shared.Utility.Auxiliary);
local EntityManager = require(ServerScriptService.Server.Components.Core.EntityManager);
local Wiki = require(Shared.Wiki);
local Object = require(SharedComponents.NexusObject);
local Sound = require(Shared.Utility.SoundHandler);

local Spell = Object:Extend();
Sound:Cache();
local random = Random.new();

Spell.CastSign = 3;
Spell.Cooldown = 5;
Spell.ManaCost = 0;

function Spell:OnCast()
end

function Spell:ManaCheck() 
	-- local M = self.Character:FindFirstChild("__Mana")
	-- if M and M.Value >= self.ManaCost then
	-- 	return self.ManaCost
	-- else
	-- 	return
	-- end
    return;
end

function Spell:CastSigns(Entity)
    for i = 1, self.CastSign do
        local CastTrack: AnimationTrack = Entity.Animator:Fetch('Universal/Cast/Sign'..i);
        Sound.Spawn("clickfast", Entity.Character.Root, 2, {
            Pitch = random:NextNumber(0.85, 1.15),
        });

        CastTrack:Play();
        CastTrack:AdjustSpeed(2);
        CastTrack.Stopped:Wait();
    end
end

function Spell:ActivateSpell(Entity, Args)
	assert(Entity, "Entity is not set for the spell");

    if not Entity.Combat:CanUse() then
        return;
    end

    Entity.Combat:Active(false);

    Spell:CastSigns(Entity);

    Entity.Combat:Active(true);

    self:OnCast(Entity, Args);
end

return Spell;	