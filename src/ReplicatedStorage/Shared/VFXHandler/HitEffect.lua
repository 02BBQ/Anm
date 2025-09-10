local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")    

local SoundHandler = require(ReplicatedStorage.Shared.Utility.SoundHandler);
local FX = require(ReplicatedStorage.Shared.Utility.FX);

local Hits = ReplicatedStorage.Shared.Assets.Hits;
local random = Random.new();

-- VFX 템플릿 캐싱 테이블
local VFX_Cache = {}

-- 초기 캐싱 함수
local function CacheVFXEmitters(vfxFolder)
	for _, vfx in pairs(vfxFolder:GetChildren()) do
		if vfx:IsA("BasePart") or vfx:IsA("Folder") then
			-- GetDescendants 한 번 호출
			local emitters = {}
			for _, descendant in ipairs(vfx:GetDescendants()) do
				if descendant:IsA("ParticleEmitter") or descendant:IsA("PointLight") then
					-- 경로 기억을 위해 함수 작성 (상대경로 구하기)
					local relativePath = {}
					local current = descendant
					-- 부모를 따라 올라가며 vfx까지의 경로 추적
					while current and current ~= vfx do
						table.insert(relativePath, 1, current.Name)
						current = current.Parent
					end
					-- 경로를 키로,Emitter 이름을 값으로 emitters 테이블에 저장
					emitters[#emitters+1] = relativePath
				end
			end

			-- vfx 템플릿을 key로, emitter 경로 리스트를 값으로 저장
			if #emitters > 0 then
				VFX_Cache[vfx] = emitters
			end
		end
	end
end

-- 초기화할 때 한 번만 호출
CacheVFXEmitters(Hits)


-- 이후 실제 사용할 때
local function EmitDescendantsFromCache(VFX_Clone, DontDestroy)
	-- 원본 템플릿 찾기
	local originalTemplate = Hits:FindFirstChild(VFX_Clone.Name)
	if not originalTemplate then return end


	-- local emitterPaths = VFX_Cache[originalTemplate]
	-- if not emitterPaths then return end

	for _, pathArray in pairs(VFX_Clone:GetDescendants()) do
		-- pathArray를 통해 클론된 VFX에서 동일 경로에 해당하는 Emitter찾기
		local target = pathArray
		-- for _, namePart in ipairs(pathArray) do
		--     target = target:FindFirstChild(namePart)
		--     if not target then break end
		-- end

		if target and target:IsA("PointLight") then
			-- 여기서 PointLight 처리 로직
			game.TweenService:Create(target,TweenInfo.new(0.2,Enum.EasingStyle.Linear),{Brightness = 0}):Play()
		end

		if target and target:IsA("ParticleEmitter") then
			-- 여기서 Emit 처리 로직
			task.spawn(function()
				local EmitCount = target:GetAttribute("EmitCount") or 1
				local EmitDelay = target:GetAttribute("EmitDelay") or nil
				local EmitDuration = target:GetAttribute("EmitDuration") or nil

				if EmitDelay then
					task.wait(EmitDelay)
				end

				target:Emit(EmitCount)

				if EmitDuration then
					target.Enabled = true
					task.wait(EmitDuration)
					target.Enabled = false
				end

				if not DontDestroy then
					task.delay(target.Lifetime.Max / target.TimeScale,function()
						pcall(function() target:Destroy() end)
					end)
				end
			end)
		end
	end
end

return function(Data)
	local root = Data.Origin
	local Victim = Data.Caster.Character.Rig
	local Type = Data.Type

    local torso = Victim:FindFirstChild("Torso");

    local VictimRoot = torso or root;
    if not VictimRoot then return end;

	local VFX : BasePart?  VFX = Type and Hits:FindFirstChild(Type)
	if VFX then
		VFX = VFX:Clone()

		if VFX:IsA("BasePart") then
			VFX.CFrame = CFrame.new(VictimRoot.Position, Data.Attacker.Character.Root);
			VFX.Parent = workspace.Debris;
			EmitDescendantsFromCache(VFX);
			game.Debris:AddItem(VFX, 5);
		end
	end

	
	if Data.Sound then
		SoundHandler.Spawn(Data.Sound, VictimRoot.Position, 3, {Pitch = random:NextNumber(0.9, 1.1)});
	end
end
