--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "clearInventory";
	Description = "clears Target's inventory";
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