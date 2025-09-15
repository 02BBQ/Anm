local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Services;
local Auxiliary = require(Shared.Utility.Auxiliary);

local Spell = require(ServerScriptService.Server.Skills.Spell):Extend();
Spell.Name = script.Name;
Spell.CastSign = 0;

function Spell:OnCast(Entity, Args)
	if not Args["held"] then return end;
	if not Entity.Combat:CanUse() then return end;
	
	Entity.Combat:Active(false);

	local Start : AnimationTrack = Entity.Animator:Fetch("Fallen/BStart");
	Start:Play();
	
	Entity.VFX:Fire("Fallen/Berserk", {Action = "start", ID = Start.Animation.AnimationId});
	
	Auxiliary.Shared.WaitForMarker(Start, "run")
	
	local result = Shared.Remotes.Hitbox:InvokeClient(Entity.Player, {
		caster = Entity:GetClientEntity();
		Time = 0.7;
		size = Vector3.new(10, 10, 10);
		offset = CFrame.new(0,0,-5);
		single = true;
		root = Entity.Character.Root;
	})
	
	if result then
		local hitbox = Entity:CreateHitbox()
		hitbox.instance = Entity.Character.Root;
		hitbox.size = Vector3.new(55,55,55);
		hitbox.offset = CFrame.new(0,0,-25);
		hitbox.detecting = {result};
		hitbox.single = true;
		hitbox.onHit = function(EnemyEntity)
			Start:Stop();
			local User : AnimationTrack = Entity.Animator:Fetch("Fallen/Berserk Hit");
			User:Play();
			
			local Weld = Instance.new('Weld', Entity.Character.Rig);
			Weld.Name = 'CarryWeld';
			Weld.Part0 = Entity.Character.Root;
			Weld.Part1 = EnemyEntity.Character.Root;
			Weld.C0 = CFrame.new(0, 0, -8) * CFrame.Angles(0,math.pi,0);
			
			local Victim : AnimationTrack = EnemyEntity.Animator:Fetch("Fallen/Berserk Victim");
			Victim:Play();
			
			Auxiliary.Shared.SetCollisionGroups(EnemyEntity.Character.Rig, "Carry");
			for Index, Part in pairs(EnemyEntity.Character.Rig:GetChildren()) do
				if Part:IsA'BasePart' then
					if Part:GetAttribute'WasMassless' == nil then Part:SetAttribute('WasMassless', Part.Massless) end

					Part.Massless = true
					Part:SetNetworkOwner(Entity.Player);
				end
			end

            Entity.VFX:Fire("Fallen/Berserk", {Action = "grab", ID = User.Animation.AnimationId});
			
			Victim.Stopped:Wait();
			
			Entity.Combat:Active(true);
			
			Weld:Destroy();
			
			Auxiliary.Shared.SetCollisionGroups(EnemyEntity.Character.Rig, "Entity");

			if EnemyEntity.Character.Rig:IsDescendantOf(workspace) then
				for Index, Part in pairs(EnemyEntity.Character.Rig:GetChildren()) do
					if Part:IsA'BasePart' then
						if Part:GetAttribute'WasMassless' == nil then Part:SetAttribute('WasMassless', Part.Massless) end

						Part.Massless = Part:GetAttribute'WasMassless'
						Part:SetNetworkOwner(EnemyEntity.Player)
					end
				end
			end
			
			local DamageData = {
				Damage = 10;
				Knockback = {Velocity = Entity.Character.Root.CFrame.LookVector * 5 + Vector3.new(0,75 ,0), Duration = 0.25};
				Ragdoll = {Duration = 2};
			}
			EnemyEntity.Combat:TakeDamage(DamageData, Entity);
		end
		hitbox:Fire();
	end
	
	Start.Stopped:Wait();
	Entity.Combat:Active(true);

end;


return Spell;