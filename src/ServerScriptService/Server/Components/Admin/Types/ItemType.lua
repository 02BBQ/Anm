--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local ItemInfo = require(Shared.Wiki).ItemInfo;

--//Module
return (function(Registry)
	local RaceList = {};
	
	for _ in pairs(ItemInfo) do
		table.insert(RaceList, _);
	end

	Registry:RegisterType('item', Registry.Cmdr.Util.MakeEnumType('Item', RaceList))
end);