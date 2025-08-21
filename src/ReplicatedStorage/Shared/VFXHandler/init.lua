local Check1 = {};
local Check2 = {};
local Utils = {};

local Shared  = game:GetService("ReplicatedStorage").Shared;

local Auxiliary = require(Shared.Utility.Auxiliary);

local Childrens, LastIndex = script:GetDescendants();

while true do
	local index, value = next(Childrens, LastIndex);
	if not index then
		break;
	end;
	
	LastIndex = index;
	if value:IsA("ModuleScript") then
		local Path = Auxiliary.Shared.GetPath(value, script)
		table.insert(Check1, value);
		spawn(function()
			Utils[Path] = require(value);
			table.insert(Check2, value);
		end);
	end;	
end;
while #Check1 ~= #Check2 do
	task.wait();	
end;

local metatable = {};
function metatable.__index(p1, Util)
	return Utils[Util] or require(script[Util]);
end;
return setmetatable({}, metatable);