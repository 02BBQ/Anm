local delay = task.delay;

--[[
	#Writer: TheBlackwave;
	@class 'debris';
]]

--[[
	//// Misc \\\\
	"Reworked" module from that guy who open sourced it. I just managed to organize it.
	
	//// Debris Module Application \\\\
	Ex. of Use.:
	
	local Crater = require(CraterModule)
	
	//// Ground Rocks \\\\
	local Position = RootPart.Position
	
	Crater:Spawn({
		Position = Position, --> Position
		
		AmountPerUnit = 2, --> Amount of Rocks Per Unit (1 would appear a single rock per angle step.)
		
		Amount = 14, --> Amount of rocks that will exist in the circle. (360 / Amount)
		
		Angle = {10, 30}, --> Random Angles (Y) axis.
		Radius = {4, 6}, --> Random Radius;
		Size = {2.5, 3}, --> Random Size (number only);
		
		Offset = {
			X = 0,
			Y = 0.5,
			Z = 0,
		}, --> Random offset (Y);

		DespawnTime = 5, --> Despawn Time
	})
	
	//// Rocks Trail \\\\
	local TrailData = {
		Size = {
			Vector3.one * 0.8,
			Vector3.one * 1.2,
		}, --> Sizes [Random]
		Offset = {
			X = 0,
			Y = 0.1,
			Z = 0,
		}, --> Offsets (Y)

		AmountPerUnit = 2, --> Per Unit
		Distance = 40, --> Max Distance
		
		Increment = 0.05, --> Size increment;
		ReachTime = {3, 10^-4}, --> Each [3] rock groups waits [0.0001].
		
		Spread = Vector3.new(1, 2, 1), --> Spread Vector (You can play with the values, but isn't that usefull.)
		
		Spacing = 3, --> Spacing number;
		DespawnTime = 5, --> Despawn Time.
	}
	
	This part, you can make a summary, but, y'know, when we can't think on a better idea, let's just stay like this.
	
	local RightVector = RootCFrame.RightVector.Unit
	local LookVector = RootCFrame.LookVector.Unit
	local UpVector = RootCFrame.UpVector.Unit
	
	Crater:Trail(
		RootCFrame.Position + (LookVector * 5) + (RightVector * 2), --> That's the space between you and the rocks.
		LookVector + (RightVector * 0.25), --> 0 to 1 just manages to change the (X) known as side axis, so, get your perfect value.
		
		TrailData,
		Folder --> In case you want to have a specific folder existing.
	)
	
	Crater:Trail(
		RootCFrame.Position + (LookVector * 5) - (RightVector * 2),
		LookVector - (RightVector * 0.25),
	
		TrailData,
		Folder --> In case you want to have a specific folder existing.
	)
	
	
	//// Explosion Rocks \\\\
	local RootCFrame = RootPart.CFrame
	
	Crater:ExplosionRocks({
		Position = RootCFrame.Position, --> Position;
		
		Amount = 15, --> Amount of Rocks;
		
		Radius = {
			X = 2,
			Y = -2,
			Z = 2,
		}, --> Radius (Y);
		
		Size = {Vector3.one, Vector3.one * 1.45}, --> Random Sizes between '1' and '2';
		
		Force = {
			X = {-10, 10},
			Y = {10, 30},
			Z = {40, 80},
		}, --> Forces (X, Y, Z) [Random]
		
		Trail = false, --> Enable / Disable
		
		Direction = RootCFrame, --> Direction (Gets 'LookVector', 'UpVector' and 'RightVector' automatically)
		
		DespawnTime = 4, --> Despawn Time.
	})
	
	
]]

--/ @services \--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')

--/ @defined \--
local Map = workspace.World.Map
local Effects = workspace.World.Debris

--/ @modules 'services' \--
local SpawnService = {}
local MaidService = {}

function MaidService:Task(func: (...any)->(), ...): ()
	task.defer(function(...)
		func(...)
	end, ...)
end

function SpawnService:Wait(waitTime: number, func: (...any)->(), ...): ()
	MaidService:Task(function(waitTime, ...)
		task.wait(waitTime)
		if func then
			func(...)
		end
	end, waitTime, ...)
end

function SpawnService:AddItem(object: Instance, lifeTime: number): ()
	SpawnService:Wait(lifeTime, function()
		if object and object.Parent then
			object:Destroy()
		end
	end)
end

--/ @modules 'shared' \--
local Auxiliary = {}
Auxiliary.RaycastParams = {}
Auxiliary.OverlapParams = {}

Auxiliary.RaycastParams.Map = RaycastParams.new()
Auxiliary.RaycastParams.Map.FilterType = Enum.RaycastFilterType.Include
Auxiliary.RaycastParams.Map.FilterDescendantsInstances = {Map}

Auxiliary.OverlapParams.Map = OverlapParams.new()
Auxiliary.OverlapParams.Map.FilterType = Enum.RaycastFilterType.Include
Auxiliary.OverlapParams.Map.FilterDescendantsInstances = {Map}

function Auxiliary:Raycast(Origin: Vector3, Direction: Vector3): RaycastResult
	return workspace:Raycast(Origin, Direction, Auxiliary.RaycastParams.Map)
end

--/ @constants \--
local Seed = Random.new()
local lastCleanupTime = 0;
local debrisPool = {}
local localPlayer = game.Players.LocalPlayer

--/ @functions \--
function Create_Tween(object: Instance, tweenInfo: TweenInfo, goal: {[string]: any}): Tween
	local TweenInstance = TweenService:Create(object, tweenInfo, goal)
	TweenInstance:Play()
	TweenInstance:Destroy()
	return TweenInstance
end

-- Aligns a vector to a surface normal using quaternion rotation
local function alignToNormal(fromVector, toVector, upVector)
    local dotProduct = fromVector:Dot(toVector)
    local crossProduct = fromVector:Cross(toVector)
    
    -- Handle opposite vectors (180 degree rotation)
    if dotProduct < -0.99999 then
        return CFrame.fromAxisAngle(upVector, math.pi)
    else
        -- Create rotation CFrame using cross product and dot product
        -- This creates a quaternion-based rotation
        return CFrame.new(0, 0, 0, crossProduct.x, crossProduct.y, crossProduct.z, 1 + dotProduct)
    end
end

-- Gets all parts that are touching/intersecting with the given part
local function getPartsInRegion(part)
    if not part then
        return
    elseif part.ClassName == "Model" then
        return -- Models don't have GetTouchingParts method
    else
        -- Create a temporary connection to enable collision detection
        local connection = part.Touched:Connect(function()
            -- Empty function - we just need the connection to exist
        end)
        
        -- Get all parts currently touching this part
        local touchingParts = workspace:GetPartsInPart(part, Auxiliary.OverlapParams.Map) --part:GetTouchingParts()
        
        -- Disconnect the temporary connection
        connection:Disconnect()
        
        -- Filter out unwanted parts
        local filteredParts = {}
        for _, touchingPart in pairs(touchingParts) do
            if touchingPart.Name ~= "InvisibleBorder" and touchingPart.Name ~= "InfBall" then
                table.insert(filteredParts, touchingPart)
            end
        end
        
        return filteredParts
    end
end

function getPooledPart()
    -- upvalues: lastCleanupTime (v302), debrisPool (v115)
    
    -- Periodic cleanup: every 300 seconds (5 minutes)
    if tick() - lastCleanupTime > 300 then
        lastCleanupTime = tick()
        local deletedCount = 0
        
        -- Clean up old parts in workspace.Thrown
        for _, part in pairs(workspace.Thrown:GetChildren()) do
            if part:IsA("Part") and 
               part:GetAttribute("Spawn") and 
               not table.find(debrisPool, part) and 
               not part:GetAttribute("DeletionImmunity") and 
               tick() - part:GetAttribute("Spawn") > 60 then
                part:Destroy()
                deletedCount = deletedCount + 1
            end
        end
        return -- Exit early during cleanup cycle
    else
        -- Get first part from the pool
        local pooledPart = rawget(debrisPool, 1)
        
        -- Limit pool size to prevent memory bloat
        if #debrisPool > 100 then
            -- Remove excess parts (keep only first 100)
            for i = 101, #debrisPool do
                local excessPart = rawget(debrisPool, 101)
                table.remove(debrisPool, 101)
                if excessPart then
                    excessPart:Destroy()
                end
            end
        end
        
        -- Remove part from pool if it has no parent (was destroyed)
        if pooledPart and not pooledPart.Parent then
            table.remove(debrisPool, 1)
        end
        
        -- Return recycled part if available and valid
        if pooledPart and pooledPart.Parent then
            table.remove(debrisPool, 1)
            
            -- Reset part name if it was a starter debris
            if pooledPart.Name == "starterdeb" then
                pooledPart.Name = "aa"
            end
            
            -- Reset collision group to default
            pooledPart.CollisionGroup = "Default"
            
            -- Mark spawn time for cleanup tracking
            pooledPart:SetAttribute("Spawn", tick())
            
            return pooledPart
        else
            -- No valid part available in pool
            return nil
        end
    end
end

--/ @types \--
export type GroundData = {
	Amount: number?,
	AmountPerUnit: number?,
	
	Radius: {number}?,
	Angle: {number}?,
	Offset: {
		X: number?,
		Y: number?,
		Z: number?
	}?,
	Size: {number}?,

	Position: Vector3,

	DespawnTime: number?
}

export type RockData = {
	Amount: number?,
	Radius: { number}?,
	Force: {X: {number}, Y: {number}, Z: {number}}?,

	Trail: boolean?,

	Direction: Vector3?,
	Position: Vector3,

	Size: {Vector3}?,

	DespawnTime: number?
}

export type TrailData = {	
	Size: {Vector3}?,
	Offset: {X: number, Y: number, Z: number}?,

	ReachTime: {number}?,

	AmountPerUnit: number?,
	Distance: number?,

	Increment: number?,

	Spread: Vector3?,

	Spacing: number?,
	DespawnTime: number?,
}

export type ImpactData = {
	Start: Vector3 | Instance,  -- 시작 위치 또는 Attachment/Part
	End: Vector3,               -- 방향 벡터
	
	-- 연기 설정
	NoSmoke: boolean?,          -- 연기 효과 비활성화
	NoCircleSmoke: boolean?,    -- 원형 연기 비활성화
	NoUpSmoke: boolean?,        -- 상승 연기 비활성화
	Smoked: boolean?,           -- 특수 연기 모드
	
	-- 크레이터 설정
	NoCrater: boolean?,         -- 크레이터 비활성화
	Amount: number?,            -- 파편 개수
	Size: number?,              -- 크레이터 크기 배수
	SizeMult: number?,          -- 파편 크기 배수
	Angle: number?,             -- 파편 각도
	AngleCFrame: CFrame?,       -- 파편 각도 CFrame
	
	-- 효과 설정
	Stronger: {                 -- 강화된 효과
		size1: number?,
		size2: number?,
		minus: number?
	}?,
	CloserCircle: boolean?,     -- 가까운 원형 효과
	Closerr: boolean?,          -- 더 가까운 효과
	
	-- 기타 설정
	Sound: Sound?,              -- 재생할 사운드
	Seed: number?,              -- 랜덤 시드
	NoSound: boolean?,          -- 사운드 비활성화
	DontCollide: boolean?,      -- 충돌 비활성화
	NoDebris: boolean?,         -- 파편 비활성화
	NoTiles: boolean?,          -- 타일 비활성화
	DisperseFast: boolean?,     -- 빠른 분산
}

--/ @utility functions \--
local function GetPositionFromInstance(instance: Instance | Vector3): Vector3
	if typeof(instance) == "Instance" then
		if instance:IsA("Attachment") then
			return instance.WorldPosition
		else
			return instance.Position
		end
	end
	return instance
end

local function ResizeParticle(particle: ParticleEmitter, scale: number)
	local size = particle.Size
	local keypoints = {}
	for i, keypoint in ipairs(size.Keypoints) do
		table.insert(keypoints, NumberSequenceKeypoint.new(
			keypoint.Time,
			keypoint.Value * scale,
			keypoint.Envelope * scale
		))
	end
	particle.Size = NumberSequence.new(keypoints)
end

local function GetCFrameUpVector(cf: CFrame, normal: Vector3, up: Vector3): CFrame
	local right = normal:Cross(up)
	if right.Magnitude < 0.001 then
		right = normal:Cross(Vector3.new(1, 0, 0))
	end
	right = right.Unit
	local newUp = right:Cross(normal)
	return CFrame.fromMatrix(cf.Position, right, newUp, -normal)
end

--/ @class 'debris' \--
local Crater = {}

--/ @functions \--
function RandomVector3(VectorA : Vector3, VectorB : Vector3): Vector3
	return Vector3.new(Seed:NextNumber(VectorA.X, VectorB.X), Seed:NextNumber(VectorA.Y, VectorB.Y), Seed:NextNumber(VectorA.Z, VectorB.Z))
end

--/ @debris 'rocks' \--
function Crater:ExplosionRocks(Data: RockData)
	--/ @variables \--
	local Amount = Data.Amount or 10
	local Radius = Data.Radius or {X = 0, Y = 0, Z = 0}
	local Force = Data.Force or {X = {0, 0}, Y = {0, 0}, Z = {0, 0}}
	local Size = Data.Size or {Vector3.one, Vector3.one}
	
	local Trail = Data.Trail or false
	local DespawnTime = Data.DespawnTime or 3

	local Position = Data.Position or nil
	local Direction = Data.Direction or nil

	--/ @return \--
	if not Position then
		return
	end

	--/ @folder \--
	local Folder = Instance.new('Folder')
	Folder.Name = 'RockFolder'
	Folder.Parent = Effects

	--/ @loop \--
	MaidService:Task(function()
		for i = 1, Amount do
			if not Folder.Parent then
				break
			end
			
			local function FixNumber(Axis): number
				return if Axis < 0 then math.abs(Axis) else Axis
			end

			local Radius = {
				X = math.random(-FixNumber(Radius.X), FixNumber(Radius.X)),
				Y = math.random(-FixNumber(Radius.Y), FixNumber(Radius.Y)),
				Z = math.random(-FixNumber(Radius.Z), FixNumber(Radius.Z)),
			}

			local Size = RandomVector3(Size[1], Size[2])
			
			local Part = Instance.new('Part')
			Part.Massless = true
			Part.CanTouch = true
			Part.CanCollide = true

			Part.Size = Size

			Part.Anchored = false
			Part.CastShadow = false
			Part.CanQuery = false

			Part.CollisionGroup = 'Debris'

			Part.CFrame = CFrame.new(Position) * CFrame.new(Radius.X, Radius.Y, Radius.Z)
			Part.Parent = Folder
			
			if Trail then
				local Attachment0 = Instance.new('Attachment')
				Attachment0.Name = 'Attachment0'
				Attachment0.CFrame = CFrame.new(0, Part.Size.Y / 5, 0)
				Attachment0.Parent = Part

				local Attachment1 = Instance.new('Attachment')
				Attachment1.Name = 'Attachment1'
				Attachment1.CFrame = CFrame.new(0, -Part.Size.Y / 5, 0)
				Attachment1.Parent = Part

				local Trail = script.Trail:Clone()
				Trail.Attachment0 = Attachment0
				Trail.Attachment1 = Attachment1
				Trail.Parent = Part
			end

			local Raycast = Auxiliary:Raycast(Part.Position, -Vector3.yAxis * 30)

			if Raycast then
				local Velocity = Vector3.new(math.random(Force.X[1], Force.X[2]), math.random(Force.Y[1], Force.Y[2]), math.random(Force.Z[1], Force.Z[2]))

				local Object = Raycast.Instance

				Part.Position = Raycast.Position + (Vector3.yAxis * math.random(1, 3))

				Part.Material = Object.Material or Enum.Material.Plastic
				Part.Color = Object.Color
				Part.CanCollide = false
				Part.Transparency = Object.Transparency

				Part.CFrame = CFrame.new(Part.Position) * CFrame.Angles(math.random(0, 360), math.random(0, 360), math.random(0, 360))

				local BodyVelocity = Instance.new('BodyVelocity')
				BodyVelocity.MaxForce = Vector3.one * 125000
				BodyVelocity.P = 820
				-- local t = Vector3.new(math.random(-20,20),math.random(30,40),math.random(-20,20))
				BodyVelocity.Velocity = Velocity

				BodyVelocity.Parent = Part
				SpawnService:AddItem(BodyVelocity, 0.15)

				--/ @wait \--
				SpawnService:Wait(DespawnTime, function()
					if i % 2 == 0 then
						task.wait(0.1 + (math.random(-1, 1) / 20))
					end

					Create_Tween(Part, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
						Transparency = 1
					})

					SpawnService:AddItem(Part, 0.5)

				end)
			else
				Part:Destroy()
			end
		end
	end)

	SpawnService:AddItem(Folder, DespawnTime + 2)
