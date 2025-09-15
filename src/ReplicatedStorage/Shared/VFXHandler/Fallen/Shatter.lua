--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");

local Shared = ReplicatedStorage.Shared;
local FXParent = workspace.World.Debris;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local Assets = Shared.Assets.Resources.Fallen;

local VFX = {};


-- Creates and plays a tween with automatic cleanup
-- Parameters:
--   target: The object to tween (Instance)
--   tweenInfo: TweenInfo or table containing tween properties (Time, EasingStyle, etc.)
--   onComplete: Optional callback function to run when tween completes
-- Returns: The created Tween object
function PlayTween(target, tweenInfo, onComplete)
	-- Create the tween (v1 is assumed to be TweenService)
	local tween = TweenService:Create(target, tweenInfo)

	-- Start playing the tween
	tween:Play()

	-- Set up completion handler
	local completedConnection = tween.Completed:Once(function()
		-- Run the callback function if provided
		if onComplete then
			onComplete()
		end

		-- Clean up the tween
		tween:Destroy()
	end)

	-- Failsafe: Clean up after the tween time even if Completed doesn't fire
	task.delay(tweenInfo.Time, function()
		-- Disconnect the completion handler to prevent double cleanup
		completedConnection:Disconnect()

		-- Destroy the tween if it still exists
		tween:Destroy()
	end)

	return tween
end

function PlayAttachment(gameObject, cleanupTime, options)
	local primaryPart = nil

	-- If it's a Model, get its PrimaryPart for ground detection
	if not gameObject:IsA("Part") and gameObject:IsA("Model") then
		primaryPart = gameObject.PrimaryPart
	end

	-- Check if the object is on the ground using raycast
	local isOnGround = false
	if primaryPart then
		local raycastParams = workspace.CurrentCamera -- assuming v31 is raycast params
		local rayResult = workspace:Raycast(primaryPart.Position, Vector3.new(0, -10, 0), raycastParams)
		isOnGround = rayResult ~= nil
	end

	-- Process all descendants of the game object
	for _, descendant in pairs(gameObject:GetDescendants()) do

		-- Handle ParticleEmitter effects
		if descendant:IsA("ParticleEmitter") then
			local attributes = descendant:GetAttributes()
			local emitDelay = attributes.EmitDelay
			local repeatCount = attributes.RepeatCount or 1
			local repeatDelay = attributes.RepeatDelay

			-- Spawn a new thread to handle particle emission
			task.spawn(function()
				for i = 1, repeatCount do
					-- Handle emission with optional delay
					if emitDelay then
						task.delay(emitDelay, function()
							descendant:Emit(attributes.EmitCount)

							-- Handle continuous emission for a duration
							if attributes.EmitDuration then
								descendant.Enabled = true
								task.delay(attributes.EmitDuration, function()
									descendant.Enabled = false
								end)
							end
						end)
					else
						-- Immediate emission
						descendant:Emit(attributes.EmitCount)

						-- Handle continuous emission for a duration
						if attributes.EmitDuration then
							descendant.Enabled = true
							task.delay(attributes.EmitDuration, function()
								descendant.Enabled = false
							end)
						end
					end

					-- Wait between repeats if specified
					if repeatDelay then
						task.wait(repeatDelay)
					end
				end
			end)
		end

		-- Handle PointLight fade out
		if descendant:IsA("PointLight") and cleanupTime then
			-- Assuming v0.PlayTween is a custom tween function
			PlayTween(descendant, {
				EasingStyle = "Sine",
				Time = cleanupTime,
				Goal = {
					Brightness = 0
				}
			})
		end

		-- Handle Beam effects
		if descendant:IsA("Beam") then
			local attributes = descendant:GetAttributes()
			local duration = attributes.Duration
			local tweenTime = 0.5 -- default tween time

			-- Override tween time if specified in options
			if options and options.TweenTime then
				tweenTime = options.TweenTime
			end

			-- Function to turn off the beam by reducing width to 0
			local function turnOffBeam()
				game:GetService("TweenService"):Create(
					descendant, 
					TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{
						Width1 = 0,
						Width0 = 0
					}
				):Play()
			end

			-- Function to turn on the beam by setting it to original width
			local function turnOnBeam()
				game:GetService("TweenService"):Create(
					descendant,
					TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{
						Width1 = attributes.Width1,
						Width0 = attributes.Width0
					}
				):Play()
			end

			-- Turn on the beam immediately
			turnOnBeam()

			-- Schedule beam to turn off after duration if specified
			if duration then
				task.delay(duration, function()
					turnOffBeam()
				end)
			end
		end
	end

	-- Clean up the game object after specified time
	if cleanupTime then
		game.Debris:AddItem(gameObject, cleanupTime)
	end
