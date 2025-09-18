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
	if not Args["target"] then return end;

	local EnemyEntity = _G.FindEntity(Args["target"]);

	local Start : AnimationTrack = Entity.Animator:Fetch("Fallen/Rar");
	Start:Play();
	
	Entity.VFX:Fire("Fallen/Ruin", {Action = "start", ID = Start.Animation.AnimationId});

	Auxiliary.Shared.WaitForMarker(Start, "start");

	Entity.VFX:Fire("Fallen/Ruin", {Action = "invis", ID = Start.Animation.AnimationId});

	Auxiliary.Shared.WaitForMarker(Start, "tp");

	if not EnemyEntity or not EnemyEntity.Character.Rig:IsDescendantOf(workspace) then return end;

	local dir = (EnemyEntity.Character.Root.Position - Entity.Character.Root.Position).Unit;
	dir = Vector3.new(dir.X, 1.7, dir.Z).Unit;
	local ray: RaycastResult = workspace:Raycast(EnemyEntity.Character.Root.Position, dir * 25, Auxiliary.Shared.RayParams.Map);
	local goal = EnemyEntity.Character.Root.Position + dir * (ray and ray.Distance or 25);
	dir = Vector3.new(dir.X, 0, dir.Z).Unit;
	Entity.Character.Rig:PivotTo(CFrame.new(goal, goal - dir));
	
	local bp = Auxiliary.Shared.CreatePosition(Entity.Character.Root);
	bp.Position = goal;

	Auxiliary.Shared.WaitForMarker(Start, "slash");
	
	Entity.VFX:Fire("Fallen/Ruin", {Action = "slash", ID = Start.Animation.AnimationId});
	
	Start.Stopped:Wait();
	bp:Destroy();
end;


return Spell;