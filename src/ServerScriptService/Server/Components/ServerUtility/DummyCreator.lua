--//Variables
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;

local _TroveClass = require(SharedComponents.Utility.Trove);

local Map: Folder = workspace:WaitForChild('Map');
local DummyData: Folder = Map.Data.Dummies;

local EntityManager = require(Components.Core.EntityManager);

--//Module
local DummyCreator = {};
DummyCreator.Enabled = true;

DummyCreator.Types = {
	
	Trading = function(Entity : {})
		
		repeat
			
			pcall(function()
				
				task.wait(0.5)
				
				Entity.ActionManager:Execute("Block", false)
				
				task.wait(0.1)
				
				Entity.ActionManager:Execute('Light', true);
				
				task.wait(0.7)
				
				Entity.ActionManager:Execute("Block", true)
				
			end);
			
			task.wait(.1);
		until not Entity.Character.Alive;
		
	end,
	
	Finisher = function(Entity : {})
		
		Entity.Combat:Afflict(Entity, {
			NoExceptions = true;
			Actions = {
				Damage = 99;
			};
		});
		
	end,

	StringAttack = function(Entity: {})
		repeat
			pcall(function()
				Entity.ActionManager:Execute('Light', true);
			end);
			task.wait(.1);
		until not Entity.Character.Alive;
	end;
	
	FinisherAttack = function(Entity: {})
		repeat
			pcall(function()
				Entity.ActionManager:Execute('Light', true);
			end);
			task.wait(.1);
		until not Entity.Character.Alive;
		
	end;
	
	Attacking = function(Entity: {})
		repeat
			pcall(function()
				Entity.ActionManager:Execute('Light', true);
			end);
			task.wait(2);
		until not Entity.Character.Alive;
	end;
	
	Blocking = function(Entity: {})
		task.wait(3);
		repeat
			pcall(function()
				Entity.ActionManager:Execute('Block', true);
			end);
			task.wait(5);
		until not Entity.Character.Alive;
	end;
	
	Respawning = function(Entity: {})
		while task.wait(5) do
			Entity.Character:Respawn();
		end;
	end;
	
	Invincible = function(Entity: {})
		Entity.Character.MaxHealth = math.huge
		Entity.Character.Health = math.huge
	end,
	
	Regen = function(Entity: {})
		task.spawn(function()
			while task.wait(1) do
				if not Entity.Character.Alive then break end;
				if not Entity.Character.HealthRegeneration then continue end;
				if Entity.Character.Active then continue end;
				if Entity.Character.Stunned then continue end;
				
				Entity.Character.Health += (Entity.Combat and Entity.Combat.InCombat and .5) or 1;
				if Entity.Character.Health >= Entity.Character.MaxHealth then
					Entity.Character.Health = Entity.Character.MaxHealth
				end
				Entity.Character.HealthChanged:Fire()
			end
		end)
	end,
};

function DummyCreator:SpawnDefault()
	for _,v: BasePart in DummyData:GetChildren() do
		DummyCreator:Spawn(v.Name, v.CFrame, true);
	end;
end;

DummyCreator.Spawned = function(DummyType, Entity: {}, DummyFunc: () -> ()?)
	if DummyFunc then
		task.spawn(DummyFunc, Entity);
	end;
	
	local BarTrove = _TroveClass.new();
	
	local DummyBar = Shared.Storage.DummyItems.DummyHealth:Clone();
	BarTrove:Add(DummyBar);
	
	DummyBar.Parent = Entity.Character.Rig.Head;
	Entity.Character.Rig.Humanoid.DisplayName = DummyType
	
	if DummyType == "Finisher" then
		DummyBar.HealthPercentage.Text = 1 .. "%"	
		Entity.Character.Health = 1;
	end
	
	BarTrove:Connect(Entity.Character.HealthChanged.Event, function()
		
		if not DummyBar.Parent then
			return;
		end;

		local Percentage = (Entity.Character.Health / Entity.Character.MaxHealth);
		local Fraction = (math.floor(Percentage * 1000)/1000)*100;

		local DisplayPercentage = (Fraction % 1 == 0) and string.format("%.0f", Fraction) or tostring(Fraction);
		
		if Fraction >= 10 and #DisplayPercentage >= 4 then
			DisplayPercentage = string.sub(DisplayPercentage, 1, 4);
		elseif Fraction < 10 and #DisplayPercentage >= 3 then
			DisplayPercentage = string.sub(DisplayPercentage, 1, 3);
		elseif Percentage == 1 then
			DisplayPercentage = '100';
		else
			DisplayPercentage = string.sub(DisplayPercentage, 1, 2);
		end;
		
		DummyBar.HealthPercentage.Text = DisplayPercentage .. '%';
	end);
	
	local function StunUpdate()
		local IsStunned = Entity.Character:GetAttribute('Stunned') or Entity.Character:GetAttribute('Active');
		DummyBar.HealthPercentage.TextColor3 = (IsStunned and Color3.new(1, 0, 0)) or Color3.new(1,1,1);
	end;
	
	BarTrove:Connect(Entity.Character.Rig:GetAttributeChangedSignal('Stunned'), StunUpdate);
	BarTrove:Connect(Entity.Character.Rig:GetAttributeChangedSignal('Active'), StunUpdate);
	
	Entity.Character.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;
	Entity.Character.Died.Event:Wait();
	
	BarTrove:Destroy();
	
end;

function DummyCreator:Spawn(DummyType: string, Location: CFrame?, BindSpawn: boolean?)
	task.spawn(function()
		if not DummyCreator.Enabled then return end;
		
		local DummyFunc = DummyCreator.Types[DummyType];
		
		local Entity = EntityManager.Spawn('Dummy');
		repeat task.wait(0.1) until Entity.Ready;
		
		Entity.Character.SpawnPosition = Location;
		Entity.Character:OnSpawn(function()
			DummyCreator.Spawned(DummyType, Entity, DummyFunc);
			
			if not BindSpawn then
				task.wait(5);
				Entity:Destroy();
			end;
		end);
		
		if BindSpawn then
			Entity.Character:BindSpawn();
		else
			Entity.Character:Create();
		end;
	end);
end;

return DummyCreator;