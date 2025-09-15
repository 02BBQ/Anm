--//Variables
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local HttpService = game:GetService('HttpService');
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;
local Server = ServerScriptService.Server;
local Storage = ServerStorage.Storage;

local Auxiliary = require(Shared.Utility.Auxiliary);
local Wiki = require(Shared.Wiki);
local Attribute = require(Shared.Utility.Attribute);

local Factory = {};

export type itemTable = {
	Name: string;
	Id: string;
	Attributes: {};
}

Factory.CreateItem = function(Entity, item: itemTable)
    assert(Entity, "Entity is nil");
    assert(Entity.Player, "Player is nil");
	local info = Wiki.ItemInfo[item.Name];
	-- assert(info, "Item not found in Wiki: " .. item.Name);

    local Tool = Storage.Tools:FindFirstChild(item.Name) or Storage.Tools.Tool;
    Tool = Tool:Clone();
    local ToolAttributes = Attribute(Tool);
    Tool.Name = item.Name;

    if item.Id then ToolAttributes["Id"] = item.Id; end
    ToolAttributes["Type"] = item.Type or "Tool";

    if item.Attributes then
        local AttFolder = Tool:FindFirstChild("Attributes");
        if not AttFolder then
            AttFolder = Instance.new("Folder");
            AttFolder.Name = "Attributes";
            AttFolder.Parent = Tool;
        end
        for key, value in pairs(item.Attributes) do
            AttFolder:SetAttribute(key, value);
        end
    end

    Tool.Parent = Entity.Player.Backpack;
end

return Factory;