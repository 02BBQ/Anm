local CharacterHandler = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local userGameSettings = UserSettings():GetService("UserGameSettings")

--// Requires
local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary)
local AnimatorModule = require(ReplicatedStorage.Shared.Utility.Animator)
local Maid = require(ReplicatedStorage.Shared.Utility.Maid)
local Run = require(script.Run);
-- local Network = require(ReplicatedStorage.Shared.Network)

local _use = Auxiliary.BridgeNet.ClientBridge('_use');
local _knockback = Auxiliary.BridgeNet.ClientBridge('Knockback');

--// Variables
local ClientMaid = Maid.new();
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAppearanceLoaded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local humanoid = Character.Humanoid

local camera = workspace.CurrentCamera

local Animator = AnimatorModule.new(LocalPlayer);
Animator:Cache();
_G.Animator = Animator;

_G.EffectReplicator = require(ReplicatedStorage.Shared.Components.EffectReplicator)

CharacterHandler.Slide = require(script.Slide);
CharacterHandler.AirStepped = false;
CharacterHandler.AirSteppedQueue = nil;
CharacterHandler.RelativeCFrame = CFrame.new()


local self = {};

self.humanoid = Character and Character:WaitForChild("Humanoid")

if not self.humanoid then
	return
end

self.player = self.players and self.players.LocalPlayer

shared.Cx, shared.Cy, shared.Cz = 0,0,0

if not self.humanoid then 
	return error("No humanoid detected")
end

self.humanoidRootPart = self.humanoid and self.humanoid.RootPart
self.currentCamera = workspace and workspace.CurrentCamera

self.currentCamera.CameraType = Enum.CameraType.Custom
self.currentCamera.CameraSubject = Character

self.head = Character and Character:FindFirstChild("Head")
self.torso = Character and Character:FindFirstChild("Torso")

if not self.humanoidRootPart then
	return
end

self.playerGui = self.player and self.player.PlayerGui

function UpdateRelativeCFrame(dt)
	if HRP:FindFirstChildOfClass('BodyGyro') then return end
	local cameraCFr: CFrame = workspace.CurrentCamera.CFrame;
	local cameraFacingCFr: CFrame = CFrame.new(HRP.Position, HRP.Position + cameraCFr.LookVector);

	CharacterHandler.cameraFacing = cameraFacingCFr;

	local _,OrientationY =  cameraCFr:ToOrientation();
	CharacterHandler.RelativeCFrame = CFrame.new(HRP.CFrame.Position) * CFrame.Angles(0,OrientationY,0);
	
	if Character:GetAttribute('cameraFacing') then
		HRP.CFrame = CharacterHandler.RelativeCFrame;
	end;
end

if RunService:IsClient() then
	RunService.RenderStepped:Connect(UpdateRelativeCFrame)
end

_G.IsStunned = function()
	if Character:GetAttribute('ClientActive') then
		return false; 
	end
	if _G.EffectReplicator:FindEffect("Stunned") then
		return false;
	end
	local Using = Character:GetAttribute("UsingMove");
	if Using and Using > 0 then
		return false;
	end
	return true;
end

function GetMoveDirection(Character: Model)
	local humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid');
	local HRP = Character:FindFirstChild('HumanoidRootPart');
	local MoveDirection = humanoid.MoveDirection;

	local Returning = nil;

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		Returning = 'Forward';
	elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
		Returning = 'Backward';
	elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
		Returning = 'Left';
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
		Returning = 'Right';
	elseif MoveDirection.Magnitude == 0 then
		Returning = 'Forward';
		MoveDirection = -HRP.CFrame.LookVector.Unit;
	else
		if CharacterHandler.RelativeCFrame.LookVector:Dot(MoveDirection) > .7 then
			Returning = 'Forward';
		elseif (-CharacterHandler.RelativeCFrame.LookVector):Dot(MoveDirection) > .7 then
			Returning = 'Backward';
		elseif CharacterHandler.RelativeCFrame.RightVector:Dot(MoveDirection) > .7 then
			Returning = 'Right';
		elseif (-CharacterHandler.RelativeCFrame.RightVector):Dot(MoveDirection) > .7 then
			Returning = 'Left';
		else
			Returning = 'Forward';
		end;
	end;

	return Returning, MoveDirection;
