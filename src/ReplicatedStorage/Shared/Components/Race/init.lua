
local module = {}

local Races = {};

for _,raceModule in pairs(script:GetChildren()) do
	Races[raceModule.Name] = require(raceModule);
end

module.Races = Races;

local rarities = {};

for key,Race in pairs(Races) do
	rarities[key] = Race.Rarity;
end

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

function module.Initialize(Entity)
	local character = Entity.Character;
	
	Races[Entity.Data.Race]["Initialize"](Entity);
end

return module
