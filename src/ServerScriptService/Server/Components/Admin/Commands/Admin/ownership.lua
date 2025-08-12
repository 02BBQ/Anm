--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "ownership";
	Description = "Configures target players ownership";
	Group = "Special";
	Args = {
		{
			Type = 'ownershipcategory';
			Name = 'Category';
			Description = 'Item category';
		};
		
		{
			Type = "string";
			Name = "Item Name";
			Description = "Entry item name";
		};
		
		{
			Type = "boolean";
			Name = "Give/Remove";
			Description = "True for giving the entry, false for removing (Default is true)";
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