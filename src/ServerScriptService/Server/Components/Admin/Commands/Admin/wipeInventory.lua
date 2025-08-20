--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "wipeInventory";
	Description = "gives Item to Target";
	Group = "Special";
	Args = {

		{
			Type = "player";
			Name = "Target";
			Description = "What target to affect (Default is yourself)";
			Optional = true;
		};

	};
}