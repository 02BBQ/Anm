--//Variables
local Lighting = game:GetService('Lighting');
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
local EnvironmentService = require(SharedComponents.Game.EnvironmentService);

--//Module
return (function(Context, NewValue: number, Day: number?)
	if NewValue >= 24 or NewValue <= 0 then
		return 'Value can only be a number between 0> and <24';
	end;
	
	if Day then
		if Day < 0 then
			return "Day can't be smaller than 0";
		end;
		Lighting:SetAttribute('CurrentDay', Day);
	end;
	Lighting:SetAttribute('ServerTime', EnvironmentService.GetDaysInMinutes()+NewValue*60);
	
	return `Set time to {NewValue}`;
end);