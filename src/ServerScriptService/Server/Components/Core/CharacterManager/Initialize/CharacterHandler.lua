--//Variable
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService("ServerStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');

local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary);
local Signal = require(ReplicatedStorage.Shared.Utility.Signal);
local Wiki = require(ReplicatedStorage.Shared.Wiki);
local ItemFactory = require(ServerScriptService.Server.Components.Misc.ItemFactory);

local CharacterHandler = {}

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

CharacterHandler.Initialize = function(Entity)
    

	for id,v in pairs(Entity.Data.Inventory) do
		local item = {};
		item = deepcopy(Wiki.ItemInfo[v.Name]);
		item.Name = v.Name;
        item.Type = v.Type; 
		item.Id = id;
		item.Attributes = v.Attributes;
        
		ItemFactory.CreateItem(Entity, item);
	end;

    for id,v in pairs(Entity.Data.Spells) do
		local item = {};
		item.Name = id;
        item.Type = "Spell";
		item.Attributes = v;

		ItemFactory.CreateItem(Entity, item);
	end;
end;

return CharacterHandler;