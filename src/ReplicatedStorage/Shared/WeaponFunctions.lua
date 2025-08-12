local WF = {}
local Assets = game.ReplicatedStorage.Assets
local task_delay = task.delay;
local function AddItem(Item, Duration)
	task_delay(Duration, function()
		pcall(Item.Destroy, Item);
	end)
end
function WF.WeaponModelUnattach(Character,WeaponName,Attach)
	for i,v in pairs(Character:GetDescendants()) do
		if v.Name == "Grip" or v.Name == WeaponName then
			AddItem(v,0)
		end
	end
end

function WF.WeaponModelAttach(Character,WeaponName,Attach)
	local WeaponModel = Assets.Weapons[WeaponName].Handle:Clone()
	WeaponModel.Parent = Character[Attach]
	WeaponModel.Name = WeaponName;
	
	local Weld = Assets.Weapons[WeaponName].Grip:Clone()
	Weld.Parent = Character[Attach]
	Weld.Part0 = Character[Attach]
	Weld.Part1 = WeaponModel
end

return WF
