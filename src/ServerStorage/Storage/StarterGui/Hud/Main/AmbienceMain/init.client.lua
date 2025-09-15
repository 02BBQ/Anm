-- This creates a zone for every ambient group, then listens for when the local player enters and exits
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LABEL_DURATION = 3
local FADE_INFO = TweenInfo.new(1)
local Zone = require(ReplicatedStorage.Shared.Package.Zone)
local LocationClient = require(script.LocationClient)
local localPlayer = game.Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Resources = ReplicatedStorage.Shared.Assets.Resources;

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AmbientContainer"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui


local MusicVolumeMultiplier = 0;


local currentZone = {};
local currentRegion = "Nothing";
local EnterRegion = nil;


function NoRegion()
	local region = "Nothing";
	if not LocationClient[region] then return end;


	local areaLabel = Resources.TextLabel:Clone()
	areaLabel.Text = LocationClient[region].Title
	areaLabel.Name = region
	areaLabel.Parent = screenGui

	local areaLabelDesc = Resources.Desc:Clone()
	areaLabelDesc.Text = LocationClient[region].Info
	areaLabelDesc.Name = region
	areaLabelDesc.Parent = screenGui

	local sound = script.Ambience.Area:FindFirstChild(region);

	if not sound then return end;

	sound = sound.Day:Clone()
	local originalVolume = sound.Volume * MusicVolumeMultiplier;

	local endLabel = Instance.new("BindableEvent")
	sound.Volume = 0
	sound.Name = region
	sound.Parent = screenGui

	sound:Resume()
	TweenService:Create(sound, FADE_INFO, {Volume = originalVolume}):Play()
	TweenService:Create(areaLabel, FADE_INFO, {TextTransparency = 0, TextStrokeTransparency = 0.3}):Play()
	TweenService:Create(areaLabelDesc, FADE_INFO, {TextTransparency = 0, TextStrokeTransparency = 0.3}):Play()
	local ended = false
	task.spawn(function()
		local endTick = tick() + LABEL_DURATION
		repeat RunService.Heartbeat:Wait() until tick() >= endTick or ended
		if not ended then
			endLabel:Fire()
		end
	end)
	task.spawn(function()
		endLabel.Event:Wait()
		ended = true
		TweenService:Create(areaLabel, FADE_INFO, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		TweenService:Create(areaLabelDesc, FADE_INFO, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		currentZone[region] = true;
		currentRegion = region
	end)

	return function()
		local fade = TweenService:Create(sound, FADE_INFO, {Volume = 0})
		fade:Play()
		endLabel:Fire()
		currentZone[region] = false; 
		fade.Completed:Wait()
		fade:Destroy()
		if sound.Volume == 0 then
			sound:Pause()
		end
	end
end

function SetRegion(container)

	local region = container.Name;
	if not LocationClient[region] then return end;

	--
	container:WaitForChild("Part", math.huge)
	--

	local zone = Zone.new(container)
	zone:bindToGroup("EnterOnlyOneZoneAtATime")

	local areaLabel = Resources.TextLabel:Clone()
	areaLabel.Text = LocationClient[region].Title
	areaLabel.Name = region
	areaLabel.Parent = screenGui

	local areaLabelDesc = Resources.Desc:Clone()
	areaLabelDesc.Text = LocationClient[region].Info
	areaLabelDesc.Name = region
	areaLabelDesc.Parent = screenGui

	local sound = script.Ambience.Area:FindFirstChild(region);

	if not sound then return end;

	sound = sound.Day:Clone()
	local originalVolume = sound.Volume * MusicVolumeMultiplier;

	local endLabel = Instance.new("BindableEvent")
	sound.Volume = 0
	sound.Name = region
	sound.Parent = screenGui

	zone.localPlayerEntered:Connect(function()
		if EnterRegion then EnterRegion(); EnterRegion = nil; end;
		sound:Resume()
		TweenService:Create(sound, FADE_INFO, {Volume = originalVolume}):Play()
		TweenService:Create(areaLabel, FADE_INFO, {TextTransparency = 0, TextStrokeTransparency = 0.3}):Play()
		TweenService:Create(areaLabelDesc, FADE_INFO, {TextTransparency = 0, TextStrokeTransparency = 0.3}):Play()
		local ended = false
		task.spawn(function()
			local endTick = tick() + LABEL_DURATION
			repeat RunService.Heartbeat:Wait() until tick() >= endTick or ended
			if not ended then
				endLabel:Fire()
			end
		end)
		endLabel.Event:Wait()
		ended = true
		TweenService:Create(areaLabel, FADE_INFO, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		TweenService:Create(areaLabelDesc, FADE_INFO, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		currentZone[region] = true;
		currentRegion = region
	end)

	zone.localPlayerExited:Connect(function()
		local fade = TweenService:Create(sound, FADE_INFO, {Volume = 0})
		fade:Play()
		endLabel:Fire()
		
		currentZone[region] = false; 

		if #currentZone == 0 then
			currentRegion = "Nothing";
			EnterRegion = NoRegion();
		end
		
		fade.Completed:Wait()
		fade:Destroy()
		if sound.Volume == 0 then
			sound:Pause()
		end
	end)
end

local ambientAreas = workspace.World.AmbientAreas
for _, container in pairs(ambientAreas:GetChildren()) do
	SetRegion(container);
end

print("ambi re")