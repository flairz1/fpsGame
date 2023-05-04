class NewNet_BioChargedFire extends UTComp_BioChargedFire;

var float PingDT;
var bool bUseEnhancedNetCode;

const PROJ_TIMESTEP = 0.0201;
const MAX_PROJECTILE_FUDGE = 0.07500;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local rotator NewDir, OutDir;
	local float f, g;
	local vector End, HitLocation, HitNormal, VZ;
	local Actor Other;
	local BioGlob Glob;

	GotoState('');

	if (GoopLoad == 0)
		return None;

	if (!bUseEnhancedNetCode)
		return Super.SpawnProjectile(Start, Dir);

	if (class'BioGlob' != none)
	{
		if (PingDT > 0.0 && Weapon.Owner != None)
		{
			OutDir = Dir;
			for(f = 0.00; f < PingDT + PROJ_TIMESTEP; f += PROJ_TIMESTEP)
			{
				g = FMin(PingDT, f);

				End = Start + NewExtrapolate(Dir, g, OutDir, GoopLoad);

				TimeTravel(PingDT - g);
				//Trace between the start and extrapolated end
				Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);
				if (Other != None)
					break;
			}
			UnTimeTravel();

			if (Other != None && PawnCollisionCopy(Other) != None)
			{
				HitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
				Other = PawnCollisionCopy(Other).CopiedPawn;
			}

			VZ.Z = class'BioGlob'.default.TossZ;
			NewDir =  rotator(vector(OutDir)*class'BioGlob'.default.speed - VZ);
			if (Other == none)
				glob = Weapon.Spawn(class'BioGlob',,, End, NewDir);
			else
				glob = Weapon.Spawn(class'BioGlob',,, HitLocation - Vector(Newdir)*16.0, NewDir);
		}
		else
		{
			glob = Weapon.Spawn(class'BioGlob',,, Start, Dir);
		}
	}

	if (Glob != None)
	{
		Glob.Damage *= DamageAtten;
		Glob.SetGoopLevel(GoopLoad);
		Glob.AdjustSpeed();
	}
	GoopLoad = 0;

	if (Weapon.AmmoAmount(ThisModeNum) <= 0)
		Weapon.OutOfAmmo();

	return Glob;
}

function vector NewExtrapolate(rotator Dir, float dF, out rotator OutDir, byte GoopLoad)
{
	local vector V, Pos;
	local float GooSpeed;

	if (GoopLoad < 1)
		GooSpeed =  class'BioGlob'.default.speed;
	else
		GooSpeed =  class'BioGlob'.default.speed * (0.4 + GoopLoad)/(1.4*GoopLoad);

	V = vector(Dir)*GooSpeed;
	V.Z += ProjectileClass.default.TossZ;

	Pos = V*dF + 0.5*square(dF)*Weapon.Owner.PhysicsVolume.Gravity;
	OutDir = rotator(V + dF*Weapon.Owner.PhysicsVolume.Gravity);
	return Pos;
}

function vector Extrapolate(out rotator Dir, float dF, byte GoopLoad)
{
	local rotator OldDir;
	local float GooSpeed;

	OldDir = Dir;

	if (GoopLoad < 1)
		GooSpeed =  class'BioGlob'.default.speed;
	else
		GooSpeed =  class'BioGlob'.default.speed * (0.4 + GoopLoad)/(1.4*GoopLoad);

	Dir = rotator(vector(OldDir)*Goospeed + Weapon.Owner.PhysicsVolume.Gravity*dF);

	return vector(OldDir)*Goospeed*dF + 0.5*Square(dF)*Weapon.Owner.PhysicsVolume.Gravity;
}

function Actor DoTimeTravelTrace(Out vector Hitlocation, out vector HitNormal, vector End, vector Start)
{
	local Actor Other;
	local bool bFoundPCC;
	local vector NewEnd, WorldHitNormal,WorldHitLocation;
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

	if (NewNet_BioRifle(Weapon).M == none)
	{
		foreach Weapon.DynamicActors(class'MutUTComp',NewNet_BioRifle(Weapon).M)
			break;
	}

	for(PCC = NewNet_BioRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TimeTravelPawn(deltaTime);
}

function UnTimeTravel()
{
	local PawnCollisionCopy PCC;

	for(PCC = NewNet_BioRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TurnOffCollision();
}

defaultproperties
{
}