local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;
local Auxiliary = require(Shared.Utility.Auxiliary);

local Spell = require(ServerScriptService.Server.Skills.Spell):Extend();
Spell.Name = script.Name;
Spell.CastSign = 0;

function Spell:OnCast(Entity, Args)
	if not Args["held"] then return end;
	if not Entity.Combat:CanUse() then return end;

	local Start : AnimationTrack = Entity.Animator:Fetch("Fallen/Shatter");
	Start:Play();
	
	Start:AdjustSpeed(1.25);
	
	Entity.VFX:Fire("Fallen/Shatter", {Action = "start", ID = Start.Animation.AnimationId});
end;


return Spell;