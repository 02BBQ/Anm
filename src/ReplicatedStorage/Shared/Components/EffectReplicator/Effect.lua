local HttpService = game:GetService('HttpService');
local Signal = require(script.Parent.Signal);

local Effect = {};
Effect.__index = function(self, p)
	local prop = rawget(self._props, p);

	if (prop == nil) then
		prop = rawget(self, p);
	end;
	
	if (prop == nil) then
		prop = rawget(Effect, p);
	end;

	return prop;
end;

Effect.__metatable = 'Effect';

local readOnlyProperties = {'Class', 'ID', 'Domain'};

function Effect:__tostring()
	return string.format('Effect: %s [%s] (%s|%s) [%s]', tostring(self.ID), string.upper(self.Domain), tostring(self.Class), tostring(self.Value), self.Disabled and 'X' or '\226\156\147');
end;

function Effect:__newindex(p, v)
	if (table.find(readOnlyProperties, p)) then
		return error(string.format('Attempt to change %s of effect', p));
	end;

	rawset(self._props, p, v);

	if (rawget(self, 'Shadow')) then
		self.Shadow:Fire(p, v);
	end;
end;

function Effect.new(effectReplicator, data, isServer, customDebrisTime)
	local props = {};
	
	props.Domain = data.Domain or isServer and 'Server' or 'Client';
	props.ID = data.ID or HttpService:GenerateGUID(false);	
	props.Class = data.Class;
	props.Disabled = data.Disabled or false;
	props.Value = data.Value ~= nil and data.Value or '???';
	props.Parent = effectReplicator;
	props.Tags = data.Tags or {};
	props.DebrisTime = customDebrisTime or 0
	
	local self = setmetatable({_props = props}, Effect);
	
	rawset(self, 'TagAdded', Signal.new());
	rawset(self, 'TagRemoving', Signal.new());
	
	return self;
end;

function Effect:ParseEffect()
	return {
		Class = self.Class,
		Disabled = self.Disabled,
		Tags = self.Tags,
		Domain = self.Domain,
		ID = self.ID,
		Value = self.Value,
		DebrisTime = self.DebrisTime,
	}
end;

function Effect:Debris(debrisTime)
	task.delay(debrisTime, function ()
		-- print(self.Class);		
		self:Destroy();
		-- print(self);
	end);
	return self;
end;

function Effect:Connect(f)
	if (not self.Shadow) then
		rawset(self, 'Shadow', Signal.new());
	end;

	self.Shadow:Connect(f);
end;

Effect.connect = Effect.Connect;

function Effect:AddTag(name)
	self.Tags[name] = true;
	self.TagAdded:Fire(name);
end;

function Effect:RemoveTag(name)
	self.Tags[name] = nil;
	self.TagRemoving:Fire(name);
end;

function Effect:HasTag(name)
	return self.Tags[name] == true;
end;

function Effect:Destroy()
	if (self.Destroyed and not self.Parent) then
		return;
	end;

	self.Destroyed = true;
	
	if self.Parent and self.Parent.Effects then
		self.Parent:_updateCache(self, true);
		self.Parent.Effects[self.ID] = nil;
		self.Parent.EffectRemoving:Fire(self);
	end
	
	self.TagAdded:Destroy();
	self.TagRemoving:Destroy();
	
	if (self.Shadow) then
		self.Shadow:Destroy();
		self.Shadow = nil;
	end;
	
	self.TagAdded = nil;
	self.TagRemoving = nil;
	self.Parent = nil;
end;

Effect.Remove = Effect.Destroy;
return Effect;