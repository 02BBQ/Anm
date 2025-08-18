local Wiki = {};

for _, info: ModuleScript? in pairs(script:GetChildren()) do
    if info:IsA("ModuleScript") then
        local itemInfo = require(info);
        Wiki[info.Name] = itemInfo;
    end
end

return Wiki;