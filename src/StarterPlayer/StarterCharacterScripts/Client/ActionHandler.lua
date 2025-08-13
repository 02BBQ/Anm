--//Variables
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared;
local Map: Folder = workspace:WaitForChild("World"):WaitForChild('Map');

local LocalPlayer: Player = Players.LocalPlayer;

local bridgeNet = require(Shared.Components.BridgeNet2);
local CharacterHandler = require(script.Parent.CharacterHandler);

local _use = bridgeNet.ReferenceBridge("_use");

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
};



function ActionComponent.new()
	local self = setmetatable({}, ActionComponent);
	return self;
end

function ActionComponent:LightAttack(held: boolean)
	local data = {held = held};
	_use:Fire({"LightAttack", data})
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
	CharacterHandler:Dash();
	_use:Fire({"Dash", data})
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


return ActionComponent