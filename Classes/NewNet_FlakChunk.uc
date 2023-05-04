class NewNet_FlakChunk extends FlakChunk;

var int ChunkNum;
var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake, bOwned;
var FakeProjectileManager FPM;

replication
{
	unreliable if (Role == ROLE_Authority && bNetInitial)
		ChunkNum;

	unreliable if (bDemoRecording)
		DoMove, DoSetLoc;
}

const INTERP_TIME = 1.00;

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if (Level.NetMode != NM_Client)
		return;

	PC = Level.GetLocalPlayerController();
	if (CheckOwned())
		CheckForFakeProj();
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

	if (FPM == none)
		FindFPM();

	FP = FPM.GetFP(class'NewNet_Fake_FlakChunk', ChunkNum);
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