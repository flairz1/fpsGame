class NewNet_ChildLightningBolt extends ChildLightningBolt;

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
	bReplicateInstigator=true
	bSkipActorPropertyReplication=false
}