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

	local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(10,111,55);
	hitbox.offset = CFrame.new(0,0,-15);
	hitbox.single = true;
	hitbox.onHit = function(EnemyEntity)
		local User : AnimationTrack = Entity.Animator:Fetch("Fallen/CurseThrow");
		User:Play();

		Entity.Character.Rig:PivotTo(EnemyEntity.Character.Root.CFrame * CFrame.new(0,0,-4));
		
		local bp = Auxiliary.Shared.CreatePosition(Entity.Character.Root);
		bp.MaxForce = Vector3.new(0, math.huge, 0);
		bp.Position = Entity.Character.Root.Position;
		bp.P = 2000;

		local Weld = Instance.new('Weld', EnemyEntity.Character.Root);
		Weld.Name = 'CarryWeld';
		Weld.Part0 = EnemyEntity.Character.Root;
		Weld.Part1 = Entity.Character.Root;
		
		Weld.C0 = CFrame.new(0, 0, 4) * CFrame.Angles(0,math.pi,0);
		Auxiliary.Shared.WaitForMarker(User, "grab");
		
		EnemyEntity.Character:Ragdoll(false, true);

		local Victim : AnimationTrack = EnemyEntity.Animator:Fetch("Fallen/CurseThrowVic");
		Victim:Play();
		
		Auxiliary.Shared.SetCollisionGroups(EnemyEntity.Character.Rig, "Carry");
		for Index, Part in pairs(EnemyEntity.Character.Rig:GetChildren()) do
			if Part:IsA'BasePart' then
				if Part:GetAttribute'WasMassless' == nil then Part:SetAttribute('WasMassless', Part.Massless) end

				Part.Massless = true
				Part:SetNetworkOwner(Entity.Player);
			end
		end

		Victim.Stopped:Wait();
		
		Entity.Combat:Active(true);
		
		bp:Destroy();
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
			Knockback = {Velocity = Entity.Character.Root.CFrame.LookVector * 45 + Vector3.new(0,35 ,0), Duration = 0.25};
			Ragdoll = {Duration = 2};
		}
		EnemyEntity.Combat:TakeDamage(DamageData, Entity);
	end
	hitbox:Fire();

	Entity.Combat:Active(true);
end;


return Spell;