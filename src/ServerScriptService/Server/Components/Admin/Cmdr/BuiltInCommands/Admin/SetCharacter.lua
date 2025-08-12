return {
	Name = "SetCharacter";
	Aliases = {"sc"};
	Description = "Will set character of given person or you.";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "player";
			Name = "Target";
			Description = "[Player] that needs to be set Character to.";
		},
		{
			Type = "character";
			Name = "Character";
			Description = "Name given of Character.";
		},
	};
}