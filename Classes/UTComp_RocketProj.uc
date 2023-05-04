class UTComp_RocketProj extends SeekingRocketProj;

var vector DecalNormal;
var int OwnerHitCountdown;

replication
{
	unreliable if (Role == ROLE_Authority)
		DecalNormal;
}

function Landed(vector HitNormal)
{
	Super.Landed(HitNormal);
}

function ProcessTouch(Actor Other, vector HitLocation)
{
	if ((Other != Instigator) && (Projectile(Other) == None || Other.bProjTarget))
		Explode(HitLocation, -1 * vector(Rotation));
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local PlayerController PC;

	PlaySound(sound'WeaponSounds.BExplosion3',, 2.5 * TransientSoundVolume);
	if (EffectIsRelevant(Location, false))
	{
		Spawn(class'NewExplosionA',,, HitLocation + HitNormal * 20, rotator(HitNormal));
		PC = Level.GetLocalPlayerController();
		if (PC.ViewTarget != None && VSize(PC.ViewTarget.Location - Location) < 5000)
			Spawn(class'ExplosionCrap',,, HitLocation + HitNormal * 20, rotator(HitNormal));
	}

	BlowUp(HitLocation);
	if (Level.NetMode != NM_Client)
	{
		LifeSpan = 0.100000;
		bHidden = true;
		DecalNormal = HitNormal;
		SetLocation(HitLocation);
		NetUpdateTime = Level.TimeSeconds - 1;
		SetPhysics(PHYS_None);
		SetCollision(false, false, false);
		bTearOff = true;
	}
	else
	{
		Destroy();
	}
}

simulated function TornOff()
{
	if (Level.NetMode == NM_Client)
		Explode(Location, DecalNormal);
}

simulated function Timer()
{
	if (OwnerHitCountdown-- <= 0)
		SetOwner(None);

	Super.Timer();
}

defaultproperties
{
	OwnerHitCountdown=5
	bNetTemporary=false
	bUpdateSimulatedPosition=true
}