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

--//Module
return (function(Context, AccessoryName: string, IsWearing: boolean?, Target: player?)
	if IsWearing == nil then
		IsWearing = true;
	end;
	
	local Entity = EntityManager.Find(Target or Context.Executor);
	if not Entity then
		return 'Could not find entity';
	end;
	
	Entity.Accessories:Equip(AccessoryName, true, not IsWearing);
	return `{(IsWearing and 'Equipped') or 'Unequipped'} {AccessoryName}`;
end);