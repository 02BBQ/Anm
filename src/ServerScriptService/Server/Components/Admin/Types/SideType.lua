--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Information = require(SharedComponents.Data.Information);

--//Module
return (function(Registry)
	Registry:RegisterType('leftright', Registry.Cmdr.Util.MakeEnumType('LeftRight', {'Left', 'Right'}))
end);