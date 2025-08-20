-- Backpack / Hotbar UI Controller (client-only / no server calls)

--// Services
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

--// Player & Character
local Player    = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Backpack  = Player:WaitForChild("Backpack", 9e9)
local Humanoid  = Character:WaitForChild("Humanoid", 9e9)

--// UI References
local guiRoot        = script.Parent
local ToolButtonTpl  = script:WaitForChild("ToolFrame", 9e9)
local MainFrame      = guiRoot:WaitForChild("MainFrame", 9e9)
local BackpackFrame  = guiRoot:WaitForChild("BackpackFrame", 9e9)
local Scrolling      = BackpackFrame:WaitForChild("ScrollingFrame", 9e9)
local Grid           = Scrolling:WaitForChild("UIGridLayout", 9e9)
--local StatContainer  = guiRoot.Parent:WaitForChild("StatGui"):WaitForChild("Container", 9e9)

-- Wait for game-specific gate
--repeat task.wait(0.25)
--until Character:FindFirstChild("SkillsLoaded") or Character:FindFirstChild("SeraphLoad")

--// Constants
local SLOTS_COUNT = 10
local SLOT_KEY_LABELS = { "1","2","3","4","5","6","7","8","9","0","-","=" }
local DEFUALT_COLOR = Color3.fromRGB(11, 11, 11);
local SELECT_COLOR = Color3.fromRGB(22, 22, 22);

local TOOLTYPE = {
	PrimaryWeapon = 0,
	Skill         = 1,
	Spell         = 2,
	Item          = 3,
	Trinket       = 4,
	Ingredient    = 5,
	Other         = 6,
}

--// State (client-only)
local equipCooldowns = {}           -- toolName -> timestamp
local slotToTool     = {}           -- slot index -> toolName
local 	toolInfo       = {}           -- toolName -> { frame, tooltype, slot, quantityCon }
local savedSlotMap   = {}           -- "1".."12" -> toolName (session-only, no persistence)

local slotMarkers = {}
local draggingToolName = nil
local isBackpackOpen = false

--// Helpers
local function updateScrollingCanvasSize()
	Scrolling.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + 16)
end
Grid.Changed:Connect(updateScrollingCanvasSize)
updateScrollingCanvasSize()

local function findToolIn(container: Instance, name: string): Tool?
	for _, inst in container:GetChildren() do
		if inst.Name == name and inst:IsA("Tool") then
			return inst
		end
	end
	return nil
end

local function classifyTool(tool: Tool): number
	local Type = tool:GetAttribute("Type");
	if not Type then return TOOLTYPE.Other end
	if Type == ("PrimaryWeapon") then return TOOLTYPE.PrimaryWeapon end
	if Type == ("Skill")         then return TOOLTYPE.Skill         end
	if Type == ("Spell")         then return TOOLTYPE.Spell         end
	if Type == ("Item")          then return TOOLTYPE.Item          end
	if Type == ("Trinket")       then return TOOLTYPE.Trinket       end
	if Type == ("isIngredient")  then return TOOLTYPE.Ingredient    end
	return TOOLTYPE.Other
end

local function toggleEquip(toolName: string)
	local now = tick()
	if equipCooldowns[toolName] and now < equipCooldowns[toolName] then return end

	local toolOnChar = Character:FindFirstChild(toolName)
	if toolOnChar then
		if toolOnChar:FindFirstChild("Handle") then
			equipCooldowns[toolName] = now + 0.2
		end
		Humanoid:UnequipTools()
		return
	end

	local toolInBag = findToolIn(Backpack, toolName)
	if toolInBag then
		if toolInBag:FindFirstChild("Handle") then
			equipCooldowns[toolName] = now + 0.2
		end
		Humanoid:EquipTool(toolInBag)
	end
end

local function assignToolToSlot(slotIndex: number?, toolName: string)
	local info = toolInfo[toolName]
	if not info then return end

	if info.slot then
		slotToTool[info.slot] = nil
		savedSlotMap[tostring(info.slot)] = nil
	end

	if slotIndex then
		local occupying = slotToTool[slotIndex]
		if occupying then
			local occInfo = toolInfo[occupying]
			if occInfo and info.slot then
				slotToTool[info.slot] = occupying
				savedSlotMap[tostring(info.slot)] = occupying
				occInfo.slot = info.slot
			end
		end
		slotToTool[slotIndex] = toolName
		savedSlotMap[tostring(slotIndex)] = toolName
	end

	info.slot = slotIndex
end

-- slot guides
for i = 1, SLOTS_COUNT do
	local marker = script.SlotMarker:Clone()
	marker.Visible  = false
	marker.Position = UDim2.new((i - 1) / (SLOTS_COUNT - 1), 0, 0, 0)
	marker.Parent   = MainFrame
	slotMarkers[i]  = marker
