class NewNet_AssaultGrenade extends UTComp_AssaultGrenade;

var float PingDT;
var bool bUseEnhancedNetCode;

const PROJ_TIMESTEP = 0.0201;
const MAX_PROJECTILE_FUDGE = 0.0750;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local Grenade g;
	local vector X, Y, Z, Velocity;
	local float h, f, pawnSpeed, Speed;
	local rotator NewDir, OutDir;
	local Actor Other;
	local vector HitNormal, HitLocation, End;

	if (!bUseEnhancedNetCode)
		return Super.SpawnProjectile(Start, Dir);

	Weapon.GetViewAxes(X,Y,Z);
	pawnSpeed = X dot Instigator.Velocity;
	if (Bot(Instigator.Controller) != None)
		Speed = mHoldSpeedMax;
	else
		Speed = mHoldSpeedMin + HoldTime*mHoldSpeedGainPerSec;

	Speed = FClamp(Speed, mHoldSpeedMin, mHoldSpeedMax);
	Speed = pawnSpeed + Speed;
	Velocity = Speed * Vector(Dir);
	if (PingDT > 0.0 && Weapon.Owner != None)
	{
		OutDir = Dir;
		for(f = 0.00; f < PingDT + PROJ_TIMESTEP; f += PROJ_TIMESTEP)
		{
			h = FMin(PingDT, f);

			End = Start + NewExtrapolate(Dir, h, OutDir);
			TimeTravel(PingDT - h);
			//Trace between the start and extrapolated end
			Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);
			if (Other != None)
			{
				break;
			}
		}
		UnTimeTravel();

		if (Other != None && PawnCollisionCopy(Other) != None)
		{
			HitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
			Other = PawnCollisionCopy(Other).CopiedPawn;
		}

		Velocity = Speed * Vector(OutDir);
		if (Other == none)
			g = Grenade(Weapon.Spawn(ProjectileClass,,, End, NewDir));
		else
			g = Grenade(Weapon.Spawn(ProjectileClass,,, HitLocation - Vector(Newdir)*16.0, NewDir));
	}
	else
	{
		g = Grenade(Weapon.Spawn(ProjectileClass, instigator,, Start, Dir));
	}

	if (g == None)
		return none;

	g.Speed = Speed;
	g.Velocity = Velocity;
	g.Damage *= DamageAtten;

	return g;
}

function vector NewExtrapolate(rotator Dir, float dF, out rotator OutDir)
{
	local vector V, Pos;

	V = vector(Dir) * ProjectileClass.default.speed;
	V.Z += ProjectileClass.default.TossZ;

	Pos = V*dF + 0.5*square(dF)*Weapon.Owner.PhysicsVolume.Gravity;
	OutDir = rotator(V + dF*Weapon.Owner.PhysicsVolume.Gravity);
	return Pos;
}

function vector Extrapolate(out rotator Dir, float dF, float Speed)
{
	local rotator OldDir;

	OldDir = Dir;
	Dir = rotator(vector(OldDir)*speed + Weapon.Owner.PhysicsVolume.Gravity*dF);

	return vector(OldDir)*speed*dF + 0.5*Square(dF)*Weapon.Owner.PhysicsVolume.Gravity;
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

	if (NewNet_AssaultRifle(Weapon).M == none)
	{
		foreach Weapon.DynamicActors(class'MutUTComp', NewNet_AssaultRifle(Weapon).M)
			break;
	}

	for(PCC = NewNet_AssaultRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TimeTravelPawn(deltaTime);
}

function UnTimeTravel()
{
	local PawnCollisionCopy PCC;

	for(PCC = NewNet_AssaultRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TurnOffCollision();
}

defaultproperties
{
}