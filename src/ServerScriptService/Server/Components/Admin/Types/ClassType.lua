--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

local Auxiliary = require(Shared.Utility.Auxiliary);

--//Module
return (function(Registry)
	local ClassList = {"FallenOne"};

	Registry:RegisterType('class', Registry.Cmdr.Util.MakeEnumType('Class', ClassList))
end);