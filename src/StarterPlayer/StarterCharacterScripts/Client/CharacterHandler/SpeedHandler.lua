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
local Character = LocalPlayer.Character or LocalPlayer.CharacterAppearanceLoaded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local humanoid: Humanoid = Character.Humanoid

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

local jumpTick = 0

humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.Jumping then
		jumpTick = tick()
	end
end)

return function() 
	local function onRender(dt)
		local cache = {};
		
		local WalkSpeed = (Character:GetAttribute("Running") and _G.CanUse() and not _G.EffectReplicator:FindEffect("SlowedMovement")) and 36 or 15
		local JumpPower = 50 - 10 * (1 - humanoid.Health / humanoid.MaxHealth);
		
		for i, Effect in _G.EffectReplicator:GetEffects() do
			local Value = Effect.Value or 1;
			local Class = Effect.Class;
			if Class == "Jump" then
				JumpPower += Value
			end
			if Class == "Speed" or Class == "SpeedBoost" then
				WalkSpeed += Value
			end
			if Class == "SlowedMovement" then
				WalkSpeed += Value
			end
			if Class == "SpeedBoostMultiplier" then
				WalkSpeed *= Value
			end
			-- if Class == "ControlledSlow" then
			-- 	WalkSpeed = WalkSpeed - (WalkSpeed * 0.1)
			-- end

			if cache[Class] == nil then
				cache[Class] = {};
			end
			if not Class.Disabled then
				table.insert(cache[Class], Value);
			end
		end

		if cache["UsingMove"] then
			WalkSpeed -= 1
		end
		
		if cache["Stunned"] then
			WalkSpeed -= 10
		end
		
		if _G.EffectReplicator:FindEffect("CantMove") then
			WalkSpeed = 0;
			JumpPower = 0;
		end

		if not Character:GetAttribute("Flash") then
			humanoid.WalkSpeed = WalkSpeed
		end
		
		if tick() - jumpTick < 0.6 then
			JumpPower *= 0.7
		end
	
		humanoid.JumpPower = JumpPower
	end
	return RunService.RenderStepped:Connect(onRender);
end
