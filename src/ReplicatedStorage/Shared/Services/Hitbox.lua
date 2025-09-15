--//Variables
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService('RunService');

local Player = Players.LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

local World   : Folder = workspace:WaitForChild("World")
local Entities: Folder = World:WaitForChild('Alive');

local Auxiliary = require(Shared.Utility.Auxiliary);

--//Module 
local ClientHitbox = {};
ClientHitbox.__index = ClientHitbox;

ClientHitbox.new = function(CasterEntity: {}?)
	local self = setmetatable({

		_DetectionBlacklist = {};

		caster = CasterEntity;
		detected = {};

	}, ClientHitbox);

	self.shape = 'Box'; -- Provide PartType enum

	self.ignorePrevious = true; -- Ignores entities that have already been stored in the hitbox object if detected again
	self.ignoreCaster = true; -- Ignores entity that casted hitbox
	self.ignoreRagdolled = true; -- Ignores ragdolled entities
	self.ignoreDead = false; -- Ignore dead entities
	self.ignoredEntities = {}; -- Ignores any detected entities if they're in this table

	self.single = false; -- Only detect 1 entity

	self.root = nil; -- Root of hitbox (Vector3 | CFrame | Part)
	self.offset = CFrame.new(0,0,0); -- CFrame offset
	self.size = Vector3.one*5; -- Hitbox size

	self.zMiddlePoint = false; -- Add middle point of Z scale to offset

	self.onHit = nil; -- Optional callback function
	self.debug = false; -- Creates transparent part to display hitbox

	self.hit = false; -- Sets to true once a hit has been detected

	return self;
end;

function ClientHitbox:GetParams()
	local Detecting = {};

	Detecting = self.detecting or {workspace.World.Alive}

	local EntityOverlapParams = OverlapParams.new();
	EntityOverlapParams.FilterDescendantsInstances = Detecting;
	EntityOverlapParams.FilterType = Enum.RaycastFilterType.Include;
	EntityOverlapParams.CollisionGroup = 'Hitbox';

	return EntityOverlapParams;
end;

local function FireHitbox(self)
	local HitboxRoot = (typeof(self.root) == 'Instance' and self.root.CFrame) or (typeof(self.root) == 'Vector3' and CFrame.new(self.root)) or (typeof(self.root) == 'CFrame' and self.root);
	if not HitboxRoot then
		if self.caster and self.caster.Character and self.caster.Character.Root then
			HitboxRoot = self.caster.Character.Root.CFrame;
		else
			-- Fallback to player character
			local playerCharacter = Player.Character;
			if playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart") then
				HitboxRoot = playerCharacter.HumanoidRootPart.CFrame;
			else
				return {}; -- No valid root found
			end;
		end;
	end;

	local Offsetting: CFrame = self.offset;
	if self.zMiddlePoint then
		Offsetting *= CFrame.new(0,0,-(self.size.Z/2));
	end;

	local HitboxPart: Part = Shared.Hitboxes[self.shape]:Clone();

	HitboxPart.CFrame = HitboxRoot * Offsetting;
	HitboxPart.Size = self.size;

	self.currentDetected = {};

	local Touching = workspace:GetPartsInPart(HitboxPart, self:GetParams());
	for _,v: Part in Touching do
		self:Parse(v);
	end;

	HitboxPart:Destroy()

	if self.debug then
		local DebugPart = HitboxPart:Clone();
		DebugPart.Material = Enum.Material.SmoothPlastic;
		DebugPart.Color = Color3.new(0,1,0); -- Green for client debug
		DebugPart.Transparency = .9;
		DebugPart.CastShadow = false;

		DebugPart.Parent = workspace.World.Debris;
		game.Debris:AddItem(DebugPart, 1);
	end;

	return self.currentDetected;
end;

function ClientHitbox:Fire(Yielding: boolean?)
	if Yielding then
		return FireHitbox(self);
	else
		local result = nil;
		task.spawn(function()
			result = FireHitbox(self);
		end);
		-- Wait for result
		repeat task.wait() until result ~= nil;
		return result;
	end;
end;

