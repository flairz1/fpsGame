class NewNet_MiniGunFire extends UTComp_MiniGunFire;

var float PingDT;
var bool bUseEnhancedNetCode;

function DoTrace(Vector Start, Rotator Dir)
{
	local Vector X, End, HitLocation, HitNormal, RefNormal;
	local Actor Other;
	local int Damage, ReflectNum;
	local bool bDoReflect;
	local vector PawnHitLocation;

	if (!bUseEnhancedNetCode)
	{
		Super.DoTrace(Start, Dir);
		return;
	}

	MaxRange();
	ReflectNum = 0;

	TimeTravel(PingDT);
	while(true)
	{
		bDoReflect = false;
		X = Vector(Dir);
		End = Start + TraceRange * X;

		if (PingDT <= 0.0)
			Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);
		else
			Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);

		if (Other != None && PawnCollisionCopy(Other) != None)
		{
			PawnHitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
			Other = PawnCollisionCopy(Other).CopiedPawn;
		}
		else
		{
			PawnHitLocation = HitLocation;
		}

		if (Other != None && (Other != Instigator || ReflectNum > 0))
		{
			if (bReflective && xPawn(Other) != None && xPawn(Other).CheckReflect(PawnHitLocation, RefNormal, DamageMin*0.25))
			{
				bDoReflect = true;
				HitNormal = Vect(0,0,0);
			}
			else if (!Other.bWorldGeometry)
			{
				Damage = DamageMin;
				if ((DamageMin != DamageMax) && (FRand() > 0.5))
					Damage += Rand(1 + DamageMax - DamageMin);
				Damage = Damage * DamageAtten;

				// Update hit effect except for pawns (blood) other than vehicles.
				if (Vehicle(Other) != None || (Pawn(Other) == None && HitScanBlockingVolume(Other)!= None))
					WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, PawnHitLocation, HitNormal);

				Other.TakeDamage(Damage, Instigator, PawnHitLocation, Momentum*X, DamageType);
				HitNormal = Vect(0,0,0);
			}
			else if (WeaponAttachment(Weapon.ThirdPersonActor) != None)
			{
				WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, PawnHitLocation, HitNormal);
			}
		}
		else
		{
			HitLocation = End;
			HitNormal = Vect(0,0,0);
			WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, PawnHitLocation, HitNormal);
		}

		SpawnBeamEffect(Start, Dir, HitLocation, HitNormal, ReflectNum);

		if (bDoReflect && ReflectNum++ < 4)
		{
			Start = HitLocation;
			Dir = Rotator(RefNormal);
		}
		else
		{
			break;
		}
	}
	UnTimeTravel();
}

function Actor DoTimeTravelTrace(Out vector Hitlocation, out vector HitNormal, vector End, vector Start)
{
	local Actor Other;
	local bool bFoundPCC;
	local vector NewEnd, WorldHitNormal, WorldHitLocation;
	local vector PCCHitNormal, PCCHitLocation;
	local PawnCollisionCopy PCC, returnPCC;

	//First, lets set the extent of our trace.  End once we hit an actor which won't be checked by an unlagged copy.
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

	if (NewNet_MiniGun(Weapon).M == none)
	{
		foreach Weapon.DynamicActors(class'MutUTComp', NewNet_MiniGun(Weapon).M)
			break;
	}

	for(PCC = NewNet_MiniGun(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TimeTravelPawn(deltaTime);
}

function UnTimeTravel()
{
	local PawnCollisionCopy PCC;

	for(PCC = NewNet_MiniGun(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TurnOffCollision();
}

defaultproperties
{
}