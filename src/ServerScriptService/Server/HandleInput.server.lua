--// Services
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local BadgeService = game:GetService("BadgeService")
local Chat = game:GetService("Chat")
local Teams = game:GetService("Teams")
local TestService = game:GetService("TestService")
local LocalizationService = game:GetService("LocalizationService")
local AnalyticsService = game:GetService("AnalyticsService")
local HapticService = game:GetService("HapticService")
local MessagingService = game:GetService("MessagingService")
local PolicyService = game:GetService("PolicyService")
local SocialService = game:GetService("SocialService")
local TextService = game:GetService("TextService")
local VRService = game:GetService("VRService")
local VoiceChatService = game:GetService("VoiceChatService")

--// Locations
local Server = ServerScriptService.Server;
local ServerComponents = Server.Components; 

--// Modules
local EntityManager = require(ServerComponents.Core.EntityManager);
local bridgeNet2 = require(ReplicatedStorage.Shared.Components.BridgeNet2)
local Skills = require(Server.Skills);

--// Variables
local _use = bridgeNet2.ServerBridge('_use')

local function HandleM1(Entity, args)
    local data = args[2];
    local held = data["held"];
    local tool = data["tool"];

    if tool and tool.Parent ~= Entity.Character.Rig then
        print("Tool is not in the character, ignoring M1 action.");
        return; -- Tool is not in the character, ignore
    end

    if tool then
        local Activator = tool:FindFirstChild("Activator");
        if Activator then
            require(Activator).Active(Entity);
        end
        if tool:GetAttribute("Type") == "Spell" then
            -- Handle spell casting
            local spellName = tool.Name;
            Skills['Spell/' .. spellName]:ActivateSpell(Entity, args);
        end
    else
        -- Entity.Combat:LightAttack(held);
    end
end

_use:Connect(function(player, args)
    local Entity = EntityManager.Find(player);

    local action = args[1];
    local data = args[2];
    local held = data["held"];

    if action == "Block" then
        Entity.Combat:Block(held);
    elseif action == "M1" then
        HandleM1(Entity, args);
    end
end);