end

local function refreshUI()
	-- used slot count
	local usedSlots = 0
	for i = 1, SLOTS_COUNT do
		if slotToTool[i] then usedSlots += 1 end
	end

	-- quantities
	local tools = Backpack:GetChildren()
	local equipped = Character:FindFirstChildOfClass("Tool")
	if equipped then table.insert(tools, equipped) end

	local totalQuantity = {}
	for _, t in ipairs(tools) do
		local name = t.Name
		local qVal = (t:FindFirstChild("Quantity") and (t :: any).Quantity.Value) or 1
		totalQuantity[name] = (totalQuantity[name] or 0) + qVal
	end

	-- place hotbar items
	local placed = 0
	for i = 1, SLOTS_COUNT do
		local toolName = slotToTool[i]
		local info = toolName and toolInfo[toolName]
		if info then
			placed += 1
			local frame = info.frame
			if frame and draggingToolName ~= toolName then
				local t = (usedSlots > 1) and (placed - 1) / (usedSlots - 1) or 0
				if isBackpackOpen then t = (i - 1) / (SLOTS_COUNT - 1) end
				frame.Slot.Text = SLOT_KEY_LABELS[i]
				frame.Position  = UDim2.new(t, 0, 0, 0)
				frame.Slot.Visible = true
				frame.Parent = MainFrame
				if slotMarkers[i] then slotMarkers[i].Visible = false end
			end
		else
			if slotMarkers[i] then slotMarkers[i].Visible = isBackpackOpen end
		end
	end

	-- per-tool visuals
	for name, info in pairs(toolInfo) do
		local frame = info.frame
		if not frame then continue end

		local q = totalQuantity[name]
		if q then
			frame.Quantity.Text = string.format("x%i", q)
			frame.Quantity.Visible = q > 1
		end

		if draggingToolName ~= name then
			local isSelected = CollectionService:HasTag(frame, "BPSelected")
			if Character:FindFirstChild(name) then
				if not isSelected then
					TweenService:Create(frame, TweenInfo.new(0.1), {
						BackgroundColor3 = SELECT_COLOR,
						TextTransparency = 0
					}):Play()
					TweenService:Create(frame.Overlay, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
						Size = UDim2.new(1, 10, 1, 10)
					}):Play()
					CollectionService:AddTag(frame, "BPSelected")
				end
			elseif isSelected then
				TweenService:Create(frame, TweenInfo.new(0.1), {
					BackgroundColor3 = DEFUALT_COLOR,
					TextTransparency = 0.2
				}):Play()
				TweenService:Create(frame.Overlay, TweenInfo.new(0.1), {
					Size = UDim2.new(1, 6, 1, 6)
				}):Play()
				CollectionService:RemoveTag(frame, "BPSelected")
			else
				frame.BackgroundColor3 = DEFUALT_COLOR
				frame.TextTransparency = 0.2
				frame.Overlay.Size     = UDim2.new(1, 6, 1, 6)
			end

			if not info.slot then
				frame.Slot.Visible = false
				frame.Parent = Scrolling
			end
		end
	end

	local width = (usedSlots > 1) and (72 * (usedSlots - 1)) or 0
	if isBackpackOpen then width = 792 end
	MainFrame.Size = UDim2.new(0, width, 0, 60)

	BackpackFrame.Visible = isBackpackOpen
end

