class NewNet_SniperRifle extends UTComp_SniperRifle
	HideDropDown
	CacheExempt
	Config(fpsGameClient);

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

var TimeStamp_Pawn T;
var MutUTComp M;
var float LastDT;

replication
{
	reliable if (Role < ROLE_Authority)
		NewNet_ServerStartFire;

	unreliable if (bDemoRecording)
		SpawnLGEffect;
}

function DisableNet()
{
	NewNet_SniperFire(FireMode[0]).bUseEnhancedNetCode = false;
	NewNet_SniperFire(FireMode[0]).PingDT = 0.00;
}

simulated function SpawnLGEffect(class<Actor> tmpHitEmitClass, vector ArcEnd, vector HitNormal, vector HitLocation)
{
	local xEmitter HitEmitter;

	if (Level.NetMode != NM_Client)
		Warn("Server should never spawn the client lightningbolt");

	HitEmitter = xEmitter(Spawn(tmpHitEmitClass,,, arcEnd, Rotator(HitNormal)));
	if (HitEmitter != None)
		HitEmitter.mSpawnVecA = HitLocation;
}

simulated function ClientStartFire(int Mode)
{
	if (Level.NetMode != NM_Client)
	{
		Super.ClientStartFire(Mode);
		return;
	}

	if (Mode == 1)
	{
		FireMode[Mode].bIsFiring = true;
		if (PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ToggleZoom();
	}
	else
	{
		if (BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
			NewNet_ClientStartFire(Mode);
		else
			Super(Weapon).ClientStartFire(Mode);
	}
}

simulated function NewNet_ClientStartFire(int mode)
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
		if (ReadyToFire(Mode) && StartFire(Mode))
		{
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

			NewNet_SniperFire(FireMode[Mode]).DoInstantFireEffect();
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

function NewNet_ServerStartFire(byte Mode, byte ClientTimeStamp, float DT, ReplicatedRotator R, ReplicatedVector V, bool bBelievesHit, optional actor A)
{
	if ((Instigator != None) && (Instigator.Weapon != self))
	{
		if (Instigator.Weapon == None)
			Instigator.ServerChangedWeapon(None,self);
		else
			Instigator.Weapon.SynchronizeWeapon(self);
		return;
	}

	if (M == None)
	{
		foreach DynamicActors(class'MutUTComp', M)
			break;
	}

	NewNet_SniperFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
	NewNet_SniperFire(FireMode[Mode]).AverDT = M.AverDT;
	if (bBelievesHit)
	{
		NewNet_SniperFire(FireMode[Mode]).bBelievesHit = true;
		NewNet_SniperFire(FireMode[Mode]).BelievedHitActor = A;
	}
	else
	{
		NewNet_SniperFire(FireMode[Mode]).bBelievesHit = false;
	}

	NewNet_SniperFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	NewNet_SniperFire(FireMode[Mode]).bFirstGo = true;
	if ((FireMode[Mode].NextFireTime <= Level.TimeSeconds + FireMode[Mode].PreFireTime) && StartFire(Mode))
	{
		FireMode[Mode].ServerStartFireTime = Level.TimeSeconds;
		FireMode[Mode].bServerDelayStartFire = false;
		NewNet_SniperFire(FireMode[Mode]).SavedVec.X = V.X;
		NewNet_SniperFire(FireMode[Mode]).SavedVec.Y = V.Y;
		NewNet_SniperFire(FireMode[Mode]).SavedVec.Z = V.Z;
		NewNet_SniperFire(FireMode[Mode]).SavedRot.Yaw = R.Yaw;
		NewNet_SniperFire(FireMode[Mode]).SavedRot.Pitch = R.Pitch;
		NewNet_SniperFire(FireMode[Mode]).bUseReplicatedInfo = IsReasonable(NewNet_SniperFire(FireMode[Mode]).SavedVec);
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

simulated function WeaponTick(float deltaTime)
{
	LastDT = deltaTime;
}

simulated function bool StartFire(int Mode)
{
	local int alt;

	if (!ReadyToFire(Mode))
		return false;

	if (Mode == 0)
		alt = 1;
	else
		alt = 0;

	FireMode[Mode].bIsFiring = true;
	FireMode[Mode].NextFireTime = Level.TimeSeconds - LastDT*0.5 + FireMode[Mode].PreFireTime;

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

defaultproperties
{
	FireModeClass(0)=class'NewNet_SniperFire'
	PickupClass=class'NewNet_SniperRiflePickup'
}