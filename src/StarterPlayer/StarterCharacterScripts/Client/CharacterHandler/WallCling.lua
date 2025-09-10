local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary)
local AnimatorModule = require(ReplicatedStorage.Shared.Utility.Animator)

local _use = Auxiliary.BridgeNet.ClientBridge('_use')

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAppearanceLoaded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local humanoid = Character.Humanoid

local Animator = AnimatorModule.new(LocalPlayer)
Animator:Cache()

local WallClingActive = false
local WallClingCooldown = false

local function WallClingHandle(Data)
    local HumanoidRootPart = Character.HumanoidRootPart
    local Humanoid = Character.Humanoid

    Humanoid.WalkSpeed = 0
    Humanoid.JumpHeight = 0
    Humanoid.AutoRotate = false
    
    WallClingCooldown = true
    WallClingActive = true

    local HitNormal = Data.FirstResult
    local HitInstance = Data.Instance
    local CurrentDecrease = Auxiliary.Wiki.Default.Combat.WallClingDecrease or 10
    local ClingStartTime = tick()
    local AnimationCheck

    local AlignOrientation = Instance.new('AlignOrientation')
    AlignOrientation.Parent = HumanoidRootPart
    AlignOrientation.Name = 'WallClingAlignOrientation'
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    AlignOrientation.Attachment0 = Character:FindFirstChild("RootAttachment", true)
    AlignOrientation.Responsiveness = 500
    AlignOrientation.CFrame = CFrame.lookAlong(Character.PrimaryPart.CFrame.Position, -HitNormal)
    
    local WallClingVelocity = Instance.new("LinearVelocity")
    WallClingVelocity.Attachment0 = HumanoidRootPart.RootAttachment
    WallClingVelocity.Name = "WallClingMover"
    WallClingVelocity.MaxForce = math.huge
    WallClingVelocity.Parent = HumanoidRootPart
    WallClingVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    WallClingVelocity.ForceLimitsEnabled = true
    WallClingVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    local MassValue = HumanoidRootPart.AssemblyMass * 1000
    WallClingVelocity.MaxAxesForce = Vector3.new(0, MassValue, 0)
    WallClingVelocity.VectorVelocity = Vector3.new(0, 0, 0)

    -- Play wall cling animations if available
    local WallClingLand = Animator:Fetch('Universal/WallClingLand')
    local WallClingIdle = Animator:Fetch('Universal/WallClingIdle')
    
    if WallClingLand then
        WallClingLand:Play()
        WallClingLand.Stopped:Connect(function()
            if WallClingIdle then
                WallClingIdle:Play()
            end
        end)
    elseif WallClingIdle then
        WallClingIdle:Play()
    end

    local WallClingCheckLoop

    local function StopWallCling()
        Character:SetAttribute('ClientActive', false);
        if WallClingLand then WallClingLand:Stop() end
        if WallClingIdle then WallClingIdle:Stop() end

        if WallClingVelocity then WallClingVelocity:Destroy() end
        if AlignOrientation then AlignOrientation:Destroy() end
        
        if WallClingCheckLoop then
            task.delay(0.1, function()
                WallClingCheckLoop:Disconnect()
            end)
        end
        
        if AnimationCheck then
            AnimationCheck:Disconnect()
        end

        Humanoid.WalkSpeed = Auxiliary.Wiki.Default.Combat.BaseSpeed or 26
        Humanoid.JumpHeight = Auxiliary.Wiki.Default.Combat.BaseJumpHeight or 25
        Humanoid.AutoRotate = true

        Character:SetAttribute('WallClung', nil)
        WallClingActive = false
        
        task.delay(Auxiliary.Wiki.Default.Combat.WallClingCooldown or 0.5, function()
            WallClingCooldown = false
        end)
    end

    Character:SetAttribute('WallClung', true)

    WallClingCheckLoop = RunService.Heartbeat:Connect(function()
        CurrentDecrease += 0.15
        WallClingVelocity.VectorVelocity = HumanoidRootPart.CFrame.UpVector * -CurrentDecrease
        
        if tick() - ClingStartTime >= (Auxiliary.Wiki.Default.Combat.WallClingDuration or 3) then
            StopWallCling()
        end

        -- Wall check
        local WallCheck = workspace:Raycast(HumanoidRootPart.Position, HumanoidRootPart.CFrame.LookVector * (Auxiliary.Wiki.Default.Combat.WallClingDetectionRange or 5))
        
        if not WallCheck then
            StopWallCling()
        end
        
        if Humanoid.FloorMaterial ~= Enum.Material.Air then 
            StopWallCling()
        end
    end)
