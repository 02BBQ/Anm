
local module = {}

local Races = {};

for _,raceModule in pairs(script:GetChildren()) do
	Races[raceModule.Name] = require(raceModule);
end

local rarities = {
	Kasparan = 40,
	Ashiin = 35,
	Haseldan = 35,
	Rigan = 35,
	RiganDarkly = 35,
	Castellan = 35,
	Morvid = 20,
	DzinBlue = 12,
	Madrasian = 20,
	Gaian = 20,
	Fischeran = 14,
	Dzin = 12,
	Dinakeri = 14,
	Vind = 14,
	LesserNavaran = 14,
	Scroom = 35,
}

local random = Random.new()


function module.Choose()
	local sum = 0
	for _, weight in pairs(rarities) do
		sum += weight
	end 
	local choice = random:NextNumber(0, sum)

	local result
	for item, weight in pairs(rarities) do
		choice -= weight
		if choice <= 0 then
			result = item
			break
		end
	end
	if result == "Azael" then repeat result = rarities[math.random(1,#rarities)] until result ~= "Azael" end -- i would make it redo the entire rolling thing but if you had the luck to roll fucking azael than i think you deserve a same chance roll
	return result
end

function module.ChooseReroll()
	local sum = 0
	for _, weight in pairs(rarities) do
		sum += weight
	end 
	local choice = random:NextNumber(0, sum)

	local result
	for item, weight in pairs(rarities) do
		choice -= weight
		if choice <= 0 then
			result = item
			break
		end
	end
	return result
end

function module.Initialize(Entity, Race)
	local character = Entity.Character;
	
	local Module = Races[Race]["Initialize"](Entity);
end

return module
