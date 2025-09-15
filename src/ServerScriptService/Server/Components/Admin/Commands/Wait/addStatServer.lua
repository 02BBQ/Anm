--//Variables
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local Players = game:GetService('Players');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

local Auxiliary = require(Shared.Utility.Auxiliary);
local EntityManager = require(Components.Core.EntityManager);

--//Module
return (function(Context, StatName: string, Amount: number?, Target: Player?)
	Target = Target or Context.Executor;
	Amount = Amount or 1;

	local Entity = EntityManager.Find(Target);
	if not Entity then
		return 'Could not find entity';
	end;

	Entity:AddStat(StatName, Amount);
	return `Successfully increased {StatName} by {Amount} for {Entity.Name}`;
end);