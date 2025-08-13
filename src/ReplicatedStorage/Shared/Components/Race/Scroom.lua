local Race = {};

Race.Name = script.Name;
Race.Rarity = 20;

Race.Initialize = function(entity)
    local character = entity.Character;
    local rig = character.Rig;

    for i,v in pairs(rig:GetChildren()) do
        if v.Name == "Head" or v.Name == "Torso" or v.Name == "Left Arm" or v.Name == "Left Leg" or v.Name == "Right Arm" or v.Name == "Right Leg" then
            v.Color = Color3.fromRGB(219, 175, 175)
        end
    end
end

Race.Names = {
    "Acedias",
    "Affliction",
    "Agony",
    "Alpha",
    "Andromeda",
    "Beta",
    "Bereft",
    "Cinder",
    "Crescendo",
    "Dark",
    "Delta",
    "Demise",
    "Discord",
    "Dissonance",
    "Ember",
    "Empty",
    "End",
    "Epoch",
    "Eternal",
    "Euphoria",
    "Facade",
    "Fallen",
    "Fear",
    "Full",
    "Gamma",
    "Glory",
    "Gratitude",
    "Grief",
    "Harmony",
    "Harrow",
    "Hate",
    "Haven",
    "Hollow",
    "Hope",
    "Hopeless",
    "Ire",
    "Indifferent",
    "Joy",
    "Lambda",
    "Lament",
    "Liar",
    "Light",
    "Lost",
    "Lull",
    "Mask",
    "Melody",
    "Mirth",
    "Nadir",
    "Null",
    "Omega",
    "Omicron",
    "Ophiuchus",
    "Orion",
    "Ouroboros",
    "Pleasure",
    "Prayer",
    "Prime",
    "Prodigy",
    "Requiem",
    "Respite",
    "Rhapsody",
    "Risen",
    "Scourge",
    "Serendipity",
    "Shell",
    "Sigma",
    "Solace",
    "Sorrow",
    "Symphony",
    "Truth",
    "Unity",
    "Vainglory",
    "Vessel",
    "Zenith"
};

return Race;