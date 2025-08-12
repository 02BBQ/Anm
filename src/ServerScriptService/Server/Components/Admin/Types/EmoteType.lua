--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Information = require(SharedComponents.Data.Information);

--//Module
return (function(Registry)
	local Emotes = Information:Get('Emotes');
	local EmoteList = Auxiliary.Shared.KeysToValues(Emotes);
	
	Registry:RegisterType('emote', Registry.Cmdr.Util.MakeEnumType('Emote', EmoteList))
end);