class NewNet_Client_LightningBolt extends NewLightningBolt;

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Level.NetMode != NM_Client)
		Warn("Server should never spawn the client lightning bolt");
}

defaultproperties
{
}