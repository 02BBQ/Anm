--//Variables
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');
local MessagingService = game:GetService('MessagingService');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

--//Module
local Wrapper = {};

function Wrapper:Listen(Channel: string, Callback)
	MessagingService:SubscribeAsync(Channel, function(Serialized)
		local Data = HttpService:JSONDecode(Serialized.Data);
		if Data._Source.JobId == game.JobId then
			return;
		end;
		
		task.spawn(Callback, Data, Serialized.Sent);
	end);
end;

function Wrapper:Send(Channel: string, Data: {})
	Data._Source = {
		Place = game.PlaceId;
		JobId = game.JobId;
	};
	
	MessagingService:PublishAsync(Channel, HttpService:JSONEncode(Data));
end;

return Wrapper;