local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary)
local Animator = _G.Animator

local TurnPower = 9
local Friction = 45
local AirResist = 1 
local SlidePower = 45
local SlideCD = 0.7

local SlideInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

local slideParams = Auxiliary.Shared.RayParams.Map;

local SlideConnection = nil
local bv, alignOrient = nil
local ActiveAnim
local EndedTick = tick()

local MovementModule = {}

local function CalculateSlopeEffect(lookVector, normalVector)
    -- 표면의 경사 각도 계산
    local slopeAngle = math.deg(math.acos(normalVector:Dot(Vector3.new(0, 1, 0))))
    
    -- 바라보는 방향과 경사 방향의 관계 계산
    local directionFactor = lookVector:Dot(Vector3.new(normalVector.X, 0, normalVector.Z).Unit)

    -- 결과 해석
    if directionFactor > 0 then
        -- 내리막길
        return slopeAngle, directionFactor -- downhill upper than 0
    elseif directionFactor < 0 then
        -- 오르막길
        return slopeAngle, directionFactor -- uphill lower than 0
    else
        -- 평지
        return slopeAngle, 0 -- flat
    end
end


function MovementModule.Slide(Character)
	
	if tick() - EndedTick < SlideCD then return end

	local HRP : BasePart = Character:WaitForChild("HumanoidRootPart")
	local hum : Humanoid = Character:WaitForChild("Humanoid")
	local RootAttach = HRP:WaitForChild("RootAttachment")

	local BodyVelocity = Instance.new("BodyVelocity", HRP)
	BodyVelocity.Name = "SlideVelocity"
	BodyVelocity.MaxForce = Vector3.new(1,1,1) * math.huge
	BodyVelocity.Velocity = HRP.CFrame.LookVector * SlidePower
	bv = BodyVelocity

	if HRP then
		local TimeFalling = 0
		
		ActiveAnim = Animator:Fetch('Universal/Slide')
		ActiveAnim:Play()

		SlideConnection = RunService.PreRender:Connect(function(deltaTime)
			local projected = HRP.CFrame:VectorToObjectSpace(BodyVelocity.Velocity) * Vector3.new(1, 0 ,1)
			local angle = math.deg(math.atan2(projected.X, -projected.Z))

			local LazyFrame = CFrame.new(Vector3.zero, BodyVelocity.Velocity.Unit)
			local DesiredAngle = BodyVelocity.Velocity.Unit - LazyFrame.RightVector * (angle/180) * deltaTime * TurnPower

			local result = workspace:Raycast(HRP.Position, Vector3.new(0, -4, 0), slideParams)

			if result then

				local DistToFloor = (HRP.Position.Y - result.Position.Y)

				local addval = 3 - (math.round(DistToFloor * 100)/100)

				local dir = (DesiredAngle - result.Normal * DesiredAngle:Dot(result.Normal)).Unit

				local slopeAngle, slopeType = CalculateSlopeEffect(HRP.CFrame.LookVector, result.Normal)
				local speedModifier = 1

				if slopeType > 0 then
					speedModifier = 1 + (slopeAngle / 45) * -math.abs(slopeType);
				elseif slopeType < 0 then
					speedModifier = 1 - (slopeAngle / 45) * -math.abs(slopeType);
				end
				
				local currentSpeed = (BodyVelocity.Velocity).Magnitude - deltaTime * Friction * speedModifier
				BodyVelocity.Velocity = dir * (currentSpeed) + Vector3.new(0, addval * 5, 0)
				
				--TS:Create(alignOrient, SlideInfo,{CFrame = CFrame.fromMatrix(HRP.Position, HRP.CFrame.RightVector, result.Normal, HRP.CFrame.RightVector:Cross(result.Normal))}):Play()

				TimeFalling = 0
			else
				MovementModule.StopSlide(Character);
			end

			if BodyVelocity.Velocity.Magnitude < 10 then
				MovementModule.StopSlide(Character)
			end
		end)
	end
end

function MovementModule.StopSlide(Character)
	local HRP : BasePart = Character:WaitForChild("HumanoidRootPart")
	local hum : Humanoid = Character:WaitForChild("Humanoid")
	
	if SlideConnection ~= nil then
		SlideConnection:Disconnect()
		SlideConnection = nil
		
		if HRP and hum then 
			HRP.AssemblyLinearVelocity = bv.Velocity
			hum.HipHeight = 0
		end
		bv:Destroy()
		ActiveAnim:Stop()
		
		--alignOrient:Destroy()
		
		EndedTick = tick()
	end
end

return MovementModule;