class NewNet_LinkAltFire extends UTComp_LinkAltFire;

var float PingDT;
var bool bUseEnhancedNetCode;

const PROJ_TIMESTEP = 0.0201;
const MAX_PROJECTILE_FUDGE = 0.075;
const SLACK = 0.025;

var class<Projectile> FakeProjectileClass;
var FakeProjectileManager FPM;

var vector OldInstigatorLocation;
var Vector OldInstigatorEyePosition;
var vector OldXAxis, OldYAxis, OldZAxis;
var rotator OldAim;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local LinkProjectile Proj;
	local vector HitLocation, HitNormal, End;
	local Actor Other;
	local UTComp_PRI uPRI;
	local float f, g;

	if (Level.NetMode == NM_Client && BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
		return SpawnFakeProjectile(Start, Dir);

	if (!bUseEnhancedNetCode)
		return Super.SpawnProjectile(Start, Dir);

	if (xPawn(Weapon.Owner) != None && xPawn(Weapon.Owner).Controller != None)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
		if (uPRI != None)
			uPRI.NormalWepStatsPrim[9] += 1;
	}

	Start += Vector(Dir) * 10.0 * LinkGun(Weapon).Links;
	if (PingDT > 0.0 && Weapon.Owner != None)
	{
		Start -= 1.0*vector(Dir);
		for(f = 0.00; f < PingDT + PROJ_TIMESTEP; f += PROJ_TIMESTEP)
		{
			g = FMin(PingDT, f);
			//Where will it be after deltaF, Dir byRef for next tick
			if (f >= PingDT)
				End = Start + Extrapolate(Dir, (PingDT - f + PROJ_TIMESTEP));
			else
				End = Start + Extrapolate(Dir, PROJ_TIMESTEP);
			//Put pawns there
			TimeTravel(PingDT - g);
			//Trace between the start and extrapolated end
			Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);
			if (Other != None)
			{
				break;
			}
			Start = End;
		}
		UnTimeTravel();

		if (Other != None && PawnCollisionCopy(Other) != None)
		{
			HitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
			Other = PawnCollisionCopy(Other).CopiedPawn;
		}

		if (Other == none)
		{
			Proj = Weapon.Spawn(class'NewNet_LinkProjectile',,, End, Dir);
		}
		else
		{
			Proj = Weapon.Spawn(class'NewNet_LinkProjectile',,, HitLocation - Vector(dir)*20.0, Dir);
			NewNet_LinkGun(Weapon).DispatchClientEffect(HitLocation - Vector(dir)*20.0, Dir);
		}
	}
	else
	{
		Proj = Weapon.Spawn(class'NewNet_LinkProjectile',,, Start, Dir);
	}

	if (Proj != None)
	{
		Proj.Links = LinkGun(Weapon).Links;
		Proj.LinkAdjust();
	}

	if (NewNet_LinkProjectile(Proj) != None)
	{
		NewNet_LinkProjectile(Proj).Index = NewNet_LinkGun(Weapon).CurIndex;
		NewNet_LinkGun(Weapon).CurIndex++;
	}

	return Proj;
}

function vector Extrapolate(out rotator Dir, float dF)
{
	return vector(Dir)*ProjectileClass.default.speed*dF;
}

function Actor DoTimeTravelTrace(Out vector Hitlocation, out vector HitNormal, vector End, vector Start)
{
	local Actor Other;
	local bool bFoundPCC;
	local vector NewEnd, WorldHitNormal, WorldHitLocation;
	local vector PCCHitNormal, PCCHitLocation;
	local PawnCollisionCopy PCC, returnPCC;

	foreach Weapon.TraceActors(class'Actor', Other, WorldHitLocation, WorldHitNormal, End, Start)
	{
		if ((Other.bBlockActors || Other.bProjTarget || Other.bWorldGeometry) && !class'MutUTComp'.static.IsPredicted(Other))
		{
			break;
		}
		Other = None;
	}

	if (Other != None)
		NewEnd = WorldHitlocation;
	else
		NewEnd = End;

	//Now, lets see if we run into any copies, we stop at the location determined by the previous trace.
	foreach Weapon.TraceActors(class'PawnCollisionCopy', PCC, PCCHitLocation, PCCHitNormal, NewEnd, Start)
	{
		if (PCC != None && PCC.CopiedPawn != None && PCC.CopiedPawn != Instigator)
		{
			bFoundPCC = true;
			returnPCC = PCC;
			break;
		}
	}

	// Give back the corresponding info depending on whether or not we found a copy
	if (bFoundPCC)
	{
		HitLocation = PCCHitLocation;
		HitNormal = PCCHitNormal;
		return returnPCC;
	}
	else
	{
		HitLocation = WorldHitLocation;
		HitNormal = WorldHitNormal;
		return Other;
	}
}

