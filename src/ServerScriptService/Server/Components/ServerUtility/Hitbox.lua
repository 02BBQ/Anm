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
		
		Caster = CasterEntity;
		Detected = {};
		
	}, Hitbox);
	
	self.Shape = 'Box'; -- Provide PartType enum
	
	self.IgnorePrevious = true; -- Ignores entities that have already been stored in the hitbox object if detected again
	self.IgnoreCaster = true; -- Ignores entity that casted hitbox
	self.IgnoreRagdolled = true; -- Ignores ragdolled entities
	self.IgnoreDead = false; -- Ignore dead entities
	self.IgnoredEntities = {}; -- Ignores any detected entities if they're in this table
	
	self.Single = false; -- Only detect 1 entity
	
	self.AccurateCFrame = false; -- If root is a humanoidrootpart, hitbox requests HRP CFrame from client, not recommended as there can be significant delays
	
	self.Root = nil; -- Root of hitbox (Vector3 | CFrame | Part)
	self.Offset = CFrame.new(0,0,0); -- CFrame offset
	self.Size = Vector3.one*5; -- Hitbox size
	
	self.ZMiddlePoint = true; -- Add middle point of Z scale to offset
	
	self.ClientMagnitudeTolerance = 10; -- Maximum distance between clients provided CFrame of HRP and servers HRP CFrame
	
	self.OnHit = nil; -- Optional callback function
	self.Debug = false; -- Creates transparent part to display hitbox
	
	self.Hit = false; -- Sets to true once a hit has been detected
	
	return self;
end;

function Hitbox:GetParams()
	local Detecting = {};
	
	Detecting = {workspace.World.Alive}
	
	local EntityOverlapParams = OverlapParams.new();
	EntityOverlapParams.FilterDescendantsInstances = Detecting;
	EntityOverlapParams.FilterType = Enum.RaycastFilterType.Include;
	EntityOverlapParams.CollisionGroup = 'Hitbox';
	
	if self.Single then
		EntityOverlapParams.MaxParts = 1;
	end;
	
	return EntityOverlapParams;
end;

local function FireHitbox(self)
	local HitboxRoot = (typeof(self.Root) == 'Instance' and self.Root.CFrame) or (typeof(self.Root) == 'Vector3' and CFrame.new(self.Root)) or (typeof(self.Root) == 'CFrame' and self.Root);
	if not HitboxRoot then
		HitboxRoot = (self.AccurateCFrame and self.Caster.Character:GetRootCFrame(self.ClientMagnitudeTolerance)) or self.Caster.Character.Root.CFrame;
	end;

	local Offsetting: CFrame = self.Offset;
	if self.ZMiddlePoint then
		Offsetting *= CFrame.new(0,0,-(self.Size.Z/2));
	end;

	local HitboxPart: Part = Shared.Hitboxes[self.Shape]:Clone();

	HitboxPart.CFrame = HitboxRoot * Offsetting;
	HitboxPart.Size = self.Size;

	self.CurrentDetected = {};

	local Touching = workspace:GetPartsInPart(HitboxPart, self:GetParams());
	for _,v: Part in Touching do
		self:Parse(v);
	end;
	
	HitboxPart:Destroy()

	if self.Debug then
		local DebugPart = HitboxPart:Clone();
		DebugPart.Material = Enum.Material.SmoothPlastic;
		DebugPart.Color = Color3.new(1,0,0);
		DebugPart.Transparency = .7;
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
			if self.Completed == true then
				break;
			end;
			
			self:Fire(not NoCallYield);
			task.wait(FireDelay);
		end;
		self.Completed = true;
	end;
	
	if Yielding then
		Action(self);
	else
		task.spawn(Action, self);
	end;
end;

function Hitbox:AnticipateHit(Duration: number)
	task.wait(Duration);
	if not self.Completed then
		repeat task.wait(0.1) until self.Completed;
	end;
	return self.Hit;
end;

function Hitbox:Parse(HitboxPart: Part)	
	local Character = HitboxPart:FindFirstAncestorWhichIsA("Model")
	if not Character then return end

	local humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	if not Character:FindFirstChildOfClass('Humanoid') then return end;
	
	local FoundEntity = _G.FindEntity(Character);
	if not FoundEntity then return end;
	if self.IgnoreCaster and FoundEntity == self.Caster then return end;
	
	if self.Single and (#self.CurrentDetected > 0 or self.Hit) then
		return;
	end;
	
	if table.find(self.CurrentDetected, FoundEntity) then return end;
	if self._DetectionBlacklist[FoundEntity] then return end;
	if not FoundEntity.Combat.Detectable then return end;
	if self.IgnorePrevious and table.find(self.Detected, FoundEntity) then return end;
	if self.IgnoreRagdolled and FoundEntity.Character.Ragdolled then return end;
	if not FoundEntity.Character.Alive and self.IgnoreDead then return end;
	if #self.IgnoredEntities ~= 0 then
		if table.find(self.IgnoredEntities, FoundEntity) then
			return;
		end;
	end;
	
	table.insert(self.CurrentDetected, FoundEntity);
	table.insert(self.Detected, FoundEntity);
	
	if self.OnHit then 
		task.spawn(self.OnHit, FoundEntity);
	end;
	
	self.Hit = true;
	
end;

return Hitbox;