local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local ClientEffect = Remotes.Clients

return function(info)
	local victim =  info.victim
	local humanoid = victim.Humanoid
	local Damage = info.Damage
	local stun = info.stun
	
	-- Stun --
	
	-- Damage --
	humanoid:TakeDamage(Damage)
	
	-- Hit Vfx --
	ClientEffect:FireAllClients({
		Type = "HitVfx";
		parent = victim;
		hit_type = info.hit_type;
	})
	
end