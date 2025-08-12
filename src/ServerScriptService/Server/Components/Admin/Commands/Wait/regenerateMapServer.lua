--//Variables
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local Players = game:GetService('Players');

local Server = ServerScriptService:WaitForChild('Server');
local Components = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local EntityManager = require(Components.Core.EntityManager);

local Voxelizer = require(Components.Game.DestructionService.Voxelizer);

--//Module
return (function(Context, OnTop: boolean?)
	Voxelizer:ResetAll();
end);