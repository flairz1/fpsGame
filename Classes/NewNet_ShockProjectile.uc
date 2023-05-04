class NewNet_ShockProjectile extends UTComp_ShockProjectile;

var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake, bOwned, bMoved;
var float ping;
var FakeProjectileManager FPM;

const INTERP_TIME = 0.70;
const PLACEBO_FIX = 0.025;

replication
{
	unreliable if (bDemoRecording)
		DoMove, DoSetLoc;
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if (Level.NetMode != NM_Client)
		return;

	DoPostNet();
}

simulated function DoPostNet()
{
	PC = Level.GetLocalPlayerController();
	if (CheckOwned())
	{
		if (!CheckForFakeProj())
		{
			bMoved = true;
			DoMove(FMax(0.00, (class'NewNet_PRI'.default.PredictedPing - 1.5*class'TimeStamp'.default.AverDT))*Velocity);
		}
	}
}

simulated function DoMove(Vector V)
{
	Move(V);
}

simulated function DoSetLoc(Vector V)
{
	SetLocation(V);
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

	ping = FMax(0.0, class'NewNet_PRI'.default.PredictedPing - 1.50*class'TimeStamp'.default.AverDT);
	if (FPM == none)
		FindFPM();

	FP = FPM.GetFP(class'NewNet_Fake_ShockProjectile');
	if (FP != none)
	{
		bInterpFake = true;
		if (bMoved)
			DesiredDeltaFake = Location - FP.Location;
		else
			DesiredDeltaFake = (Location+Velocity*ping) - FP.Location;
		DoSetLoc(FP.Location);
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

	DoTick(deltaTime);
}

simulated function DoTick(float deltaTime)
{
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