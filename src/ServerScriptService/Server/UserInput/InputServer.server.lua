local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServiceSciriptService = game:GetService("ServerScriptService");
local Shared = ReplicatedStorage.Shared;

local bridgeNet = require(Shared.Components.BridgeNet2);
local entityManager = require(ServiceSciriptService.Server.Components.Core.EntityManager);
local Moveset = ServiceSciriptService.Server.Components.Action.Moveset;

local _use = bridgeNet.ServerBridge("_use");

local skillCache = {}

--local function loadSkills()
--	for _, classFolder in pairs(Moveset:GetChildren()) do
--		if classFolder:IsA("Folder") then
--			skillCache[classFolder.Name] = {}
--			for _, skillModule in pairs(classFolder:GetChildren()) do
--				if skillModule:IsA("ModuleScript") then
--					skillCache[classFolder.Name][skillModule.Name] = require(skillModule)
--				end
--			end
--		end
--	end
--end

--loadSkills();

--_use:Connect(function(player: Players?, Params: {})
--	local Entity = entityManager.Find(player);
--	Params.Caster = Entity;

--	local TargetClass = Params.class or "Universal";
--	local Action = Params[1];
	
--	if not skillCache[TargetClass]  then
--		warn("Class not found: " .. TargetClass)
--		return;
--	end
	
--	if not skillCache[TargetClass][Action] then
--		warn("Action not found: " .. Action)
--		return;
--	end
	
--	--print("Found Skill!")
	
--	skillCache[TargetClass][Action](Params);
--end)