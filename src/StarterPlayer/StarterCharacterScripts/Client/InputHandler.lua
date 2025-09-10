-- InputComponent.lua
local UserInputService = game:GetService("UserInputService")

local InputComponent = {}
InputComponent.__index = InputComponent

function InputComponent.new()
	local self = setmetatable({}, InputComponent)
	self.actions = {}  -- 각 입력에 대한 동작과 인자 등록

	return self
end

function InputComponent:BindAction(keyCode, callback, ...)
	self.actions[keyCode] = {callback = callback, args = {...}}
end

local mouseInputTypes = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseButton2] = true,
	[Enum.UserInputType.MouseButton3] = true,
}

function InputComponent:HandleInput(Input: InputObject, isHeld)
	local action
	
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		action = self.actions[Input.KeyCode]
	else --if mouseInputTypes[Input.UserInputType] then
		action = self.actions[Input.UserInputType]	
	end
	
	if action then
		action:callback(Input.UserInputState == Enum.UserInputState.Begin and true or false, table.unpack(action.args))
	end
end

function InputComponent:Destroy()
	self = nil;
end

return InputComponent
