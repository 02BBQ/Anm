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

	local Start = Entity.Animator:Fetch("Fighter/RapidPunches");
    Start:Play();
    Start:AdjustSpeed(1.2);
end;


return Spell;