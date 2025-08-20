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
local Attribute = require(Shared.Utility.Attribute);
local EntityManager = require(Server.Components.Core.EntityManager);
local Wiki = require(Shared.Wiki);

local Weapon = {};
Weapon.__index = Weapon;

function Weapon.new(Entity)
    local self = setmetatable({}, Weapon);
    self.Parent = Entity;
    self.Stats = {};
    
    
end

return Weapon;