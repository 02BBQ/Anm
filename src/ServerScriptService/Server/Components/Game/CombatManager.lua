--//Variable
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');

local Server: Folder = ServerScriptService:WaitForChild('Server');
local Components: Folder = Server.Components;
local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;

local BridgeNet = require(Shared.Package.BridgeNet2);
local Auxiliary = require(Shared.Utility.Auxiliary);
local TroveClass = require(Shared.Utility.Trove);
local SoundHandler = require(Shared.Utility.SoundHandler);

local IsStudio = RunService:IsStudio();
local random = Random.new();

local Knockback = BridgeNet.ServerBridge('Knockback');

--//Module
local CombatManager = {};
CombatManager.__index = CombatManager;

CombatManager.new = function(Entity: {})
	local self = setmetatable({
		
		Parent = Entity;	
		_Trove = TroveClass.new();

		AirtimeManager = require(Server.Components.Game.AirtimeManager);
		
		Cancellables = {};
		MobilityQueue = {};
		
		Timers = {};
		
		InCombat = false;
		_Active = true;
		
		Detectable = true;
		
		_Block = {
			postureMax = 20;
			IsBlocking = false;
			Posture = 20;
			Animation = nil;
		};
		_ParryingQueue = {};
		
		ComboTick = 0;
		Combo = 1;

		_isAirborne = false;
		
	}, CombatManager);

	return self;
end;

function CombatManager:IsAirborne()
	return self._isAirborne;
end

function CombatManager:IsStunned()
	local Character = self.Parent.Character.Rig;
	if Character.Humanoid.Health <= 0 then 
		return true;
	end
	if not self._Active then
		return true;
	end
	if self.Parent.EffectReplicator:FindEffect("Stunned") then 
		return true;
	end
	if self.Parent.EffectReplicator:FindEffect("TrueStunned") then 
		return true;
	end
	if self.Parent.Character.Ragdolled then
		return true;
	end
	return false;
end

function CombatManager:CanUse()
	local Character = self.Parent.Character.Rig;
	if Character.Humanoid.Health <= 0 then 
		return false;
	end
	if self.Parent.EffectReplicator:FindEffect("TrueStunned") then 
		return false;
	end
	if not self._Active then
		return false;
	end
	if self.Parent.Character.Ragdolled then
		return false;
	end
	return true;
end

function CombatManager:Active(bool: boolean)
	self._Active = bool;
	self.Parent.Character.Rig:SetAttribute("Active", bool);
end

function CombatManager:UpdateCombatStatus()
	local LastTick = self.LastCombatTick;
	if not LastTick then
		self.InCombat = false;
		return;
	end;
	
	self.InCombat = (tick()-self.LastCombatTick) < 30; --Information:Get('Combat/Default').InCombatDuration;
end;

function CombatManager:AddCombatStatus()
	self.LastCombatTick = tick();
	self:UpdateCombatStatus();
	
	task.delay(30, function() --Information:Get('Combat/Default').InCombatDuration, function()
		self:UpdateCombatStatus();
	end);
end;

function CombatManager:Block(held: boolean?)
	local Entity = self.Parent;

	self._Block.Animation = Entity.Animator:Fetch('Universal/Block/Main');

	if held then
		if not self:CanUse() then return end
		self:Parry();
		if self:IsStunned() then return end
		self._Block.Animation:Play();
		self:AddBlock();
		self._Active = false;
	else
		self:RemoveBlock();
	end
end

function CombatManager:AddBlock()
	self._Block.IsBlocking = true;
	self._Block.Posture = self._Block.postureMax;
end

function CombatManager:RemoveBlock()
	self._Active = true;
	if not self._Block.IsBlocking then return end
	self._Block.IsBlocking = false;
	self._Block.Posture = 0;
	self._Block.Animation:Stop();
end

function CombatManager:IsParrying()
	return #self._ParryingQueue > 0;
end;

function CombatManager:AddParryingFrame()
	table.insert(self._ParryingQueue, true);
end;

function CombatManager:Parry()
	if self.Parent.Cooldowns.OnCooldown['Parry'] then return end;
	self.Parent.Cooldowns:Add('Parry', 1);
	local ParryingWindow = 0.22;
	self:AddParryingFrame();

	local anim = self.Parent.Animator:Fetch('Weapons/Fist/Parry');
	anim:Play();

	task.delay(ParryingWindow, function()
		self:RemoveParryingFrame();
	end);
end;

function CombatManager:RemoveParryingFrame()
	if #self._ParryingQueue <= 0 then return end;
	table.remove(self._ParryingQueue, 1);
