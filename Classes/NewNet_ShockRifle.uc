class NewNet_ShockRifle extends UTComp_ShockRifle
	HideDropDown
	CacheExempt
	Config(fpsGameClient);

var TimeStamp_Pawn T;
var MutUTComp M;
var float LastDT;

struct ReplicatedRotator
{
	var int Yaw;
	var int Pitch;
};

struct ReplicatedVector
{
	var float X;
	var float Y;
	var float Z;
};

replication
{
	reliable if (Role < ROLE_Authority)
		NewNet_ServerStartFire, NewNet_OldServerStartFire;

	unreliable if (bDemoRecording)
		SpawnBeamEffect;
}

function DisableNet()
{
	NewNet_ShockBeamFire(FireMode[0]).bUseEnhancedNetCode = false;
	NewNet_ShockBeamFire(FireMode[0]).PingDT = 0.00;
}

simulated event ClientStartFire(int Mode)
{
	if (Level.NetMode != NM_Client || !BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet() || NewNet_ShockBeamFire(FireMode[Mode]) == None)
		Super.ClientStartFire(Mode);
	else
		NewNet_ClientStartFire(Mode);
}

simulated event NewNet_ClientStartFire(int Mode)
{
	local ReplicatedRotator R;
	local ReplicatedVector V;
	local vector Start;
	local byte stamp;
	local bool b;
	local Actor A;
	local vector HN, HL;

	if (Pawn(Owner).Controller.IsInState('GameEnded') || Pawn(Owner).Controller.IsInState('RoundEnded'))
		return;

	if (Role < ROLE_Authority)
	{
		if (AltReadyToFire(Mode) && StartFire(Mode))
		{
			if (!ReadyToFire(Mode))
			{
				if (T == None)
				{
					foreach DynamicActors(class'TimeStamp_Pawn', T)
						break;
				}
				Stamp = T.TimeStamp;
				NewNet_OldServerStartFire(Mode, Stamp, T.DT);

				return;
			}
			R.Pitch = Pawn(Owner).Controller.Rotation.Pitch;
			R.Yaw = Pawn(Owner).Controller.Rotation.Yaw;
			Start = Pawn(Owner).Location + Pawn(Owner).EyePosition();

			V.X = Start.X;
			V.Y = Start.Y;
			V.Z = Start.Z;

			if (T == None)
			{
				foreach DynamicActors(class'TimeStamp_Pawn', T)
					break;
			}
			Stamp = T.TimeStamp;
			NewNet_ShockBeamFire(FireMode[Mode]).DoInstantFireEffect();

			A = Trace(HN, HL, Start + Vector(Pawn(Owner).Controller.Rotation)*40000.0, Start, true);
			if (A != None && (xPawn(A) != None || Vehicle(A) != None))
				b = true;

			NewNet_ServerStartFire(Mode, Stamp, T.DT, R, V, b, A);
		}
	}
	else
	{
		StartFire(Mode);
	}
}

simulated function bool AltReadyToFire(int Mode)
{
	local int alt;
	local float f;

	return ReadyToFire(Mode);

	f = 0.015;
	if (!ReadyToFire(Mode))
		return false;

	if (Mode == 0)
		alt = 1;
	else
		alt = 0;

	if (
		((FireMode[alt] != FireMode[Mode]) && FireMode[alt].bModeExclusive && FireMode[alt].bIsFiring)
		|| !FireMode[Mode].AllowFire()
		|| (FireMode[Mode].NextFireTime > Level.TimeSeconds + FireMode[Mode].PreFireTime - f)
	)
	{
		return false;
	}

	return true;
}

simulated function WeaponTick(float deltaTime)
{
	LastDT = deltaTime;
	Super.Tick(deltaTime);
}

simulated function bool StartFire(int Mode)
{
	local int alt;

	if (bWaitForCombo && (Bot(Instigator.Controller) != None))
	{
		if ((ComboTarget == None) || ComboTarget.bDeleteMe)
			bWaitForCombo = false;
		else
			return false;
	}

	if (!ReadyToFire(Mode))
		return false;

	if (Mode == 0)
		alt = 1;
	else
		alt = 0;

	FireMode[Mode].bIsFiring = true;
	FireMode[Mode].NextFireTime = Level.TimeSeconds-LastDT*0.5 + FireMode[Mode].PreFireTime;

	if (FireMode[alt].bModeExclusive)
		FireMode[Mode].NextFireTime = FMax(FireMode[Mode].NextFireTime, FireMode[alt].NextFireTime);

	if (Instigator.IsLocallyControlled())
	{
		if (FireMode[Mode].PreFireTime > 0.0 || FireMode[Mode].bFireOnRelease)
		{
			FireMode[Mode].PlayPreFire();
		}
		FireMode[Mode].FireCount = 0;
	}

	return true;
}