end

--/ @debris 'impact' - 새로 추가된 충격 효과 \--
function Crater:Impact(data: ImpactData)
	-- 시작 위치 처리
	local startPos = GetPositionFromInstance(data.Start)
	local endDir = data.End
	
	-- 랜덤 생성기 설정
	local random = data.Seed and Random.new(data.Seed) or Seed
	
	-- 레이캐스트 실행
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {Map}
	
	local rayResult = workspace:Raycast(startPos, endDir * 1000, raycastParams)
	
	if not rayResult then
		return nil
	end
	
	local hitPart = rayResult.Instance
	local hitPos = rayResult.Position
	local hitNormal = rayResult.Normal
	
	-- 사운드 재생
	if data.Sound and not data.NoSound then
		data.Sound.CFrame = CFrame.new(hitPos)
		data.Sound:Play()
	end
	
	-- Attachment 생성
	local attachment = Instance.new("Attachment")
	if hitPart.Anchored and not data.Smoked then
		attachment.Parent = hitPart
	else
		attachment.Parent = workspace.Terrain
	end
	
	local upVector = CFrame.new(hitPos).UpVector
	local rotationCF = GetCFrameUpVector(CFrame.new(hitPos), hitNormal, Vector3.new(0, 1, 0))
	attachment.WorldCFrame = CFrame.new(hitPos) * rotationCF
	
	-- 연기 효과 생성
	if not data.NoSmoke then
		local player = game.Players.LocalPlayer
		local fastMode = player and player:GetAttribute("S_FastMode") or false
		
		-- 원형 연기
		-- if not data.NoCircleSmoke and hitPart ~= workspace.Terrain then
		-- 	local circleSmoke = ReplicatedStorage.Resources.Smoke:Clone()
		-- 	circleSmoke.Parent = attachment
			
		-- 	local zOffset = random:NextNumber(-0.001, 0.001)
		-- 	circleSmoke.ZOffset = circleSmoke.ZOffset + zOffset
			
		-- 	-- 색상 설정
		-- 	local smokeColor = hitPart == workspace.Terrain 
		-- 		and Color3.fromRGB(227, 206, 157) 
		-- 		or hitPart.Color
		-- 	circleSmoke.Color = ColorSequence.new(smokeColor)
			
		-- 	-- 크기 및 속도 조정
		-- 	if data.Stronger then
		-- 		ResizeParticle(circleSmoke, data.Stronger.size1 or 4.2)
		-- 		local speedMult = 4.5 - (data.Stronger.minus or 0)
		-- 		circleSmoke.Speed = NumberRange.new(
		-- 			circleSmoke.Speed.Min * speedMult,
		-- 			circleSmoke.Speed.Max * speedMult
		-- 		)
		-- 		circleSmoke.Lifetime = NumberRange.new(
		-- 			circleSmoke.Lifetime.Min * 2,
		-- 			circleSmoke.Lifetime.Max * 2
		-- 		)
		-- 		circleSmoke.RotSpeed = NumberRange.new(
		-- 			circleSmoke.RotSpeed.Min * 0.35,
		-- 			circleSmoke.RotSpeed.Max * 0.35
		-- 		)
		-- 	else
		-- 		ResizeParticle(circleSmoke, 1.25)
				
		-- 		if data.CloserCircle then
		-- 			circleSmoke.Speed = NumberRange.new(25, 50)
		-- 			ResizeParticle(circleSmoke, 0.7)
		-- 		elseif data.Closerr then
		-- 			ResizeParticle(circleSmoke, 0.55)
		-- 			circleSmoke.Speed = NumberRange.new(7, 25)
		-- 		end
		-- 	end
			
		-- 	local emitCount = fastMode and 4 or 8
		-- 	if data.CloserCircle then
		-- 		emitCount = emitCount / 1.5
		-- 	end
		-- 	circleSmoke:Emit(emitCount)
		-- end
		
		-- -- 상승 연기
		-- if not data.NoUpSmoke and hitPart ~= workspace.Terrain then
		-- 	local upSmoke = ReplicatedStorage.Resources.UpSmoke:Clone()
		-- 	upSmoke.Parent = attachment
			
		-- 	local zOffset = random:NextNumber(-0.001, 0.001)
		-- 	upSmoke.ZOffset = upSmoke.ZOffset + zOffset
			
		-- 	-- 색상 설정
		-- 	local smokeColor = hitPart == workspace.Terrain 
		-- 		and Color3.fromRGB(227, 206, 157) 
		-- 		or hitPart.Color
		-- 	upSmoke.Color = ColorSequence.new(smokeColor)
			
		-- 	-- 크기 및 속도 조정
		-- 	if data.Stronger then
		-- 		ResizeParticle(upSmoke, data.Stronger.size2 or 4.2)
		-- 		local speedMult = 4.5 - (data.Stronger.minus or 0)
		-- 		upSmoke.Speed = NumberRange.new(
		-- 			upSmoke.Speed.Min * speedMult,
		-- 			upSmoke.Speed.Max * speedMult
		-- 		)
		-- 		upSmoke.Lifetime = NumberRange.new(
		-- 			upSmoke.Lifetime.Min * 2,
		-- 			upSmoke.Lifetime.Max * 2
		-- 		)
		-- 		upSmoke.RotSpeed = NumberRange.new(
		-- 			upSmoke.RotSpeed.Min * 0.35,
		-- 			upSmoke.RotSpeed.Max * 0.35
		-- 		)
		-- 	else
		-- 		ResizeParticle(upSmoke, 1.25)
				
		-- 		if data.Closerr then
		-- 			ResizeParticle(upSmoke, 0.3)
		-- 			upSmoke.Speed = NumberRange.new(20, 35)
		-- 		end
		-- 	end
			
		-- 	local emitCount = fastMode and 4 or 8
		-- 	if data.Closerr then
		-- 		emitCount = emitCount / 1.5
		-- 	end
		-- 	upSmoke:Emit(emitCount)
		-- end
	end
	
	-- Attachment 제거 예약
	game.Debris:AddItem(attachment, 9)
	
	-- 크레이터 생성
	if not data.NoCrater then
		local isSandOrSnow = hitPart.Material == Enum.Material.Sand 
			or hitPart.Material == Enum.Material.Snow
		-- 지면 파편 효과
		Crater:createDebrisEffect({
			ground = hitPart,                    
			cframe = CFrame.new(hitPos),         
			amount = (data.amount or isSandOrSnow and 7 or 10) / 1.25,
			normal = hitNormal,                  
			sand = isSandOrSnow and true or nil, 
			add = {
				sounds = true
			}, 
			sizemult = data.sizemult,           
			new = {
				5 * (data.size or 1), 
				5.5 * (data.size or 1)
			}, 
			nosound = data.nosound, 
			angle = data.angle, 
			dontcollide = data.dontcollide, 
			anglecfr = data.anglecfr, 
			nodebris = data.nodebris, 
			notiles = data.notiles, 
			Seed = data.Seed, 
			dispersefast = data.dispersefast
		});
		
		-- 폭발 바위 효과 (선택적)
		if not data.NoDebris then
			Crater:ExplosionRocks({
				Position = hitPos,
				Amount = math.floor((data.Amount or 10) * 0.5),
				Size = {
					Vector3.one * (data.SizeMult or 1),
					Vector3.one * 1.5 * (data.SizeMult or 1)
				},
				Force = {
					X = {-20, 20},
					Y = {20, 40},
					Z = {-20, 20}
				},
				Trail = false,
				DespawnTime = 4
			})
		end
	end
	
	return {
		HitPart = hitPart,
		HitPosition = hitPos,
		HitNormal = hitNormal,
		Attachment = attachment
	}