end;

function CombatManager:TakeDamage(DamageData, attackerEntity)
	local entity = self.Parent;

	local rig = entity.Character.Rig;
	local attacker = attackerEntity.Character.Rig;

	local VFX : string? = DamageData.VFX;
	local BaseDamage : number? = DamageData.Damage;
	local Damage : number?;
	Damage = BaseDamage

	local Type : string? = DamageData.Type;

	local function OnHit()

		if self:IsParrying() and not DamageData.NotParryable then
			self.Parent.Animator:Fetch('Weapons/Fist/Parrying1');

			entity.Cooldowns:Reset('Parry', 1);
			attackerEntity.Combat:AttemptCancel(DamageData.Cancel or 1);
			attackerEntity.EffectReplicator:CreateEffect("Stunned"):Debris();
			entity.VFX:Fire("HitEffect",
				{
					Root = attacker.HumanoidRootPart;
					Type = "Parry";
					Sound = "Hit/Parry";
				}, BridgeNet.AllPlayers())

			return;
		end

		if DamageData.BypassBlock then
			self:RemoveBlock();
		end

		if self:IsBlocking(DamageData) and not DamageData.BypassBlock then
			self.Parent.Animator:Fetch('Weapons/Fist/Parrying1'):Play();

			entity.Cooldowns:Reset('Parry', 1);
			attackerEntity.Combat:AttemptCancel(DamageData.Cancel or 1);
			attackerEntity.EffectReplicator:CreateEffect("Stunned"):Debris();
			entity.VFX:Fire("HitEffect",
				{
					Root = attacker.HumanoidRootPart;
					Type = "Parry";
					Sound = "Hit/Parry";
				}, BridgeNet.AllPlayers())

			return	

			
			-- self._Block.Posture -= (Damage or 0);

			-- if self._Block.Posture <= 0 then
			-- 	self:BlockBreak();
			-- else
			-- 	self.Parent.Animator:Fetch('Universal/Block/Hurt/'..math.random(1,3)):Play();
			-- 	entity.VFX:Fire("HitEffect",
			-- 	{
			-- 		Root = attacker.HumanoidRootPart;
			-- 		Type = "Parry";
			-- 		Sound = "Hit/Block";
			-- 	}, BridgeNet.AllPlayers())
			-- 	return;
			-- end
		end

		if DamageData.Knockback then
			DamageData.Knockback.attacker = attackerEntity;	
			self:Knockback(DamageData.Knockback)
			if DamageData.Knockback.Follow then
				attackerEntity.Combat:Knockback(DamageData.Knockback)
			end
		end

		if DamageData.OnHit then
			DamageData.OnHit(rig)
		end

		if DamageData.Ragdoll then
			entity.Character:Ragdoll(DamageData.Ragdoll.Duration)
		end

		if DamageData.Stun then
			self:AttemptCancel(DamageData.Cancel or 1);
			entity.EffectReplicator:CreateEffect("Stunned"):Debris(DamageData.Stun);
		end

		if DamageData.camShake then
			--pcall(function()
			--	if not attackerEntity.Player then return end;
			--	_util:Fire(attackerEntity.Player, {
			--		'addShake', DamageData.camShake;
			--	});
			--end)
			--pcall(function()
			--	if not entity.Player then return end;
			--	_util:Fire(entity.Player, {
			--		'addShake', DamageData.camShake;
			--	});
			--end)
		end

		if Damage then
			if entity.Character.Humanoid.Health - Damage <= 1 then
				entity.Character.Humanoid.Health = 1;
				entity.Character:Knock();
			else
				entity.Character.Humanoid.Health -= Damage;
			end

			entity.VFX:Fire("HitEffect",
					{
						Victim = rig;
						Attacker = attackerEntity:GetClientEntity();
						Type = VFX;
						Damage = Damage;
						Sound = DamageData.Sound;
					})

			entity.Animator:Fetch('Universal/Hurt'..random:NextInteger(1,3)):Play()
		end
	end;

	OnHit();
end