end;

local function AirDash()
	Character:SetAttribute('CantDash', true);

	task.delay(0.5, function()
		Character:SetAttribute('CantDash', false);
	end)

	Character:SetAttribute('ClientActive', true);

	task.delay(0.25, function()
		Character:SetAttribute('ClientActive', false);
	end)

	Animator:Fetch('Universal/AirDash'):Play();
	local BV = Auxiliary.Shared.CreateVelocity(HRP);
	BV.Name = 'DashVelocity';
	BV.MaxForce *= Vector3.new(1,1,1);
	
	local moveDirection = GetMoveDirection(Character);
	local dir;
	if moveDirection == 'Left' then
		dir = -workspace.CurrentCamera.CFrame.RightVector;
	elseif moveDirection == 'Right' then
		dir = workspace.CurrentCamera.CFrame.RightVector;
	elseif moveDirection == 'Forward' then
		dir = workspace.CurrentCamera.CFrame.LookVector;
	elseif moveDirection == 'Backward' then
		dir = -workspace.CurrentCamera.CFrame.LookVector;
	else
		dir = workspace.CurrentCamera.CFrame.LookVector;
	end
	
	BV.Velocity = dir * 85;
	game.Debris:AddItem(BV, 0.15);
end;

function CharacterHandler.Dash()
	local Character = LocalPlayer.Character;
	if not Character or not Character:IsDescendantOf(Auxiliary.Shared.Alive) then return end;
	if not _G.IsStunned() then return end;
	if Character:GetAttribute('CantDash') then return end;

	if CharacterHandler.AirStepped then
		AirDash();
		return;
	end;

	Character:SetAttribute('CantDash', true);

	task.delay(2, function()
		Character:SetAttribute('CantDash', false);
	end)

	_use:Fire({"Action", "Dash", {MoveDirection = GetMoveDirection(Character)}});

	local MoveDirection = GetMoveDirection(Character);
	local IsSide = MoveDirection == 'Left' or MoveDirection == 'Right';

	local HRP = Character:WaitForChild('HumanoidRootPart');
	local humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid');

	if HRP:FindFirstChild('DashVelocity') then
		HRP.DashVelocity:Destroy();
	end;

	local Resp;
	task.spawn(function()
		--Resp = Network:Send('Action', {
		--	Action='Dash';
		--	Data = {
		--		MoveDirection = MoveDirection;
		--	};
		--}, true);
	end);

	local Anim;
	if MoveDirection ~= 'No' then
		Anim = Animator:Fetch('Universal/'..MoveDirection);
		if Anim then
			Anim:Play();
			Anim.Stopped:Connect(function()
				if HRP:FindFirstChildOfClass('BodyPosition') then
					HRP:FindFirstChildOfClass('BodyPosition'):Destroy();
				end
				if HRP:FindFirstChildOfClass('BodyVelocity') then
					HRP:FindFirstChildOfClass('BodyVelocity'):Destroy();
				end
			end)
		end
	end;

	local DashTick = tick();
	local function CheckDashing()
		if not Resp and tick()-DashTick < 2 then
			return true;
		end;
		return Character:GetAttribute('Dashing');
	end;

	local BV = Auxiliary.Shared.CreateVelocity(HRP);
	BV.Name = 'DashVelocity';
	local yMaxForce = 0; --humanoid:GetState() == Enum.HumanoidStateType.Freefall and 0.5 or 0;
	BV.MaxForce *= Vector3.new(1,yMaxForce,1);

	humanoid.AutoRotate = true;
	-- add later
	Character:SetAttribute('ClientActive', true);

	local Dash = function()
		Character:SetAttribute('SideDashingClient', true);

		task.delay(0.5, function()
			Character:SetAttribute('ClientActive', false);
		end);

		local DashDuration = 0.4;

		local VelocityValue = Instance.new('NumberValue');
		VelocityValue.Value = 0;

		task.spawn(function()
			TweenService:Create(VelocityValue, TweenInfo.new(DashDuration*.05, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Value = 115}):Play();

			task.wait(DashDuration*.05);

			TweenService:Create(VelocityValue, TweenInfo.new(DashDuration*1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = 0}):Play();
		end);

		Character:SetAttribute('cameraFacing', true);

		local Connec = RunService.Stepped:Connect(function()
			local Vel = ((MoveDirection == 'Left' or MoveDirection == 'Backward') and -VelocityValue.Value) or VelocityValue.Value;
			local RelativeCFr = CharacterHandler.RelativeCFrame;

			if IsSide then
				BV.Velocity = RelativeCFr.RightVector * Vel;
			else
				BV.Velocity = RelativeCFr.LookVector * Vel;
			end
		end);

		local function Finish()
			Character:SetAttribute('cameraFacing', false);
			VelocityValue:Destroy();
			Connec:Disconnect();
			BV:Destroy();
			Character:SetAttribute('SideDashingClient', nil);
		end

		local Cancel = false

		task.delay(DashDuration * 0.6, function()
			if Cancel then return end

			Finish()
		end);
	end;

	Dash();
	humanoid.AutoRotate = true;
	--CharacterHandler.SetMovementDisabled(false);

	if not IsSide then
		Character:SetAttribute('ClientActive', false);
	end;
