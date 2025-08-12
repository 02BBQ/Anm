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

return function(Params)
	local SkillName = script.Name
	
	local Entity = Params.Caster;
	local Character = Entity.Character;
	local CharacterValues = Attribute(Character);
	local Humanoid = Character.Humanoid;
	
	local RealCharacter = Character.Rig
	local RunningSpeed = RealCharacter:GetAttribute("RunSpeed")
	local WalkSpeed = RealCharacter:GetAttribute("WalkSpeed")
	local IsRunning = RealCharacter:GetAttribute("Running")
	if not Entity.Combat:IsActive() then return end;
	

	if IsRunning == false then
		RealCharacter:SetAttribute("Running",true)
		Humanoid.WalkSpeed = RunningSpeed
	else
		RealCharacter:SetAttribute("Running",false)
		Humanoid.WalkSpeed = WalkSpeed
	end
end