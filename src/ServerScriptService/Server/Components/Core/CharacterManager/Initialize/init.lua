--//Variable
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService("ServerStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');

local module = {}

local Setups = {
    Race = require(ReplicatedStorage.Shared.Components.Race);
};

-- 모든 Setup 모듈들을 자동으로 로드
for _, setupModule in pairs(script:GetChildren()) do
    if setupModule:IsA("ModuleScript") then
        local setup = require(setupModule);
        Setups[setupModule.Name] = setup;
    end
end

module.Setups = Setups;

-- 모든 Setup을 실행하는 함수
function module.Initialize(Entity)
    for name, setup in pairs(Setups) do
        if setup.Initialize then
            setup.Initialize(Entity);
        end
    end
end

return module