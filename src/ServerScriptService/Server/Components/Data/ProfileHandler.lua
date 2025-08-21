--//Variables
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local serverScriptService = game:GetService('ServerScriptService');

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local ProfileService = require(script.Parent.ProfileService);
local Auxiliary = require(Shared.Utility.Auxiliary);
local RaceManager = require(SharedComponents.Race);

--//Module
local ProfileHandler = {};
ProfileHandler.__index = ProfileHandler;

ProfileHandler.Constants = {
	ProfileStoreName = 'TestingStaging_1a';
	
	DataTemplate = {

		Race = "";
		
		LastName = "";
		
		Inventory = {};
		Spells = {};
		
	};
};

ProfileHandler._Cache = {};

ProfileHandler.SessionProfiles = {};
ProfileHandler.ProfileStore = ProfileService.GetProfileStore(ProfileHandler.Constants.ProfileStoreName, ProfileHandler.Constants.DataTemplate);

function WatchTableRecursive(tbl: table, path: string, onChange: (key: any, value: any, fullPath: string) -> ()): table
	local proxy = {}

	local function wrap(value, subPath)
		if typeof(value) == "table" then
			return WatchTableRecursive(value, subPath, onChange)
		end
		return value
	end

	for k, v in pairs(tbl) do
		rawset(proxy, k, wrap(v, path .. "." .. tostring(k)))
	end

	return setmetatable(proxy, {
		__index = tbl,
		__newindex = function(_, key, value)
			local fullPath = path .. "." .. tostring(key)
			local wrappedValue = wrap(value, fullPath)
			tbl[key] = wrappedValue
			rawset(proxy, key, wrappedValue)
			onChange(key, value, fullPath)
		end
	})
end

function ProfileHandler.GetProfileById(UserId: number)
	if not ProfileHandler._Cache[UserId] then
		ProfileHandler._Cache[UserId] = ProfileHandler.ProfileStore:LoadProfileAsync(`Player_{tostring(UserId)}`);
	end;
	return ProfileHandler._Cache[UserId];
end;

function GetMonthYearKey(): string
	local date = os.date("*t", os.time())
	local month = string.format("%02d", date.month)
	local year = date.year
	return month .. "/" .. tostring(year)
end

function ProfileHandler.UpdateDate(profile: {})
	if profile.Data.Date ~= GetMonthYearKey() and profile.Data.Date ~= "" then
	end
	profile.Data.Date = GetMonthYearKey()
end

function ProfileHandler:UpdateRace()
	if RaceManager.Races[self.Profile.Data.Race] then return end;
	self.Profile.Data.Race = RaceManager.ChooseReroll();
	print(self.Profile.Data.Race);
end

function ProfileHandler:UpdateName()
	if not self.Profile.Data.LastName or self.Profile.Data.LastName == "" then
		local Race = RaceManager.Races[self.Profile.Data.Race];
		local lastName = Race.Names[math.random(1, #Race.Names)];
		self.Profile.Data.LastName = lastName;
	end;

	self.Player:SetAttribute("LastName", self.Profile.Data.LastName);
end

ProfileHandler.new = function(Player: Player)	
	local self = setmetatable({}, ProfileHandler);
	self.Player = Player;
	self.Profile = ProfileHandler.GetProfileById(Player.UserId);
	if not self.Profile then
		local maxWait = 10;
		repeat
			task.wait(.1)
			maxWait -= .1
			self.Profile = ProfileHandler.GetProfileById(Player.UserId);
		until self.Profile or maxWait <= 0
		if not self.Profile then
			self.Player:Kick('Could Not Fetch Profile! Please Rejoin.');
			return;
		end
	end;
	
	self.Profile:AddUserId(Player.UserId);
	self.Profile:Reconcile();
	
	self.Profile:ListenToRelease(function()
		ProfileHandler.SessionProfiles[self.Player] = nil;
		ProfileHandler._Cache[Player.UserId] = nil;
		self.Player:Kick('Profile Released');
	end)
	
	self.Data = self.Profile.Data;
	self.Data.Wearing = {}
	
	ProfileHandler.UpdateDate(self.Profile)
	self:UpdateRace();
	self:UpdateName();
	ProfileHandler.SessionProfiles[self.Player] = self.Profile
	
	assert(self.Player:IsDescendantOf(Players), 'Player Left, profile was not returned');
	return self;
end;

function ProfileHandler.Retrieve(Player : Player)
	local Profile = ProfileHandler.SessionProfiles[Player];
	if Profile then
		return Profile
	end
end

function ProfileHandler:Clean()
	local Profile = ProfileHandler.SessionProfiles[self.Player];
	if Profile then
		ProfileHandler.SessionProfiles[self.Player] = nil;
		--Profile:Release();
	end;
end;

return ProfileHandler;