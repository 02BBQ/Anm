local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local isStudio = RunService:IsStudio()

local Storage = ServerStorage:WaitForChild("Storage")

local coroutine_wrap = coroutine.wrap;
local task_delay = task.delay;
local task_spawn = task.spawn;
local math_random = math.random;
local math_max = math.max; 
local math_min = math.min;
local task_wait = task.wait;

workspace:SetAttribute("RbxLegacyAnimationBlending", true)

local ServerReplicator = {};
local EffectReplicator, Replication = require(ReplicatedStorage.Shared.Components.EffectReplicator), ReplicatedStorage.Remotes.EffectReplication
local PlayerEffects = {}
local UpdateRemote = Replication._update
local PlayerContainers = {}
local Characters = {}

local Components = ServerScriptService.Server.Components;

local EntityManager = require(Components.Core.EntityManager)
local Cmdr = require(Components.Admin.Cmdr);
local Network = require(ReplicatedStorage.Shared.Components.Networking.Network);

Network:OpenDefaultChannels();

Cmdr:RegisterHooksIn(Components.Admin.Hooks)
Cmdr:RegisterDefaultCommands()
Cmdr:RegisterCommandsIn(Components.Admin.Commands.Admin)
Cmdr:RegisterTypesIn(Components.Admin.Types);

for _,v in pairs(Storage.StarterGui:GetChildren()) do
	v:Clone().Parent = game.StarterGui;
end

function shared.GetReplicator(Player)
	return PlayerEffects[Player];
end

function EffectReplicator:Destroy()
	pcall(function()
		UpdateRemote:FireClient(self.Player, {
			updateType = "clear"
		})
	end)
end

function _G.FindEntity(param)
	return EntityManager.Find(param);
end

function _G.RemoveReplicator(Player)
	local oldEffectReplicator = PlayerEffects[Player]

	if oldEffectReplicator then
		oldEffectReplicator:Destroy()
	end
end

function CreateReplicator(Player, isNPC)
	local oldEffectReplicator = PlayerEffects[Player]


	if oldEffectReplicator then
		oldEffectReplicator:Destroy()
	end

	local newPlayerContainer = {};
	local effectReplicator = EffectReplicator.new();
	effectReplicator.Player = Player;

	if not isNPC then
		effectReplicator.EffectAdded:Connect(function(effect, DebrisTime)
			task.wait();
			if (effect.Destroyed) then return end;

			if (effect.Domain == "Server") then
				UpdateRemote:FireClient(Player, {
					updateType = "update";
					sum = effectReplicator:ParseEffects()
				});

				for i,v in next, {effect, effect.TagAdded, effect.TagRemoving} do
					v:Connect(function()
						UpdateRemote:FireClient(Player, {
							updateType = "update";
							sum = {effect:ParseEffect()};
						});
					end)
				end
			end;
		end)

		effectReplicator.EffectRemoving:Connect(function(effect)
			UpdateRemote:FireClient(Player, {
				updateType = "remove";
				sum = effect.ID;
			});
		end);
	end

	PlayerEffects[Player] = effectReplicator;
	PlayerContainers[Player] = newPlayerContainer;

	if not isNPC then
		UpdateRemote:FireClient(Player, {
			updateType = "updatecontainer";
			sum = newPlayerContainer;
		});
	end
	return effectReplicator
end

local function AddItem(Item, Duration)
	task_delay(Duration, function()
		pcall(Item.Destroy, Item);
	end)
end

function InitializeCharacter(Character)
	local isPlayer = Players:GetPlayerFromCharacter(Character) or Character;
	local effectReplicator = CreateReplicator(isPlayer, not isPlayer:IsA("Player"))
	local Entity = EntityManager.Find(isPlayer)
	if not Entity then return end
	Entity:HandleCharacter(effectReplicator)
end

function OnPlayerAdded(Player : Player?)
	task.wait(isStudio and 0 or 2); --// prevents from dupe

	local Entity = EntityManager.new(nil, Player);

	Player.CharacterAdded:Connect(function(Character)
		--Character = Player.Character or Player.CharacterAppearanceLoaded:Wait()
		Entity.Character.Rig = Character
		Character.Parent = workspace.World.Alive
	end)

	Player:LoadCharacter()
end

function RemovingPlayer(Player)
	if Player:GetAttribute("Loaded") then
		while not pcall(function()
				shared.SaveData(Player, nil, true);
			end) do
			task.wait(1)
		end
	end
	EntityManager.Find(Player):Destroy();
	for i,v in next, {PlayerContainers, PlayerEffects} do
		if v[Player] then
			table.clear(v[Player]);
			v[Player] = nil;
		end
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)

Players.PlayerRemoving:Connect(RemovingPlayer)

local characterInitialize = function(character)
	if not character:FindFirstChildOfClass("Humanoid") then
		return;
	end

	local isPlayer = Players:GetPlayerFromCharacter(character) or character;
	local effectReplicator = CreateReplicator(isPlayer, not isPlayer:IsA("Player"))
	local Entity = EntityManager.Find(isPlayer)
	if not Entity then return end
	Entity:HandleCharacter(effectReplicator)
	
	print("INIT"..character.Name)
end

for _,v in pairs(workspace.World.Alive:GetChildren()) do
	characterInitialize(v);
end

workspace.World.Alive.ChildAdded:Connect(characterInitialize)

EntityManager.Spawn("Sans_0909").Character.Rig.Parent = workspace.World.Alive;
EntityManager.Spawn("Block_Sans").Character.Rig.Parent = workspace.World.Alive;