function TimeTravel(float deltaTime)
{
	local PawnCollisionCopy PCC;

	if (NewNet_LinkGun(Weapon).M == none)
	{
		foreach Weapon.DynamicActors(class'MutUTComp',NewNet_FlakCannon(Weapon).M)
			break;
	}

	for(PCC = NewNet_LinkGun(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TimeTravelPawn(deltaTime);
}

function UnTimeTravel()
{
	local PawnCollisionCopy PCC;

	for(PCC = NewNet_LinkGun(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TurnOffCollision();
}

function CheckFireEffect()
{
	if (Level.NetMode == NM_Client && Instigator.IsLocallyControlled())
	{
		if (class'NewNet_PRI'.default.PredictedPing - SLACK > MAX_PROJECTILE_FUDGE)
		{
			OldInstigatorLocation = Instigator.Location;
			OldInstigatorEyePosition = Instigator.EyePosition();
			Weapon.GetViewAxes(OldXAxis, OldYAxis, OldZAxis);
			OldAim = AdjustAim(OldInstigatorLocation + OldInstigatorEyePosition, AimError);
			SetTimer(class'NewNet_PRI'.default.PredictedPing - SLACK - MAX_PROJECTILE_FUDGE, false);
		}
		else
		{
			DoClientFireEffect();
		}
	}
}

function Timer()
{
	DoTimedClientFireEffect();
}

function PlayFiring()
{
	Super.PlayFiring();

	if (Level.NetMode != NM_Client || !BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
		return;

	CheckFireEffect();
}

function DoClientFireEffect()
{
	Super.DoFireEffect();
}

simulated function DoTimedClientFireEffect()
{
	local Vector StartProj, StartTrace, X, Y, Z;
	local Rotator R, Aim;
	local Vector HitLocation, HitNormal;
	local Actor Other;
	local int p, SpawnCount;
	local float theta;

	Instigator.MakeNoise(1.0);
	// Weapon.GetViewAxes(X,Y,Z);
	X = OldXAxis;
	Y = OldXAxis;
	Z = OldXAxis;

	//  StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
	StartTrace = OldInstigatorLocation + OldInstigatorEyePosition;

	StartProj = StartTrace + X*ProjSpawnOffset.X;
	if (!Weapon.WeaponCentered())
		StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

	// check if projectile would spawn through a wall and adjust start location accordingly
	Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
	if (Other != None)
		StartProj = HitLocation;

	// Aim = AdjustAim(StartProj, AimError);
	Aim = OldAim;

	SpawnCount = Max(1, ProjPerFire * int(Load));
	switch(SpreadStyle)
	{
		case SS_Random:
			X = Vector(Aim);
			for(p = 0; p < SpawnCount; p++)
			{
				R.Yaw = Spread * (FRand()-0.5);
				R.Pitch = Spread * (FRand()-0.5);
				R.Roll = Spread * (FRand()-0.5);
				SpawnFakeProjectile(StartProj, Rotator(X >> R));
			}
			break;
		case SS_Line:
			for(p = 0; p < SpawnCount; p++)
			{
				theta = Spread*PI/32768*(p - float(SpawnCount-1)/2.0);
				X.X = Cos(theta);
				X.Y = Sin(theta);
				X.Z = 0.0;
				SpawnFakeProjectile(StartProj, Rotator(X >> Aim));
			}
			break;
		default:
			SpawnFakeProjectile(StartProj, Aim);
	}
}

simulated function Projectile SpawnFakeProjectile(Vector Start, Rotator Dir)
{
	local Projectile p;

	if (FPM == None)
		FindFPM();

	if (FPM.AllowFakeProjectile(FakeProjectileClass, NewNet_LinkGun(Weapon).CurIndex) && class'NewNet_PRI'.default.PredictedPing >= 0.050)
		p = Spawn(FakeProjectileClass,Weapon.Owner,, Start, Dir);

	if (p == none)
		return None;

	FPM.RegisterFakeProjectile(p, NewNet_LinkGun(Weapon).CurIndex);
	return p;
}

simulated function FindFPM()
{
	foreach Weapon.DynamicActors(class'FakeProjectileManager', FPM)
		break;
}

defaultproperties
{
	FakeProjectileClass=class'NewNet_Fake_LinkProjectile'
	ProjectileClass=class'NewNet_LinkProjectile'
}