local Auxiliary = {}

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local BadgeService = game:GetService("BadgeService")
local Chat = game:GetService("Chat")
local Teams = game:GetService("Teams")
local TestService = game:GetService("TestService")
local LocalizationService = game:GetService("LocalizationService")
local AnalyticsService = game:GetService("AnalyticsService")
local HapticService = game:GetService("HapticService")
local MessagingService = game:GetService("MessagingService")
local PolicyService = game:GetService("PolicyService")
local SocialService = game:GetService("SocialService")
local TextService = game:GetService("TextService")
local VRService = game:GetService("VRService")
local VoiceChatService = game:GetService("VoiceChatService")

local TroveClass = require(ReplicatedStorage.Shared.Utility.Trove);

Auxiliary.GetPath = function(Bottom, Top)
	local CurrentParent = Bottom;
	local Occurences = {};
	local PathStr = '';

	repeat
		Occurences[#Occurences+1] = CurrentParent.Name;
		CurrentParent = CurrentParent.Parent;
	until CurrentParent == Top;

	for i = #Occurences,1,-1 do
		PathStr ..= Occurences[i]..'/';
	end;

	return PathStr:sub(1,#PathStr-1);
end;

Auxiliary.FixedUpdate = function(updateFunction: (number) -> (), updateRate: number, variableUpdateFunction: (number) -> ()?): () -> ()
	local Accumulated = 0
	local TotalDT = 0

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if variableUpdateFunction then
			variableUpdateFunction(deltaTime)
		end

		Accumulated += deltaTime
		TotalDT += deltaTime

		while Accumulated >= updateRate do
			task.spawn(updateFunction, TotalDT)
			Accumulated -= updateRate
			TotalDT = 0
		end
	end)

	return function()
		connection:Disconnect()
	end
end;

Auxiliary.WaitForMarker = function(Track: AnimationTrack, Marker: string)
	if not Track.IsPlaying then
		return;
	end;
	
	local Proceed;
	local Param;
	
	local Trove = TroveClass.new();
	local Ended: BindableEvent = Trove:Add(Instance.new('BindableEvent'));
	
	Trove:Connect(Track.Stopped, function() 
		Ended:Fire()
	end);
	
	Trove:Connect(Track:GetMarkerReachedSignal(Marker), function(ParamString: string)
		Param = ParamString;
		Ended:Fire();
	end);
	
	Ended.Event:Wait();
	
	Trove:Destroy();
	return Param;
end;

Auxiliary.CreateVelocity = function(Parent: BasePart, Data: {MaxForce: Vector3?})
	local BodyVelocity: BodyVelocity = Instance.new('BodyVelocity');
	BodyVelocity.P = 20_000;
	BodyVelocity.MaxForce = (Data and Data.MaxForce) or Vector3.one*4e4;

	BodyVelocity.Parent = Parent;
	return BodyVelocity;
end;

Auxiliary.CreatePosition = function(Parent: BasePart, Data: table)
	local BodyPosition: BodyPosition = Instance.new('BodyPosition');
	BodyPosition.P = 20_000;
	BodyPosition.MaxForce = (Data and Data.MaxForce) or Vector3.one*math.huge;
	BodyPosition.Position = Parent.Position;

	BodyPosition.Parent = Parent;
	return BodyPosition;
end;

Auxiliary.RemoveFirstValue = function(tab )
	for i in tab do
		table.remove(tab,i);
		break;
	end;
end;

Auxiliary.MapInstances = {
	workspace.World.Map;
};

Auxiliary.Debris = workspace.World.Debris;
Auxiliary.Alive = workspace.World.Alive;

local ParamFuncs = {
	Map = (function()
		local NewParams: RaycastParams = RaycastParams.new();
		NewParams.FilterType = Enum.RaycastFilterType.Include;
		NewParams.FilterDescendantsInstances = Auxiliary.MapInstances;

		return NewParams;
	end);
};

Auxiliary.RayParams = {
	Map = ParamFuncs.Map();
};

for _,v in pairs(script:GetChildren()) do
	if v:IsA('ModuleScript') then
		Auxiliary[v.Name] = require(v);
	end;
end;

return Auxiliary;