--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "addStat";
	Description = "Adds stat";
	Group = "Special";
	Args = {
		{
			Type = 'string';
			Name = 'Stat';
			Description = 'Stat name';
		};
		
		{
			Type = 'number';
			Name = 'Amount';
			Description = 'Amount to add to stat';
			Optional = true;
		};
		
		{
			Type = "player";
			Name = "Target";
			Description = "What target to affect (Default is yourself)";
			Optional = true;
		};
	};
}