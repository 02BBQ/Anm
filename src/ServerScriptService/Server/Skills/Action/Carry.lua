local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared;
local SharedComponents = Shared.Components;
local Server = ServerScriptService.Server;

local Wiki = require(Shared.Wiki);
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

local WeaponInfos = Wiki.WeaponInfo;

local maxCombo = 5;
local comboResetTime = 1.2;

return function(Params)
	local Args = Params.Args;

	local Entity = Params.Caster;
	local Character = Entity.Character;

	if Entity.Cooldowns.OnCooldown["Carry"] then return end;
	if not Entity.Combat:CanUse() then return end;
	if Args.held then return end;

    local hit = false;

    Entity.Character.Carrying = Entity.Character.Carrying or {}; 
    
    if Entity.Character.Carrying.Carried then
        Entity.Character.Carrying.Cancel();
        return;
	end

    local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(12,12,12);
	hitbox.debug = true;
	hitbox.ignoreRagdolled = false;
    hitbox.shape = "Sphere";
	hitbox.onHit = function(EnemyEntity)
        if hit then return end;
		if EnemyEntity.Character.Knocked and EnemyEntity.Character.Alive and not EnemyEntity.Character.Carriedand and not EnemyEntity.Character.Gripped then
            hit = true;
        else
            return; 
		end
		
		local PickUpAnim: AnimationTrack = Entity.Animator:Fetch('Universal/Pickup');
		PickUpAnim:Play();

		local StartCancel = Entity.Combat:CreateCancel(1,function()
			PickUpAnim:Stop();
		end)

		PickUpAnim.Stopped:Connect(function()
			StartCancel.Remove();
		end)

		task.wait(0.6);
		if StartCancel.Removed then return end;

		if EnemyEntity.Character.Knocked and EnemyEntity.Character.Alive and not EnemyEntity.Character.Carried and not EnemyEntity.Character.Gripped then
        else
            return; 
		end
		
        local Carrying = Entity.Animator:Fetch('Universal/Carrying');
        Carrying:Play();
		local Weld = Instance.new('Weld', Character.Rig);
		Weld.Name = 'CarryWeld';
		Weld.Part0 = Character.Root;
		Weld.Part1 = EnemyEntity.Character.Root;
		Weld.C0 = CFrame.new(1.75, 1.5, 0) * CFrame.Angles(math.pi/2,math.pi,0);

        EnemyEntity.Character.Carried = true;

        Auxiliary.Shared.SetCollisionGroups(EnemyEntity.Character.Rig, "Carry");
        for Index, Part in pairs(EnemyEntity.Character.Rig:GetChildren()) do
			if Part:IsA'BasePart' then
				if Part:GetAttribute'WasMassless' == nil then Part:SetAttribute('WasMassless', Part.Massless) end
				
				Part.Massless = true
				Part:SetNetworkOwner(Entity.Player);
			end
		end

        Entity.Character.Carrying = {
            Carried = EnemyEntity;
            Cancel = function()
                Weld:Destroy();
				Carrying:Stop();
					
				if EnemyEntity.Character then
					EnemyEntity.Character.Carried = false;
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
				end

				if Entity.Character.Carrying then
					for _,v: RBXScriptConnection in Entity.Character.Carrying do
						if typeof(v) ~= 'RBXScriptConnection' then continue end;
						v:Disconnect();
					end
					table.clear(Entity.Character.Carrying);
				end

            end;
            Quit = Entity.Character.Rig:GetPropertyChangedSignal("Parent"):Connect(function()
                if not Entity.Character.Rig.Parent then
                    Entity.Character.Carrying.Cancel();
                end
            end);
            Enemy = EnemyEntity.Character.Rig:GetPropertyChangedSignal("Parent"):Connect(function()
                if not EnemyEntity.Character.Rig.Parent then
                    Entity.Character.Carrying.Cancel();
                end
            end);
            Died = Entity.Character.Humanoid.Died:Connect(function()
                Entity.Character.Carrying.Cancel();
            end);
        }
	end

	hitbox:Fire();
    
    Entity.Cooldowns:Add("Carry", 0.3)
end