--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");

local Shared = ReplicatedStorage.Shared;
local FXParent = workspace.World.Debris;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local Assets = Shared.Assets.Resources.Fallen;

local VFX = {};

VFX.start = function(Data)
    local Root = Data.Origin
	local Humanoid: Humanoid? = Data.Caster.Character.Humanoid;
	
	local Animation: AnimationTrack;
	
	for _,v: AnimationTrack in pairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
		if v.Animation.AnimationId == Data.ID then
			Animation = v;
		end
	end
	
	if not Animation then return end;

	local jumpMaid = Auxiliary.Maid.new();

	Sound.Spawn("Fallen/Sukuna Laugh", Root, .9);
	
	local bp: BodyPosition = Auxiliary.Shared.CreatePosition(Root, {MaxForce = Vector3.one * 1e6});
	jumpMaid:AddTask(bp);
	bp.Position = Root.Position + (Root.CFrame.LookVector * -11 + Vector3.new(0,14,0))*2;
	bp.P = 5000;
	bp.D = 600;

	local fx = Auxiliary.Shared.BindFX(jumpMaid, Assets.Jump);
	fx:PivotTo(Root.CFrame * CFrame.new(0,-2.2,0));
	fx:ScaleTo(2);
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);

	local smoke = Auxiliary.Shared.BindFX(jumpMaid, Assets.Smoke);
	smoke:PivotTo(Root.CFrame * CFrame.new(0,-2.2,0));
	smoke:ScaleTo(2);
	smoke.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(smoke);

	task.delay(5,function()
		jumpMaid:Destroy();
	end)

	Auxiliary.Shared.WaitForMarker(Animation, "kick")
	local origin = Root.CFrame;
	bp:Destroy();

	Sound.Spawn("Fallen/sukuna_slash_single", Root, 3)
	
	local meshVFX = Auxiliary.Maid.new();
	
	local part = Auxiliary.Shared.BindFX(meshVFX, Assets.nothing);
	part.CFrame = Root.CFrame * CFrame.new(0,0,-3) * CFrame.Angles(0,0,-math.pi/3);
	part.Parent = workspace.World.Debris;
	
	local meshes2: Model = Auxiliary.Shared.BindFX(meshVFX, Auxiliary.MeshEmitter.StartMeshEmitter(
		part,
		Assets.Disdzxmantle
		));
	
	Auxiliary.Shared.BindFX(meshVFX,part);
	
	local fx = Auxiliary.Shared.BindFX(meshVFX, Assets.SpaceDistortion);
	fx:PivotTo(part.CFrame * CFrame.new(0,0,-3));
	fx.Parent = FXParent;
	Auxiliary.Shared.PlayAttachment(fx);
	
	task.delay(5,function()
		meshVFX:Destroy();
	end)

	task.wait(0.5);

	local ray: RaycastResult = workspace:Raycast(origin.Position, origin.LookVector * 1000, Auxiliary.Shared.RayParams.Map);

	if not ray then return end;

	local slamVFX = Auxiliary.Maid.new();

	local Dark = Assets.Dark2:Clone();
	Dark.Parent = game.Lighting;

	local part = Auxiliary.Shared.BindFX(slamVFX, Assets.slammin);
	part:PivotTo(CFrame.new(ray.Position, ray.Normal + ray.Position) * CFrame.Angles(0,0,-math.pi/3));
	part.Parent = FXParent;
	local meshes2: Model = Auxiliary.Shared.BindFX(slamVFX, Auxiliary.MeshEmitter.StartMeshEmitter(
		part,
		Assets.DisMesh,
		CFrame.Angles(-math.pi/2,0,0) * CFrame.new(0,0,1),
		0.11
	));

	local meshes2: Model = Auxiliary.Shared.BindFX(meshVFX, Auxiliary.MeshEmitter.StartMeshEmitter(
		part,
		Assets.Disdzxmantle,
		CFrame.Angles(-math.pi/2,0,0) * CFrame.new(0,0,1)
	));
	
	task.wait(0.11);
	Dark:Destroy();
	
	Auxiliary.Shared.PlayAttachment(part);
	Sound.Spawn("Fallen/sukuna_WCS_hit_sfx", Root, 6)

	task.delay(5,function()
		slamVFX:Destroy();
	end)


	Auxiliary.Crater:Impact({
		Start = origin.Position,
		End = origin.LookVector,
		Seed = tick(),             -- 랜덤 시드
		NoSound = false,           -- 사운드 허용
		NoCrater = false,          -- 크레이터 생성
		Amount = 7;
		NoSmoke = true,            -- 연기는 주석처리되어 사용 안됨
		NoDebris = true,          -- 바위 파편 허용
		amount = 7,                -- 지면 파편 개수
		sizemult = 2.5,              -- 파편 크기 배수
		size = 5,                   -- 크레이터 크기
		DespawnTime = 5
	})
end

return VFX;