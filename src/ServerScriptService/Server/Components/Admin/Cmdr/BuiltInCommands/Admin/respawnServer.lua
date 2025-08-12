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
return function (Context, players)
	players = players or {Context.Executor};
	
	for _, player in pairs(players) do
		local Entity = EntityManager.Find(player);
		if not Entity then
			continue;
		end;

		Entity.Character:Respawn();
	end

	return ("Killed %d players."):format(#players)
end