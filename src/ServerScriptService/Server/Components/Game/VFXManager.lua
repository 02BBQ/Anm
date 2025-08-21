--//Variable
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local Network = require(SharedComponents.BridgeNet2);
local Auxiliary = require(Shared.Utility.Auxiliary);

local _effect = Network.ServerBridge('_effect');

--//Module
local VFXManager = {};
VFXManager.__index = VFXManager;

VFXManager.new = function(Entity: {})
	local self = setmetatable({
		
		Parent = Entity;
		
	}, VFXManager);
	
	return self;
end;

--Makeshift entity object for client-side
function VFXManager:GetClientEntity()
	return {
		Player = self.Parent.Player;
		Character = {
			Humanoid = self.Parent.Character.Humanoid;
			Root = self.Parent.Character.Root;
			Rig = self.Parent.Character.Rig;	
		};
	};
end;

function VFXManager:Fire(ModulePath: string, Data: {}, Receiving: {} | Player | nil)
	local ClientEntity = self:GetClientEntity();

	if not Receiving then
		Receiving = Network.AllPlayers();
	end

	if Data then
		for i,v: {}? in Data do
			if typeof(v) ~= 'table' then continue end;
			if v._Class ~= 'Entity' then continue end;
			Data[i] = v.VFX:GetClientEntity();
		end;
	end;

	--Send to designated VFX channel
	Data["Caster"] = ClientEntity
	Data["Origin"] = ClientEntity.Character.Root
	_effect:Fire(Receiving, {ModulePath, Data})
end;

function VFXManager:Destroy()
	
end;

return VFXManager;