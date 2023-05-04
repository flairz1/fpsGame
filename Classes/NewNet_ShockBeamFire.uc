class NewNet_ShockBeamFire extends UTComp_ShockBeamFire;

var bool bUseReplicatedInfo;
var rotator SavedRot;
var vector SavedVec;

var float PingDT;
var bool bSkipNextEffect;
var bool bUseEnhancedNetCode;
var bool bBelievesHit;
var Actor BelievedHitActor;
var vector BelievedHitLocation;
var float AverDT;
var bool bFirstGo;

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
		DoFireEffect();
}

function DoTrace(Vector Start, Rotator Dir)
{
	local Vector X, End, HitLocation, HitNormal, RefNormal;
	local Actor Other, AltOther;
	local int Damage, ReflectNum;
	local bool bDoReflect;
	local vector PawnHitLocation;
	local vector AltHitlocation,altHitNormal,altPawnHitLocation;
	local float f;

	if (!bUseEnhancedNetCode)
	{
		Super.DoTrace(Start, Dir);
		return;
	}

	MaxRange();
	ReflectNum = 0;
	while(true)
	{
		TimeTravel(PingDT);
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

		if (bFirstGo && bBelievesHit && !(Other == BelievedHitActor))
		{
			if (ReflectNum == 0)
			{
				f = 0.02;
				while(abs(f) < (0.04 + 2.0*AverDT))
				{
					TimeTravel(PingDT-f);
					if ((PingDT - f) <= 0.0)
						AltOther = Weapon.Trace(AltHitLocation, AltHitNormal, End, Start, true);
					else
						AltOther = DoTimeTravelTrace(AltHitLocation, AltHitNormal, End, Start);

					if (AltOther != None && PawnCollisionCopy(AltOther) != None)
					{
						AltPawnHitLocation = AltHitLocation + PawnCollisionCopy(AltOther).CopiedPawn.Location - AltOther.Location;
						AltOther = PawnCollisionCopy(AltOther).CopiedPawn;
					}
					else
					{
						AltPawnHitLocation = AltHitLocation;
					}

					if (AltOther == BelievedHitACtor)
					{
						Other = AltOther;
						PawnHitLocation = AltPawnHitLocation;
						HitLocation = AltHitLocation;
						f = 10.0;
					}
					if (f > 0.00)
						f = -1.0*f;
					else
						f = -1.0*f + 0.02;
				}
			}
		}
		else if (bFirstGo && !bBelievesHit && Other != None && (xPawn(Other) != None || Vehicle(Other) != None))
		{
			if (ReflectNum == 0)
			{
				f = 0.02;
				while(abs(f) < (0.04 + 2.0*AverDT))
				{
					AltOther = None;
					TimeTravel(PingDT - f);
					if ((PingDT - f) <= 0.0)
						AltOther = Weapon.Trace(AltHitLocation, AltHitNormal, End, Start, true);
					else
						AltOther = DoTimeTravelTrace(AltHitLocation, AltHitNormal, End, Start);

					if (AltOther != None && PawnCollisionCopy(AltOther) != None)
					{
						AltPawnHitLocation = AltHitLocation + PawnCollisionCopy(AltOther).CopiedPawn.Location - AltOther.Location;
						AltOther = PawnCollisionCopy(AltOther).CopiedPawn;
					}
					else
					{
						AltPawnHitLocation = AltHitLocation;
					}

					if (AltOther == None || (xPawn(AltOther) == None || Vehicle(AltOther) == None))
					{
						Other = AltOther;
						PawnHitLocation = AltPawnHitLocation;
						HitLocation = AltHitLocation;
						f = 10.0;
					}

					if (f > 0.00)
						f = -1.0*f;
					else
						f = -1.0*f + 0.02;
				}
			}
		}
		bFirstGo = false;
		UnTimeTravel();

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
				if (Vehicle(Other) != None || (Pawn(Other) == None && HitScanBlockingVolume(Other) == None))
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
}

function DoInstantFireEffect()
{
	if (Level.NetMode == NM_Client && Instigator.IsLocallyControlled())
	{
		DoFireEffect();
		bSkipNextEffect = true;
	}
}

function DoFireEffect()
{
	local Vector StartTrace;
	local Rotator R, Aim;

	if (!bUseEnhancedNetCode && Level.NetMode != NM_Client)
	{
		Super.DoFireEffect();
		return;
	}

	Instigator.MakeNoise(1.0);

	if (bUseReplicatedInfo)
	{
		StartTrace = SavedVec;
		R = SavedRot;
		bUseReplicatedInfo = false;
	}
	else
	{
		StartTrace = Instigator.Location + Instigator.EyePosition();
		Aim = AdjustAim(StartTrace, AimError);
		R = rotator(vector(Aim) + VRand()*FRand()*Spread);
	}

	if (Level.NetMode == NM_Client)
		DoClientTrace(StartTrace, R);
	else
		DoTrace(StartTrace, R);
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

	if (NewNet_ShockRifle(Weapon).M == none)
	{
		foreach Weapon.DynamicActors(class'MutUTComp', NewNet_ShockRifle(Weapon).M)
			break;
	}

	for(PCC = NewNet_ShockRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TimeTravelPawn(deltaTime);
}

function UnTimeTravel()
{
	local PawnCollisionCopy PCC;

	for(PCC = NewNet_ShockRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TurnOffCollision();
}

simulated function DoClientTrace(Vector Start, Rotator Dir)
{
	local Vector X, End, HitLocation, HitNormal, RefNormal;
	local Actor Other;
	local bool bDoReflect;
	local int ReflectNum;

	MaxRange();
	ReflectNum = 0;
	while(true)
	{
		bDoReflect = false;
		X = Vector(Dir);
		End = Start + TraceRange * X;

		Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);
		if (Other != None && (Other != Instigator || ReflectNum > 0))
		{
			if (bReflective && xPawn(Other) != None && xPawn(Other).CheckReflect(HitLocation, RefNormal, DamageMin*0.25))
			{
				bDoReflect = true;
				HitNormal = Vect(0,0,0);
			}
			else if (!Other.bWorldGeometry)
			{
				// Update hit effect except for pawns (blood) other than vehicles.
				if (Vehicle(Other) != None || (Pawn(Other) == None && HitScanBlockingVolume(Other) == None))
					WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, HitLocation, HitNormal);

				HitNormal = Vect(0,0,0);
			}
			else if (WeaponAttachment(Weapon.ThirdPersonActor) != None)
			{
				WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, HitLocation, HitNormal);
			}
		}
		else
		{
			HitLocation = End;
			HitNormal = Vect(0,0,0);
			WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, HitLocation, HitNormal);
		}

		SpawnClientBeamEffect(Start, Dir, HitLocation, HitNormal, ReflectNum);

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
}

simulated function SpawnClientBeamEffect(Vector Start, Rotator Dir, Vector HitLocation, Vector HitNormal, int ReflectNum)
{
	NewNet_ShockRifle(Weapon).SpawnBeamEffect(HitLocation, HitNormal, Start, Dir, ReflectNum);
}

function SpawnBeamEffect(Vector Start, Rotator Dir, Vector HitLocation, Vector HitNormal, int ReflectNum)
{
	local ShockBeamEffect Beam;

	if (!bUseEnhancedNetCode)
	{
		if (Weapon != None)
		{
			Beam = Weapon.Spawn(Class'XWeapons.ShockBeamEffect',,, Start, Dir);
			if (ReflectNum != 0)
				Beam.Instigator = None;
			Beam.AimAt(HitLocation, HitNormal);
		}
		return;
	}

	if (Weapon != None)
	{
		Beam = Weapon.Spawn(BeamEffectClass,Weapon.Owner,, Start, Dir);
		if (ReflectNum != 0)
			Beam.Instigator = None;
		Beam.AimAt(HitLocation, HitNormal);
	}
}

defaultproperties
{
	BeamEffectClass=class'NewNet_ShockBeamEffect'
}