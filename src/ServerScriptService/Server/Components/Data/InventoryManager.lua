--//Variables
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local serverScriptService = game:GetService('ServerScriptService');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Auxiliary = require(Shared.Utility.Auxiliary);
local EntityManager = require(serverScriptService.Server.Components.Game.EntityManager);

local InventoryManager = {};



InventoryManager.__index = InventoryManager;


InventoryManager.Add(function(Entity, item)
    if not player or not item then
        return false;
    end

    local inventory = self:GetInventory(player);
    if not inventory then
        return false;
    end

    table.insert(inventory, item);
    return true;
end)


return InventoryManager;
