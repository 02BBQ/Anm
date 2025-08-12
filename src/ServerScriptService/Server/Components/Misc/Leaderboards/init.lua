return function()
	local dataStoreService = game:GetService("DataStoreService")
	local serverScriptService = game:GetService("ServerScriptService")
	local players = game:GetService("Players")
	
	local serverComponents = serverScriptService:WaitForChild("Server"):WaitForChild("Components")
	local serverDataModules = serverComponents:WaitForChild("Data")
	local profileHandler = require(serverDataModules:WaitForChild("ProfileHandler"))
	
	local list = require(script:WaitForChild("List"))
	local ordered = {}
	local additionalDelay = 0
	
	local function GetValueByPath(data: {}, path: string): any
		local current = data
		for key in string.gmatch(path, "[^/]+") do
			if typeof(current) == "table" then
				current = current[key]
			else
				return nil
			end
		end
		return current
	end

	local function GetMonthYearKey(): string
		local date = os.date("*t", os.time())
		local month = string.format("%02d", date.month)
		local year = date.year
		return month .. "/" .. tostring(year)
	end
	
	local function UpdateOrdered()
		for _, v: {} in pairs(list) do
			local valuePath: string = v.Path
			local dateCheck: boolean = v.DateCheck

			if valuePath and dateCheck ~= nil then
				local name: string
				if dateCheck then
					name = `{GetMonthYearKey()}_{valuePath}`
				else
					name = valuePath
				end
				
				ordered[valuePath] = dataStoreService:GetOrderedDataStore(name)
				warn("Initialized", name)
			else
				warn("Something went wrong, params missing in the leaderboards list")
				return
			end
		end
	end
	
	UpdateOrdered()
	
	local function UpdatePlayer(player: Player)
		additionalDelay += 1
		task.delay(1, function()
			additionalDelay -= 1
		end)
		
		pcall(function()
			local profile = profileHandler.GetProfileById(player.UserId)
			if profile then
				profileHandler.UpdateDate(profile)
				for _, v: {} in pairs(list) do
					local valuePath: string = v.Path
					local dateCheck: boolean = v.DateCheck
					local DS: OrderedDataStore = ordered[valuePath]

					if DS and (not dateCheck or profile.Data.Date == GetMonthYearKey()) then
						pcall(function()
							local foundValue: any = GetValueByPath(profile.Data, valuePath)
							DS:SetAsync(`Player_{player.UserId}`, foundValue)
							warn("Updated", valuePath, "for", player.Name)
						end)
					end
				end
			end
		end)
	end
	
	players.PlayerAdded:Connect(function(player)
		task.delay(5 + additionalDelay, UpdatePlayer, player)
	end)
	
	task.spawn(function()
		while task.wait(120) do
			UpdateOrdered()
			for _, player: Player in pairs(players:GetPlayers()) do
				UpdatePlayer(player)
			end
		end
	end)
end