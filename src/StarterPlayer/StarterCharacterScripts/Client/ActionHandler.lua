--// Services
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');
local RunService = game:GetService("RunService")

--// Locations
local Shared = ReplicatedStorage.Shared;
local Map: Folder = workspace:WaitForChild("World"):WaitForChild('Map');

--// Modules
local bridgeNet = require(Shared.Package.BridgeNet2);
local Network = require(Shared.Services.Networking.Network);
local CharacterHandler = require(script.Parent.CharacterHandler);
local Auxiliary = require(Shared.Utility.Auxiliary);

--// Variables
local LocalPlayer: Player = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();
local _use = bridgeNet.ReferenceBridge("_use");
local Remote = LocalPlayer.Character:WaitForChild("RemoteEvent", 100);
assert(Remote, "RemoteEvent not found in StarterCharacterScripts");

--// Component
local ActionComponent = {}
ActionComponent.__index = ActionComponent

local FetchTypes = {
	Camera = function()
		return workspace.CurrentCamera.CFrame;
	end;

	RootCFrame = function()
		local Character = LocalPlayer.Character;
		if not Character or not Character:IsDescendantOf(workspace.World.Alive) then return end;
		local HRP = Character:FindFirstChild('HumanoidRootPart');

		return HRP.CFrame;
	end;

	LastActionCheck = function()
		local Character = LocalPlayer.Character;
		if not Character or not Character:IsDescendantOf(workspace.World.Alive) then return end;
		local Humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid');
		if not Humanoid then return end;

		local CurrentPunch = Character:GetAttribute('CurrentPunch')		
		if (not CurrentPunch) or (CurrentPunch+1 ~= 4) then return end;

		if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			return 'Downslam';
		elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) or Humanoid.Jump then
			return 'Uptilt';
		end;

		return 'Normal';
	end;

	FloorMaterial = function()
		local Character = LocalPlayer.Character;
		if not Character or not Character:IsDescendantOf(workspace.World.Alive) then return end;
		local Humanoid: Humanoid = Character:WaitForChild('Humanoid');
		if not Humanoid then return end;

		return Humanoid.FloorMaterial;
	end;

	GetMouse = function(IgnoreCanCollide)
		if IgnoreCanCollide then
			local mousePos = UserInputService:GetMouseLocation();
			local ray = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y);
			-- local ray = workspace.CurrentCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
			local OriginPos = workspace.CurrentCamera.CFrame.Position
			
			local RayLength = 1000
			
			local result = workspace:Raycast(ray.Origin, ray.Direction * RayLength, Auxiliary.Shared.RayParams.MapRespect)
			if not result then return ray.Origin + ray.Direction * 1000, nil end
			
			return CFrame.new(result.Position).Position
		end
		
		return LocalPlayer:GetMouse().Hit.Position;
	end;
};



function ActionComponent.Bind()
	--local self = setmetatable({}, ActionComponent);
	Network:BindChannel('Fetch', function(Params)
		return FetchTypes[Params.Fetching]();
	end);
	--return self;
end

function ActionComponent:LMB(held: boolean)
	local Character = LocalPlayer.Character;
	local Tool = Character:FindFirstChildOfClass("Tool");

	local data = {held = held, tool = Tool, mousePos = FetchTypes.GetMouse(true)};
	_use:Fire({"M1", data})
end

function ActionComponent:Critical(held: boolean)
	local data = {held = held};
	_use:Fire({"Critical", data})
end

function ActionComponent:Block(held: boolean)
	local data = {held = held};
	_use:Fire({"Block", data})
end

function ActionComponent:Dash(held: boolean)
	local data = {held = held};
	CharacterHandler:Dash(data);
end

function ActionComponent:WallCling(held: boolean)
	local data = {held = held};
	CharacterHandler.WallCling(data);
end

function ActionComponent:RMB(held: boolean)
	local data = {held = held};
	_use:Fire({"RMB", data})
end

local lastPressTime = 0
local doubleTapThreshold = 0.3

function ActionComponent:Sprint(held: boolean)
	local currentTime = tick()
	if currentTime - lastPressTime < doubleTapThreshold then
		-- 더블탭: 달리기 모드 시작
		local data = {held = held};
		_use:Fire({"Run", data})
	end
	lastPressTime = currentTime
end

function ActionComponent:Carry(held: boolean)
	local data = {held = held};
	_use:Fire({"Carry", data})
end

function ActionComponent:Grip(held: boolean)
	local data = {held = held};
	_use:Fire({"Grip", data})
end

return ActionComponent