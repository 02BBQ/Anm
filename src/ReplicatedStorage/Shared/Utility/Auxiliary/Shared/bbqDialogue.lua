local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = game.Players.LocalPlayer

local Dialogue = {}

local dialogueData = {
    {
        Text = "This will be the ",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 17, 17)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        }),
        TextStrokeColor = Color3.new(0, 0, 0),
        Bold = false,
        Italic = false,
        Shake = {
            Enabled = false,
            Intensity = 1,
            Lifetime = 2
        },
        TypeSpeed = 0.03
    },
    {
        Text = "LAST TIME!",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 17, 17))
        }),
        TextStrokeColor = Color3.new(0, 0, 0),
        Bold = true,
        Italic = true,
        Shake = {
            Enabled = true,
            Intensity = 5,
            Lifetime = 1
        },
        TypeSpeed = 0.04
    }
}

local function easeOutQuad(t)
    return 1 + 2.70158 * math.pow(t - 1, 3) + 1.70158 * math.pow(t - 1, 2)
end

local function getColor(t, keypoints)
    for i = 1, #keypoints - 1 do
        if keypoints[i].Time <= t and t <= keypoints[i + 1].Time then
            local startKeypoint = keypoints[i]
            local endKeypoint = keypoints[i + 1]
            local alpha = (t - startKeypoint.Time) / (endKeypoint.Time - startKeypoint.Time)
            return startKeypoint.Value:lerp(endKeypoint.Value, alpha)
        end
    end
    return keypoints[1].Value
end

local function retireTexts(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == "letter" then
            child:SetAttribute("Ending", true)
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = child.Position + UDim2.new(0, 0, 0, 50),
                TextTransparency = 1,
                TextStrokeTransparency = 1
            }):Play()
            game.Debris:AddItem(child, 0.5)
        end
    end
end

