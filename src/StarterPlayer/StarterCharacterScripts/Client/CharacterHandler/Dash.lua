local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary)
local AnimatorModule = require(ReplicatedStorage.Shared.Utility.Animator)

local _use = Auxiliary.BridgeNet.ClientBridge('_use')

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAppearanceLoaded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local humanoid = Character.Humanoid

local Animator = AnimatorModule.new(LocalPlayer)
Animator:Cache()

-- CharacterHandler에서 가져와야 할 함수들을 로컬에서 재정의
local function GetMoveDirection(Character)
	local humanoid = Character:FindFirstChildOfClass('Humanoid')
	local HRP = Character:FindFirstChild('HumanoidRootPart')
	local MoveDirection = humanoid.MoveDirection

	local Returning = nil

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		Returning = 'Forward'
	elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
		Returning = 'Backward'
	elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
		Returning = 'Left'
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
		Returning = 'Right'
	elseif MoveDirection.Magnitude == 0 then
		Returning = 'Forward'
		MoveDirection = -HRP.CFrame.LookVector.Unit
	else
		local RelativeCFrame = CFrame.new(HRP.CFrame.Position) * CFrame.Angles(0, workspace.CurrentCamera.CFrame:ToOrientation(), 0)
		if RelativeCFrame.LookVector:Dot(MoveDirection) > .7 then
			Returning = 'Forward'
		elseif (-RelativeCFrame.LookVector):Dot(MoveDirection) > .7 then
			Returning = 'Backward'
		elseif RelativeCFrame.RightVector:Dot(MoveDirection) > .7 then
			Returning = 'Right'
		elseif (-RelativeCFrame.RightVector):Dot(MoveDirection) > .7 then
			Returning = 'Left'
		else
			Returning = 'Forward'
		end
	end

	return Returning, MoveDirection
end

local function AirDash()
	Character:SetAttribute('CantDash', true)

	task.delay(0.5, function()
		Character:SetAttribute('CantDash', false)
	end)

	Character:SetAttribute('ClientActive', true)

	task.delay(0.25, function()
		Character:SetAttribute('ClientActive', false)
	end)

	Animator:Fetch('Universal/AirDash'):Play()
	local BV = Auxiliary.Shared.CreateVelocity(HRP)
	BV.Name = 'DashVelocity'
	BV.MaxForce *= Vector3.new(1,1,1)
	
	local moveDirection = GetMoveDirection(Character)
	local dir
	if moveDirection == 'Left' then
		dir = -workspace.CurrentCamera.CFrame.RightVector
	elseif moveDirection == 'Right' then
		dir = workspace.CurrentCamera.CFrame.RightVector
	elseif moveDirection == 'Forward' then
		dir = workspace.CurrentCamera.CFrame.LookVector
	elseif moveDirection == 'Backward' then
		dir = -workspace.CurrentCamera.CFrame.LookVector
	else
		dir = workspace.CurrentCamera.CFrame.LookVector
	end
	
	BV.Velocity = dir * 85
	game.Debris:AddItem(BV, 0.15)
end

return function(Data, CharacterHandler)
	local Character = LocalPlayer.Character
	if not Character or not Character:IsDescendantOf(Auxiliary.Shared.Alive) then return end
	if not _G.CanUse() then return end
	if Character:GetAttribute('CantDash') then return end
	if not Character:GetAttribute('Active') then return end

	if CharacterHandler.AirStepped then
		AirDash()
		return
	end

	Character:SetAttribute('CantDash', true)

	task.delay(2, function()
		Character:SetAttribute('CantDash', false)
	end)

	_use:Fire({"Action", "Dash", {MoveDirection = GetMoveDirection(Character)}})

	local MoveDirection = GetMoveDirection(Character)
	local IsSide = MoveDirection == 'Left' or MoveDirection == 'Right'

	local HRP = Character:WaitForChild('HumanoidRootPart')
	local humanoid = Character:FindFirstChildOfClass('Humanoid')

	if HRP:FindFirstChild('DashVelocity') then
		HRP.DashVelocity:Destroy()
	end

	local Resp
	task.spawn(function()
		_use:Fire({"Dash", Data})
	end)

	local Anim
	if MoveDirection ~= 'No' then
		Anim = Animator:Fetch('Universal/'..MoveDirection)
		if Anim then
			Anim:Play()
			Anim.Stopped:Connect(function()
				if HRP:FindFirstChildOfClass('BodyPosition') then
					HRP:FindFirstChildOfClass('BodyPosition'):Destroy()
				end
				if HRP:FindFirstChildOfClass('BodyVelocity') then
					HRP:FindFirstChildOfClass('BodyVelocity'):Destroy()
				end
			end)
		end
	end

	local DashTick = tick()
	local function CheckDashing()
		if not Resp and tick()-DashTick < 2 then
			return true
		end
		return Character:GetAttribute('Dashing')
	end

	local BV = Auxiliary.Shared.CreateVelocity(HRP)
	BV.Name = 'DashVelocity'
	local yMaxForce = 0
	BV.MaxForce *= Vector3.new(1,yMaxForce,1)

	humanoid.AutoRotate = true
	Character:SetAttribute('ClientActive', true)

	local Dash = function()
		Character:SetAttribute('SideDashingClient', true)

		local DashDuration = Auxiliary.Wiki.Default.Combat.DashDuration

		local VelocityValue = Instance.new('NumberValue')
		VelocityValue.Value = 0

		task.spawn(function()
			TweenService:Create(VelocityValue, TweenInfo.new(DashDuration*.05, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Value = 115}):Play()

			task.wait(DashDuration*.05)

			TweenService:Create(VelocityValue, TweenInfo.new(DashDuration*1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = 0}):Play()
		end)

		Character:SetAttribute('cameraFacing', true)

		local Connec = RunService.Stepped:Connect(function()
			local Vel = ((MoveDirection == 'Left' or MoveDirection == 'Backward') and -VelocityValue.Value) or VelocityValue.Value
			local RelativeCFr = CharacterHandler.RelativeCFrame

			if IsSide then
				BV.Velocity = RelativeCFr.RightVector * Vel
			else
				BV.Velocity = RelativeCFr.LookVector * Vel
			end
		end)

		local function Finish()
			Character:SetAttribute('cameraFacing', false)
			VelocityValue:Destroy()
			Connec:Disconnect()
			BV:Destroy()
			Character:SetAttribute('SideDashingClient', nil)
			Character:SetAttribute('ClientActive', false)
		end

		local Cancel = false

		task.delay(DashDuration * 0.6, function()
			if Cancel then return end

			Finish()
		end)
	end

	Dash()
	humanoid.AutoRotate = true

	if not IsSide then
		Character:SetAttribute('ClientActive', false)
	end
end