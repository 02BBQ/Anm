--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "giveItem";
	Description = "gives Item to Target";
	Group = "Special";
	Args = {
		
		{
			Type = "item";
			Name = "Item Name";
		};

		{
			Type = "player";
			Name = "Target";
			Description = "What target to affect (Default is yourself)";
			Optional = true;
		};

	};
}