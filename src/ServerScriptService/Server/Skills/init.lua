local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Check1 = {};
local Check2 = {};
local Cache = {};

local Shared  = ReplicatedStorage.Shared;

local Auxiliary = require(Shared.Utility.Auxiliary);

local Childrens, LastIndex = script:GetDescendants();
while true do
	local index, value = next(Childrens, LastIndex);
	if not index then
		break;
	end;
	LastIndex = index;
	if value:IsA("ModuleScript") then
		local Path = value.Name;--Auxiliary.Shared.GetPath(value, script)
		table.insert(Check1, value);
		task.spawn(function()
			Cache[Path] = require(value);
			table.insert(Check2, value);
		end);
	end;	
end;

return Cache