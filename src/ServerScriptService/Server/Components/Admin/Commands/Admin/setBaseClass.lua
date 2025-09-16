--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "setBaseClass";
	Description = "change target's baseClass";
	Group = "Special";
	Args = {
		
		{
			Type = "class";
			Name = "Class Name";
		};

		{
			Type = "player";
			Name = "Target";
			Description = "What target to affect (Default is yourself)";
			Optional = true;
		};

	};
}