
return function (context, plr, amount)
	
	plr.Character.Humanoid.Health += amount
	
	return "Healed "..plr.Name.." by "..amount.."HP"
end