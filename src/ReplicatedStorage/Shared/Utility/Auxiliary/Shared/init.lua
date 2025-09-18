local Auxiliary = {}

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local BadgeService = game:GetService("BadgeService")
local Chat = game:GetService("Chat")
local Teams = game:GetService("Teams")
local TestService = game:GetService("TestService")
local LocalizationService = game:GetService("LocalizationService")
local AnalyticsService = game:GetService("AnalyticsService")
local HapticService = game:GetService("HapticService")
local MessagingService = game:GetService("MessagingService")
local PolicyService = game:GetService("PolicyService")
local SocialService = game:GetService("SocialService")
local TextService = game:GetService("TextService")
local VRService = game:GetService("VRService")
local VoiceChatService = game:GetService("VoiceChatService")

local TroveClass = require(ReplicatedStorage.Shared.Utility.Trove);

Auxiliary.GetPath = function(Bottom, Top)
	local CurrentParent = Bottom;
	local Occurences = {};
	local PathStr = '';

	repeat
		Occurences[#Occurences+1] = CurrentParent.Name;
		CurrentParent = CurrentParent.Parent;
	until CurrentParent == Top;

	for i = #Occurences,1,-1 do
		PathStr ..= Occurences[i]..'/';
	end;

	return PathStr:sub(1,#PathStr-1);
end;

Auxiliary.FixedUpdate = function(updateFunction: (number) -> (), updateRate: number, variableUpdateFunction: (number) -> ()?): () -> ()
	local Accumulated = 0
	local TotalDT = 0

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if variableUpdateFunction then
			variableUpdateFunction(deltaTime)
		end

		Accumulated += deltaTime
		TotalDT += deltaTime

		while Accumulated >= updateRate do
			task.spawn(updateFunction, TotalDT)
			Accumulated -= updateRate
			TotalDT = 0
		end
	end)

	return function()
		connection:Disconnect()
	end
end;

Auxiliary.WaitForMarker = function(Track: AnimationTrack, Marker: string)
	if not Track.IsPlaying then
		return;
	end;
	
	local Proceed;
	local Param;
	
	local Trove = TroveClass.new();
	local Ended: BindableEvent = Trove:Add(Instance.new('BindableEvent'));
	
	Trove:Connect(Track.Stopped, function() 
		Ended:Fire()
	end);
	
	Trove:Connect(Track:GetMarkerReachedSignal(Marker), function(ParamString: string)
		Param = ParamString;
		Ended:Fire();
	end);
	
	Ended.Event:Wait();
	
	Trove:Destroy();
	return Param;
end;

Auxiliary.CreateVelocity = function(Parent: BasePart, Data: {MaxForce: Vector3?})
	local BodyVelocity: BodyVelocity = Instance.new('BodyVelocity');
	BodyVelocity.P = 20_000;
	BodyVelocity.MaxForce = (Data and Data.MaxForce) or Vector3.one*4e4;

	BodyVelocity.Parent = Parent;
	return BodyVelocity;
end;

Auxiliary.CreatePosition = function(Parent: BasePart, Data: table)
	local BodyPosition: BodyPosition = Instance.new('BodyPosition');
	BodyPosition.P = 20_000;
	BodyPosition.MaxForce = (Data and Data.MaxForce) or Vector3.one*math.huge;
	BodyPosition.Position = Parent.Position;

	BodyPosition.Parent = Parent;
	return BodyPosition;
end;

Auxiliary.ClearAllMovers = function(Part: BasePart)
	for _, Velocity in Part:GetChildren() do
		if Velocity and (Velocity:IsA('BodyVelocity') or Velocity:IsA('LinearVelocity') or Velocity:IsA('BodyPosition')) then
			Velocity:Destroy()
		end
	end
end

Auxiliary.Invis = function(Rig: Model?, invis: boolean)
	for _,v in pairs(Rig:GetChildren()) do
		if v:IsA("BasePart") and string.find(v.Name, "Arm") or string.find(v.Name, "Leg") or string.find(v.Name, "Torso") or string.find(v.Name, "Head") then
			v.Transparency = invis and 1 or 0;
		end
	end
end

-- Creates and plays a tween with automatic cleanup
-- Parameters:
--   target: The object to tween (Instance)
--   tweenInfo: TweenInfo or table containing tween properties (Time, EasingStyle, etc.)
--   onComplete: Optional callback function to run when tween completes
-- Returns: The created Tween object
function Auxiliary.PlayTween(target, tweenInfo, onComplete)
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

function Auxiliary.BindFX(maid, fx)
	local g = fx:Clone();
	maid:AddTask(g);
	return g;
end

function Auxiliary.PlayAttachment(gameObject, cleanupTime, options)
	local primaryPart = nil

	-- If it's a Model, get its PrimaryPart for ground detection
	if not gameObject:IsA("Part") and gameObject:IsA("Model") then
		primaryPart = gameObject.PrimaryPart
	end

	-- Check if the object is on the ground using raycast
	local isOnGround = false
	if primaryPart then
		local raycastParams = Auxiliary.RayParams.Map;
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
			Auxiliary.PlayTween(descendant, {
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

Auxiliary.DeepCopy = function(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = Auxiliary.DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

Auxiliary.RemoveFirstValue = function(tab )
	for i in tab do
		table.remove(tab,i);
		break;
	end;
end;

Auxiliary.MapInstances = {
	workspace.World.Map;
};

Auxiliary.Debris = workspace.World.Debris;
Auxiliary.Alive = workspace.World.Alive;

local ParamFuncs = {
	Map = (function()
		local NewParams: RaycastParams = RaycastParams.new();
		NewParams.FilterType = Enum.RaycastFilterType.Include;
		NewParams.FilterDescendantsInstances = Auxiliary.MapInstances;

		return NewParams;
	end);

	MapRespect = (function()
		local NewParams: RaycastParams = RaycastParams.new();
		NewParams.FilterType = Enum.RaycastFilterType.Include;
		NewParams.FilterDescendantsInstances = Auxiliary.MapInstances;
		NewParams.RespectCanCollide = true;
		return NewParams;
	end);
};

Auxiliary.RayParams = {
	Map = ParamFuncs.Map();
	MapRespect = ParamFuncs.MapRespect();
};

for _,v in pairs(script:GetChildren()) do
	if v:IsA('ModuleScript') then
		Auxiliary[v.Name] = require(v);
	end;
end;

Auxiliary.SetCollisionGroups = function(Character, Group)
	for Index, Part: BasePart in ipairs(Character:GetChildren()) do
		if Part:IsA'BasePart' then
			Part.CollisionGroup = Group;
		end
	end
end

return Auxiliary;