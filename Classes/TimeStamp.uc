class TimeStamp extends ReplicationInfo;

var float AverDT;

replication
{
	unreliable if (Role == ROLE_Authority)
		AverDT;
}

simulated function PostBeginPlay()
{
	class'ShieldFire'.default.AutoFireTestFreq = 0.050000;
	Super.PostBeginPlay();
}

simulated function Tick(float deltaTime)
{
	default.AverDT = AverDT;
}

function ReplicatedAverDT(float f)
{
	AverDT = f;
}

defaultproperties
{
	NetUpdateFrequency=100.000000
	NetPriority=5.000000
}