local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Auxiliary = require(Shared.Utility.Auxiliary);
local EntityManager = require(ServerScriptService.Server.Components.Core.EntityManager);
local Wiki = require(Shared.Wiki);
local Object = require(SharedComponents.NexusObject);

local Spell = require(script.Parent):Extend();

return Spell;