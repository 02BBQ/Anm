--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "setRace";
	Description = "change target's race";
	Group = "Special";
	Args = {
		
		{
			Type = "race";
			Name = "Race Name";
		};

		{
			Type = "player";
			Name = "Target";
			Description = "What target to affect (Default is yourself)";
		};

	};
}