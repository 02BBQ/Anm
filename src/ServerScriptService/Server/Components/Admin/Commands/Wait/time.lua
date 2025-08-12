--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "time";
	Aliases = {'setTime'};
	Description = "Sets time to value (Ex. 17.5 = 17:30:00)";
	Group = "Special";
	Args = {
		{
			Type = 'number';
			Name = 'Clocktime';
			Description = 'New clocktime value';
		};
		
		{
			Type = 'number';
			Name = 'Day';
			Description = 'New day value';
			Optional = true;
		};
	};
}