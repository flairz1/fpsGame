class NewNet_SniperFire extends UTComp_SniperFire;

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

function DoClientTrace(Vector Start, Rotator Dir)
{
	local Vector X,Y,Z, End, HitLocation, HitNormal, RefNormal;
	local Actor Other, mainArcHitTarget;
	local int ReflectNum, arcsRemaining;
	local bool bDoReflect;
	local class<Actor> tmpHitEmitClass;
	local float tmpTraceRange;
	local vector arcEnd, mainArcHit;
	local vector EffectOffset;

	if (class'PlayerController'.default.bSmallWeapons)
		EffectOffset = Weapon.SmallEffectOffset;
	else
		EffectOffset = Weapon.EffectOffset;

	Weapon.GetViewAxes(X, Y, Z);
	if (Weapon.WeaponCentered() || SniperRifle(Weapon).Zoomed)
	{
		arcEnd = (Instigator.Location + EffectOffset.Z * Z);
	}
	else if (Weapon.Hand == 0)
	{
		if (class'PlayerController'.default.bSmallWeapons)
			arcEnd = (Instigator.Location + EffectOffset.X * X);
		else
			arcEnd = (Instigator.Location + EffectOffset.X * X - 0.5 * EffectOffset.Z * Z);
	}
	else
	{
		arcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + EffectOffset.X * X + Weapon.Hand * EffectOffset.Y * Y + EffectOffset.Z * Z);
	}

	arcsRemaining = NumArcs;

	tmpHitEmitClass = class'NewNet_Client_LightningBolt';
	tmpTraceRange = TraceRange;

	ReflectNum = 0;
	while(true)
	{
		bDoReflect = false;
		X = Vector(Dir);
		End = Start + tmpTraceRange * X;
		Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);

		if (Other != None && (Other != Instigator || ReflectNum > 0))
		{
			if (bReflective && xPawn(Other) != None && xPawn(Other).CheckReflect(HitLocation, RefNormal, DamageMin*0.25))
			{
				bDoReflect = true;
			}
			else if (Other != mainArcHitTarget)
			{
				if (!Other.bWorldGeometry)
				{
				}
				else
				{
					HitLocation = HitLocation + 2.0 * HitNormal;
				}
			}
		}
		else
		{
			HitLocation = End;
			HitNormal = Normal(Start - End);
		}

		if (Weapon == None)
			return;

		NewNet_SniperRifle(Weapon).SpawnLGEffect(tmpHitEmitClass, arcEnd, HitNormal, HitLocation);

		if (HitScanBlockingVolume(Other) != None)
			return;

		if (arcsRemaining == NumArcs)
		{
			mainArcHit = HitLocation + (HitNormal * 2.0);
			if (Other != None && !Other.bWorldGeometry)
				mainArcHitTarget = Other;
		}

		if (bDoReflect && ReflectNum++ < 4)
		{
			Start = HitLocation;
			Dir = Rotator(X - 2.0*RefNormal*(X dot RefNormal));
		}
		else if (arcsRemaining > 0)
		{
			arcsRemaining--;

			Start = mainArcHit;
			Dir = Rotator(VRand());
			tmpHitEmitClass = SecHitEmitterClass;
			tmpTraceRange = SecTraceDist;
			arcEnd = mainArcHit;
		}
		else
		{
			break;
		}
	}
}

