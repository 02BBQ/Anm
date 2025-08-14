--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "setTitle";
	Description = "change target's title";
	Group = "Special";
	Args = {
		
		{
			Type = "player";
			Name = "Target";
			Description = "What target to affect (Default is yourself)";
		};

		{
			Type = "string";
			Name = "title";
		};

	};
}