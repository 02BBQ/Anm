local Players = game:GetService("Players");
local UserInputService = game:GetService("UserInputService");

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)


local closed = false
local Leaderboard = script.Parent.Parent.PlayerList
local DragObject = Leaderboard.Dragger
local Detector = DragObject.UIDragDetector

local Container = Leaderboard.Board.Backdrop.Container
local Template = Leaderboard.Board.Backdrop.TemplatePlayer

local LeaderboardData = {}

function AddPlayer(Player : Player)

    local PlayerObject = Template:Clone()
    PlayerObject.DisplayName.Text = (Player:GetAttribute"LastName" or "");
    PlayerObject.RealUser.Text = Player.Name
    PlayerObject.Name = Player.Name

    Player:GetAttributeChangedSignal("LastName"):Connect(function()
        PlayerObject.DisplayName.Text = (Player:GetAttribute"LastName" or "");
    end)
    
    LeaderboardData[Player] = {UI = PlayerObject}

    PlayerObject.Parent = Container
    PlayerObject.Visible = true

    PlayerObject.MouseEnter:Connect(function()
        PlayerObject.DisplayName.Visible = false
        PlayerObject.RealUser.Visible = true
    end)

    PlayerObject.MouseLeave:Connect(function()
        PlayerObject.DisplayName.Visible = true
        PlayerObject.RealUser.Visible = false
    end)
end

return function(maid)
    --open/close
    
    maid:AddTask(UserInputService.InputBegan:Connect(function(input,gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Tab then
            closed = not closed
            Leaderboard.Visible = closed
        end
    end))
    
    --scaling
    
    maid:AddTask(Detector.DragContinue:Connect(function(position)
        local SizeinScaleHopefully = UDim2.fromScale(1,0) - UDim2.fromScale(math.min(DragObject.Position.X.Scale, 0.86), math.min(-DragObject.Position.Y.Scale,-0.15))
        Leaderboard.Board.Size = SizeinScaleHopefully
    end))
    
    maid:AddTask(Detector.DragEnd:Connect(function()
        DragObject.Position = UDim2.fromScale(1-Leaderboard.Board.Size.X.Scale, Leaderboard.Board.Size.Y.Scale)
    end))
    
    for __, P in pairs(Players:GetPlayers()) do
        AddPlayer(P)
    end
    
    maid:AddTask(Players.PlayerAdded:Connect(function(P)
        if not LeaderboardData[P] then
            AddPlayer(P)
        end
    end))
    
    maid:AddTask(Players.PlayerRemoving:Connect(function(P)
        if LeaderboardData[P] then
            LeaderboardData[P].UI:Destroy()
            LeaderboardData[P] = nil
        end
    end))
end

--[[Leaderboard.Main.Changed:Connect(UpdateSF)
Leaderboard.Main.ChildAdded:Connect(UpdateSF)
Leaderboard.Main.ChildRemoved:Connect(UpdateSF)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateSF)--]]