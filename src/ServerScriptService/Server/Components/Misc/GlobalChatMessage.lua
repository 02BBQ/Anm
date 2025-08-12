return function()
	local messagingService = game:GetService("MessagingService")
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local players = game:GetService("Players")
	
	local sharedFolder = replicatedStorage:WaitForChild("Shared")
	local componentsFolder = sharedFolder:WaitForChild("Components")

	local networkingModules = componentsFolder:WaitForChild("Networking")
	local network = require(networkingModules:WaitForChild("Network"))
	
	messagingService:SubscribeAsync("GlobalChatMessage", function(message)
		local data: {} = message.Data
		local jobId: number = data.JobId
		local message: string = data.Message
		if jobId ~= game.JobId then
			network:Send("SystemChatMessage", message, false, players:GetPlayers())
		end
	end)
end