--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

local Auxiliary = require(Shared.Utility.Auxiliary);
local RaceManager = require(SharedComponents.Race);

--//Module
return (function(Registry)
	local RaceList = {};
	local Races = RaceManager.Races;
	
	for _,Race in pairs(Races) do
		table.insert(RaceList, _);
	end

	Registry:RegisterType('race', Registry.Cmdr.Util.MakeEnumType('Race', RaceList))
end);