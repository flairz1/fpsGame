class UTComp_FlakShell extends FlakShell;

var vector DecalNormal;

replication
{
	unreliable if (Role == ROLE_Authority)
		DecalNormal;
}

simulated function PostBeginPlay()
{
	SetTimer(0.5, false);
	Super.PostBeginPlay();
}

function Timer()
{
	SetOwner(None);
}

function ProcessTouch(Actor Other, vector HitLocation)
{
	if (Other != Instigator)
	{
		SpawnEffects(HitLocation, -1 * Normal(Velocity));
		Explode(HitLocation, Normal(HitLocation - Other.Location));
	}
}

function Landed(vector HitNormal)
{
	Super.Landed(HitNormal);
}

function Explode(vector HitLocation, vector HitNormal)
{
	local vector Start;
	local rotator Rot;
	local int i;

	Start = Location + 10 * HitNormal;
	if (Level.NetMode != NM_Client)
	{
		HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation);
		for(i = 0; i < 6; i++)
		{
			Rot = Rotation;
			Rot.Yaw += RandRange(-16000, 16000);
			Rot.Pitch += RandRange(-16000, 16000);
			Rot.Roll += RandRange(-16000, 16000);
			Spawn(class'FlakChunk', Instigator, '', Start, Rot);
		}
	}

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
	{
		SpawnEffects(Location, DecalNormal);
		Destroy();
	}
}

defaultproperties
{
	bNetTemporary=false
}