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

	Entity.Combat:Active(false);
    Character.Rig:SetAttribute('Dashing', true);
	
	task.wait(Auxiliary.Wiki.Default.Combat.DashDuration or 0.5);

    Character.Rig:SetAttribute('Dashing', false);
	Entity.Combat:Active(true);
end