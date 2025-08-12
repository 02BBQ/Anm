local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local Shared = ReplicatedStorage.Shared;

local InputHandlerModule = require(script.InputHandler);
local CharacterHandler = require(script.CharacterHandler);
local ActionHandler = require(script.ActionHandler);
local Maid = require(Shared.Utility.Maid);

local InputHandler = InputHandlerModule.new();

local Player = Players.LocalPlayer
local character = Player.Character or Player.CharacterAdded:Wait()
local humanoid = character.Humanoid;

local lastPressTime = 0
local doubleTapThreshold = 0.3

local initialize = function()
	InputHandler:BindAction(Enum.UserInputType.MouseButton1, ActionHandler.LightAttack);
	InputHandler:BindAction(Enum.KeyCode.R, ActionHandler.Critical);
	InputHandler:BindAction(Enum.KeyCode.F, ActionHandler.Block);
	InputHandler:BindAction(Enum.KeyCode.Q, ActionHandler.Dash);
	InputHandler:BindAction(Enum.KeyCode.W, ActionHandler.Sprint);

	require(ReplicatedStorage:WaitForChild"CmdrClient"):SetActivationKeys({
		Enum.KeyCode.F2,
	})
	
	CharacterHandler.Initialize();
end

initialize()

local ClientMaid = Maid.new();

ClientMaid:AddTask(InputHandler);

ClientMaid:AddTask(UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	InputHandler:HandleInput(input, true)
end))

ClientMaid:AddTask(UserInputService.InputEnded:Connect(function(input, gp)
	InputHandler:HandleInput(input, false)
end))

ClientMaid:AddTask(humanoid.Died:Connect(function()
	ClientMaid:Destroy()
end))

--UserInputService.InputBegan:Connect(function(input, isProcessed)
--	if isProcessed then return end  -- 채팅창 입력 무시
	
--	if input.KeyCode == Enum.KeyCode.LeftControl then
--		--InputRemote:FireServer({Ability_P = "Basic",MoveName = "Run",Character = Character})
--	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
--		InputRemote:FireServer({Ability_P = "Basic",MoveName = "LightAttack",Character = Character})
--	elseif input.KeyCode == Enum.KeyCode.R then
--		InputRemote:FireServer({Ability_P = "Basic",MoveName = "CriticalAttack",Character = Character})
--	elseif input.KeyCode == Enum.KeyCode.F then
--		-- 방어 시작
--		InputRemote:FireServer({Ability_P = "Basic",MoveName = "Block",Character = Character,Holding = true})
--	elseif input.KeyCode == Enum.KeyCode.Q then
--		InputRemote:FireServer({Ability_P = "Basic",MoveName = "Dash",Character = Character})
--	end
--	if input.KeyCode == Enum.KeyCode.W then
--		local currentTime = tick()
--		if currentTime - lastPressTime < doubleTapThreshold then
--			-- 더블탭: 달리기 모드 시작
--			InputRemote:FireServer({Ability_P = "Basic",MoveName = "Run",Character = Character})
--		end
--		lastPressTime = currentTime
--	end
--end)
--UserInputService.InputEnded:Connect(function(input, isProcessed)
--	if isProcessed then return end  -- 채팅창 입력 무시

--	if input.KeyCode == Enum.KeyCode.F then
--		-- 방어 취소 + 방어 캔슬
--		InputRemote:FireServer({Ability_P = "Basic",MoveName = "Block",Character = Character,Holding = false})
--	end
--	if input.KeyCode == Enum.KeyCode.W and Character:GetAttribute("Running") == true then
--		-- W 키 뗐을 때: 걷기로 돌아감
--		InputRemote:FireServer({Ability_P = "Basic",MoveName = "Run",Character = Character})
--	end
--end)

