--//Variable
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Network = require(SharedComponents.Networking.Network);
local Information = require(SharedComponents.Data.Information);
local Auxiliary = require(Shared.Utility.Auxiliary);
local EnvironmentService = require(SharedComponents.Game.EnvironmentService);

local Categories = Information:Get('OwnershipCategories');

--//Module
local OwnershipManager = {};
OwnershipManager.__index = OwnershipManager;

OwnershipManager.new = function(Entity: {})
	local self = setmetatable({

		Parent = Entity;
		Unlocked = {};

	}, OwnershipManager);
	
	for _,v in Categories do
		self.Unlocked[v] = {};
	end;
	
	return self;
end;

function OwnershipManager:Update()
	self.Parent.Data.Unlocked = self.Unlocked;
end;

function OwnershipManager:Give(Category: string, Item: string)
	local CategoryList = self.Unlocked[Category];
	if not CategoryList then
		return;
	end;
	
	table.insert(CategoryList, Item);
	self:Update();
	
	return true;
end;

function OwnershipManager:Clear(Category: string)
	local CategoryList = self.Unlocked[Category];
	if not CategoryList then
		return;
	end;
	
	table.clear(CategoryList);
	return true;
end;

function OwnershipManager:Remove(Category: string, Item: string)
	local CategoryList = self.Unlocked[Category];
	if not CategoryList then
		return;
	end;
	
	local Index = table.find(CategoryList, Item);
	if Index then
		table.remove(CategoryList, Index);
	else
		warn(`Entity does not have {Item}`);
	end;
	self:Update();
	
	return true;
end;

function OwnershipManager:GetOwned(Category: string)
	local Unlocked = self.Unlocked[Category];
	assert(Unlocked, `Category {Category} does not exist`);
	
	return Unlocked;
end;

function OwnershipManager:Has(Category: string, Item: string)
	local CategoryList = self.Unlocked[Category];
	if not CategoryList then
		warn(`Category {Category} does not exist`);
		return;
	end;
	
	return table.find(CategoryList, Item) ~= nil;
end;

function OwnershipManager:Destroy()
	
end;

return OwnershipManager;