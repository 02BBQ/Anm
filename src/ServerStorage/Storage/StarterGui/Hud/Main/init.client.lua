local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Tween = game:GetService("TweenService");
local Maid = require(ReplicatedStorage.Shared.Utility.Maid);



local UIMaid = Maid.new();

local Player = Players.LocalPlayer;
local Character = Player.Character;
local Humanoid : Humanoid? = Character.Humanoid;
local MainFrame = script.Parent.MainFrame;

local StatusFrame = MainFrame:WaitForChild("Display")

local Health = Player.PlayerGui.Hud.MainFrame.Display.Health

local function UpdateHealth()
	local HPRatio = UDim2.new(math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1), 0, 1, 0)
	--local HPLagRatio = UDim2.new(math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1), 0, 0, 0)

	Health.Fill.Size = HPRatio  

	local Tween = Tween:Create(Health.Delay, TweenInfo.new(0.4), {Size = HPRatio});
	Tween:Play();
end

UIMaid:AddTask(Humanoid:GetPropertyChangedSignal("Health"):Connect(UpdateHealth))
UIMaid:AddTask(Humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(UpdateHealth))
UpdateHealth()

require(script.Leaderboard)(UIMaid);

UIMaid:AddTask(Humanoid.Died:Connect(function()
	UpdateHealth();
	UIMaid.Destroy();
end));