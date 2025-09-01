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

	if Entity.Cooldowns.OnCooldown["Grip"] then return end;
    if Args.held then return end;
    Entity.Character.Grip = Entity.Character.Grip or {}; 
    
    if Entity.Character.Grip.Victim then
        Entity.Character.Grip.Cancel();
        return;
    end
	if not Entity.Combat:CanUse() then return end;

    local hit = false;

    local hitbox = Entity:CreateHitbox()
	hitbox.instance = Entity.Character.Root;
	hitbox.size = Vector3.new(12,12,12);
	hitbox.debug = true;
	hitbox.ignoreRagdolled = false;
    hitbox.shape = "Sphere";
	hitbox.onHit = function(EnemyEntity)
        if hit then return end;
        if EnemyEntity.Character.Knocked and EnemyEntity.Character.Alive and not EnemyEntity.Character.Carried and not EnemyEntity.Character.Gripped then
            hit = true;
        else
            return; 
        end
		local GripAnim = Entity.Animator:Fetch('Grip/Grip');
		GripAnim:Play();
		
		GripAnim:AdjustSpeed(1);
		
		local GrippedAnim = EnemyEntity.Animator:Fetch('Grip/GettingGripped');
		GrippedAnim:Play();

        EnemyEntity.Character:Ragdoll(false, true);

        Entity.Combat:Active(false);

        local Weld = Instance.new('Weld', Character.Rig);
		Weld.Name = 'CarryWeld';
		Weld.Part0 = Character.Root;
		Weld.Part1 = EnemyEntity.Character.Root;
		Weld.C0 = CFrame.new(0, 0, -2) * CFrame.Angles(0,math.pi,0);

        EnemyEntity.Character.Gripped = true;

        Auxiliary.Shared.SetCollisionGroups(EnemyEntity.Character.Rig, "Carry");
        for Index, Part in pairs(EnemyEntity.Character.Rig:GetChildren()) do
			if Part:IsA'BasePart' then
				if Part:GetAttribute'WasMassless' == nil then Part:SetAttribute('WasMassless', Part.Massless) end
				
				Part.Massless = true
				Part:SetNetworkOwner(Entity.Player);
			end
		end

        local GripCancel = Entity.Combat:CreateCancel(1,function()
            Entity.Comba:Active(true);
            Entity.Character.Grip.Cancel();
        end)

        Entity.Character.Grip = {
            Victim = EnemyEntity;
            Cancel = function()
                Weld:Destroy();
				GripAnim:Stop();
                GrippedAnim:Stop();
					
				if EnemyEntity.Character then
                    EnemyEntity.Character:Ragdoll(true);
                    EnemyEntity.Character.Gripped = false;
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

				if Entity.Character.Grip then
					for _,v: RBXScriptConnection in Entity.Character.Grip do
						if typeof(v) ~= 'RBXScriptConnection' then continue end;
						v:Disconnect();
					end
					table.clear(Entity.Character.Grip);
				end

            end;
            Quit = Entity.Character.Rig:GetPropertyChangedSignal("Parent"):Connect(function()
                if not Entity.Character.Rig.Parent then
                    Entity.Character.Grip.Cancel();
                end
            end);
            Enemy = EnemyEntity.Character.Rig:GetPropertyChangedSignal("Parent"):Connect(function()
                if not EnemyEntity.Character.Rig.Parent then
                    Entity.Character.Grip.Cancel();
                end
            end);
            Died = Entity.Character.Humanoid.Died:Connect(function()
                Entity.Character.Grip.Cancel();
            end);
            Died2 = EnemyEntity.Character.Humanoid.Died:Connect(function()
                Entity.Character.Grip.Cancel();
            end);
        }

        task.wait(1.7);
        if GripCancel.Cancelled then GripCancel.Remove(); return; end;
        GripCancel.Remove();
        if Entity.Character.Grip.Victim then
            Entity.Character.Grip.Cancel();
            EnemyEntity.Character.Humanoid.Health = 0;
        end
        Entity.Combat:Active(true);
        Sound.Spawn("bass.wav", Entity.Character.Root, 3);
	end

	hitbox:Fire();
    
    Entity.Cooldowns:Add("Grip", 0.3)
end