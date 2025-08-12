local R_RacePools = {}

local pools = {
	["Human"] = 70;
	["Stonevein"] = 15; -- 돌맹이
	["Batbor"] = 6; -- 박쥐
	["Cindrak"] = 5; -- 불
	["Arachkin"] = 3; -- 거미
	["Mycoroid"] = 1; -- 곰팡이
}
function R_RacePools.GetRacePools()
	return pools
end

return R_RacePools
