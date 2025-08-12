local ItemModels = script.Parent.ItemModels

local ItemsInfo = {
	["Slime Ball"] = {
		Name = "Slime Ball";
		Type = "Tool";
		Model = ItemModels["Slime Ball"];
		Stackable = true;
		StackCap = 15;
		Desc = "haha. poolish slime ball!";
		Rarerity = "Common";
		Attribute = "Item";
		Item_Icon = "http://www.roblox.com/asset/?id=347489174";
	};
	["Slime Head"] = {
		Name = "Slime Head";
		Type = "Equipment";
		EquipPiece = "Head";
		Armor = true;
		Model = ItemModels["Slime Head"];
		Stackable = false;
		StackCap = 1;
		Desc = "slime's head, you can maybe equip it??";
		Rarerity = "Epic";
		Attribute = "Item";
		Item_Icon = "http://www.roblox.com/asset/?id=347489174";
	};
	["Wood Dagger"] = {
		Name = "Wood Dagger";
		Type = "Tool";
		WeaponType = "Dagger";
		Attach = "Right Arm";
		Equippable = true;
		Weapon = true;
		Model = ItemModels["Wood Dagger"];
		Stackable = false;
		StackCap = 1;
		Desc = "an wood dagger for begineers";
		Rarerity = "Common";
		Attribute = "Item";
		Item_Icon = "http://www.roblox.com/asset/?id=129697913";
	};
}

return ItemsInfo

