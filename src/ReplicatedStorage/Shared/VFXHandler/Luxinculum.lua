--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");

local Shared = ReplicatedStorage.Shared;
local Auxiliary = require(Shared.Utility.Auxiliary);
local Sound = require(Shared.Utility.SoundHandler);

--// Modules
local Assets = Shared.Assets.Resources;

local VFX = {};

-- Perlin noise 대체 함수 (Roblox의 math.noise가 없을 경우 사용)
local function smoothNoise(x, y, seed)
    seed = seed or 0;
    local n = math.sin(x * 12.9898 + y * 78.233 + seed) * 43758.5453;
    return (n - math.floor(n)) * 2 - 1;
end

VFX.start = function(Data)
    local target = Data.Target;
    local targetRig = target.Character.Rig;
    local targetRoot = target.Character.Root;

    local root = Data.Origin;
    local beam: BasePart = Assets.Luxinculum.Light:Clone();
    beam.Weld.Part0 = Data.Caster.Character.Root;
    beam.Parent = workspace.World.Debris;
    
    local elapsed = 0;
    local dur = 0.3;
    local time = 0; -- 전체 시간 추적
    
    -- 체인 물리 파라미터
    local waveFrequency = 8; -- 흔들림 빈도
    local waveAmplitude = 1.5; -- 흔들림 강도
    local turbulenceSpeed = 15; -- 난류 속도
    local dampingFactor = 0.85; -- 감쇠 계수 (끝으로 갈수록 약해짐)
    
    -- Secondary motion을 위한 변수
    local velocityX = 0;
    local velocityY = 0;
    local offsetX = 0;
    local offsetY = 0;
    
    -- 초기 임펄스 (발사 시 더 강한 움직임)
    local initialImpulse = math.random() * 2 - 1;
    local initialImpulseY = math.random() * 2 - 1;

    local tasks = {};

    tasks.Chain = task.spawn(function()
        while true do
            local dt = RunService.PreRender:Wait();
            if not beam:IsDescendantOf(workspace) then 
                tasks.Chain:Disconnect();
                return;
			end
			
			local tip = Data.Caster.Character.Rig["Right Arm"].CFrame * CFrame.new(0,-1,0);
    
            elapsed = elapsed + dt / dur;
            time = time + dt;
            
            local progress = math.clamp(elapsed, 0, 1);
            local look = (targetRoot.Position - root.Position).Unit;
            local dist = (targetRoot.Position - root.Position).Magnitude;
            
            -- 진행도에 따른 감쇠 (처음엔 강하게, 나중엔 약하게)
            local progressDamping = math.sin(progress * math.pi); -- 중간에 최대
            local endDamping = 1 - (progress ^ 3); -- 끝으로 갈수록 감소
            
            -- Primary Wave Motion (기본 웨이브)
            local primaryWave = math.sin(time * waveFrequency + progress * math.pi * 2);
            local secondaryWave = math.cos(time * waveFrequency * 1.5 + progress * math.pi);
            
            -- Turbulence (난류 효과)
            local turbulenceX = smoothNoise(time * turbulenceSpeed, progress * 10, 100);
            local turbulenceY = smoothNoise(time * turbulenceSpeed, progress * 10, 200);
            
            -- 초기 임펄스 적용 (시작할 때 강한 움직임)
            local impulseFactor = (1 - progress) ^ 2; -- 급격히 감소
            local impulseX = initialImpulse * impulseFactor * 2;
            local impulseY = initialImpulseY * impulseFactor * 2;
            
            -- Spring physics (스프링 물리)
            local springForceX = -offsetX * 0.3; -- 복원력
            local springForceY = -offsetY * 0.3;
            
            velocityX = velocityX * 0.92 + springForceX + turbulenceX * 0.1; -- 감쇠 적용
            velocityY = velocityY * 0.92 + springForceY + turbulenceY * 0.1;
            
            offsetX = offsetX + velocityX * dt * 5;
            offsetY = offsetY + velocityY * dt * 5;
            
            -- 최종 Curve 계산
            local baseCurveX = dist * waveAmplitude * progressDamping;
            local baseCurveY = dist * waveAmplitude * progressDamping * 0.7; -- Y축은 좀 덜 움직임
            
            -- 복합 움직임 조합
            local finalCurveX = baseCurveX * (
                primaryWave * 0.4 + 
                turbulenceX * 0.3 * endDamping +
                impulseX +
                offsetX * 0.2
            );
            
            local finalCurveY = baseCurveY * (
                secondaryWave * 0.4 + 
                turbulenceY * 0.3 * endDamping +
                impulseY +
                offsetY * 0.2
            );
            
            -- Whip effect (채찍 효과 - 끝부분이 더 크게 움직임)
            local whipFactor = math.sin(progress * math.pi * 0.5) ^ 2; -- 0에서 1로 증가
            local whipMotion = math.sin(time * 20 - progress * 10) * whipFactor * 0.5;
            
            -- 목표 위치 계산
            local endCF = root.Position:Lerp(targetRoot.Position, progress);
            endCF = CFrame.new(endCF, endCF + look);
            
            -- Beam curve 업데이트
            for _, Beam: Beam in pairs(beam:GetChildren()) do
                if Beam:IsA("Beam") then
                    -- 각 빔마다 약간 다른 움직임
                    local variation = Beam.Name:match("1") and 1 or 0.8;
                    
                    Beam.CurveSize0 = finalCurveX * variation + whipMotion * dist * 0.3;
                    Beam.CurveSize1 = finalCurveY * variation * dampingFactor - whipMotion * dist * 0.2;
                    
                    -- 추가 디테일: 빔 자체도 약간 회전
                    if progress < 0.8 then
                        local twist = math.sin(time * 15) * 0.1 * (1 - progress);
                        Beam.CurveSize0 = Beam.CurveSize0 + twist * dist;
                    end
                end
            end
    
            beam.End.WorldCFrame = endCF;
			beam.Start.WorldCFrame = CFrame.new(tip.Position, tip.Position + look);
        end
    end)

    -- 종료 처리
    task.delay(dur, function()
        -- 부드러운 수축 애니메이션
        for _, Beam: Beam in pairs(beam:GetChildren()) do
            if Beam:IsA("Beam") then
                -- 마지막에 살짝 튕기는 효과
                TweenService:Create(Beam, TweenInfo.new(dur * 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Width0 = Beam.Width0 * 1.2; 
                    Width1 = Beam.Width1 * 1.2;
                }):Play();
                
                task.wait(0.05);
                
                TweenService:Create(Beam, TweenInfo.new(dur * 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                    Width0 = 0; 
                    Width1 = 0;
                    CurveSize0 = 0;
                    CurveSize1 = 0;
                }):Play();
            end
        end
        
        task.delay(dur, function()
            task.cancel(tasks.Chain);
            tasks.Chain = nil;
            if beam and beam.Parent then
                beam:Destroy();
            end
        end);
    end)
end

return VFX;