end;

function CharacterHandler.HandleTool(Held, Tool)
	local Character = LocalPlayer.Character;
	if not Character or not Character:IsDescendantOf(workspace.World.Alive) then return end;
	local Tool = Tool or Character:FindFirstChildOfClass("Tool");

	if not Tool then return end;
	
	--local _ = Information:Get("Combat/Moveset")[Tool.Name]
	--if _ then
	--	_use:Fire({"Skill", Held, {Name = Tool.Name}})
	--	Character.Humanoid:UnequipTools();
	--end
	
	--if Character:GetAttribute("Equipped") then
	--	_use:Fire({"LMB", Held})
	--	return;
	--end
end

local isRunning = false;

CharacterHandler.GetMouseTarget = function(Data)
	local camera = workspace.CurrentCamera
	local mouse = LocalPlayer:GetMouse()

	local Target = nil
	local Distance = Data or 0.4

	local Position = CFrame.new(camera.CFrame.p, mouse.Hit.p)

	for a, b in pairs(workspace.World.Alive:GetChildren()) do
		if b.Name ~= LocalPlayer.Name and b:FindFirstChild("HumanoidRootPart") and b:FindFirstChild("Humanoid") and b:FindFirstChild("Humanoid").Health > 0 then
			if (CFrame.new(camera.CFrame.p,  b.HumanoidRootPart.Position).lookVector - Position.lookVector).magnitude < Distance then
				Distance = (CFrame.new(camera.CFrame.p,  b.HumanoidRootPart.Position).lookVector - Position.lookVector).magnitude
				Target = b
			end
		end
	end

	return Target
end

