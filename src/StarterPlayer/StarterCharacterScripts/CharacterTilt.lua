-- Services --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Game --
local Player = Players.LocalPlayer
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid", 8)
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 8)
local Torso = Character:WaitForChild("Torso", 8)
local RootJoint = HumanoidRootPart.RootJoint
local LeftHipJoint = Torso["Left Hip"]
local RightHipJoint = Torso["Right Hip"]
local Force = nil
local Direction = nil
local Value1 = 0
local Value2 = 0
local RootJointC0 = RootJoint.C0
local LeftHipJointC0 = LeftHipJoint.C0
local RightHipJointC0 = RightHipJoint.C0

-- Modules --
local Config = require(ReplicatedStorage.Modules.Configuration)

-- Values --
local Tilt = Config.GameData.MaxTiltAngle

-- Functions --
local function Lerp(a, b, c)
	return a + (b - a) * c
end

--

RunService.RenderStepped:Connect(function(DeltaTime)
	Force = HumanoidRootPart.Velocity * Vector3.new(1,0,1)
	if Force.Magnitude > 2 then
		Direction = Force.Unit	
		Value1 = HumanoidRootPart.CFrame.RightVector:Dot(Direction)
		Value2 = HumanoidRootPart.CFrame.LookVector:Dot(Direction)
	else
		Value1 = 0
		Value2 = 0
	end

	RootJoint.C0 = RootJoint.C0:Lerp(RootJointC0 * CFrame.Angles(math.rad(Value2 * Tilt), math.rad(-Value1 * Tilt), 0), 6 * DeltaTime)
	LeftHipJoint.C0 = LeftHipJoint.C0:Lerp(LeftHipJointC0 * CFrame.Angles(math.rad(Value1 * Tilt), 0, 0), 6 * DeltaTime)
	RightHipJoint.C0 = RightHipJoint.C0:Lerp(RightHipJointC0 * CFrame.Angles(math.rad(-Value1 * Tilt), 0, 0), 6 * DeltaTime)
end)