function CombatManager:Knockback(Data)
	local TargetEntity = self.Parent;
	if TargetEntity.Player and TargetEntity.Character.Root:GetNetworkOwner() == TargetEntity.Player then
		Knockback:Fire(TargetEntity.Player, {Entity = TargetEntity:GetClientEntity(); Data = Data});
	else
		local dir = self.Parent.Character.Root.Position - Data.attacker.Character.Root.Position;
		dir = dir.Unit;

		local TrueVelocity = Data.Velocity or ((dir or self.Parent.Character.Root.CFrame.LookVector) * Data.Push);
		--TargetEntity.Character:AssignOwnership(self.Parent.Player);

		if Data.AngularVelocity then
			TargetEntity.Character.Root.AssemblyAngularVelocity += Data.AngularVelocity;
		end;

		local BV: BodyVelocity = Auxiliary.Shared.CreateVelocity(TargetEntity.Character.Root);		
		BV.Velocity = TrueVelocity;

		if Data.MaxForce then
			BV.MaxForce = Data.MaxForce;
		end;

		if Data.Ease then
			TweenService:Create(BV, TweenInfo.new(Data.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Velocity = Vector3.zero}):Play();
		end;

		task.delay(Data.Duration, function()
			if Data.Stay then
				task.delay(Data.Stay, function()
					BV:Destroy();
					--TargetEntity.Character:AssignOwnership(false);
				end)
			else
				BV:Destroy();
				--TargetEntity.Character:AssignOwnership(false);
			end

		end);
	end
end

function CombatManager:BlockBreak()
	self:RemoveBlock();
	local cantMove = self.Parent.EffectReplicator:CreateEffect("CantMove");
	cantMove:Debris(1.5);
	local stunned = self.Parent.EffectReplicator:CreateEffect("TrueStunned");
	stunned:Debris(1.5);
	--_G.effect:Fire(BridgeNet.AllPlayers(), {"HitEffect",
	--	{
	--		Origin = self.Parent.Character.Root;
	--		Victim = self.Parent.Character.Rig;
	--		Root = self.Parent.Character.Root;
	--		Type = "BlockBreak";
	--		Sound = "Hit/GuardBreak";
	--	}})
end

function CombatManager:IsBlocking(DamageData)
	if DamageData.Dot and self._Block.IsBlocking then
		local Origin : Model? = typeof(DamageData.Origin) == "table" and DamageData.Origin.Character.Rig or DamageData.Origin;
		local Victim : Model? = typeof(DamageData.Victim) == "table" and DamageData.Victim.Character.Rig or DamageData.Victim;

		local selfToOtherChar = (Victim.HumanoidRootPart.Position - Origin.HumanoidRootPart.Position).Unit
		local lookVector = Victim.HumanoidRootPart.CFrame.LookVector

		local dotProduct = lookVector:Dot(selfToOtherChar)
		--print(dotProduct)

		if dotProduct <= -0.2 then
			--print("Blocked")
			return true
		else
			self:RemoveBlock();
			return false
		end
	end

	return self._Block.IsBlocking;
end

function CombatManager:CreateCancel(Level: number?, Callback: () -> ()?, IgnoreHit: boolean | {}?, DebugName: string?)
	local CancelObject = {
		Level = Level or 1;
		IgnoreHit = IgnoreHit;
		Added = {};
		Callback = Callback or (function() end);
		Cancelled = false;
	};
	self.Cancellables[CancelObject] = true;
	
	if typeof(IgnoreHit) == 'table' then
		CancelObject.Included = IgnoreHit;
		
		for _,v in IgnoreHit do
			v.Combat.Cancellables[CancelObject] = true;
			v.Combat.Detectable = false;
		end;
	end;
	
	function CancelObject.RemoveShared()
		if CancelObject.Included then
			for _,v in CancelObject.Included do
				v.Combat.Cancellables[CancelObject] = nil;
				v.Combat.Detectable = true;
			end;
		end;
	end;
	
	function CancelObject.Remove()
		self.Cancellables[CancelObject] = nil;
		CancelObject.RemoveShared();
	end;
	
	function CancelObject:Add(Func)
		table.insert(CancelObject.Added, Func);
	end;
	
	if IsStudio then
		task.delay(10, function()
			if not self.Cancellables[CancelObject] then return end;
			warn(debug.traceback('\n*\n		Cancel instance has existed for a significant amount of time, did you forget to remove it?\n*'));
			if DebugName then
				warn(`Called by: {DebugName}`);
			end;
		end);
	end;
		
	return CancelObject;
end;

function CombatManager:AttemptCancel(Level: number)
	for v in self.Cancellables do
		if v.Level <= Level then
			v.Cancelled = true;		
			for _,Func in v.Added do
				Func();
			end;
			v.Callback();
			v.Remove();
		else
			if v.IgnoreHit then
				return false;
			end;
		end;
	end;
	
	return true;
end;

function CombatManager:Destroy()
	self._Trove:Destroy();
	self = nil;
end;

return CombatManager;