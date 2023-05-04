class NewNet_LinkProjectile extends LinkProjectile;

var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake, bOwned;
var FakeProjectileManager FPM;

const INTERP_TIME = 0.250;
var int Index;

replication
{
	reliable if (Role == ROLE_Authority && bNetInitial)
		Index;

	unreliable if (bDemoRecording)
		DoMove, DoSetLoc;
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

simulated function DoMove(Vector V)
{
	Move(V);
}

simulated function DoSetLoc(Vector V)
{
	SetLocation(V);
}

simulated function bool CheckForFakeProj()
{
	local float ping;
	local Projectile FP;

	ping = FMax(0.0, class'NewNet_PRI'.default.PredictedPing - 0.5*class'TimeStamp'.default.AverDT);

	if (FPM == none)
		FindFPM();

	FP = FPM.GetFP(class'NewNet_Fake_LinkProjectile', index);
	if (FP != none)
	{
		bInterpFake = true;
		DesiredDeltaFake = Location - FP.Location;
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