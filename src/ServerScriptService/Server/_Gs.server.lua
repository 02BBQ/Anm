local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');

local Shared = ReplicatedStorage.Shared;
local Server = ServerScriptService.Server;
local ServerComponents = Server.Components;

_G.BridgeNet2 = require(Shared.Package.BridgeNet2)
_G.FindEntity = require(ServerComponents.Core.EntityManager).Find