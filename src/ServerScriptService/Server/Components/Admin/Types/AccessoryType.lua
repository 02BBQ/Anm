--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Information = require(SharedComponents.Data.Information);

--//Module
return (function(Registry)
	local Accessories = Information:Get('Accessories');
	local AccessoryList = Auxiliary.Shared.KeysToValues(Accessories);
	
	Registry:RegisterType('accessory', Registry.Cmdr.Util.MakeEnumType('Accessory', AccessoryList))
end);