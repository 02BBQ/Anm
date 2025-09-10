local RunService = game:GetService('RunService');

return {
	Shared = require(script.Shared);
	Maid = require(game:GetService("ReplicatedStorage").Shared.Utility.Maid);
	BoatTween = require(game:GetService("ReplicatedStorage").Shared.Utility.BoatTween);
	BridgeNet = require(game:GetService("ReplicatedStorage").Shared.Components.BridgeNet2);
};