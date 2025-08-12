local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage.Shared;

local Auxiliary = require(Shared.Utility.Auxiliary);

local module = {}

for _, skill: ModuleScript in pairs(script:GetDescendants()) do
	if not skill:IsA("ModuleScript") then continue end;
	module[Auxiliary.Shared.GetPath(skill, script)] = require(skill);
end

return module
