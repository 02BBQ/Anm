local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared;
local InfoModules = ReplicatedStorage.Shared.InfoModules
local CharacterControls = require(InfoModules.CharacterControls)
local Attribute = require(InfoModules.Attribute)
local Animations = ReplicatedStorage.Shared.Assets.Animations
local Functions = require(ReplicatedStorage.Shared.SystemModules.Functions)
local Assets = ReplicatedStorage.Shared.Assets
local WeaponsInfo = require(ReplicatedStorage.Shared.WeaponsInfo)
local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary);
local Clients = ReplicatedStorage.Remotes.Clients

local cooldown = 1

return function(Params)
	local SkillName = script.Name;
	local Entity = Params.Caster;
	
	local Character = Entity.Character;
	
	local CharacterValues = Attribute(Character);
	local RealCharacter = Character.Rig
	local Humanoid = RealCharacter.Humanoid;

	if Entity.Cooldowns.OnCooldown[SkillName] then return end;
	if not Entity.Combat:IsActive() then return end;
	if Humanoid.MoveDirection == Vector3.zero then
		return
	end
	
	Entity.Combat.Acting = true;
	Entity.Combat.IFrame = true;

	Clients:FireAllClients({
		seperate = "YES";
		Type = "Dash";
		Name = "Dash_Custom";
		Humanoid = Humanoid;
	})
	Clients:FireAllClients({
		Type = "Dash_Smokes";
		chr = RealCharacter;
	})
	Clients:FireAllClients({Type = "Custom_Dash_Velocity",Character = RealCharacter})
	
	task.delay(0.35, function()
		Entity.Cooldowns:Add(SkillName,cooldown)
		Entity.Combat.Acting = false;
		Entity.Combat.IFrame = false;
	end)
	
end