end

--/ @debris 'trail' \--
function Crater:Trail(Position: Vector3, Direction: Vector3, Data: TrailData, ExistingFolder: Folder?)
	--/ @variables \--
	local AmountPerUnit = Data.AmountPerUnit or 10
	local Distance = Data.Distance or 10

	local Size = Data.Size or {Vector3.one, Vector3.one}
	local Offset = Data.Offset or {X = 0, Y = 0, Z = 0}

	local Spread = Data.Spread or Vector3.one
	local Spacing = Data.Spacing or 1
	local DespawnTime = Data.DespawnTime or 4

	local ReachTime = Data.ReachTime or nil

	local Increment = Data.Increment or 0.1

	MaidService:Task(function()
		local Extra = 0

		if ReachTime and type(ReachTime) == 'table' and ReachTime[2] then
			Extra = ReachTime[2] or 0
		end

		local MaxRocks = Distance - (Spacing * AmountPerUnit)

		local Folder = ExistingFolder or (function()
			local Folder = Instance.new('Folder')
			Folder.Name = 'RockTrail'
			Folder.Parent = Effects
			SpawnService:AddItem(Folder, DespawnTime + (Extra * AmountPerUnit) + 2)
			return Folder
		end)()

		local Rocks = {}
		
		local Counting = 1

		for x = 1, Distance, Spacing do
			Counting += 1
			
			if not Folder.Parent then
				break
			end
			
			local Line = Position + (Direction * x)

			for Index = 1, AmountPerUnit do				
				local Factor = Vector3.one * (Increment * x)
				local NewPosition = Line + Vector3.new(Seed:NextNumber(-Spread.X, Spread.X),  Seed:NextNumber(-Spread.Y, Spread.Y), Seed:NextNumber(-Spread.Z, Spread.Z))

				local Part = Instance.new('Part')

				Part.Size = RandomVector3(Size[1] + Factor, Size[2] + Factor)

				Part.Orientation = Vector3.one * math.random(0, 360)

				Part.Anchored = true
				Part.CanCollide = true
				Part.Massless = true

				Part.CanTouch = false
				Part.CastShadow = false
				Part.CanQuery = false

				Part.CollisionGroup = 'Debris'

				local Raycast = Auxiliary:Raycast(NewPosition, -Vector3.yAxis * 20)

				if Raycast then					
					local ResultPosition = Raycast.Position
					local Object = Raycast.Instance

					Part.Material = Object.Material or Enum.Material.Plastic
					Part.Color = Object.Color
					Part.Transparency = Object.Transparency

					Part.Position = Vector3.new(
						NewPosition.X,
						ResultPosition.Y - Offset.Y - Part.Size.Y / 2,
						NewPosition.Z
					)

					Create_Tween(Part, TweenInfo.new(0.125, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
						Position = Part.Position + ( Vector3.yAxis * ( (Part.Size.Y / 2) - Offset.Y) )
					})

					Part.Parent = Folder
				else
					Part:Destroy()
				end

				Rocks[#Rocks + 1] = Part
			end
			

			if ReachTime and type(ReachTime) == 'table' and Counting % ReachTime[1] then
				task.wait(Extra)
			end
		end

		SpawnService:Wait(DespawnTime, function()
			for Index, Part in Rocks do
				local Time = (Index / MaxRocks) * 0.2

				if Index % AmountPerUnit == 0 then
					Time = 0
				end

				SpawnService:Wait(Time, function()
					local Tween = Create_Tween(Part, TweenInfo.new(0.85, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
						Position = Part.Position - Vector3.yAxis * (Part.Size.Y / 2 + Offset.Y + 3),
					})

					Create_Tween(Part, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Transparency = 1})
					Create_Tween(Part, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = Vector3.zero})
					
					SpawnService:AddItem(Part, 0.6)
				end)
			end
		end)
	end)
