local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');

local Shared = ReplicatedStorage.Shared;
local Server = ServerScriptService.Server;
local ServerComponents = Server.Components;

_G.BridgeNet2 = require(Shared.Components.BridgeNet2)
