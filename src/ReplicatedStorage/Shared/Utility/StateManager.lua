local StateService = {}

--

function StateService:GetInfoFolder(character)
	local info = character:FindFirstChild("Info")
	
	if not info then
		info = Instance.new("Folder")
		info.Name = "Info"
		info.Parent = character
	end
	
	return info
end

--

function StateService:HasState(character, stateName)
	local info = StateService:GetInfoFolder(character)
	return info:FindFirstChild(stateName) ~= nil
end

--

function StateService:AddState(character, stateName, duration)
	local info = StateService:GetInfoFolder(character)
	if info:FindFirstChild(stateName) then return end

	local state = Instance.new("BoolValue")
	state.Name = stateName
	state.Value = false
	state.Parent = info

	if duration then
		task.delay(duration, function()
			if state and state.Parent then
				state:Destroy()
			end
		end)
	end
end

--

function StateService:RemoveState(character, stateName)
	local info = self:GetInfoFolder(character)
	local state = info:FindFirstChild(stateName)
	if state then
		state:Destroy()
	end
end

--

return StateService