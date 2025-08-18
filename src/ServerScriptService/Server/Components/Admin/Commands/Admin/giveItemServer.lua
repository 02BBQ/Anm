--//Variables
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local Players = game:GetService('Players');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local EntityManager = require(Components.Core.EntityManager);
local InventoryManager = require(Components.Data.InventoryManager);

--//Module
return (function(Context, Item: string, Target: Player?)
	Target = Target or Context.Executor;
	
	InventoryManager.Add(Target, Item);
	
	return `Successfully gave {Item} to {Target.Name}.`;
end);