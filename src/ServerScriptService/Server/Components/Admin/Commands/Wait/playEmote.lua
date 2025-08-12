--//Variables
local Players = game:GetService('Players');

--//Module
return {
	Name = "playEmote";
	Description = "Makes player play emote";
	Group = "Special";
	Args = {
		{
			Type = "emote";
			Name = "Emote Name";
		};
		
		{
			Type = "player";
			Name = "Target";
			Description = "Which player to play the emote";
			Optional = true;
		};
	};
}