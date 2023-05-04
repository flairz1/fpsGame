class NewNet_FlakShell extends FlakShell
	HideDropDown
	CacheExempt;

var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake, bOwned;
var FakeProjectileManager FPM;

struct ReplicatedRotator
{
	var int Yaw;
	var int Pitch;
	var int Roll;
};

struct ReplicatedVector
{
	var float X;
	var float Y;
	var float Z;
};

const INTERP_TIME = 0.50;

replication
{
	unreliable if (bDemoRecording)
		DoMove, DoSetLoc;
}

simulated function DoMove(Vector V)
{
	Move(V);
}

simulated function DoSetLoc(Vector V)
{
	SetLocation(V);
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if (Level.NetMode != NM_Client)
		return;

	PC = Level.GetLocalPlayerController();
	if (CheckOwned())
		CheckForFakeProj();
}

simulated function bool CheckOwned()
{
	local UTComp_Settings S;

	foreach AllObjects(class'UTComp_Settings', S)
		break;

	if (S != none && S.bClientNetcode == false)
		return false;

	bOwned = (PC != None && PC.Pawn != None && PC.Pawn == Instigator);
	return bOwned;
}

simulated function bool CheckForFakeProj()
{
	local Projectile FP;

	if (FPM == none)
		FindFPM();

	FP = FPM.GetFP(class'NewNet_Fake_FlakShell');
	if (FP != none)
	{
		DesiredDeltaFake = Location - FP.Location;
		doSetLoc(FP.Location);
		FPM.RemoveProjectile(FP);
		bOwned = false;
		return true;
	}
	return false;
}

simulated function FindFPM()
{
	foreach DynamicActors(class'FakeProjectileManager', FPM)
		break;
}

simulated function Tick(float deltaTime)
{
	Super.Tick(deltaTime);

	if (Level.NetMode != NM_Client)
		return;

	if (bInterpFake)
		FakeInterp(deltaTime);
	else if (bOwned)
		CheckForFakeProj();
}

simulated function FakeInterp(float deltaTime)
{
	local vector V;
	local float OldDeltaFakeTime;

	V = DesiredDeltaFake * deltaTime/INTERP_TIME;

	OldDeltaFakeTime = CurrentDeltaFakeTime;
	CurrentDeltaFakeTime += deltaTime;

	if (CurrentDeltaFakeTime < INTERP_TIME)
	{
		DoMove(V);
	}
	else
	{
		DoMove((INTERP_TIME - OldDeltaFakeTime) / deltaTime * V);
		bInterpFake = false;
	}
}

defaultproperties
{
}