end

local function WallClingJumpHandle()
    local HumanoidRootPart = Character.HumanoidRootPart
    local Humanoid = Character.Humanoid

    Humanoid.WalkSpeed = Auxiliary.Wiki.Default.Combat.BaseSpeed or 26
    Humanoid.JumpHeight = Auxiliary.Wiki.Default.Combat.BaseJumpHeight or 25
    Humanoid.AutoRotate = true
    
    -- Clear existing movers
    for _, v in pairs(HumanoidRootPart:GetChildren()) do
        if v:IsA("LinearVelocity") or v:IsA("BodyVelocity") or v:IsA("BodyPosition") then
            v:Destroy()
        end
    end
    
    Character:SetAttribute('WallClung', nil)
    WallClingActive = false
    
    task.delay(Auxiliary.Wiki.Default.Combat.WallClingJumpCooldown or 0.075, function()
        WallClingCooldown = false
    end)
    
    local WallClingJumpVelocity = Instance.new("LinearVelocity")
    WallClingJumpVelocity.Attachment0 = HumanoidRootPart.RootAttachment
    WallClingJumpVelocity.Name = "WallClingJumpMover"
    WallClingJumpVelocity.MaxForce = math.huge
    WallClingJumpVelocity.Parent = HumanoidRootPart
    WallClingJumpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    WallClingJumpVelocity.ForceLimitsEnabled = true
    WallClingJumpVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    local MassValue = HumanoidRootPart.AssemblyMass * 1000
    WallClingJumpVelocity.MaxAxesForce = Vector3.new(MassValue, MassValue, MassValue)
    
    WallClingJumpVelocity.VectorVelocity = -HumanoidRootPart.CFrame.LookVector * (Auxiliary.Wiki.Default.Combat.WallClingBackBoost or 50) + Vector3.new(0, Auxiliary.Wiki.Default.Combat.WallClingUpBoost or 50, 0)

    Debris:AddItem(WallClingJumpVelocity, 0.2)

    local WallClingJump = Animator:Fetch('Universal/WallClingJump')
    if WallClingJump then
        WallClingJump:Play()
    end
end

return function(IsJump)
    local Character = LocalPlayer.Character
    if not Character or not Character:IsDescendantOf(Auxiliary.Shared.Alive) then return end

    if IsJump and WallClingActive then
        WallClingJumpHandle()
        return
    end

    -- Check conditions
    if not _G.CanUse() then return end
    if Character:GetAttribute('UsingMove') then return end
    if WallClingActive then return end
    if WallClingCooldown then return end

    
    local HumanoidRootPart = Character.HumanoidRootPart
    local PlayerVelocity = -HumanoidRootPart.Velocity.Y
    if PlayerVelocity > 250 then return end
    
    -- Wall detection
    local detectionRange = Auxiliary.Wiki.Default.Combat.WallClingDetectionRange or 5
    local WallClingRaycast = workspace:Raycast(HumanoidRootPart.Position, HumanoidRootPart.CFrame.LookVector * detectionRange)
    
    if WallClingRaycast and WallClingRaycast.Instance.CanCollide then
        Character:SetAttribute('ClientActive', true)
        
        -- Clear existing movers
        Auxiliary.Shared.ClearAllMovers(HumanoidRootPart);

        WallClingHandle({
            FirstResult = WallClingRaycast.Normal,
            Instance = WallClingRaycast.Instance,
            Position = WallClingRaycast.Position
        })
    end
end