-- Modified FireFor to return detected entities immediately when found
function ClientHitbox:FireFor(Duration: number, Frequency: number?)
	assert(Duration, 'No duration was provided!');

	Frequency = Frequency or 1/60;
	local detectedEntities = {};
	local startTime = tick();

	local connection;
	connection = RunService.RenderStepped:Connect(function()
		if tick() - startTime >= Duration then
			connection:Disconnect();
			return;
		end;

		local currentHits = self:Fire(true);
		if #currentHits > 0 then
			for _, entity in pairs(currentHits) do
				if not table.find(detectedEntities, entity) then
					table.insert(detectedEntities, entity);
				end;
			end;
		end;
	end);

	-- Wait for duration or until entities are found
	local elapsed = 0;
	while elapsed < Duration do
		task.wait(Frequency);
		elapsed = tick() - startTime;

		-- Return immediately if entities are detected and single mode is on
		if self.single and #detectedEntities > 0 then
			connection:Disconnect();
			break;
		end;
	end;

	connection:Disconnect();
	return detectedEntities;
end;

function ClientHitbox:FireConsecutive(Amount: number, FireDelay: number, Yielding: boolean?, NoCallYield: boolean?)
	local allDetected = {};

	local function Action(self)
		for i = 1, Amount do
			if self.completed == true then
				break;
			end;

			local currentHits = self:Fire(not NoCallYield);
			if currentHits and #currentHits > 0 then
				for _, entity in pairs(currentHits) do
					if not table.find(allDetected, entity) then
						table.insert(allDetected, entity);
					end;
				end;
			end;

			task.wait(FireDelay);
		end;
		self.completed = true;
	end;

	if Yielding then
		Action(self);
	else
		task.spawn(Action, self);
		-- Wait for completion
		repeat task.wait() until self.completed == true;
	end;

	return allDetected;
end;

function ClientHitbox:Parse(HitboxPart: Part)	
	local Character = HitboxPart:FindFirstAncestorWhichIsA("Model")
	if not Character then return end

	local humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if not Character:FindFirstChildOfClass('Humanoid') then return end;

	local FoundEntity = Character;
	if not FoundEntity then return end;
	if self.ignoreCaster and self.caster and self.caster.Character and FoundEntity == self.caster.Character.Rig then return end;

	if self.single and (#self.currentDetected > 0 or self.hit) then
		return;
	end;

	if table.find(self.currentDetected, FoundEntity) then return end;
	if self._DetectionBlacklist[FoundEntity] then return end;
	if self.ignorePrevious and table.find(self.detected, FoundEntity) then return end;
	if FoundEntity.Humanoid.Health <= 0 and self.ignoreDead then return end;
	if #self.ignoredEntities ~= 0 then
		if table.find(self.ignoredEntities, FoundEntity) then
			return;
		end;
	end;

	table.insert(self.currentDetected, FoundEntity);
	table.insert(self.detected, FoundEntity);

	if self.onHit then 
		task.spawn(self.onHit, FoundEntity);
	end;

	self.hit = true;
end;

-- Client-specific function to handle server requests
function ClientHitbox.HandleServerRequest(Params)
	local hitbox = ClientHitbox.new(Params.caster);

	-- Apply parameters
	hitbox.shape = Params.shape or 'Box';
	hitbox.ignorePrevious = Params.ignorePrevious ~= false;
	hitbox.ignoreCaster = Params.ignoreCaster ~= false;
	hitbox.ignoreRagdolled = Params.ignoreRagdolled ~= false;
	hitbox.ignoreDead = Params.ignoreDead or false;
	hitbox.ignoredEntities = Params.ignoredEntities or {};
	hitbox.single = Params.single or false;
	hitbox.root = Params.root;
	hitbox.offset = Params.offset or CFrame.new(0,0,0);
	hitbox.size = Params.size or Vector3.one*5;
	hitbox.zMiddlePoint = Params.zMiddlePoint or false;
	hitbox.debug = Params.debug or false;

	local returnValue = nil;
	local timePassed = false;

	if Params.Time == 'Once' then
		returnValue = hitbox:Fire(true);
	else
		local Start = tick();
		local connection: RBXScriptConnection, canProceed = nil, false;

		connection = RunService.RenderStepped:Connect(function()
			local playerCharacter = Player.Character;
			if not (playerCharacter and playerCharacter:FindFirstChild('cancelHitboxes')) and tick() - Start < Params.Time then
				local currentHits = hitbox:Fire(true);
				if currentHits and #currentHits > 0 then
					returnValue = currentHits;
					canProceed = true;
				end;
			else
				canProceed = true;
			end;
		end);

		repeat task.wait() until canProceed == true;
		connection:Disconnect();
	end;

	return returnValue or {};
end;

return ClientHitbox;