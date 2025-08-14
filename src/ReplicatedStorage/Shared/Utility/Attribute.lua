local attributeLookup = {}

function attributeLookup:__index(index)
	if (index == "Changed") then
		return function(Name, Fn)
			return rawget(self, "Ins"):GetAttributeChangedSignal(Name):Connect(Fn)
		end
	end

	return rawget(self, "Ins"):GetAttribute(index)
end

function attributeLookup:__newindex(index, value)
	if (value == "nil") then value = nil; end;
	rawget(self, "Ins"):SetAttribute(index, value)
end

return function(Ins)
	local self = {}
	self.Ins = Ins;

	setmetatable(self, attributeLookup)
	
	return self
end