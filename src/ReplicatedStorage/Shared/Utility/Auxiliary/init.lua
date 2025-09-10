local RunService = game:GetService('RunService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Shared = ReplicatedStorage.Shared;

return {
	Shared = require(script.Shared);
	Maid = require(Shared.Utility.Maid);
	BoatTween = require(Shared.Utility.BoatTween);
	BridgeNet = require(Shared.Components.BridgeNet2);
	Wiki = require(Shared.Wiki);

	Attribute = require(Shared.Utility.Attribute);
	-- ClientStateManager = require(Shared.Utility.ClientStateManager);
	StateManager = require(Shared.Utility.StateManager);
};