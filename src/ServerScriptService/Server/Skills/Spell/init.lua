local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Wiki = require(Shared.Wiki);
local Object = require(SharedComponents.NexusObject);
local Sound = require(Shared.Utility.SoundHandler);

local Spell = Object:Extend();
Sound:Cache();
local random = Random.new();

Spell.CastSign = 3;
Spell.Cooldown = 5;
Spell.Name = script.Name;
Spell.ManaCost = 0;
Spell.isHeldVariant = false;

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

function Spell:CastSigns(Entity, Args)
    if not Args["held"] then
        return 
    end;
    
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

    if not self.isHeldVariant then
        if Args["held"] == false then
            return;
        end;
    end;

    if not Entity.Combat:CanUse() then
        return;
    end

    Entity.Combat:Active(true);

    if not self:CanCast(Entity, Args) then return end;

    self:CastSigns(Entity, Args);

    self:OnCast(Entity, Args);
end

function Spell:CanCast(Entity, Args)
    if Entity.Cooldowns.OnCooldown[self.Name] then 
        return false;
    end;

    return true;
end

return Spell;	