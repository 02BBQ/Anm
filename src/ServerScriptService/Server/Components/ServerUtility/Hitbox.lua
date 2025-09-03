--//Variables
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService('RunService');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local World   : Folder = workspace:WaitForChild("World")
local Entities: Folder = World:WaitForChild('Alive');

--local Debris = require(SharedComponents.Utility.Debris);
--local Network = require(SharedComponents.Networking.Network);
local Auxiliary = require(Shared.Utility.Auxiliary);
--local SettingsHandler = require(ReplicatedStorage:WaitForChild('Shared').Components.Data.SettingsHandler);

--//Module
local Hitbox = {};
Hitbox.__index = Hitbox;

Hitbox.new = function(CasterEntity: {}?)
	local self = setmetatable({
		
		_DetectionBlacklist = {};
		
		caster = CasterEntity;
		detected = {};
		
	}, Hitbox);
	
	self.shape = 'Box'; -- Provide PartType enum
	
	self.ignorePrevious = true; -- Ignores entities that have already been stored in the hitbox object if detected again
	self.ignoreCaster = true; -- Ignores entity that casted hitbox
	self.ignoreRagdolled = true; -- Ignores ragdolled entities
	self.ignoreDead = false; -- Ignore dead entities
	self.ignoredEntities = {}; -- Ignores any detected entities if they're in this table
	
	self.single = false; -- Only detect 1 entity
	
	self.accurateCFrame = false; -- If root is a humanoidrootpart, hitbox requests HRP CFrame from client, not recommended as there can be significant delays
	
	self.root = nil; -- Root of hitbox (Vector3 | CFrame | Part)
	self.offset = CFrame.new(0,0,0); -- CFrame offset
	self.size = Vector3.one*5; -- Hitbox size
	
	self.zMiddlePoint = false; -- Add middle point of Z scale to offset
	
	self.clientMagnitudeTolerance = 10; -- Maximum distance between clients provided CFrame of HRP and servers HRP CFrame
	
	self.onHit = nil; -- Optional callback function
	self.debug = false; -- Creates transparent part to display hitbox
	
	self.hit = false; -- Sets to true once a hit has been detected
	
	return self;
end;

function Hitbox:GetParams()
	local Detecting = {};
	
	Detecting = {workspace.World.Alive}
	
	local EntityOverlapParams = OverlapParams.new();
	EntityOverlapParams.FilterDescendantsInstances = Detecting;
	EntityOverlapParams.FilterType = Enum.RaycastFilterType.Include;
	EntityOverlapParams.CollisionGroup = 'Hitbox';
	
	if self.single then
		EntityOverlapParams.MaxParts = 1;
	end;
	
	return EntityOverlapParams;
end;

local function FireHitbox(self)
	local HitboxRoot = (typeof(self.root) == 'Instance' and self.root.CFrame) or (typeof(self.root) == 'Vector3' and CFrame.new(self.root)) or (typeof(self.root) == 'CFrame' and self.root);
	if not HitboxRoot then
		HitboxRoot = (self.accurateCFrame and self.caster.Character:GetRootCFrame(self.clientMagnitudeTolerance)) or self.caster.Character.Root.CFrame;
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
		DebugPart.Color = Color3.new(1,0,0);
		DebugPart.Transparency = .9;
		DebugPart.CastShadow = false;

		DebugPart.Parent = workspace.World.Debris;
		game.Debris:AddItem(DebugPart, 1);
	end;
end;

function Hitbox:Fire(Yielding: boolean?)
	if Yielding then
		FireHitbox(self);
	else
		task.spawn(FireHitbox, self);
	end;
end;

function Hitbox:FireFor(Duration: number, Frequency: number?)
	assert(Duration, 'No duration was provided!');
	
	Frequency = Frequency or 1/60;
	local FireUpdate = Auxiliary.Shared.FixedUpdate(function()
		self:Fire();
	end, Frequency);
	
	task.delay(Duration, function()
		FireUpdate();
	end);
	
	return FireUpdate;
end;

function Hitbox:FireConsecutive(Amount: number, FireDelay: number, Yielding: boolean?, NoCallYield: boolean?)
	local function Action(self)
		for i = 1,Amount do
			if self.completed == true then
				break;
			end;
			
			self:Fire(not NoCallYield);
			task.wait(FireDelay);
		end;
		self.completed = true;
	end;
	
	if Yielding then
		Action(self);
	else
		task.spawn(Action, self);
	end;
end;

function Hitbox:AnticipateHit(Duration: number)
	task.wait(Duration);
	if not self.completed then
		repeat task.wait(0.1) until self.completed;
	end;
	return self.hit;
end;

function Hitbox:Parse(HitboxPart: Part)	
	local Character = HitboxPart:FindFirstAncestorWhichIsA("Model")
	if not Character then return end

	local humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	if not Character:FindFirstChildOfClass('Humanoid') then return end;
	
	local FoundEntity = _G.FindEntity(Character);
	if not FoundEntity then return end;
	if self.ignoreCaster and FoundEntity == self.caster then return end;
	
	if self.single and (#self.currentDetected > 0 or self.hit) then
		return;
	end;
	
	if table.find(self.currentDetected, FoundEntity) then return end;
	if self._DetectionBlacklist[FoundEntity] then return end;
	if not FoundEntity.Combat.Detectable then return end;
	if self.ignorePrevious and table.find(self.detected, FoundEntity) then return end;
	-- if self.ignoreRagdolled and FoundEntity.Character.Ragdolled then return end;
	if not FoundEntity.Character.Alive and self.ignoreDead then return end;
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

return Hitbox;