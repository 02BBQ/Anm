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
return (function(Context, Category: string, Name: string, Target: Player?)
	Target = Target or Context.Executor;

	local Entity = EntityManager.Find(Target);
	if not Entity then
		return 'Could not find entity';
	end;
	
	local Success = Entity.Ownership:Clear(Category);
	
	if not Success then
		return `Error while clearing category {Category} from {Entity.Name}`;
	end;
	return `Successfully cleared {Category} from {Entity.Name}`;
end);