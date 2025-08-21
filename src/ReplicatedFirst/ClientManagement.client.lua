local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local assets = { 
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Assets"):WaitForChild("Animations"),
}

ContentProvider:PreloadAsync(assets)

print("All assets loaded.")


local BridgeNet2 = require(ReplicatedStorage.Shared.Components.BridgeNet2);
local EffectHandler = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFXHandler"));
local Sound = require(ReplicatedStorage.Shared.Utility.SoundHandler);
Sound:Cache();

local _effect = BridgeNet2.ReferenceBridge('_effect');
local player = Players.LocalPlayer

function doEffect(a,Data)
	local dis = Data.Distance or 150
	local suc,err = pcall(function()
		local target = Data.Caster.Character.Root;
		if target:IsA("Model") then target = target.PrimaryPart or target:FindFirstChildOfClass"Part" end
		if not target then return end;
		if (target.Position-player.Character.HumanoidRootPart.Position).magnitude > dis then	
			return;
		end
		if not EffectHandler[a] then
			return;
		end
		if typeof(EffectHandler[a]) == "table" then
			EffectHandler[a][Data.Action](Data)
		else
			EffectHandler[a](Data)
		end
	end)
	
	if not suc then
		error(err)
	end
end

_effect:Connect(function(data)
	doEffect(data[1], data[2])
end)