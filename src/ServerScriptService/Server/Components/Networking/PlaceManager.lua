--//Variables
local TeleportService = game:GetService('TeleportService');
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerScriptService = game:GetService('ServerScriptService');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

local Network = require(SharedComponents.Networking.Network);
local PlaceService = require(SharedComponents.Networking.PlaceService);
local EntityManager = require(Components.Core.EntityManager);
local Signal = require(SharedComponents.Package.Signal);

type ServerOptions = {
	AccessCode: string?;
	JobId: string?;
	Reserving: boolean?;
	Data: {}?;
};

local IsStudio = RunService:IsStudio();

--//Module
local PlaceManager = {
	Teleporting = Signal.new();
};

function PlaceManager:Bind()
	Network:OpenChannel('Teleport', function(Player: Player, Params: {})
		local TeleportType: string = Params.TeleportType;
		if TeleportType == 'Duels' then
			PlaceManager:Teleport('DuelsLobby', {Player});
		elseif TeleportType == 'Main' then
			PlaceManager:Teleport('Main', {Player});
		end;
	end);
end;

function PlaceManager:Reserve(PlaceName: string)
	local Id;
	if PlaceName then
		Id = PlaceService:FetchPlaceByName(PlaceName).Id;
	else
		Id = game.PlaceId;
	end;
	
	return TeleportService:ReserveServer(Id);
end;

function PlaceManager:Teleport(PlaceName: string, Sending: {} | Player, TransferData: {}?, Options: ServerOptions?)
	local IsPlayer = (typeof(Sending[1]) == 'Instance');
	
	local TeleportOptions;
	if Options then
		if Options.Reserving and Options.AccessCode then
			warn('Trying to reserve new server with teleport but still provided access code');
			return;
		end;
		
		TeleportOptions = Instance.new('TeleportOptions');

		if Options.AccessCode then
			TeleportOptions.ReservedServerAccessCode = Options.AccessCode;
		end;
		
		if Options.JobId then
			TeleportOptions.ServerInstanceId = Options.JobId;
		end;
		
		if Options.Reserving then
			TeleportOptions.ShouldReserveServer = Options.Reserving;
		end;
		
		-- Not recommended, can be seen by both client and server and manipulated by client
		if Options.Data then
			TeleportOptions:SetTeleportData(Options.Data);
		end;
	end
	
	local PlaceId = PlaceService:FetchPlaceByName(PlaceName).Id;
	assert(PlaceId, debug.traceback(`Could not find place id for place {PlaceName}`));
	
	local TeleportId: string = HttpService:GenerateGUID(false);
	
	local Entities = {};
	local Players = {};
	
	if IsPlayer then
		Players = Sending;
	else
		Entities = Sending;
		for _,v in Entities do
			table.insert(Players, v.Player);
		end;
	end;
	
	if IsPlayer then
		for _,v: Player in Players do
			local Entity = EntityManager.Find(v);
			if not Entity then
				warn('could not find entity for', v);
				continue;
			end;
			
			Entities[v] = Entity;
		end;
	end;
	
	for _,v in Entities do
		v.Data._CurrentTeleport = TeleportId;
		v.Data._TeleportTransferData[TeleportId] = TransferData;
		v.Player:SetAttribute('_Teleporting', true);
		v.Server.Teleporting = true;
	end;
	
	PlaceManager.Teleporting:Fire(Entities);
	
	Network:Send('Notification', {
		Title = 'Teleporting';
		Description = "Being teleported, if it takes too long rejoin and try again";
		Icon = 'rbxassetid://15000498894';
		Duration = 20;
	}, false, Players);
	
	if IsStudio then
		print('Attempting to teleport', Players, 'to', PlaceName, '\nwith options', Options, '\nand transfer data', TransferData);
		return true;
	end;

	TeleportService:TeleportAsync(PlaceId, Players, TeleportOptions);
	return true;
end;

return PlaceManager;