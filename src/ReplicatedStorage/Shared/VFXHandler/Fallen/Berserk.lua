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

    local tasks = {};
    local Cancelled = false;
	local runMaid = Auxiliary.Maid.new();
	local runVFXMaid = Auxiliary.Maid.new();
	
	local speed = Instance.new("NumberValue");
	runMaid:AddTask(speed);
	
	local function BindFX(maid, fx)
		local g = fx:Clone();
		maid:AddTask(g);
		return g;
	end

    local start = BindFX(runVFXMaid, Assets.BerserkStart);
    start:PivotTo(Root.CFrame);
    start.Parent = FXParent;
    Auxiliary.Shared.PlayAttachment(start);

    local bv: BodyVelocity;

	local cancel = function()
		if Cancelled then return end;
        if bv then
            TweenService:Create(bv,TweenInfo.new(0.4), {Velocity = Vector3.new(0,0,0)}):Play();
            game.Debris:AddItem(bv, 0.35);
        end
        for _,t in pairs(tasks) do
            task.cancel(t);
        end
        tasks = nil;
        Cancelled = true;
		runMaid:Destroy();
		task.delay(4,function()
			runVFXMaid:Destroy();
		end)
	end;
	
	Animation.Stopped:Connect(cancel);
	
	Auxiliary.Shared.WaitForMarker(Animation, "run")

	local st = BindFX(runVFXMaid, Assets.Stutter);
	st.CFrame = Root.CFrame;
	st.Weld.Part0 = Root;
	st.Parent = FXParent;

	task.delay(1,function()
		for _,v in pairs(st:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v.Enabled = false;
			end
		end
	end)
	
	table.insert(tasks, task.spawn(function()
		for i=1,5 do
            if Cancelled then break end
			local Au = BindFX(runVFXMaid, Assets.launchup);
			Au.CFrame = Root.CFrame * CFrame.new(0,-2.25,-0.5);
			Au.Parent = FXParent;
			Auxiliary.Shared.PlayAttachment(Au);

            Auxiliary.Crater:Impact({
                Start = Root.Position,
                End = -Root.CFrame.UpVector,
                Seed = tick(),             -- 랜덤 시드
                NoSound = false,           -- 사운드 허용
                NoCrater = false,          -- 크레이터 생성
				Amount = 4;
                NoSmoke = true,            -- 연기는 주석처리되어 사용 안됨
                NoDebris = true,          -- 바위 파편 허용
                amount = 8,                -- 지면 파편 개수
                sizemult = 1,              -- 파편 크기 배수
                size = 1,                   -- 크레이터 크기
                DespawnTime = 5
            })

			task.wait(0.2)
		end
	end))
	local Tween = TweenService:Create(speed,TweenInfo.new(0.1), {Value = 200}); Tween:Play();
	Tween.Completed:Connect(function()
		TweenService:Create(speed,TweenInfo.new(0.5), {Value = 55}):Play();
	end)
	
	bv = Auxiliary.Shared.CreateVelocity(Root, {MaxForce = Vector3.new(40000,0,40000)});
	
	runVFXMaid:AddTask(bv);

	local run run = RunService.PreRender:Connect(function(dt)
		if not bv:IsDescendantOf(workspace) or not speed then bv:Destroy(); run:Disconnect(); return end;
		bv.Velocity = Root.CFrame.LookVector * speed.Value;
	end)

    runMaid:AddTask(run);
	
	Animation:GetMarkerReachedSignal("runEnd"):Connect(function()
		local drag = BindFX(runVFXMaid, Assets.drag);
		drag.CFrame = Root.CFrame;
		drag.Weld.Part0 = Root;
		drag.Parent = FXParent;

		task.delay(0.4,function()
			for _,v in pairs(drag:GetDescendants()) do
				if v:IsA("ParticleEmitter") then
					v.Enabled = false;
				end
			end
		end)
		cancel();
	end)
end

VFX.grab = function(Data)
    local Root = Data.Origin
	local Humanoid: Humanoid? = Data.Caster.Character.Humanoid;
	
	local Animation: AnimationTrack;
	
	for _,v: AnimationTrack in pairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
		if v.Animation.AnimationId == Data.ID then
			Animation = v;
		end
	end
	
	if not Animation then return end;

    local grabMaid = Auxiliary.Maid.new();

    local fx = Auxiliary.Shared.BindFX(grabMaid, Assets.berHit);
    fx:PivotTo(Root.CFrame * CFrame.new(0,0,-5));
    fx.Parent = FXParent;
    Auxiliary.Shared.PlayAttachment(fx);

    local function cancel()
        grabMaid:Destroy();
    end

    Animation.Stopped:Connect(cancel);

    Auxiliary.Shared.WaitForMarker(Animation, "throw");

    local bv = Auxiliary.Shared.CreateVelocity(Root, {MaxForce = Vector3.new(40000,0,40000)});
    grabMaid:AddTask(bv);
    bv.Velocity = Root.CFrame.LookVector * 170;
    local Tween = TweenService:Create(bv,TweenInfo.new(0.5), {Velocity = Vector3.new(0,0,0)}); Tween:Play();
    Tween.Completed:Connect(function()
        cancel();
    end)
end

return VFX;