function NewNet_ServerStartFire(byte Mode, byte ClientTimeStamp, float DT, ReplicatedRotator R, ReplicatedVector V, bool bBelievesHit, Actor A)
{
	if ((Instigator != None) && (Instigator.Weapon != self))
	{
		if (Instigator.Weapon == None)
			Instigator.ServerChangedWeapon(None, self);
		else
			Instigator.Weapon.SynchronizeWeapon(self);
		return;
	}

	if (M == None)
	{
		foreach DynamicActors(class'MutUTComp', M)
			break;
	}

	NewNet_ShockBeamFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
	NewNet_ShockBeamFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	NewNet_ShockBeamFire(FireMode[Mode]).AverDT = M.AverDT;

	if (bBelievesHit)
	{
		NewNet_ShockBeamFire(FireMode[Mode]).bBelievesHit = true;
		NewNet_ShockBeamFire(FireMode[Mode]).BelievedHitActor = A;
	}
	else
	{
		NewNet_ShockBeamFire(FireMode[Mode]).bBelievesHit = false;
	}

	NewNet_ShockBeamFire(FireMode[Mode]).bFirstGo = true;
	if ((FireMode[Mode].NextFireTime <= Level.TimeSeconds + FireMode[Mode].PreFireTime) && StartFire(Mode))
	{
		FireMode[Mode].ServerStartFireTime = Level.TimeSeconds;
		FireMode[Mode].bServerDelayStartFire = false;
		NewNet_ShockBeamFire(FireMode[Mode]).SavedVec.X = V.X;
		NewNet_ShockBeamFire(FireMode[Mode]).SavedVec.Y = V.Y;
		NewNet_ShockBeamFire(FireMode[Mode]).SavedVec.Z = V.Z;
		NewNet_ShockBeamFire(FireMode[Mode]).SavedRot.Yaw = R.Yaw;
		NewNet_ShockBeamFire(FireMode[Mode]).SavedRot.Pitch = R.Pitch;
		NewNet_ShockBeamFire(FireMode[Mode]).bUseReplicatedInfo = IsReasonable(NewNet_ShockBeamFire(FireMode[Mode]).SavedVec);
	}
	else if (FireMode[Mode].AllowFire())
	{
		FireMode[Mode].bServerDelayStartFire = true;
	}
	else
	{
		ClientForceAmmoUpdate(Mode, AmmoAmount(Mode));
	}
}

function NewNet_OldServerStartFire(byte Mode, byte ClientTimeStamp, float DT)
{
	if (M == None)
	{
		foreach DynamicActors(class'MutUTComp', M)
			break;
	}

	NewNet_ShockBeamFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
	NewNet_ShockBeamFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	ServerStartFire(Mode);
}

function bool IsReasonable(Vector V)
{
	local vector LocDiff;
	local float clErr;

	if (Owner == none || Pawn(Owner) == none)
		return true;

	LocDiff = V - (Pawn(Owner).Location + Pawn(Owner).EyePosition());
	clErr = (LocDiff dot LocDiff);
	return clErr < 1250.0;
}

simulated function SpawnBeamEffect(vector HitLocation, vector HitNormal, vector Start, rotator Dir, int ReflectNum)
{
	local ShockBeamEffect Beam;

	if (bClientDemoNetFunc)
		Start.Z = Start.Z - 64.0;

	Beam = Spawn(class'NewNet_Client_ShockBeamEffect',,, Start, Dir);
	if (ReflectNum != 0)
		Beam.Instigator = None;
	Beam.AimAt(HitLocation, HitNormal);
}

defaultproperties
{
	FireModeClass(0)=class'NewNet_ShockBeamFire'
	FireModeClass(1)=class'NewNet_ShockProjFire'
	PickupClass=class'NewNet_ShockRiflePickup'
}