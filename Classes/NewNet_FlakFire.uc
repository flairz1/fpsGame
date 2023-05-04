class NewNet_FlakFire extends UTComp_FlakFire;

var float PingDT;
var bool bUseEnhancedNetCode;

var bool bUseReplicatedInfo;
var rotator savedRot;
var vector savedVec;

var vector OldInstigatorLocation;
var Vector OldInstigatorEyePosition;
var vector OldXAxis, OldYAxis, OldZAxis;
var rotator OldAim;

var class<Projectile> FakeProjectileClass;
var FakeProjectileManager FPM;
var MutUTComp MNN;
var bool bSkipNextEffect;

const PROJ_TIMESTEP = 0.0251;
const MAX_PROJECTILE_FUDGE = 0.075;
const SLACK = 0.035;

function PlayFiring()
{
	Super.PlayFiring();

	if (Level.NetMode != NM_Client || !BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
		return;

	if (!bSkipNextEffect)
	{
		CheckFireEffect();
	}
	else
	{
		bSkipNextEffect = false;
		Weapon.ClientStopFire(0);
	}
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

function DoInstantFireEffect()
{
	CheckFireEffect();
	bSkipNextEffect = true;
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
	//Weapon.GetViewAxes(X,Y,Z);
	X = OldXAxis;
	Y = OldXAxis;
	Z = OldXAxis;

	// StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
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
				R = NewNet_FlakCannon(Weapon).GetRandRot();
				if (FPM == None)
					FindFPM();
				if (FPM.AllowFakeProjectile(FakeProjectileClass, p))
					FPM.RegisterFakeProjectile(FlakChunk(SpawnFakeProjectile(StartProj, Rotator(X >> R))), p);
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

simulated function DoClientFireEffect()
{
	local Vector StartProj, StartTrace, X, Y, Z;
	local Rotator R, Aim;
	local Vector HitLocation, HitNormal;
	local Actor Other;
	local int p, SpawnCount;
	local float theta;

	Instigator.MakeNoise(1.0);
	Weapon.GetViewAxes(X,Y,Z);

	StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
	StartProj = StartTrace + X*ProjSpawnOffset.X;
	if (!Weapon.WeaponCentered())
		StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

	// check if projectile would spawn through a wall and adjust start location accordingly
	Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
	if (Other != None)
		StartProj = HitLocation;

	Aim = AdjustAim(StartProj, AimError);

	SpawnCount = Max(1, ProjPerFire * int(Load));
	switch(SpreadStyle)
	{
		case SS_Random:
			X = Vector(Aim);
			for(p = 0; p < SpawnCount; p++)
			{
				R = NewNet_FlakCannon(Weapon).GetRandRot();
				if (FPM == None)
					FindFPM();
				if (FPM.AllowFakeProjectile(FakeProjectileClass, p))
					FPM.RegisterFakeProjectile(FlakChunk(SpawnFakeProjectile(StartProj, Rotator(X >> R))), p);
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

	p = FakeSuperSpawnProjectile(Start, Dir);
	return p;
}

simulated function Projectile FakeSuperSpawnProjectile(Vector Start, Rotator Dir)
{
	local Projectile p;

	if (ProjectileClass != None)
		p = Weapon.Spawn(FakeProjectileClass,,, Start, Dir);

	if (p == none)
		return None;

	p.Damage *= DamageAtten;
	return p;
}

simulated function FindFPM()
{
	foreach Weapon.DynamicActors(class'FakeProjectileManager', FPM)
		break;
}

function DoFireEffect()
{
	local Vector StartProj, StartTrace, X, Y, Z;
	local Rotator R, Aim;
	local Vector HitLocation, HitNormal;
	local Actor Other;
	local int p, SpawnCount;
	local float theta;
	local Projectile proj;

	if (!bUseEnhancedNetCode)
	{
		Super.DoFireEffect();
		return;
	}

	Instigator.MakeNoise(1.0);
	Weapon.GetViewAxes(X,Y,Z);

	if (bUseReplicatedInfo)
		StartTrace = SavedVec;
	else
		StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;

	StartProj = StartTrace + X*ProjSpawnOffset.X;
	if (!Weapon.WeaponCentered())
		StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

	// check if projectile would spawn through a wall and adjust start location accordingly
	if (Weapon.Owner != None)
		Other = Weapon.Owner.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
	else
		Other=Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);

	if (Other != None)
		StartProj = HitLocation;

	if (bUseReplicatedInfo)
	{
		Aim = SavedRot;
		bUseReplicatedInfo = false;
	}
	else
	{
		Aim = AdjustAim(StartProj, AimError);
	}

	SpawnCount = Max(1, ProjPerFire * int(Load));
	switch(SpreadStyle)
	{
		case SS_Random:
			X = Vector(Aim);
			for(p = 0; p < SpawnCount; p++)
			{
				R = NewNet_FlakCannon(Weapon).GetRandRot();
				proj = SpawnProjectile(StartProj, Rotator(X >> R));
				if (proj != None)
					NewNet_FlakChunk(proj).ChunkNum = p;
			}
			break;
		case SS_Line:
			for(p = 0; p < SpawnCount; p++)
			{
				theta = Spread*PI/32768*(p - float(SpawnCount-1)/2.0);
				X.X = Cos(theta);
				X.Y = Sin(theta);
				X.Z = 0.0;
				SpawnProjectile(StartProj, Rotator(X >> Aim));
			}
			break;
		default:
			SpawnProjectile(StartProj, Aim);
	}
	NewNet_FlakCannon(Weapon).SendNewRandSeed();
}

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local Projectile p;
	local vector End, HitNormal, HitLocation;
	local Actor Other;
	local float f, g;

	if (!bUseEnhancedNetCode)
		return Super.SpawnProjectile(Start, Dir);

	if (ProjectileClass != None)
	{
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
				p = Weapon.Spawn(ProjectileClass,,, End, Dir);
			else
				p = Weapon.Spawn(ProjectileClass,,, HitLocation - Vector(dir)*20.0, Dir);
		}
		else
		{
			p = Weapon.Spawn(ProjectileClass,,, Start, Dir);
		}
	}

	if (p == None)
		return None;

	p.Damage *= DamageAtten;
	return p;
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
		NewEnd=WorldHitlocation;
	else
		NewEnd=End;

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

	if (NewNet_FlakCannon(Weapon).M == none)
	{
		foreach Weapon.DynamicActors(class'MutUTComp', NewNet_FlakCannon(Weapon).M)
			break;
	}

	for(PCC = NewNet_FlakCannon(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TimeTravelPawn(deltaTime);
}

function UnTimeTravel()
{
	local PawnCollisionCopy PCC;

	for(PCC = NewNet_FlakCannon(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TurnOffCollision();
}

defaultproperties
{
	FakeProjectileClass=class'NewNet_Fake_FlakChunk'
	ProjectileClass=class'NewNet_FlakChunk'
}