class NewNet_NewLightningBolt extends NewLightningBolt;

simulated function PostNetBeginPlay()
{
	local PlayerController PC;

	Super.PostNetBeginPlay();

	if (Role == ROLE_Authority)
		return;

	PC = Level.GetLocalPlayerController();
	if (PC != None && PC.Pawn != None && PC.Pawn == Instigator)
		Destroy();
}

defaultproperties
{
	bSkipActorPropertyReplication=false
}