return {
	Name = "heal",
	Aliases = {"h"},
	Description = "Heals a player",

	Group = "Tester",

	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player who should be healed."
		},
		{
			Type = "number",
			Name = "Amount",
			Description = "Amount to heal"
		}
	}
}
