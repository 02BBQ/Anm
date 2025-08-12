--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "clearOwnership";
	Description = "Clears ownership category";
	Group = "Special";
	Args = {
		{
			Type = 'ownershipcategory';
			Name = 'Category';
			Description = 'Category name';
		};
		
		{
			Type = "player";
			Name = "Target";
			Description = "What target to affect (Default is yourself)";
			Optional = true;
		};
	};
}