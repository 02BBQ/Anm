local CCS = {}
local Cooldowns = {}
local Stuns = {}
-- Cooldowns - Start
function CCS.HasCooldown(Character : Model, Name : string) : boolean
	return Cooldowns[Character] and Cooldowns[Character][Name]
end
function CCS.AddCooldown(Character : Model, Name : string, Duration : number)
	if not Cooldowns[Character] then
		Cooldowns[Character] = {}
	end

	Cooldowns[Character][Name] = true
	task.delay(Duration, function()
		CCS.RemoveCooldown(Character, Name)
	end)
end
function CCS.RemoveCooldown(Character : Model, Name : string)
	if CCS.HasCooldown(Character, Name) then
		Cooldowns[Character][Name] = nil

		if pairs(Cooldowns[Character]) == nil then
			Cooldowns[Character] = nil
		end
	end
end
-- Cooldowns - End




function CCS.ReturnSpeed(Character)
	if not Character:GetAttribute("Dummy") then
		local Humanoid = Character:FindFirstChild("Humanoid")
		local RunningSpeed = Character:GetAttribute("RunSpeed")
		local WalkSpeed = Character:GetAttribute("WalkSpeed")
		local Blocking = Character:GetAttribute("Blocking")

		if not Character:GetAttribute("Blocking") then
			if Character:GetAttribute("Running") == true then
				Humanoid.WalkSpeed = RunningSpeed
			else
				Humanoid.WalkSpeed = WalkSpeed
				Humanoid.JumpPower = Character:GetAttribute("JumpPower")
			end
		end
	end
end
function CCS.ReduceSpeed(Character,Speed,Dur)
	local Humanoid = Character["Humanoid"]
	Humanoid.WalkSpeed = Speed
	task.spawn(function()
		task.wait(Dur)
		CCS.ReturnSpeed(Character)
	end)
end
function CCS.Stun(Character : Model, Duration : number)
	local Humanoid = Character:FindFirstChild("Humanoid")

	if not Stuns[Character] then
		Stuns[Character] = 0
	end

	if (Stuns[Character] == 0) then
		Humanoid.WalkSpeed = 4
		Humanoid.JumpPower = 4
	end

	Stuns[Character] += 1

	Character:SetAttribute("Stunned", true)
	Character:SetAttribute("Running", false)
	
	if Character:GetAttribute("CanBeCancelled") then
		Character:SetAttribute("CanBeCancelled", nil)
	end

	local Suc
	local a = function()
		if Suc == true then return end
		Suc = true
		Stuns[Character] -= 1
		if (Stuns[Character] <= 0) then
			CCS.ReturnSpeed(Character)
			Character:SetAttribute("Stunned", false)

			Stuns[Character] = nil
		end
	end
	task.delay(Duration, a)
	return a
end
function CCS.CheckReadyToAct(Character) -- 캐릭터가 행동할 수 있는 상태인지 확인하는 함수
	local Acting = Character:GetAttribute("Acting")
	local Stunned = Character:GetAttribute("Stunned")
	local Ragdolled = Character:GetAttribute("Ragdolled")
	local Stunned = Character:GetAttribute("Stunned")
	if Acting == true or Stunned == true or Ragdolled == true then
		return false
	elseif Acting == false and Stunned == false then
		return true
	end
end

return CCS
