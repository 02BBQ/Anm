local Auxiliary = require(game:GetService("ReplicatedStorage").Shared.Utility.Auxiliary);
local RayParams = Auxiliary.Shared.RayParams.Map;

local module = {}

module.EmitDescendants = function(Object,DontDestroy)
	coroutine.wrap(function()
		if Object:IsA("ParticleEmitter") then
			local EmitCount = Object:GetAttribute("EmitCount") or 1
			local EmitDelay = Object:GetAttribute("EmitDelay") or nil

			if EmitDelay then
				task.wait(EmitDelay)
			end

			Object:Emit(EmitCount)
		else
			for _,Emitter : ParticleEmitter in pairs(Object:GetDescendants()) do
				if Emitter:IsA("ParticleEmitter") then
					task.spawn(function()
						local EmitCount = Emitter:GetAttribute("EmitCount") or 1
						local EmitDelay = Emitter:GetAttribute("EmitDelay") or nil
						local EmitDuration = Emitter:GetAttribute("EmitDuration") or nil

						if EmitDelay then
							task.wait(EmitDelay)
						end

						Emitter:Emit(EmitCount)
						
						if EmitDuration then
							Emitter.Enabled = true
							task.wait(EmitDuration)
							Emitter.Enabled = false
						end
						
						if not DontDestroy then
							task.delay(Emitter.Lifetime.Max / Emitter.TimeScale,function()
								pcall(function() Emitter:Destroy() end)
							end)
						end
					end)
				end
			end
		end
	end)()
end

module.EnableAll = function(Object)
	coroutine.wrap(function()
		for _,Emitter : ParticleEmitter in pairs(Object:GetDescendants()) do
			if Emitter:IsA("ParticleEmitter") or Emitter:IsA("Trail") then
				Emitter.Enabled = not Emitter.Enabled
			end
		end

	end)()
end

module.GetGround = function(Position,Range,Character : Model?)
	local RaycastOrigin = Position
	local Range = Range or 1000

	local Result = workspace:Raycast(RaycastOrigin + Vector3.new(0,2,0), Vector3.new(0,-1,0) * (Range + 2), RayParams)

	if Result then
		local Return = {
			Position = Result.Position;
			Object = Result.Instance;
		}

		return Return
	else
		return nil
	end
end

module.Tween = function(obj, info, goal)
	local tween = game:GetService("TweenService"):Create(obj, info, goal);
	tween:Play();
	task.delay(info.Time, function()
		tween:Destroy();
	end);
	return tween;
end

return module