--//Variable
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService("ServerStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');

local Auxiliary = require(ReplicatedStorage.Shared.Utility.Auxiliary);
local Attirbute = require(ReplicatedStorage.Shared.Utility.Attribute);
local Ragdoll = require(script.Ragdoll);
local Signal = require(ReplicatedStorage.Shared.Package.Signal);
local Race = require(ReplicatedStorage.Shared.Services.Race);
local ItemFactory = require(ServerScriptService.Server.Components.Misc.ItemFactory);
local InitializeManager = require(script.Initialize);
local WeaponManager = require(ServerScriptService.Server.Components.Game.WeaponManager);
local Trove = require(ReplicatedStorage.Shared.Utility.Trove)
local Network = require(ReplicatedStorage.Shared.Services.Networking.Network);

local CharacterManager = {}

CharacterManager.__index = CharacterManager;

CharacterManager.new = function(Entity)
	local self = setmetatable({
		Parent = Entity;	
		
		_Trove = Trove.new();
		Rig = nil;
		Template = nil;
		
		Alive = false;
		
		_Connections = {};
		RagdollQueue = {};

		Ragdolled = false;
		Knocked = false;

		Attirbutes = nil;
		
		OnRespawn = Signal.new();
	}, CharacterManager);

	self.Weapon = self._Trove:Add(WeaponManager.new(self));

	return self;
end;

function CharacterManager:Respawn()
	local Entity = self.Parent
	if Entity.Player then
		self.Rig:Destroy();
		local newCharacter = Entity.Player:LoadCharacter();
	else
		if not self.Template then return end
		self.Rig:Destroy();
		self.Rig = self.Template:Clone();
		self.Rig.Parent = workspace.World.Alive;
	end
	
	-- Entity.Weapon.Equipped = false;
end

function CharacterManager:GetRootCFrame(MagnitudeTolerance: number?)
	if not self.Parent.Player then
		return self.Root.CFrame;
	end;

	local Returning;
	if self.Parent.Player then
		local Fetched = Network:Send('Fetch', {Fetching='RootCFrame'}, 1, self.Parent.Player);
		if Fetched then
			assert(typeof(Fetched) == 'CFrame', 'Returned value was not a CFrame! Possibly manipulated by the client');
			if (Fetched.Position - self.Root.Position).Magnitude <= (MagnitudeTolerance or 10) then
				Returning = Fetched;
			end;
		end;
	end;

	Returning = Returning or self.Root.CFrame;
	return Returning;
end;

--function CharacterManager:GetPointingAt()
--	if not self.Parent.Player then
--		return self.Root.CFrame * CFrame.new(0,0,-5);
--	end;

--	local ClientValues: {};
--	if self.Parent.Player then
--		local Fetched = _G.BridgeNet2
--		--local Fetched = Network:Send('Fetch', {Fetching='Pointing'}, 1, self.Parent.Player);
--		if Fetched then
--			assert(typeof(Fetched) == 'table', 'Returned value was not a table! Possibly manipulated by the client');
--			ClientValues = Fetched;
--		end;
--	end;

--	if ClientValues then
--		assert(typeof(ClientValues[1]) == 'CFrame' and typeof(ClientValues[2]) == 'CFrame', 'Invalid type returned');
--		return table.unpack(ClientValues);
--	end;

--	return {self.Root.CFrame * CFrame.new(0,0,-5), self.Root.CFrame};
--end;

--function Characters:GetRelativeCFrame()
--	local EndCFr: CFrame, RootCFr: CFrame = self:GetPointingAt();
--	local FacingCFr: CFrame = CFrame.new(RootCFr.Position, EndCFr.Position);

--	return FacingCFr;
--end;

function CharacterManager:Knock()
	local Entity = self.Parent;
	self.Knocked = true;
	self:Ragdoll(true);
	Entity.Combat:Active(false);
end

function CharacterManager:Ragdoll(Val, Absolute: boolean?)
	local IsDuration = typeof(Val) == 'number';
	if self.Ragdolled then
		if not IsDuration and Val == true then return; end;
	end;

	if IsDuration then
		Ragdoll.Ragdoll(self.Parent, true);
		task.delay(Val, function()
			Ragdoll.Ragdoll(self.Parent, false, Absolute);
		end);
	else
		Ragdoll.Ragdoll(self.Parent, Val, Absolute);
	end;
end;

function CharacterManager:InitCharacter()
	local Entity = self.Parent
	
	
	local Rig = self.Rig;
	self.Parent.Combat:Active(true);
	self.Alive = true;

	self.Attirbutes = Attirbute(Rig);
	table.clear(self.RagdollQueue);
	self.Ragdolled = false;

	-- Character Setup 시스템 실행
	InitializeManager.Initialize(Entity);
	
	assert(Rig, 'There is no rig');
	self.Humanoid = Rig:FindFirstChildOfClass("Humanoid")
	self.Root = Rig.HumanoidRootPart
	self.Animator = self.Humanoid:FindFirstChildOfClass("Animator")

	self.Humanoid.BreakJointsOnDeath = false;

	Auxiliary.Shared.SetCollisionGroups(Rig, "Entity");

	self.Parent.Animator:Cache();
	
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true);
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false);
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false);
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false);
	
	Rig.Humanoid.Died:Connect(function()
		for i,con in pairs(self._Connections) do
			con:Disconnect();	
		end
		
		self:Ragdoll(true);
		self.Alive = false;
		task.wait(5);
		self:Respawn();
	end);
end

function CharacterManager:Destroy()
	if self.Rig then
		self.Rig:Destroy();
	end;
	self._Trove:Destroy();
end;

return CharacterManager
