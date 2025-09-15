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
return (function(Context, Category: string, Name: string, Give: boolean?, Target: Player?)
	Target = Target or Context.Executor;
	
	local Entity = EntityManager.Find(Target);
	if not Entity then
		return 'Could not find entity';
	end;
	
	if Give then
		local Result = Entity.Ownership:Give(Category, Name);
		if not Result then
			return 'Error giving entry';
		end;
	else
		local Result = Entity.Ownership:Remove(Category, Name);
		if not Result then
			return 'Error removing entry';
		end;
	end;
	
	return `Successfully {(Give and 'Gave') or 'Removed'} {Category}/{Name} from {Entity.Name}`;
end);