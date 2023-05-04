class GTransRecall extends WeaponFire;

var() Sound TransFailedSound;
var bool bGibMe;
var Material TransMaterials[2];

simulated function PlayFiring()
{
	if (GTransLauncher(Weapon).bBeaconDeployed)
		Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
}

simulated function bool AllowFire()
{
	local bool success;
    
	success = (GTransLauncher(Weapon).AmmoChargeF >= 1.0);
	if (!success && (Weapon.Role == ROLE_Authority) && (GTransLauncher(Weapon).GTransBeacon != none))
	{
		if (PlayerController(Instigator.Controller) != none)
			PlayerController(Instigator.Controller).ClientPlaySound(TransFailedSound);
	}

	return success;
}

function bool AttemptTranslocation(vector dest, GTransBeacon GTransBeacon)
{
	local vector OldLocation, HitLocation, HitNormal;
	local Actor HitActor;
	
	OldLocation = Instigator.Location;
	if (!TranslocSucceeded(dest, GTransBeacon))
		return false;

	HitActor = Weapon.Trace(HitLocation, HitNormal, Instigator.Location, dest, false);
	if (HitActor == none || !HitActor.bBlockActors || !HitActor.bBlockNonZeroExtentTraces)
		return true;

	Instigator.SetLocation(OldLocation);
	return false;
}

function bool TranslocSucceeded(vector dest, GTransBeacon GTransBeacon)
{
	local vector newdest;
	
	if (Instigator.SetLocation(dest) || BotTranslocation())
		return true;

	if (GTransBeacon.Physics != PHYS_None)
	{
		newdest = GTransBeacon.Location - Instigator.CollisionRadius * Normal(GTransBeacon.Velocity);
		if (Instigator.SetLocation(newdest))
			return true;
	}

	if ((dest != GTransBeacon.Location) && Instigator.SetLocation(GTransBeacon.Location))
		return true;
	
	newdest = dest + Instigator.CollisionRadius * vect(1,1,0);
	if (Instigator.SetLocation(newdest))
		return true;

	newdest = dest + Instigator.CollisionRadius * vect(1,-1,0);
	if (Instigator.SetLocation(newdest))
		return true;

	newdest = dest + Instigator.CollisionRadius * vect(-1,1,0);
	if (Instigator.SetLocation(newdest))
		return true;

	newdest = dest + Instigator.CollisionRadius * vect(-1,-1,0);
	if (Instigator.SetLocation(newdest))
		return true;
	
	return false;
}

function Translocate()
{
    	local GTransBeacon GTransBeacon;
	local Actor HitActor;
	local Vector HitNormal, HitLocation, dest, Vel2D;
    	local Vector PrevLocation;
    	local xPawn XP;
	local bool bFailedTransloc;
	local int EffectNum;

	if ((Instigator == none) || (GTransLauncher(Weapon) == none))
		return;

	GTransBeacon = GTransLauncher(Weapon).GTransBeacon;
	if (GTransBeacon.Disrupted())
	{
		UnrealMPGameInfo(Level.Game).SpecialEvent(Instigator.PlayerReplicationInfo, "translocate_gib");
		bGibMe = true;
		return;
	}

	dest = GTransBeacon.Location;
	if (GTransBeacon.Physics == PHYS_None)
		dest += vect(0,0,1) * Instigator.CollisionHeight;
	else
		dest += vect(0,0,0.5) * Instigator.CollisionHeight;

	HitActor = Weapon.Trace(HitLocation, HitNormal, dest, GTransBeacon.Location, true);
	if (HitActor != none)
		dest = GTransBeacon.Location;    

	GTransBeacon.SetCollision(false, false, false);    
	if (Instigator.PlayerReplicationInfo.HasFlag != none)
		Instigator.PlayerReplicationInfo.HasFlag.Drop(0.5 * Instigator.Velocity);

	PrevLocation = Instigator.Location;
	if (!bFailedTransloc && AttemptTranslocation(dest, GTransBeacon))
	{
		GTransLauncher(Weapon).ReduceAmmo();
		XP = xPawn(Instigator);
		if (XP != none)
			XP.DoTranslocateOut(PrevLocation);

		Vel2D = Instigator.Velocity;
		Vel2D.Z = 0;
		Vel2D = Normal(Vel2D) * FMin(Instigator.GroundSpeed, VSize(Vel2D));
		Vel2D.Z = Instigator.Velocity.Z;
		Instigator.Velocity = Vel2D;
		
		if (Instigator.PlayerReplicationInfo.Team != none)
			EffectNum = Instigator.PlayerReplicationInfo.Team.TeamIndex;
			
		Instigator.SetOverlayMaterial(TransMaterials[EffectNum], 1.0, false);
		Instigator.PlayTeleportEffect(false, false);

		if (!Instigator.PhysicsVolume.bWaterVolume)
		{
			if (Bot(Instigator.Controller) != none)
			{
				Instigator.Velocity.X = 0;
				Instigator.Velocity.Y = 0;
				Instigator.Velocity.Z = -150;
				Instigator.Acceleration = vect(0,0,0);
			}
			Instigator.SetPhysics(PHYS_Falling);
		}

		if (UnrealTeamInfo(Instigator.PlayerReplicationInfo.Team) != none)
			UnrealTeamInfo(Instigator.PlayerReplicationInfo.Team).AI.CallForBall(Instigator);
	}
	else if (PlayerController(Instigator.Controller) != none)
	{
		PlayerController(Instigator.Controller).ClientPlaySound(TransFailedSound);
	}

	GTransBeacon.Destroy();
	GTransLauncher(Weapon).GTransBeacon = none;
	GTransLauncher(Weapon).ViewPlayer();
}

function ModeDoFire()
{
	local GTransBeacon GTransBeacon;

	Super.ModeDoFire();

	if (Weapon.Role == ROLE_Authority && bGibMe)
	{
		GTransBeacon = GTransLauncher(Weapon).GTransBeacon;
		GTransLauncher(Weapon).GTransBeacon = none;
		GTransLauncher(Weapon).ViewPlayer();
		Instigator.GibbedBy(GTransBeacon.Disruptor);
		GTransBeacon.Destroy();
		bGibMe = false;
	}
}

function DoFireEffect()
{
	if (GTransLauncher(Weapon).GTransBeacon != none)
		Translocate();
}

function bool BotTranslocation()
{
	local Bot B;

	B = Bot(Instigator.Controller);
	if ((B == none) || !B.bPreparingMove || (B.RealTranslocationTarget == none))
		return false;

	return (Instigator.SetLocation(B.RealTranslocationTarget.Location));
}

defaultproperties
{
	TransFailedSound=Sound'WeaponSounds.BaseGunTech.BSeekLost1'
	TransMaterials(0)=Shader'XGameShaders.PlayerShaders.PlayerShieldSh' //'PlayerTransRed'
	TransMaterials(1)=Shader'XGameShaders.PlayerShaders.PlayerShieldSh' //'PlayerTrans'
	bModeExclusive=false
	FireAnim="Recall"
	FireRate=0.250000
	BotRefireRate=0.300000
}