local function createToolButton(tool: Tool, mayAutoSlot: boolean)
	if not tool.Parent then return end
	local name = tool.Name
	if toolInfo[name] then return end

	local frame = ToolButtonTpl:Clone()
	frame.Text = name

	local typeId = classifyTool(tool)
	frame.Name = tostring(typeId) .. name

	local info -- forward declare
	frame.MouseButton1Down:Connect(function()
		if draggingToolName then return end

		if not isBackpackOpen then
			toggleEquip(name)
			refreshUI()
			return
		end

		local currentSlot = info.slot
		draggingToolName = name

		frame.BackgroundColor3 = SELECT_COLOR
		frame.Parent = guiRoot

		for i = 1, SLOTS_COUNT do
			local occName = slotToTool[i]
			local occInfo = occName and toolInfo[occName]
			local marker  = slotMarkers[i]
			if marker then
				marker.Visible = not occInfo or not occInfo.frame or i == currentSlot
			end
		end

		local CurrentCamera = workspace.CurrentCamera
		local dropSlot = nil

		while true do
			local mouse = UserInputService:GetMouseLocation()
			frame.Position = UDim2.new(0, mouse.X, 0, mouse.Y)

			local vp = CurrentCamera.ViewportSize
			local overHotbar = (mouse.Y > (vp.Y - 70))

			local normalized = (mouse.X - ((vp/2).X - 396)) / 792 * (SLOTS_COUNT - 1) + 1
			local nearest = (normalized - math.floor(normalized) > 0.5)
				and math.ceil(normalized) or math.floor(normalized)

			if nearest >= 1 and nearest <= SLOTS_COUNT and overHotbar then
				dropSlot = nearest
			else
				dropSlot = nil
			end

			RunService.RenderStepped:Wait()
			if not draggingToolName then break end
		end

		if dropSlot == currentSlot then
			toggleEquip(name)
		else
			assignToolToSlot(dropSlot, name)
		end
		refreshUI()
	end)

	info = {
		frame = frame,
		tooltype = typeId,
		slot = nil,
		quantityCon = nil,
	}
	toolInfo[name] = info

	local qty = tool:FindFirstChild("Quantity")
	if qty then
		info.quantityCon = qty.Changed:Connect(refreshUI)
	end

	local restored = false
	for k, v in pairs(savedSlotMap) do
		local index = tonumber(k)
		if index and v == name then
			assignToolToSlot(index, name)
			restored = true
			break
		end
	end

	if (not restored) and mayAutoSlot then
		for i = 1, SLOTS_COUNT do
			if not slotToTool[i] then
				assignToolToSlot(i, name)
				break
			end
		end
	end

	refreshUI()
end

local function removeToolByName(toolName: string)
	local info = toolInfo[toolName]
	if not info then return end

	if Character:FindFirstChild(toolName) or findToolIn(Backpack, toolName) then
		return
	end

	-- FIXME: 원본 동작 보존 (항상 6으로 처리)
	local v85 = 6
	-- 만약 의도된 로직으로 고치려면 아래로 교체:
	-- local v85 = info.tooltype or TOOLTYPE.Other

	toolInfo[toolName] = nil
	if info.frame then info.frame:Destroy() end

	if info.slot and slotToTool[info.slot] == toolName and v85 ~= 1 and v85 ~= 2 and v85 ~= 0 then
		slotToTool[info.slot] = nil
		savedSlotMap[tostring(info.slot)] = nil
	end

	if info.quantityCon then
		pcall(function() info.quantityCon:Disconnect() end)
	end

	refreshUI()
end

--// Input
local KEY_TO_SLOT = {
	[Enum.KeyCode.One]    = 1,
	[Enum.KeyCode.Two]    = 2,
	[Enum.KeyCode.Three]  = 3,
	[Enum.KeyCode.Four]   = 4,
	[Enum.KeyCode.Five]   = 5,
	[Enum.KeyCode.Six]    = 6,
	[Enum.KeyCode.Seven]  = 7,
	[Enum.KeyCode.Eight]  = 8,
	[Enum.KeyCode.Nine]   = 9,
	[Enum.KeyCode.Zero]   = 10,
	[Enum.KeyCode.Minus]  = 11,
	[Enum.KeyCode.Equals] = 12,
}

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	local slotIndex = KEY_TO_SLOT[input.KeyCode]
	local toolName = slotIndex and slotToTool[slotIndex]
	if toolName then
		toggleEquip(toolName)
		refreshUI()
		return
	end

	if input.KeyCode == Enum.KeyCode.Backquote then
		isBackpackOpen = not isBackpackOpen
		--StatContainer.Visible = not isBackpackOpen
		refreshUI()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingToolName = nil
	end
end)

--// Backpack & Character listeners
Backpack.ChildAdded:Connect(function(obj)
	if not obj:IsA("Tool") then return end
	if toolInfo[obj.Name] then
		refreshUI()
		return
	end
	task.wait()
	createToolButton(obj, true)
end)

Backpack.ChildRemoved:Connect(function(obj)
	if not obj:IsA("Tool") then return end
	if not toolInfo[obj.Name] then
		refreshUI()
		return
	end
	removeToolByName(obj.Name)
end)

Character.ChildAdded:Connect(function(obj)
	if not obj:IsA("Tool") then return end
	if toolInfo[obj.Name] then
		refreshUI()
		return
	end
	task.wait()
	createToolButton(obj, true)
end)

Character.ChildRemoved:Connect(function(obj)
	if not obj:IsA("Tool") then return end
	if not toolInfo[obj.Name] then
		refreshUI()
		return
	end
	removeToolByName(obj.Name)
end)

-- initial populate
local hadSaved = next(savedSlotMap) ~= nil -- always false in client-only
for _, t in ipairs(Backpack:GetChildren()) do
	if t:IsA("Tool") then
		createToolButton(t, not hadSaved)
	end
end

-- Hide default CoreGui
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,   false)
