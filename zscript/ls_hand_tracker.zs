/*
*
*	VR main hand offset hack
*	Should work in both GZDoomVR and QuestZDoom
*	Author: Ermac (https://github.com/iAmErmac)
*	
*	You can modify and use this script in your mod
*	Just leave this comment at the top of the sript
*	and give me credit please
*		
*/

Class LSMainHandPosTracker : EventHandler
{
	override void PlayerEntered(PlayerEvent e)
	{
		let pmo = players[e.PlayerNumber].mo;
		pmo.SetInventory("LSMainHandTracker", 1, false);
	}
}

Class LSMainHandTracker : CustomInventory
{
	Vector3 AttackPos;
	Float AttackAngle;
	Float AttackPitch;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.AUTOACTIVATE;
	}
	
	override void DoEffect()
	{
		Actor mainhand_tracker = owner.SpawnPlayerMissile("LSHandPosTracker");
		if(mainhand_tracker) mainhand_tracker.master = self;
		
		//console.printf("x: %d, y: %d, z: %d, angle: %d, pitch: %d", AttackPos.x, AttackPos.y, AttackPos.z, AttackAngle, AttackPitch);
		
		Super.DoEffect();
	}

	States
	{
	Use:
		TNT1 A 0;
		Fail;
	Pickup:
		TNT1 A 0
		{
			return true;
		}
		Stop;
	}
}

Class LSHandPosTracker : Actor
{
	Vector3 t_pos;
	double t_pitch;
	
	override void BeginPlay()
	{
		t_pos = self.pos;
	}

	override void Tick()
	{
		Super.Tick();
		
		let dX = t_pos.x - self.pos.x;
		let dY = t_pos.y - self.pos.y;
		let dZ = t_pos.z - self.pos.z;
		
		t_pitch = (atan2(sqrt(dX * dX + dY * dY), dZ) * -1) + 90;
		
		LSMainHandTracker(master).AttackPos = t_pos;
		LSMainHandTracker(master).AttackAngle = self.angle;
		LSMainHandTracker(master).AttackPitch = t_pitch;
	}

	Default
	{
	Projectile;
	+MISSILE;
	+NOGRAVITY;
	+NOBLOCKMAP;
	+DONTSPLASH;
	+THRUACTORS;
	//+NOCLIP;
	Radius 1;
	Height 1;
	Damage 0;
	Speed 65;
	RenderStyle "None";
	}
	
	States
	{
	Spawn:
		TNT1 A 1; //don't need more than a single tick
		Stop;
	}
}