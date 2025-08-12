local Animations = game:GetService("ReplicatedStorage").Shared.Assets.Animations

export type weaponInfo = {
	HitType: string;

	LightAttack: {
		SwingSpeed: number;
		Damage: number;
		Endlag: number;
		stun: number;
		Hitbox: {
			Size: Vector3;
			Offset: CFrame;
		};
		Animation: string;
	};

	Critical: {
		SwingSpeed: number;
		Animation: string;
		Endlag: number;
		stun: number;
	};
}

local Weapons = {
	
	["Dagger"] = {
		HitType = "Slash";
		
		LightAttack = {
			SwingSpeed = 1.6;
			Damage = 4;
			Endlag = 0;
			Stun = 0.4;
			Hitbox = {
				Size = Vector3.new(4,4,8);
				Offset = CFrame.new(0,0,-4);
			};
			Animation = "LightAttacks/Dagger";
		};
		
		Critical = {
			Damage = 4;	
			Endlag = 1.5;
			Stun = 0.4;
			Hitbox = {
				Size = Vector3.new(4,4,8);
				Offset = CFrame.new(0,0,-4);
			};
			Animation = "Criticals/Dagger";
		};
	};
	
	["Fist"] = {
		HitType = "Blunt";

		LightAttack = {
			SwingSpeed = 1;
			Damage = 3;
			Endlag = 0;
			Stun = 0.4;
			Hitbox = {
				Size = Vector3.new(4,4,8);
				Offset = CFrame.new(0,0,-4);
			};
			Animation = "LightAttacks/Fist";
		};

		Critical = {
			Damage = 10;	
			Endlag = 0.5;
			Stun = 0.4;
			Hitbox = {
				Size = Vector3.new(4,4,8);
				Offset = CFrame.new(0,0,-4);
			};
			Animation = "Criticals/Fist";
		};
	};
	
} 

return Weapons;