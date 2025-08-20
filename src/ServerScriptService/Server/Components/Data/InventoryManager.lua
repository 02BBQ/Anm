--//Variables
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local HttpService = game:GetService('HttpService');
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Server = ServerScriptService.Server;
local Storage = ServerStorage.Storage;

local Auxiliary = require(Shared.Utility.Auxiliary);
local EntityManager = require(Server.Components.Core.EntityManager);
local ItemFactory = require(Server.Components.Misc.ItemFactory);
local Wiki = require(Shared.Wiki);

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

local InventoryManager = {};

export type itemTable = {
	Name: string;
	Id: string;
	Attributes: {};
}

InventoryManager.__index = InventoryManager;

InventoryManager.new = function(Entity)
	return setmetatable({}, InventoryManager);
end;

InventoryManager.Add = function(player, name)
    if not player then
        return false;
    end

    if not Wiki.ItemInfo[name] then
        warn("Item not found in Wiki: " .. name);
        return false;
    end
    
    local id = HttpService:GenerateGUID(false);
    
    local Entity = EntityManager.Find(player);
	local item: itemTable = {};

    item = deepcopy(Wiki.ItemInfo[name]);
    item.Name = name;
    item.Id = id;
    item.Attributes = item.Attributes or nil;

    Entity.Data.Inventory[id] = {
        Name = item.Name;
        Attributes = item.Attributes;
    };

    ItemFactory.CreateItem(Entity, item);
end;

InventoryManager.Remove = function(player, id)
    if not player then
        return false;
    end

    local Entity = EntityManager.Find(player);
    assert(Entity, "Entity not found for player: " .. player.Name);
    Entity.Data.Inventory[id] = nil;
    
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:GetAttribute("Id") == id then
            tool:Destroy();
            break;
        end
    end
end

InventoryManager.RemoveByName = function(player, toolName)
    if not player then
        return false;
    end

    local tool;
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item.Name == toolName then
            tool = item;
            break;
        end
    end

    local id = tool:GetAttribute("Id");

    local Entity = EntityManager.Find(player);
    assert(Entity, "Entity not found for player: " .. player.Name);
    Entity.Data.Inventory[id] = nil;

    tool:Destroy();
end

return InventoryManager;
