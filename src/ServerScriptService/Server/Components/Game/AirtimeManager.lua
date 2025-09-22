local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Debris = require(game:GetService("ReplicatedStorage").Shared.Utility.Debris)

local AirtimeData = {}
local AirtimeManager = {}

local function createAlignPosition(entity, position, speed)
	local AlignPosition = Instance.new("AlignPosition")
	AlignPosition.Name = "AirDuration"
	AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	AlignPosition.Attachment0 = entity.Character.Root.RootAttachment
	AlignPosition.MaxForce = 99999
	AlignPosition.MaxVelocity = speed or 50
	AlignPosition.Responsiveness = 100
	AlignPosition.Position = position
	AlignPosition.Parent = entity.Character.Root

	return AlignPosition
end

local function cleanupAirtimeData(characterName)
	if AirtimeData[characterName] then
		AirtimeData[characterName]:Disconnect()
		AirtimeData[characterName] = nil
	end
end

local function removeAirDuration(entity)
	local character = entity.Character.Rig
	character:SetAttribute("AirDuration", nil)

	local alignPosition = entity.Character.Root:FindFirstChild("AirDuration")
	if alignPosition then
		alignPosition:Destroy()
	end

	cleanupAirtimeData(character.Name)
end

local function startAirtimeDuration(entity, duration, onCleanup)
	local character = entity.Character.Rig
	character:SetAttribute("AirDuration", DateTime.now().UnixTimestampMillis)

	task.delay(duration, function()
		if character:GetAttribute("AirDuration") then
			local timeDifference = DateTime.now().UnixTimestampMillis - character:GetAttribute("AirDuration")
			if timeDifference >= duration * 995 then
				removeAirDuration(entity)
				if onCleanup then
					onCleanup()
				end
			end
		end
	end)
end

local function setupPlayerConnection(attackerEntity, targetEntity)
	local playerAttacker = attackerEntity.Player
	local targetCharacter = targetEntity.Character.Rig

	if playerAttacker and not AirtimeData[targetCharacter.Name] then
		AirtimeData[targetCharacter.Name] = playerAttacker.CharacterRemoving:Connect(function()
			removeAirDuration(targetEntity)
		end)
	end
end

function AirtimeManager:UpdatePosition(Entity, Position, Speed)
	local Character = Entity.Character.Rig
	if Character:GetAttribute("AirDuration") then
		local AlignPosition = Entity.Character.Root:FindFirstChild("AirDuration")
		if AlignPosition then
			if Speed then
				AlignPosition.MaxVelocity = Speed
			end
			AlignPosition.Position = Position
		end
	end
end

function AirtimeManager:ReleaseAirtime(Entity, Knockback)
	local Character = Entity.Character.Rig
	if Character:GetAttribute("AirDuration") then
		removeAirDuration(Entity)

		if Knockback then
			local BodyVelocity = Instance.new("BodyVelocity")
			BodyVelocity.MaxForce = Vector3.new(80000, 0, 80000)
			BodyVelocity.Velocity = Entity.Character.Root.CFrame.LookVector * -45
			BodyVelocity.Parent = Character.Head
			Debris:AddItem(BodyVelocity, 0.3)
		end
	end
end

function AirtimeManager:Airtime(AttackerEntity, TargetEntity, Duration, Offset, Speed)
	local AttackOwner = AttackerEntity.Character.Rig
	local Character = TargetEntity.Character.Rig
	local AttackerCFrame = AttackerEntity.Character.Root.CFrame * CFrame.new(0, 15, 0)

	if Offset then
		AttackerCFrame *= Offset
	end

	if Character:GetAttribute("AirDuration") then
		AirtimeManager:MaintainAirtime(AttackerEntity, TargetEntity, Duration)
	else
		local targetPosition = (AttackerCFrame * CFrame.new(0, 0, -4.5)).Position
		createAlignPosition(TargetEntity, targetPosition, Speed)

		setupPlayerConnection(AttackerEntity, TargetEntity)
		startAirtimeDuration(TargetEntity, Duration)
	end

	if not AttackOwner:GetAttribute("AirDuration") then
		createAlignPosition(AttackerEntity, AttackerCFrame.Position, Speed)
		startAirtimeDuration(AttackerEntity, Duration)
	end
end

function AirtimeManager:MaintainAirtime(AttackerEntity, TargetEntity, Duration)
	local AttackOwner = AttackerEntity.Character.Rig
	local Character = TargetEntity.Character.Rig
	local LookVector = AttackerEntity.Character.Root.CFrame.LookVector

	local AlignPosition = TargetEntity.Character.Root:FindFirstChild("AirDuration")
	local AttackerAlignPosition = AttackerEntity.Character.Root:FindFirstChild("AirDuration")

	if AlignPosition then
		AlignPosition.Position = AlignPosition.Position + (LookVector * 2)
		startAirtimeDuration(TargetEntity, Duration)
	end

	if AttackerAlignPosition then
		AttackerAlignPosition.Position = AttackerAlignPosition.Position + (LookVector * 2)
		startAirtimeDuration(AttackerEntity, Duration)
	end
end

return AirtimeManager