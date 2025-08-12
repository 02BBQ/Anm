local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimatorModule = require(ReplicatedStorage.Shared.Utility.Animator)

local Animator = AnimatorModule.new(Players.LocalPlayer);
local Character = Players.LocalPlayer.Character;
local humanoid = Character:FindFirstChildOfClass("Humanoid");
Animator:Cache();

local _state = nil;

return function(State)
    if State then 
        if _state ~= State then 
            _state = State;
            Character:SetAttribute("Running", true)
        end;
        
        if humanoid:GetState() == (Enum.HumanoidStateType.Freefall or Enum.HumanoidStateType.Jumping)
        or humanoid.WalkSpeed < 26 then
            Animator:Fetch('Universal/Run'):Stop()
        else
            if not Animator:Fetch('Universal/Run').IsPlaying then
                Animator:Fetch('Universal/Run'):Play()
            end
        end
    else
        if _state ~= State then
            _state = State;
            Character:SetAttribute("Running", false)
        end;
        Animator:Fetch('Universal/Run'):Stop()
    end
end