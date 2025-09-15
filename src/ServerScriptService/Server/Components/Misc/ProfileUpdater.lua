local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ReplicatedStorage.Shared.Services.Networking.Network);
local ProfileHandler = require(ServerScriptService.Server.Components.Data.ProfileHandler)

local UpdateInterval = 99999

local ProfileUpdater = {}

function ConvertTableToFolder(Parent: Instance, Data: {[string]: any})
	for Key, Value in pairs(Data) do
		local FoundInstance = Parent:FindFirstChild(Key)

		if typeof(Value) == "table" then
			if not FoundInstance then
				FoundInstance = Instance.new("Folder")
				FoundInstance.Name = Key
				FoundInstance.Parent = Parent
			end
			ConvertTableToFolder(FoundInstance, Value)
		else
			local Types = {
				number = "NumberValue",
				string = "StringValue",
				boolean = "BoolValue"
			}

			local InstanceType = Types[typeof(Value)]
			if InstanceType then
				if not FoundInstance then
					FoundInstance = Instance.new(InstanceType)
					FoundInstance.Name = Key
					FoundInstance.Parent = Parent
				end
				local Success, Message = pcall(function()
					FoundInstance.Value = Value
				end)
				if not Success then
					warn("Error setting profile data value:", Message)
				end
			else
				warn("Invalid data type received:", Key, typeof(Value))
			end
		end
	end
end

function ProfileUpdater.PlayerAdded(Player : Player)
	local Profile = ProfileHandler.GetProfileById(Player.UserId)
	
	if not Profile then
		print("No profile found", Profile)
		return
	end
	
	Network:Send("ClientDataUpdate", Profile.Data or {}, false, {Player})
	
	Player.CharacterAdded:Connect(function(character)
		task.wait(2)
		
		Network:Send("ClientDataUpdate", Profile.Data or {}, false, {Player})
	end)
end

for _, Player : Player in Players:GetPlayers() do
	task.spawn(ProfileUpdater.PlayerAdded, Player)
end

Players.PlayerAdded:Connect(ProfileUpdater.PlayerAdded)

Network:OpenChannel("ClientDataUpdate", function(Player: Player)
	local Profile = ProfileHandler.GetProfileById(Player.UserId)

	if not Profile then
		return
	end
	
	local SendData = Profile.Data or {}
	Network:Send("ClientDataUpdate", SendData, false, {Player})
	
	local DataFolder: Folder = Player:FindFirstChild("ServerData") or Instance.new("Folder") -- @xertwel: too lazy to make it normal bro
	DataFolder.Name = "ServerData"
	ConvertTableToFolder(DataFolder, SendData)
	DataFolder.Parent = Player
	
	local Entity = _G.SharedFunctions.FindEntity(Player)
	
	if not Entity then
		return
	end

	Entity:UpdateLeaderstats()
	
end)

task.spawn(function()
	while true do
		task.wait(UpdateInterval)
		
		for _, Player : Player in Players:GetPlayers() do
			local Profile = ProfileHandler.GetProfileById(Player.UserId)
			
			if not Profile then
				continue
			end
			
			Network:Send("ClientDataUpdate", Profile.Data or {}, false, {Player})
		end
	end
end)


local event = game.ReplicatedStorage.Shared.DataRequests.SearchPlayer
event.OnServerEvent:Connect(function(Player:Player,UserName)
	local userID:number
	pcall(function()
		userID = Players:GetUserIdFromNameAsync(UserName)
	end)
	if userID then
		local profile = ProfileHandler.GetProfileById(userID)
		
		if profile then
			event:FireClient(Player,userID,profile.Data)
		else
			event:FireClient(Player,false)
		end
	else
		event:FireClient(Player,false)
	end
end)

return ProfileUpdater