end

--/ @debris 'Spawn2 Ground' \--
-- Debris creation function for ground destruction effects
-- Creates flying debris particles and ground cracks/holes
function Crater:createDebrisEffect(config)
    -- Initialize default values
    if not config.add then
        config.add = {}
    end
    
    local sizeMultiplier = config.sizemult or 1
    local addConfig = config.add
    
    -- Early exit if dispersefast is enabled and position is off-screen
    if config.dispersefast and not shared.OnScreen(config.cframe.Position) then
        return
    end
    
    -- Initialize random generator
    local randomGen = Random.new(config.Seed or tick())
    
    -- Helper function for random number generation
    local function getRandomNumber(min, max)
        return randomGen:NextNumber(min or 0, max or 1)
    end
    
    -- Floor the amount value if provided
    if config.amount then
        config.amount = math.floor(config.amount)
    end
    
    local debrisReduction = addConfig.less and 2.5 or 1
    local stadiumBreakEffect = nil
    
    -- Create stadium break effect if applicable
    -- if config.ground.Name == "Stadium" and 
    --    not config.ground:GetAttribute("FakeStadium") and 
    --    not config.notiles then
    --     stadiumBreakEffect = createBreakModelEffect({
    --         Effect = "Break Model",
    --         Stadium = config.ground
    --     })
    -- end
    
    -- Calculate number of large debris pieces
    local minDebris, maxDebris = 3, 5
    local largeDebrisCount = randomGen:NextNumber(minDebris, maxDebris)
    
    -- Reduce debris count in fast mode
    if localPlayer:GetAttribute("S_FastMode") then
        largeDebrisCount = largeDebrisCount / 2
    end
    
    -- Skip debris if nodebris flag is set
    if config.nodebris then
        largeDebrisCount = 0
    end
    
    -- Handle water/terrain special cases
    local isWaterTerrain = false
    if config.ground.Material == Enum.Material.Water or config.ground == workspace.Terrain then
        config.ground = {
            Material = Enum.Material.Sand,
            Color = Color3.fromRGB(227, 206, 157),
            Transparency = 0,
            GetAttribute = function() end
        }
        isWaterTerrain = true
    end
    
    -- CREATE LARGE DEBRIS PIECES
    for i = 1, largeDebrisCount do
        if not addConfig.less and not isWaterTerrain then
            local debrisPiece = getPooledPart() or Instance.new("Part")
            debrisPiece.CollisionGroup = "Debris"
            
            -- Random rotation
            local randomCFrame = config.cframe * CFrame.Angles(
                math.rad(getRandomNumber(-360, 360)),
                math.rad(getRandomNumber(-360, 360)),
                math.rad(getRandomNumber(-360, 360))
            )
            
            -- Random size
            local pieceSize = getRandomNumber(1, 3)
            debrisPiece.CFrame = randomCFrame
            debrisPiece.Size = Vector3.new(pieceSize, pieceSize, pieceSize)
            debrisPiece.Color = config.ground.Color
            debrisPiece.CanCollide = not isWaterTerrain
            debrisPiece.Anchored = false
            debrisPiece.Material = config.ground.Material
            debrisPiece.Transparency = config.ground.Transparency
            debrisPiece.Parent = workspace.Thrown
            
            -- Convert neon to concrete for physics
            if debrisPiece.Material == Enum.Material.Neon then
                debrisPiece.Material = Enum.Material.Concrete
            end
            
            -- Add velocity for flying effect
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(2000000000, 2000000000, 2000000000)
            bodyVelocity.Velocity = Vector3.new(
                getRandomNumber(-25, 25),
                getRandomNumber(5, 25),
                getRandomNumber(-25, 25)
            ) * 2
            bodyVelocity.Parent = debrisPiece
            
            -- Clean up velocity after short time
            game:GetService("Debris"):AddItem(bodyVelocity, 0.15)
            
            -- Animate and clean up debris piece
            local cleanupDelay = isWaterTerrain and 0 or (3 + getRandomNumber(0, 1))
            delay(cleanupDelay, function()
                -- Fade out animation
                TweenService:Create(debrisPiece, 
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Transparency = 1,
                        Size = isWaterTerrain and Vector3.new(0, 0, 0) or debrisPiece.Size / 1.5
                    }
                ):Play()
                
                -- Final cleanup
                delay(0.3, function()
                    debrisPiece.Anchored = true
                    debrisPiece.AssemblyLinearVelocity = Vector3.zero
                    debrisPiece.AssemblyAngularVelocity = Vector3.zero
                    debrisPiece.Velocity = Vector3.zero
                    debrisPiece.CanCollide = false
                    debrisPiece.CFrame = CFrame.new(100000000, 100000000, 100000000)
                    table.insert(debrisPool, debrisPiece)
                end)
            end)
        end
    end
    
    -- Calculate number of small debris pieces
    local smallDebrisCount = getRandomNumber(4, 7) / debrisReduction
    if localPlayer:GetAttribute("S_FastMode") then
        smallDebrisCount = smallDebrisCount / 2
    end
    if config.nodebris then
        smallDebrisCount = 0
    end
    
    -- CREATE SMALL DEBRIS PIECES
    for i = 1, smallDebrisCount do
        if not isWaterTerrain then
            local smallDebris = getPooledPart() or Instance.new("Part")
            smallDebris.CFrame = config.cframe
            
            -- Align with surface normal
            local alignmentCFrame = alignToNormal(smallDebris.CFrame.UpVector, config.normal, Vector3.new(0, 1, 0))
            smallDebris.CFrame = smallDebris.CFrame * (alignmentCFrame * CFrame.Angles(math.pi/2, 0, 0))
            
            smallDebris.CollisionGroup = "Debris"
            local debrisSize = getRandomNumber(0.6, 0.8)
            smallDebris.Size = Vector3.new(debrisSize, debrisSize, debrisSize)
            smallDebris.Color = config.ground.Color
            smallDebris.CanCollide = not isWaterTerrain
            smallDebris.Name = "SmallDebris"
            smallDebris.Anchored = false
            smallDebris.Material = config.ground.Material
            smallDebris.Transparency = config.ground.Transparency
            smallDebris.Parent = workspace.Thrown
            
            -- Convert neon to concrete
            if smallDebris.Material == Enum.Material.Neon then
                smallDebris.Material = Enum.Material.Concrete
            end
            
            -- Add physics
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(2000000000, 2000000000, 2000000000)
            bodyVelocity.Velocity = Vector3.new(
                getRandomNumber(-25, 25),
                getRandomNumber(5, 25),
                getRandomNumber(-25, 25)
            ) * 2
            bodyVelocity.Parent = smallDebris
            game:GetService("Debris"):AddItem(bodyVelocity, 0.15)
            
            -- Add rotation
            local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
            bodyAngularVelocity.Parent = smallDebris
            game:GetService("Debris"):AddItem(bodyAngularVelocity, 0.5)
            
            -- Cleanup small debris
            local cleanupDelay = isWaterTerrain and 0 or (3 + getRandomNumber(0, 1))
            delay(cleanupDelay, function()
                TweenService:Create(smallDebris,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Transparency = 1,
                        Size = isWaterTerrain and Vector3.new(0, 0, 0) or smallDebris.Size / 1.5
                    }
                ):Play()
                
                delay(0.3, function()
                    bodyAngularVelocity:Destroy()
                    smallDebris.Anchored = true
                    smallDebris.AssemblyLinearVelocity = Vector3.zero
                    smallDebris.AssemblyAngularVelocity = Vector3.zero
                    smallDebris.Velocity = Vector3.zero
                    smallDebris.CanCollide = false
                    smallDebris.CFrame = CFrame.new(100000000, 100000000, 100000000)
                    table.insert(debrisPool, smallDebris)
                end)
            end)
        end
    end
    
    -- CREATE GROUND CRACKS/HOLES
    local crackPieces = {}
    local minRadius, maxRadius = 5, 7
    
    -- Use custom radius if provided
    if config.new then
        minRadius, maxRadius = config.new[1], config.new[2]
    end
    
    local baseCFrame = CFrame.new(config.cframe.p)
    local averageRadius = (minRadius + maxRadius) / 2
    local pieceCount = config.amount or 16
    
    -- Reduce pieces in fast mode
    if localPlayer:GetAttribute("S_FastMode") then
        pieceCount = pieceCount / 2
    end
    
    -- Align to surface normal and add random rotation
    baseCFrame = baseCFrame * alignToNormal(baseCFrame.UpVector, config.normal, Vector3.new(0, 1, 0))
    baseCFrame = baseCFrame * CFrame.Angles(0, math.rad(getRandomNumber(-360, 360)), 0)
    
    local alternateCFrame = baseCFrame * CFrame.Angles(0, math.rad(getRandomNumber(-16, 16)), 0)
    local firstSound = true
    
    -- Double pieces if using non-standard radius
    if minRadius ~= 5 or maxRadius ~= 7 then
        config.Double = 2
    end
    
    -- Create radial pattern of ground pieces
    for pieceIndex = 1, pieceCount do
        for doubleIndex = 1, (config.Double or 1) do
            local currentCFrame = baseCFrame
            if doubleIndex > 1 then
                currentCFrame = alternateCFrame
                averageRadius = averageRadius + 1
            end
            
            -- Calculate position in circle
            local angle = (360 / pieceCount) * pieceIndex
            local radians = math.rad(angle)
            local xOffset = averageRadius * math.sin(radians)
            local zOffset = averageRadius * math.cos(radians)
            local pieceCFrame = currentCFrame * CFrame.new(xOffset, 0, zOffset)
            
            -- Add random forward/backward offset
            local depthOffset = config.Double and 0.35 or 0.2
            local lookVector = pieceCFrame.lookVector
            pieceCFrame = pieceCFrame + lookVector * getRandomNumber(-depthOffset, depthOffset)
            
            -- Create ground piece
            local groundPiece = getPooledPart() or Instance.new("Part")
            
            -- Set collision group if needed
            if config.dontcollide == localPlayer then
                groundPiece.CollisionGroup = "Debris"
            end
            
            -- Configure basic properties
			groundPiece.Name = "GroundPiece"
            groundPiece.Anchored = true
            groundPiece.CanCollide = false
            groundPiece.CanTouch = true
            groundPiece.Material = config.ground.Material
            groundPiece.Color = config.ground.Color
            groundPiece.CFrame = pieceCFrame * CFrame.fromEulerAnglesXYZ(0, radians, 0)
            
            -- Add random tilt
            local tiltAngle = math.rad(-getRandomNumber(6, 42))
            groundPiece.CFrame = groundPiece.CFrame * CFrame.Angles(tiltAngle, 0, 0)
            
            -- Set size with some variation
            local pieceSize = getRandomNumber(2, 5) * (doubleIndex > 1 and 1.8 or (config.Double and 1.35 or 1))
            local pieceHeight = getRandomNumber(1.9, 2.4)
            local pieceDepth = getRandomNumber(2, 6)
            groundPiece.Size = Vector3.new(pieceSize, pieceHeight, pieceDepth) * sizeMultiplier
            
            -- Adjust position to embed in ground
            groundPiece.CFrame = groundPiece.CFrame * CFrame.new(0, -(groundPiece.Size.Y / 3 + groundPiece.Size.Z / 3) / 3, 0)
            
            -- Initially invisible
            groundPiece.Transparency = 1
            groundPiece.Parent = workspace.Thrown
            
            -- Check for collisions and determine visibility
            local originalCFrame = groundPiece.CFrame
            local hitParts = getPartsInRegion(groundPiece)
            local differentMaterialPart = nil
            local hitGroundPart = nil
            local hitStadium = false
            
            for _, part in pairs(hitParts) do
                if not part:IsDescendantOf(workspace.World.Alive) and 
                   part.Name ~= "invis" and 
                   part.Parent ~= workspace.Thrown then
                    if part.Material ~= config.ground.Material then
                        differentMaterialPart = part
                    end
                    if part == config.ground then
                        hitGroundPart = config.ground
                    end
                    if part.Name == "Stadium" then
                        hitStadium = true
                    end
                end
            end
            
            -- Add final random positioning
            groundPiece.CFrame = groundPiece.CFrame * CFrame.new(0, -3, -1.5) * CFrame.Angles(
                math.rad(getRandomNumber(-11, 11)),
                math.rad(getRandomNumber(-11, 11)),
                math.rad(getRandomNumber(-11, 11))
            )
            
            -- Make visible
            groundPiece.Transparency = 0
            table.insert(crackPieces, groundPiece)
            
            -- Check if piece should be visible
            local shouldBreak = true
            if #hitParts ~= 0 then
                shouldBreak = config.ground:GetAttribute("Breakable") or not config.ground.Anchored
            end
            
            -- Check angle constraint if provided
            local withinAngle = config.angle
            if config.angle then
                local angleCheck = config.anglecfr
                local piecePos = originalCFrame.Position
                local projectedPos = Vector3.new(piecePos.X, angleCheck.p.Y, piecePos.Z)
                local direction = (projectedPos - angleCheck.p).unit
                withinAngle = math.deg(math.acos(angleCheck.LookVector:Dot(direction))) <= config.angle
            end

            -- Determine final appearance
            if shouldBreak or withinAngle then
                if not isWaterTerrain then
                    groundPiece.Transparency = 1
                end
            else
                -- Use different material if found
                if differentMaterialPart and 
                   (not hitGroundPart or hitGroundPart.Name ~= "Stadium") and
                   (not hitStadium or config.ground.Name ~= "Stadium") then
                    -- Special case: grass becomes dirt
                    if config.ground.Material == Enum.Material.Grass and hitGroundPart then
                        differentMaterialPart = workspace.Preload.Dirt
                    end
                    groundPiece.Color = differentMaterialPart.Color
                    groundPiece.Material = differentMaterialPart.Material
                end
                groundPiece.Transparency = config.ground.Transparency
            end
            
            -- Set collision properties based on visibility
            if groundPiece.Transparency >= 1 then
                groundPiece.CanCollide = false
                groundPiece.CanTouch = false
                groundPiece.CanQuery = false
            else
                groundPiece.CanCollide = true
            end
            
            -- Reset any existing velocity
            if groundPiece.Velocity.magnitude > 0 then
                groundPiece.AssemblyLinearVelocity = Vector3.zero
                groundPiece.AssemblyAngularVelocity = Vector3.zero
                groundPiece.Velocity = Vector3.zero
            end
            
            -- -- Special handling for water/terrain
            -- if isWaterTerrain then
            --     groundPiece.CFrame = originalCFrame
            --     addSpecialEffect(groundPiece)
            -- end
            
            -- SOUND EFFECTS
            if firstSound then
                firstSound = false
                
                -- Define sound arrays
                local crackSounds = {"rbxassetid://3848076724", "rbxassetid://3848078820"}
                local breakSounds = {
                    "rbxassetid://4307208601", "rbxassetid://4307207425", "rbxassetid://4307207693",
                    "rbxassetid://4307205188", "rbxassetid://3778609188", "rbxassetid://3778608737",
                    "rbxassetid://3744401196", "rbxassetid://4307204962"
                }
                local impactSounds = {"rbxassetid://4307204696", "rbxassetid://4307204452"}
                
                -- Water terrain special effects
                if isWaterTerrain then
                    local volumeDivisor = stadiumBreakEffect and 2 or 1
                    local radius = (minRadius + maxRadius) / 12
                    
                    -- Adaptive wait function for sound timing
                    local function getAdaptiveDelay(size)
                        local baseDelay = 0.015
                        if size < 0.8 then
                            baseDelay = baseDelay + (0.8 - size) * 0.02
                        end
                        return baseDelay
                    end
                    
                    -- Play destruction sounds after delay
                    task.delay(getAdaptiveDelay(radius), function()
                        -- Check for recent debris to avoid sound spam
                        local canPlaySound = true
                        if not shared.recentdebris then
                            shared.recentdebris = {}
                        end
                        
                        for index, data in pairs(shared.recentdebris) do
                            local pos, time = data[1], data[2]
                            if tick() - time > 0.5 then
                                shared.recentdebris[index] = nil
                            elseif (pos.Position - currentCFrame.Position).magnitude <= 5 then
                                canPlaySound = false
                                break
                            end
                        end
                        
                        if canPlaySound then
                            local isLarge = radius >= 0.8
                            
                            -- Play break sound for large impacts
                            if isLarge then
                                table.insert(shared.recentdebris, {currentCFrame, tick()})
                                -- playSound({
                                --     SoundId = ({"rbxassetid://18922680029", "rbxassetid://18922679331", 
                                --               "rbxassetid://18922678743", "rbxassetid://18922678349"})[math.random(1, 4)],
                                --     Volume = 1.35 / volumeDivisor,
                                --     CFrame = currentCFrame
                                -- })
                            end
                            
                            -- Water splash effects
                            local splashSounds = isLarge and 
                                {"rbxassetid://18922743710", "rbxassetid://18922743936", "rbxassetid://18922744361"} or
                                {"rbxassetid://97900036122485", "rbxassetid://73075062841158", "rbxassetid://122164610127113",
                                 "rbxassetid://78182682399983", "rbxassetid://89999290123856", "rbxassetid://70534139031144"}
                            
                            local volumeBoost = isLarge and 0 or 1
                            -- playSound({
                            --     SoundId = splashSounds[math.random(#splashSounds)],
                            --     Volume = 1.75 / volumeDivisor + math.max(radius - 1, 0) + volumeBoost,
                            --     PlaybackSpeed = getRandomNumber(0.9, 1.1),
                            --     CFrame = currentCFrame
                            -- })
                            
                            -- Create splash effect
                            local splashEffect = game.ReplicatedStorage.Resources.Splash:Clone()
                            game:GetService("Debris"):AddItem(splashEffect, 5)
                            splashEffect:ScaleTo(radius + 0.3)
                            splashEffect.PrimaryPart.CFrame = currentCFrame
                            splashEffect.Parent = workspace.Thrown
                            
                            -- Emit particles
                            for _, descendant in pairs(splashEffect:GetDescendants()) do
                                if descendant:IsA("ParticleEmitter") then
                                    descendant:Emit(descendant:GetAttribute("EmitCount"))
                                end
                            end
                        end
                    end)
                    
                -- Regular terrain sound effects
                elseif addConfig.sounds and not config.nosound then
                    local volumeDivisor = stadiumBreakEffect and 2 or 1
                    
                    -- Play impact sound
                    -- playSound({
                    --     SoundId = impactSounds[math.random(#impactSounds)],
                    --     Volume = 3.85 / volumeDivisor,
                    --     Parent = groundPiece
                    -- })
                    
                    -- -- Play break sound
                    -- playSound({
                    --     SoundId = breakSounds[math.random(#breakSounds)],
                    --     Volume = 4.3 / volumeDivisor,
                    --     Parent = groundPiece
                    -- })
                    
                    -- -- Play crack sound
                    -- playSound({
                    --     SoundId = crackSounds[math.random(#crackSounds)],
                    --     Volume = 4.12 / volumeDivisor,
                    --     Parent = groundPiece
                    -- })
                end
            end
            
            -- Store original position
            groundPiece:SetAttribute("OGCframe", originalCFrame)
            
            -- Animate piece into final position
            if not isWaterTerrain then
                TweenService:Create(groundPiece,
                    TweenInfo.new(getRandomNumber(0.2, 0.3), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { CFrame = originalCFrame }
                ):Play()
            end
            
            -- CLEANUP AND DISPOSAL
            if isWaterTerrain then
                -- Quick cleanup for water terrain
                task.delay(1, function()
                    groundPiece:SetAttribute("OGCframe", nil)
                    groundPiece.Anchored = true
                    groundPiece.AssemblyLinearVelocity = Vector3.zero
                    groundPiece.AssemblyAngularVelocity = Vector3.zero
                    groundPiece.Velocity = Vector3.zero
                    groundPiece.CFrame = CFrame.new(100000000, 100000000, 100000000)
                    table.insert(debrisPool, groundPiece)
                end)
            else
                -- Regular cleanup with optional keeping
                local keepTime = addConfig.keep
                if not keepTime then
                    keepTime = getRandomNumber(5, 7)
                end
                
                local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                if config.dispersefast then
                    keepTime = config.dispersefast
                end
                if config.customtween then
                    tweenInfo = config.customtween
                end
                
                delay(keepTime, function()
                    -- Optional keep animation
                    if addConfig.keep then
                        TweenService:Create(groundPiece,
                            TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            { CFrame = originalCFrame, Size = groundPiece.Size }
                        ):Play()
                        wait(2)
                    end
                    
                    -- Sink into ground animation
                    TweenService:Create(groundPiece, tweenInfo, {
                        CFrame = groundPiece.CFrame * CFrame.new(0, -7, 0),
                        Size = groundPiece.Size / 1.5
                    }):Play()
                    
                    wait(2)
                    
                    -- Final cleanup
                    groundPiece:SetAttribute("OGCframe", nil)
                    groundPiece.Anchored = true
                    groundPiece.AssemblyLinearVelocity = Vector3.zero
                    groundPiece.AssemblyAngularVelocity = Vector3.zero
                    groundPiece.Velocity = Vector3.zero
                    groundPiece.CFrame = CFrame.new(100000000, 100000000, 100000000)
                    table.insert(debrisPool, groundPiece)
                end)
            end
        end
    end
    
    return crackPieces
end

--/ @debris 'ground' \--
function Crater:Spawn(Data: GroundData)
	--/ @variables \--
	local AmountPerUnit = Data.AmountPerUnit or 1
	
	local Amount = Data.Amount or 10
	local Radius = Data.Radius or {5, 5}

	local Size = Data.Size or {3, 4}
	local Offset = Data.Offset or {X = 0, Y = 0, Z = 0}
	local Angle = Data.Angle or {30, 30}

	local DespawnTime = Data.DespawnTime or 3

	local Position = Data.Position or nil

	--/ @return \--
	if not Position then
		return
	end

	--/ @dependency \--
	local Orientation = 0

	--/ @loop \--
	MaidService:Task(function()
		local Folder = Instance.new('Folder')
		Folder.Name = 'RockFolder'
		Folder.Parent = Effects
		SpawnService:AddItem(Folder, DespawnTime + 3)

		for x = 1, Amount do
			if not Folder.Parent then
				break
			end
			
			for i = 1, AmountPerUnit do
				local Radius = Seed:NextNumber(Radius[1], Radius[2]) 
				local NewCFrame = CFrame.new(Position) * CFrame.fromEulerAnglesXYZ(0, math.rad(Orientation), 0) * CFrame.new(Radius, 0, Radius) 

				local Part = Instance.new('Part')
				Part.Anchored = true
				Part.CanCollide = true
				Part.Massless = true

				Part.CanTouch = false
				Part.CastShadow = false
				Part.CanQuery = false

				Part.CollisionGroup = 'Debris'

				Part.CFrame = NewCFrame
				Part.Parent = Folder

				local Raycast = Auxiliary:Raycast(Part.Position, -Vector3.yAxis * 13)

				if Raycast then
					local ResultPosition = Raycast.Position
					local Object = Raycast.Instance

					local EndFrame = CFrame.lookAt(
						Vector3.new(
							NewCFrame.Position.X,
							ResultPosition.Y - Offset.Y,
							NewCFrame.Position.Z
						),
						Vector3.new(
							Position.X,
							ResultPosition.Y,
							Position.Z
						)
					)

					Part.CFrame = EndFrame * CFrame.new(0, -4, 0)

					Part.Material = Object.Material or Enum.Material.Plastic
					Part.Color = Object.Color
					Part.Transparency = Object.Transparency

					Part.Size = Vector3.zero

					Part.CFrame *= CFrame.fromEulerAnglesXYZ(
						math.rad(math.random(-10, 10) / 20),
						math.rad(Orientation + (math.random(-200, 200) / 20)),
						math.rad(math.random(-10, 10) / 20)
					)

					--/ @tween \--
					Create_Tween(Part, TweenInfo.new(0.1), {
						Size = Vector3.one * math.random(Size[1] , Size[2]),
						CFrame = EndFrame * CFrame.Angles(math.rad( -math.random(Angle[1], Angle[2]) ), 0, 0),
					})

					--/ @wait \--
					SpawnService:Wait(DespawnTime, function()
						task.wait((i / Amount) / 25)

						Create_Tween(Part, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
							Size = Part.Size * 0.2,
						})

						Create_Tween(Part, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
							Transparency = 1
						})

						local Tween = Create_Tween(Part, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
							CFrame = EndFrame * CFrame.new(0, -4, 0),
						})

						SpawnService:AddItem(Part, 1)
					end)

				else
					Part:Destroy()
				end
			end

			Orientation += 360 / Amount
		end
	end)
end

--/ @return 'debris' \--
return Crater