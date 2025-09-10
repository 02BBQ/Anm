local CharacterHandler = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local userGameSettings = UserSettings():GetService("UserGameSettings")

--// Variables
local LocalPlayer = Players.LocalPlayer
local Character: Model  = LocalPlayer.Character or LocalPlayer.CharacterAppearanceLoaded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local humanoid = Character.Humanoid

local camera = workspace.CurrentCamera

local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary)
local AnimatorModule = require(ReplicatedStorage.Shared.Utility.Animator)
local Animator = _G.Animator

CharacterHandler.AirStepped = false;
CharacterHandler.RelativeCFrame = CFrame.new()
CharacterHandler.AirSteppedQueue = nil;

local keyDown = false
local totalHops = 0
local hopTime = os.clock() 

return function() 
	local hop = UserInputService.JumpRequest:Connect(function()
		keyDown = true
		task.delay(0.2,function()
			keyDown = false 
		end)

		if not Character:GetAttribute("Movement") and totalHops < 4 then  -- and not Character:WaitForChild("Stuns"):FindFirstChild("Stunned") and not Character:WaitForChild("Ragdolls"):FindFirstChild("Ragdolled") and not (humanoid.Health <= 0) then
			if humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid.FloorMaterial == Enum.Material.Air then
				local ray
				local hop

				if camera.CFrame:VectorToObjectSpace(humanoid.MoveDirection).Unit.X < -.5 then
					ray = workspace:Raycast(HRP.Position,(HRP.CFrame.LookVector/2+-HRP.CFrame.RightVector).Unit*3,Auxiliary.Shared.RayParams.Map)
					hop = "Left"
				elseif camera.CFrame:VectorToObjectSpace(humanoid.MoveDirection).Unit.X > .5 then
					ray = workspace:Raycast(HRP.Position,(HRP.CFrame.LookVector/2+HRP.CFrame.RightVector).Unit*3,Auxiliary.Shared.RayParams.Map)
					hop = "Right"
				end

				if ray and ray.Instance and hop then
					userGameSettings.RotationType = Enum.RotationType.CameraRelative

					totalHops += 1
					Character:SetAttribute("Movement", true)

					if totalHops >= 4 then
						task.delay(3.5, function()
							totalHops = 0
							Character:SetAttribute("Movement", nil)
						end)
					else
						task.delay(0.5, function()
							Character:SetAttribute("Movement", nil)
						end)
					end

					Auxiliary.Shared.ClearAllMovers(HRP);

					local bv = Auxiliary.Shared.CreateVelocity(workspace)
					bv.MaxForce = Vector3.new(90000,90000,90000)

					if hop == "Left" then
						local leftHopAnim = Animator:Fetch('Universal/WallHopLeft')
						leftHopAnim:Play()

						bv.Velocity = HRP.CFrame.RightVector*25+Vector3.new(0,50,0)

						leftHopAnim.Stopped:Connect(function()

						end)
					else
						local rightHopAnim = Animator:Fetch('Universal/WallHopRight')
						rightHopAnim:Play()

						bv.Velocity = HRP.CFrame.RightVector*-25+Vector3.new(0,50,0)

						rightHopAnim.Stopped:Connect(function()

						end)
					end

					bv.Parent = HRP
					game.Debris:AddItem(bv,.12)

					bv.Destroying:Connect(function()
						userGameSettings.RotationType = Enum.RotationType.MovementRelative
					end)
				end
			end
		end
	end)
	local rem rem = Character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			hop:Disconnect();
			rem:Disconnect();
		end
	end)
	return hop
end
