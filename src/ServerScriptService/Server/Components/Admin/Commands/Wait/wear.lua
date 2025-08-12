--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "wear";
	Aliases = {'equipaccessory'};
	Description = "Equips accessory";
	Group = "Special";
	Args = {
		{
			Type = 'accessory';
			Name = 'Accessory Name';
			Description = 'Name of accessory to wear';
		};
		
		{
			Type = 'boolean';
			Name = 'Wearing';
			Description = 'Is wearing?';
			Optional = true;
		};
		
		{
			Type = 'player';
			Name = 'Target';
			Description = 'Target player';
			Optional = true;
		};
	};
}