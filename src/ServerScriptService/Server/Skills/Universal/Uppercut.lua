local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Server = ServerScriptService.Server;

local Wiki = require(Shared.Wiki);
local Attribute = require(Shared.Utility.Attribute);
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

local WeaponInfos = Wiki.WeaponInfo;

local maxCombo = 5;
local comboResetTime = 1.2;

return function(Params)
	local Args = Params.Args;

	local Entity = Params.Caster;
	local Character = Entity.Character;

	Entity.Combat:Active(false);
	
	local Start: AnimationTrack = Entity.Animator:Fetch("Universal/Uppercut");
	Start:Play();

	Entity.Combat:Active(true);
end