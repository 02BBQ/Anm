--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Information = require(SharedComponents.Data.Information);

--//Module
return (function(Registry)
	local Categories = Information:Get('OwnershipCategories');
	Registry:RegisterType('ownershipcategory', Registry.Cmdr.Util.MakeEnumType('OwnershipCategory', Categories));
end);