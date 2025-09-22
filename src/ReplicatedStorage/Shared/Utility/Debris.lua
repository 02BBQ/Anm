local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Items = {}

local Types = {
	["Instance"] = "Destroy",
	["Table"] = "Remove",
	["RBXScriptConnection"] = "Disconnect",
}

local function MoreAccurateWait(Value) -- More accurate due to normal wait being limited to 30hZ whilst this one is at 60hz
	Value = Value or 1/60
	local Start = os.clock()
	while os.clock() - Start < Value do
		RunService.Stepped:Wait()
	end
end

local function RemoveItem(Part)
	local Info = Items[Part]
	
	if Info[4] == "Instance" then		
		if Info[5] then
			local Tween = TweenService:Create(Part, Info[5].Tweeninfo, Info[5].Goals)
			Tween:Play()
			coroutine.resume(coroutine.create(function()
				MoreAccurateWait(Info[5].Duration)
				Part:Destroy()
			end))
		else
			Part:Destroy()
		end
	elseif Info[4] == "RBXScriptConnection" then
		Info[1]:Disconnect()
	else
		table.clear(Part[1])
	end

	Items[Part] = nil
end

local function AddItem(Part, Lifetime,Info) --  Info is like this {Duration = 1, Tweeninfo = TweenInfo.new(Duration,EasingStyle, EasingDirecton), Goals = {CFrame = CFrame.new(0,-5,0)}
	local Type = typeof(Part) --                                                 Case sensitive

	assert(Types[Type])
	assert(typeof(Lifetime) == "number")
	Info = Info or false
	Items[Part] = {Part, Lifetime, os.clock(), Type, Info}
end

local Debris3 = {}

function Debris3:AddItem(Part, Lifetime, Info)
	AddItem(Part, Lifetime, Info)
end

function Debris3:AddItems(Parts, Lifetimes, Info)

	for i, Item in ipairs(Parts) do
		AddItem(Item, Lifetimes[i], Info)
	end

end

function Debris3:CancelItem(Item)
	if Items[Item] then
		Items[Item] = nil
	end
end

function Debris3:GetAllDebris()
	return Items
end

function Debris3:GetDebris(Item)
	return Items[Item]
end

RunService.Heartbeat:Connect(function()
	for Part, Info in next, Items do

		if os.clock() -(Info[3] + Info[2]) > 0 then
			RemoveItem(Part)
		end

	end
end)

return Debris3