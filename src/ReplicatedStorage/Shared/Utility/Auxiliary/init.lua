local RunService = game:GetService('RunService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Shared = ReplicatedStorage.Shared;

return {
	Shared = require(script.Shared);
	Maid = require(Shared.Package.Maid);
	BoatTween = require(Shared.Package.BoatTween);
	BridgeNet = require(Shared.Package.BridgeNet2);
	Wiki = require(Shared.Wiki);
	Crater = require(Shared.Package.Crater_Module);
	MeshEmitter = require(Shared.Package.MeshEmitter);

	Attribute = require(Shared.Utility.Attribute);
	-- ClientStateManager = require(Shared.Utility.ClientStateManager);
	StateManager = require(Shared.Utility.StateManager);
};