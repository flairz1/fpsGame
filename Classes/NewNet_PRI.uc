class NewNet_PRI extends LinkedReplicationInfo;

var float PredictedPing, PingSendTime;
var bool bPingReceived;
var int numPings;

const PING_TWEEN_TIME = 3.000000;

replication
{
	reliable if (Role < ROLE_Authority)
		Ping;

	reliable if (Role == ROLE_Authority && bNetOwner)
		Pong;
}

simulated function Ping()
{
	Pong();
}

simulated function Pong()
{
	bPingReceived = true;
	PredictedPing = (2.0*PredictedPing + (Level.TimeSeconds - PingSendTime))/3.0;
	default.PredictedPing = PredictedPing;

	numPings++;
	if (NumPings < 8)
		default.PredictedPing = (Level.TimeSeconds - PingSendTime);
}

simulated function Tick(float deltaTime)
{
	Super.Tick(deltaTime);

	if (Level.NetMode != NM_Client)
		return;

	if (bPingReceived && Level.TimeSeconds > PingSendTime + PING_TWEEN_TIME)
	{
		PingSendTime = Level.TimeSeconds;
		bPingReceived = false;
		Ping();
	}
}

defaultproperties
{
	bPingReceived=true
	NetUpdateFrequency=200.000000
	NetPriority=5.000000
}