end


VFX.start = function(Data)
    local Root = Data.Origin
	local Humanoid: Humanoid? = Data.Caster.Character.Humanoid;
	
	local Animation: AnimationTrack;
	
	for _,v: AnimationTrack in pairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
		if v.Animation.AnimationId == Data.ID then
			Animation = v;
		end
	end
	
	if not Animation then return end;
	
	local speed = 10;
	
	local shatterMaid = Auxiliary.Maid.new();
	
	local endMaid = Auxiliary.Maid.new();
	
	local function isValid()
		if not Animation.IsPlaying then
			return false;
		end
		return true;
	end
	
	local function BindFX(maid, fx)
		local g = fx:Clone();
		maid:AddTask(g);
		return g;
	end
	
	local bv = Auxiliary.Shared.CreateVelocity(Root, {MaxForce = Vector3.new(40000,0,40000)});
	
	local run run = RunService.PreRender:Connect(function(dt)
		if not bv:IsDescendantOf(workspace) then run:Disconnect(); return end;
		bv.Velocity = Root.CFrame.LookVector * speed;
	end)
	
	local Au = BindFX(shatterMaid, Assets.AuraFarm);
	Au.CFrame = Root.CFrame;
	Au.Weld.Part0 = Root;
	Au.Parent = FXParent;
	PlayAttachment(Au);

	local cancel = function()
		task.delay(1,function()
			shatterMaid:Destroy();
			task.wait(4);
			endMaid:Destroy();
		end)
		run:Disconnect();
		bv.MaxForce = Vector3.one * 40000;
		bv.Velocity = Root.CFrame.LookVector * 50 + Vector3.new(0,15,0);
		game.Debris:AddItem(bv,0.15);
	end;
	
	Animation.Stopped:Connect(cancel);
	
	shatterMaid:AddTask(Animation:GetMarkerReachedSignal("rightstep"):Connect(function()
		local off = CFrame.new(0.912, -3, -.3);
		local step1 = BindFX(shatterMaid, Assets.Step1Fx);
		step1.CFrame = Root.CFrame * off;
		step1.Parent = FXParent;
		PlayAttachment(step1);
	end));
	
	shatterMaid:AddTask(Animation:GetMarkerReachedSignal("leftstep"):Connect(function()
		local off = CFrame.new(-0.912, -3, -.3);
		local step1 = BindFX(shatterMaid, Assets.Step1Fx);
		step1.CFrame = Root.CFrame * off;
		step1.Parent = FXParent;
		PlayAttachment(step1);
	end));
	
	shatterMaid:AddTask(Animation:GetMarkerReachedSignal("Slashs"):Connect(function()
		speed = 65;
		
		local fx = BindFX(shatterMaid, Assets.ultthukuna);
		fx.CFrame = Root.CFrame;
		local weldaura2 = Instance.new("Weld",fx);
		weldaura2.Part0 = Root;
		weldaura2.Part1 = fx;
		weldaura2.C0 = CFrame.new(0,0,0);
		fx.Parent = FXParent;
		PlayAttachment(fx);
		
		for _,v in pairs(Data.Caster.Character.Rig:GetChildren()) do
			if v:IsA("BasePart") and string.find(v.Name, "Arm") or string.find(v.Name, "Leg") or string.find(v.Name, "Torso") or string.find(v.Name, "Head") then
				v.Transparency = 1;
			end
		end
	end));
	
	shatterMaid:AddTask(Animation:GetMarkerReachedSignal("end slashs"):Connect(function()
		for _,v in pairs(Data.Caster.Character.Rig:GetChildren()) do
			if v:IsA("BasePart") and string.find(v.Name, "Arm") or string.find(v.Name, "Leg") or string.find(v.Name, "Torso") or string.find(v.Name, "Head") then
				v.Transparency = 0;
			end
		end
		
		local fx = BindFX(endMaid, Assets.EMIT);
		fx.CFrame = Root.CFrame;
		fx.Parent = FXParent;
		PlayAttachment(fx);
		
		cancel();
	end));
end

return VFX;