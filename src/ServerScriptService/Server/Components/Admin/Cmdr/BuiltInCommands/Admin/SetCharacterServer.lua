
return function (context, plr:Player, newCharacter:string)
	local EntityManager = require(game.ServerScriptService.Server.Components.Core.EntityManager)
	local PlayerEntity = EntityManager.Find(plr)
	
	if PlayerEntity then
		PlayerEntity:ChangeCharacter(newCharacter)
		return plr.Name.." Character was changed to :"..newCharacter
	end
end