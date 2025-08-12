local CS = game:GetService("CollectionService")

local module = {}
local ranNum = math.random
function module.getRandomItem(list) -- total can be above 100
	local Sum = 0
	for i,v in pairs(list) do
		Sum += v
	end
	local Chance = ranNum(Sum)
	local Count = 0
	for i,v in pairs(list) do
		Count += v
		if Chance <= Count then
			return i, v
		end
	end
end


return module