function CheckFireEffect()
{
	if (Level.NetMode == NM_Client && Instigator.IsLocallyControlled())
		DoFireEffect();
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

function DoTrace(Vector Start, Rotator Dir)
{
	local Vector X,Y,Z, End, HitLocation, HitNormal, RefNormal;
	local Actor Other, AltOther, mainArcHitTarget;
	local int Damage, ReflectNum, arcsRemaining;
	local bool bDoReflect;
	local xEmitter HitEmitter;
	local class<Actor> tmpHitEmitClass;
	local float f, tmpTraceRange;
	local vector arcEnd, mainArcHit;
	local Pawn HeadShotPawn;
	local vector EffectOffset, PawnHitLocation;
	local vector AltHitlocation, AltHitNormal, AltPawnHitLocation;

	if (!bUseEnhancedNetCode)
	{
		Super.DoTrace(Start, Dir);
		return;
	}

	if (class'PlayerController'.default.bSmallWeapons)
		EffectOffset = Weapon.SmallEffectOffset;
	else
		EffectOffset = Weapon.EffectOffset;

	Weapon.GetViewAxes(X, Y, Z);
	if (Level.NetMode == NM_DedicatedServer)
	{
		arcEnd = (Instigator.Location + Instigator.BaseEyeHeight * vect(0,0,1) + EffectOffset.Z * Z + EffectOffset.Y * Y + EffectOffset.X * X);
	}
	else
	{
		if (Weapon.WeaponCentered() || SniperRifle(Weapon).Zoomed)
		{
			arcEnd = (Instigator.Location + EffectOffset.Z * Z);
		}
		else if (Weapon.Hand == 0)
		{
			if (class'PlayerController'.default.bSmallWeapons)
				arcEnd = (Instigator.Location + EffectOffset.X * X);
			else
				arcEnd = (Instigator.Location + EffectOffset.X * X - 0.5 * EffectOffset.Z * Z);
		}
		else
		{
			arcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + EffectOffset.X * X + Weapon.Hand * EffectOffset.Y * Y + EffectOffset.Z * Z);
		}
	}

	arcsRemaining = NumArcs;

	tmpHitEmitClass = class'NewNet_NewLightningBolt';
	tmpTraceRange = TraceRange;

	ReflectNum = 0;

	TimeTravel(PingDT);
	while(true)
	{
		bDoReflect = false;
		X = Vector(Dir);
		End = Start + tmpTraceRange * X;

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
			if (ArcsRemaining == NumArcs)
			{
				f = 0.02;
				while(abs(f) < (0.04 + 2.0*AverDT))
				{

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
						AltPawnHitLocation=AltHitLocation;
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
			if (ArcsRemaining == NumArcs)
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
						AltPAwnHitLocation = AltHitLocation;
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
		if (Other != None && (Other != Instigator || ReflectNum > 0))
		{
			if (bReflective && xPawn(Other) != None && xPawn(Other).CheckReflect(PawnHitLocation, RefNormal, DamageMin*0.25))
			{
				bDoReflect = true;
			}
			else if (Other != mainArcHitTarget)
			{
				if (!Other.bWorldGeometry)
				{
					Damage = (DamageMin + Rand(DamageMax - DamageMin)) * DamageAtten;

					if (Vehicle(Other) != None)
						HeadShotPawn = Vehicle(Other).CheckForHeadShot(PawnHitLocation, X, 1.0);

					if (HeadShotPawn != None)
						HeadShotPawn.TakeDamage(Damage * HeadShotDamageMult, Instigator, PawnHitLocation, Momentum*X, DamageTypeHeadShot);
					else if ((Pawn(Other) != None) && (arcsRemaining == NumArcs) && Pawn(Other).IsHeadShot(PawnHitLocation, X, 1.0))
						Other.TakeDamage(Damage * HeadShotDamageMult, Instigator, PawnHitLocation, Momentum*X, DamageTypeHeadShot);
					else
					{
						if (arcsRemaining < NumArcs)
							Damage *= SecDamageMult;
						Other.TakeDamage(Damage, Instigator, PawnHitLocation, Momentum*X, DamageType);
					}
				}
				else
				{
					HitLocation = HitLocation + 2.0 * HitNormal;
				}
			}
		}
		else
		{
			HitLocation = End;
			HitNormal = Normal(Start - End);
		}

		if (Weapon == None)
			return;
		HitEmitter = xEmitter(Weapon.Spawn(tmpHitEmitClass,,, arcEnd, Rotator(HitNormal)));
		if (HitEmitter != None)
			HitEmitter.mSpawnVecA = HitLocation;

		if (HitScanBlockingVolume(Other) != None)
		{
			UnTimeTravel();
			return;
		}

		if (arcsRemaining == NumArcs)
		{
			mainArcHit = HitLocation + (HitNormal * 2.0);
			if (Other != None && !Other.bWorldGeometry)
				mainArcHitTarget = Other;
		}

		if (bDoReflect && ReflectNum++ < 4)
		{
			Start = HitLocation;
			Dir = Rotator(X - 2.0*RefNormal*(X dot RefNormal));
		}
		else if (arcsRemaining > 0)
		{
			arcsRemaining--;

			// done parent arc, now move trace point to arc trace hit location and try child arcs from there
			Start = mainArcHit;
			Dir = Rotator(VRand());
			tmpHitEmitClass = class'NewNet_ChildLightningBolt';
			tmpTraceRange = SecTraceDist;
			arcEnd = mainArcHit;
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

	if (NewNet_SniperRifle(Weapon).M == none)
	{
		foreach Weapon.DynamicActors(class'MutUTComp', NewNet_SniperRifle(Weapon).M)
			break;
	}

	for(PCC = NewNet_SniperRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TimeTravelPawn(deltaTime);
}

function UnTimeTravel()
{
	local PawnCollisionCopy PCC;

	for(PCC = NewNet_SniperRifle(Weapon).M.PCC; PCC != None; PCC = PCC.Next)
		PCC.TurnOffCollision();
}

defaultproperties
{
}