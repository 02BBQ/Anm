--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Information = require(SharedComponents.Data.Information);
local PurchaseService = require(SharedComponents.Core.PurchaseService);

--//Module
return (function(Registry)
	local Passes = {};
	for _,Product in PurchaseService.Products do
		if Product.Category ~= 'Passes' then
			continue;
		end;
		
		table.insert(Passes, Product.Name);
	end;
	
	Registry:RegisterType('gamepasses', Registry.Cmdr.Util.MakeEnumType('Gamepasses', Passes));
end);