CharacterHandler.Initialize = function()
	local Character = LocalPlayer.Character;
	
	ClientMaid:AddTask(_knockback:Connect(function(Args)
		local Data = Args.Data;
		local Entity = Args.Entity;
		
		local Root = Entity.Character.Root;
		
		local Velocity = Data["Velocity"]
		local Push = Data["Push"]
		local AngularVelocity = Data["AngularVelocity"]
		local MaxForce = Data["MaxForce"]
		local Duration = Data["Duration"]
		local Ease = Data["Ease"]
		local Stay = Data["Stay"]

		local TrueVelocity = Velocity or ((Root.CFrame).LookVector * Push)

		if AngularVelocity then
			Character.HumanoidRootPart.AssemblyAngularVelocity = Character.HumanoidRootPart.AssemblyAngularVelocity + AngularVelocity
		end

		local BV = Auxiliary.Shared.CreateVelocity(Character.HumanoidRootPart)		
		BV.Velocity = TrueVelocity

		if MaxForce then
			BV.MaxForce = MaxForce
		end

		if Ease then
			TweenService:Create(BV, TweenInfo.new(Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Velocity = Vector3.zero}):Play()
		end

		task.delay(Duration, function()
			if Stay then
				task.delay(Stay, function()
					BV:Destroy()
				end)
			else
				BV:Destroy()
			end
		end)
	end))
	
	ClientMaid:AddTask(RunService.PreRender:Connect(function(dt)
		if Character.Parent == nil then return end;
		isRunning = false;

		if humanoid.MoveDirection:Dot(HRP.CFrame.LookVector) >= 0.15 then
			isRunning = true;
		end;
	end))

	ClientMaid:AddTask(RunService.RenderStepped:Connect(function(dt)
		if humanoid.MoveDirection.Magnitude <= 0 then
			Run(false);
		elseif isRunning then
			Run(true);
		else
			Run(false);
		end;

		local BaseWalkSpeed = humanoid.WalkSpeed;

		if humanoid:GetState() == (Enum.HumanoidStateType.Freefall or Enum.HumanoidStateType.Jumping) then
			Animator:Fetch('Universal/Run'):Stop()
		end

		local newTime = self.timePassed or time()
		self.timePassed = time()
		if self.head and self.humanoidRootPart and self.torso then
			if self.currentCamera.CameraType ~= Enum.CameraType.Scriptable then
				if not Character:GetAttribute("Ragdolled") then
					self.shakePosition = Vector3.new(0 + shared.Cx, -1.5 + shared.Cy, 0 + shared.Cz);
					self.position = nil
					if Character:GetAttribute("NoHeadFollow") then
						self.position = Vector3.new(0, 1.5, 0)
					else 
						self.position = self.humanoidRootPart.CFrame:PointToObjectSpace(self.head.Position)
					end
					if self.position then
						self.cameraPosition = self.humanoid.CameraOffset:Lerp(self.position + self.shakePosition, 1 - 2.5E-5 ^ dt)
						self.humanoid.CameraOffset = self.cameraPosition + Vector3.zero
					end
				else
					self.humanoid.CameraOffset = Vector3.new()
				end
			end
		end
	end))
	
	ClientMaid:AddTask(require(script.WallHop)());
	ClientMaid:AddTask(require(script.SpeedHandler)());

	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom;
	-- workspace.CurrentCamera.CameraSubject = Character.Torso;
	workspace.CurrentCamera.FieldOfView = 70;
end

local remainJump = 1;

humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.Landed then
		remainJump = 1
	end
end)

CharacterHandler.Jump = function()
	local Character = LocalPlayer.Character;
	if not Character or not Character:IsDescendantOf(workspace.World.Alive) then return end;

	if humanoid:GetState() == Enum.HumanoidStateType.Jumping then return end;

	local Jump = function()
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall and remainJump > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping, true);
			humanoid.Jump = true;
			remainJump -= 1;
			local Anim = Animator:Fetch('Universal/AirStep');
			Anim:Play();
			CharacterHandler.AirStepped = true;

			if CharacterHandler.AirSteppedQueue then
				task.cancel(CharacterHandler.AirSteppedQueue);
			end

			CharacterHandler.AirSteppedQueue = task.delay(0.5, function()
				CharacterHandler.AirStepped = false;
			end)
		end;
	end;

	-- Jump();	f
end

return CharacterHandler