local function doText(dialogue, player)
    player = player or LocalPlayer
    local dialogueUI = player.PlayerGui:FindFirstChild(player.Name .. "KJUI") or script.KJDialogue:Clone()
    local fullText = ""
    local totalWidth = 0
    local currentWidth = 0
    local delayTime = 0

    if not dialogueUI:GetAttribute("Created") then
        local template = dialogueUI:WaitForChild("Holder"):WaitForChild("Template")
        local holder = dialogueUI.Holder
        holder.Position = holder.Position - UDim2.new(0, 0, 0, 100 * #CollectionService:GetTagged("KJUI"))
        holder = template:WaitForChild("Name")
        holder.Position = holder.Position - UDim2.new(0, 0, 0, 100)
        template:WaitForChild("Name").TextTransparency = 1
        template:WaitForChild("Name").TextStrokeTransparency = 1
        TweenService:Create(template:WaitForChild("Name"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = template:WaitForChild("Name").Position + UDim2.new(0, 0, 0, 100), 
            TextTransparency = 0, 
            TextStrokeTransparency = 0
        }):Play()
        local templateCopy = template
        task.spawn(function()
            dialogueUI:SetAttribute("Created", os.clock())
            repeat
                task.wait()
            until os.clock() - dialogueUI:GetAttribute("Created") > 5 or not dialogueUI.Parent
            dialogueUI.Name = "deleting"
            retireTexts(dialogueUI.Holder.Template)
            TweenService:Create(templateCopy:WaitForChild("Name"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = templateCopy:WaitForChild("Name").Position - UDim2.new(0, 0, 0, 100), 
                TextTransparency = 1, 
                TextStrokeTransparency = 1
            }):Play()
            task.delay(1, function()
                dialogueUI:Destroy()
            end)
        end)
    else
        dialogueUI:SetAttribute("Created", os.clock())
    end

    dialogueUI.Parent = player.PlayerGui
    dialogueUI.Enabled = true
    dialogueUI.Name = player.Name .. "KJUI"
    CollectionService:AddTag(dialogueUI, "KJUI")
    dialogueUI:WaitForChild("Holder"):WaitForChild("Template"):WaitForChild("Name").Text = player.Name

    for _, dialoguePart in ipairs(dialogue) do
        fullText = fullText .. dialoguePart.Text
    end

    local higherUp = false
    for _, dialoguePart in pairs(dialogue) do
        if dialoguePart.HigherUp then
            higherUp = true
            TweenService:Create(dialogueUI.Holder, TweenInfo.new(0.2), {
                Position = UDim2.new(0.5, 0, 0.965, 0)
            }):Play()
        end
    end

    if not higherUp and dialogueUI.Holder.Position ~= UDim2.new(0.5, 0, 1, 0) then
        TweenService:Create(dialogueUI.Holder, TweenInfo.new(1), {
            Position = UDim2.new(0.5, 0, 1, 0)
        }):Play()
    end

    retireTexts(dialogueUI.Holder.Template)

    for _, dialoguePart in ipairs(dialogue) do
        local characters = string.split(dialoguePart.Text, "")
        local font = dialoguePart.Bold and Enum.Font.SourceSansBold or dialoguePart.Italic and Enum.Font.SourceSansItalic or Enum.Font.SourceSans
        for _, char in ipairs(characters) do
            totalWidth = totalWidth + TextService:GetTextSize(char, 25, font, Vector2.new(100, 100)).X
        end
    end

    for _, dialoguePart in ipairs(dialogue) do
        local characters = string.split(dialoguePart.Text, "")
        local font = dialoguePart.Bold and Enum.Font.SourceSansBold or dialoguePart.Italic and Enum.Font.SourceSansItalic or Enum.Font.SourceSans
        for _, char in ipairs(characters) do
            local textSize = TextService:GetTextSize(char, 25, font, Vector2.new(100, 100))
            local textLabel = Instance.new("TextLabel")
            local _currentWidth = currentWidth
            textLabel.AnchorPoint = Vector2.new(0, 0.5)
            textLabel.Position = UDim2.new(0.5, _currentWidth - totalWidth / 2 // 1, 0.5, 10)
            textLabel.Size = UDim2.new(0, textSize.X, 0, textSize.Y)
            textLabel.Text = char
            textLabel.Name = "letter"
            textLabel.Font = font
            textLabel.TextSize = 25
            textLabel.Parent = dialogueUI.Holder.Template
            textLabel.BackgroundTransparency = 1
            textLabel.TextStrokeColor3 = dialoguePart.TextStrokeColor
            textLabel.TextStrokeTransparency = 0
            textLabel.TextTransparency = 1
            task.delay(delayTime, function()
                local startTime = os.clock()
                repeat
                    local elapsedTime = math.min((os.clock() - startTime) / 0.35, 1)
                    local shakeTime = math.min((os.clock() - startTime) / dialoguePart.Shake.Lifetime, 1)
                    local shakeOffset = not dialoguePart.Shake.Enabled and UDim2.new(0, 0, 0, 0) or UDim2.new(0, math.random(-dialoguePart.Shake.Intensity, dialoguePart.Shake.Intensity) * (1 - shakeTime), 0, math.random(-dialoguePart.Shake.Intensity, dialoguePart.Shake.Intensity) * (1 - shakeTime))
                    local transparency = 1 - easeOutQuad(elapsedTime)
                    textLabel.TextStrokeTransparency = (1 - elapsedTime) ^ 10
                    textLabel.TextTransparency = transparency
                    textLabel.TextSize = 25 + 25 * transparency
                    textLabel.TextColor3 = getColor(elapsedTime, dialoguePart.Color.Keypoints)
                    textLabel.Position = UDim2.new(0.5, _currentWidth - totalWidth / 2, 0.5, 0) + shakeOffset
                    task.wait()
                until os.clock() - startTime > math.max(0.35, dialoguePart.Shake.Lifetime) or not textLabel or not textLabel:IsDescendantOf(dialogueUI) or textLabel:GetAttribute("Ending")
                if textLabel then
                    textLabel.TextStrokeTransparency = 0
                    textLabel.TextTransparency = 0
                    textLabel.TextSize = 25
                    textLabel.TextColor3 = dialoguePart.Color.Keypoints[#dialoguePart.Color.Keypoints].Value
                    textLabel.Position = UDim2.new(0.5, _currentWidth - totalWidth / 2, 0.5, 0)
                end
            end)
            delayTime = delayTime + dialoguePart.TypeSpeed
            currentWidth = currentWidth + textSize.X
        end
    end
end

Dialogue.Speak = function(player, dialogue)
    doText(dialogue, player)
end

return Dialogue
