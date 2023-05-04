class GTransFire extends ProjectileFire;

var() Sound TransFireSound;
var() Sound RecallFireSound;
var() string TransFireForce;
var() string RecallFireForce;

simulated function PlayFiring()
{
	if (!GTransLauncher(Weapon).bBeaconDeployed)
	{
		Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
		ClientPlayForceFeedback(TransFireForce);
	}
}

function Rotator AdjustAim(Vector Start, float InAimError)
{
	return Instigator.Controller.Rotation;
}

simulated function bool AllowFire()
{
	return (GTransLauncher(Weapon).AmmoChargeF >= 1.0);
}

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local GTransBeacon GTransBeacon;

	if (GTransLauncher(Weapon).GTransBeacon == none)
	{
		if ((Instigator == none) || (Instigator.PlayerReplicationInfo == none) || (Instigator.PlayerReplicationInfo.Team == none))
			GTransBeacon = Weapon.Spawn(class'fpsGame.GTransBeacon',,, Start, Dir);
		else if (Instigator.PlayerReplicationInfo.Team.TeamIndex == 0)
			GTransBeacon = Weapon.Spawn(class'fpsGame.GTransBeacon',,, Start, Dir);
		else
			GTransBeacon = Weapon.Spawn(class'fpsGame.GTransBeacon',,, Start, Dir);

		GTransLauncher(Weapon).GTransBeacon = GTransBeacon;
		Weapon.PlaySound(TransFireSound,SLOT_Interact,,,,,false);
	}
	else
	{
		GTransLauncher(Weapon).ViewPlayer();
		if (GTransLauncher(Weapon).GTransBeacon.Disrupted())
		{
			if ((Instigator != none) && (PlayerController(Instigator.Controller) != none))
				PlayerController(Instigator.Controller).ClientPlaySound(Sound'WeaponSounds.BSeekLost1');
		}
		else
		{
			GTransLauncher(Weapon).GTransBeacon.Destroy();
			GTransLauncher(Weapon).GTransBeacon = none;
			Weapon.PlaySound(RecallFireSound,SLOT_Interact,,,,,false);
		}
	}
	return GTransBeacon;
}

defaultproperties
{
	TransFireSound=SoundGroup'WeaponSounds.Translocator.TranslocatorFire'
	RecallFireSound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'
	TransFireForce="TranslocatorFire"
	RecallFireForce="TranslocatorModuleRegeneration"
	ProjSpawnOffset=(X=25.000000,Y=8.000000)
	bLeadTarget=false
	bWaitForRelease=true
	bModeExclusive=false
	FireAnimRate=1.500000
	FireRate=0.250000
	AmmoPerFire=1
	ProjectileClass=Class'fpsGame.GTransBeacon'
	BotRefireRate=0.300000
}