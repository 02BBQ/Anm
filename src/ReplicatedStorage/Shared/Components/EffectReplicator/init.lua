local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService('RunService');
local Players = game:GetService('Players')

local Player = Players.LocalPlayer;
local EffectReplication = ReplicatedStorage.Remotes:WaitForChild('EffectReplication');

local Effect = require(script.Effect);
local Signal = require(script.Signal);

local isServer = RunService:IsServer();

local EffectReplicator = {};
EffectReplicator.__index = EffectReplicator;

function EffectReplicator.new(player)
	local self = setmetatable({}, EffectReplicator);

	self.EffectAdded = Signal.new();
	self.EffectRemoving = Signal.new();

	self.Container = nil;
	self.Effects = {};
	self._classCache = {};
	self._tagCache = {};
	self._serverEffectCache = {};

	if (not isServer) then	
		EffectReplication._update.OnClientEvent:Connect(function(...)
			self:_handleClientUpdate(...);
		end);
	end;

	return self;
end;

function EffectReplicator:GetEffect(effectData)
	local effectId = typeof(effectData) == 'table' and effectData.ID or effectData;

	return self.Effects[effectId];
end;

function EffectReplicator:_updateCache(effect, isRemoving)
	local class = effect.Class;
	
	if (isRemoving) then
		if (self._classCache[class]) then
			for i, cachedEffect in ipairs(self._classCache[class]) do
				if (cachedEffect == effect) then
					table.remove(self._classCache[class], i);
					break;
				end;
			end;
			if (#self._classCache[class] == 0) then
				self._classCache[class] = nil;
			end;
		end;
		
		if (effect.Domain == 'Server' and self._serverEffectCache[class]) then
			for i, cachedEffect in ipairs(self._serverEffectCache[class]) do
				if (cachedEffect == effect) then
					table.remove(self._serverEffectCache[class], i);
					break;
				end;
			end;
			if (#self._serverEffectCache[class] == 0) then
				self._serverEffectCache[class] = nil;
			end;
		end;
		
		for tag, _ in pairs(effect.Tags or {}) do
			if (self._tagCache[tag]) then
				for i, cachedEffect in ipairs(self._tagCache[tag]) do
					if (cachedEffect == effect) then
						table.remove(self._tagCache[tag], i);
						break;
					end;
				end;
				if (#self._tagCache[tag] == 0) then
					self._tagCache[tag] = nil;
				end;
			end;
		end;
	else
		if (not self._classCache[class]) then
			self._classCache[class] = {};
		end;
		table.insert(self._classCache[class], effect);
		
		if (effect.Domain == 'Server') then
			if (not self._serverEffectCache[class]) then
				self._serverEffectCache[class] = {};
			end;
			table.insert(self._serverEffectCache[class], effect);
		end;
		
		for tag, _ in pairs(effect.Tags or {}) do
			if (not self._tagCache[tag]) then
				self._tagCache[tag] = {};
			end;
			table.insert(self._tagCache[tag], effect);
		end;
	end;
end;

function EffectReplicator:FindEffect(class, ignoreDisabled)
	local cachedEffects = self._classCache[class];
	if (not cachedEffects) then
		return nil;
	end;
	
	for _, effect in ipairs(cachedEffects) do
		if (not effect.Disabled or ignoreDisabled) then
			return effect;
		end;
	end;
	
	return nil;
end;

function EffectReplicator:FindServerEffect(class, ignoreDisabled)
	local cachedEffects = self._serverEffectCache[class];
	if (not cachedEffects) then
		return nil;
	end;
	
	for _, effect in ipairs(cachedEffects) do
		if (not effect.Disabled or ignoreDisabled) then
			return effect;
		end;
	end;
	
	return nil;
end;

function EffectReplicator:FindEffectWithTag(tag, ignoreDisabled)
	local cachedEffects = self._tagCache[tag];
	if (not cachedEffects) then
		return nil;
	end;
	
	for _, effect in ipairs(cachedEffects) do
		if (not effect.Disabled or ignoreDisabled) then
			return effect;
		end;
	end;
	
	return nil;
end;

function EffectReplicator:FindEffectWithValue(class, value, ignoreDisabled)
	for _, effect in next, self.Effects do
		if (effect.Class == class and effect.Value == value and (not effect.Disabled or ignoreDisabled)) then
			return effect;
		end;
	end;
end;

function EffectReplicator:CreateEffect(name, effectData, customDebrisTime)
	effectData = effectData or {};
	effectData.Class = name;
	
	local effect = Effect.new(self, effectData, isServer, customDebrisTime);

	self.Effects[effect.ID] = effect;
	self:_updateCache(effect, false);
	self.EffectAdded:Fire(effect);

	return effect;
end;

function EffectReplicator:GetEffects()
	local effectsArray = {};

	for _, effect in next, self.Effects do
		table.insert(effectsArray, effect);
	end;

	return effectsArray;
end;

function EffectReplicator:GetEffectsOfClass(class)
	local effectsArray = {};

	for _, effect in next, self.Effects do
		if (effect.Class == class) then
			table.insert(effectsArray, effect);
		end;
	end;

	return effectsArray;
end;

function EffectReplicator:GetEffectsWithTag(tag)
	local effectsArray = {};

	for _, effect in next, self.Effects do
		if (effect.Tags[tag]) then
			table.insert(effectsArray, effect);
		end;
	end;

	return effectsArray;
end;

function EffectReplicator:GetEffectsWithValue(class, value)
	local effectsArray = {};

	for _, effect in next, self.Effects do
		if (effect.Class == class and effect.Value == value) then
			table.insert(effectsArray, effect);
		end;
	end;

	return effectsArray;
end;

function EffectReplicator:ParseEffects()
	local effectParsed = {};

	if not self or not self.Effects then
		return effectParsed;
	end;

	for i, v in next, self.Effects do
		table.insert(effectParsed, v:ParseEffect());
	end;

	return effectParsed;
end;

function EffectReplicator:GetEffectsHash()
	local effectsHash = {};

	for _, effect in next, self.Effects do
		effectsHash[effect.Class] = true;
	end;

	return effectsHash;
end;

function EffectReplicator:_clearEffects()
	for i, v in next, self:GetEffects() do
		v:Destroy();
	end;
	
	self._classCache = {};
	self._tagCache = {};
	self._serverEffectCache = {};
end;

function EffectReplicator:_handleClientUpdate(replicationData)
	local updateType = replicationData.updateType;
	local sum = replicationData.sum;

	if (updateType == 'updatecontainer') then
		if (sum ~= self.Container) then
			self:_clearEffects();
			self.Container = sum;
		end;
	elseif (updateType == 'remove') then
		local effect = self.Effects[sum];

		if (effect) then
			effect:Destroy(true);
		end;
	elseif (updateType == 'clear') then
		self:_clearEffects();
	elseif (updateType == 'update') then
		for i, v in next, sum do
			local effect = self.Effects[v.ID] or self:CreateEffect(v.Class, v);
			local wasUpdated = false;

			if (v.Tags ~= nil and effect.Tags ~= v.Tags) then
				self:_updateCache(effect, true);
				effect.Tags = v.Tags;
				wasUpdated = true;
			end;

			if (v.Value ~= nil) then
				effect.Value = v.Value;
			end;

			if (v.Disabled ~= nil) then
				effect.Disabled = v.Disabled;
			end;
			
			if (v.DebrisTime ~= nil) then
				effect.DebrisTime = v.DebrisTime
			end

			if (wasUpdated) then
				self:_updateCache(effect, false);
			end;

			self.Effects[v.ID] = effect;
		end;
	end;
end;

function EffectReplicator:WaitForContainer()
	while (not self.Container) do
		task.wait();
	end;
end;

return isServer and EffectReplicator or EffectReplicator.new();