class TimeStamp_Pawn extends Pawn;

var int TimeStamp, NewTimeStamp;
var float DT;

function PreBeginPlay()
{
	Super.PreBeginPlay();
}

function PossessedBy(Controller C)
{
	Super.PossessedBy(C);
	NetPriority = default.NetPriority;
}
function Destroyed()
{
	Super.Destroyed();
}

simulated event Tick(float deltaTime)
{
	Super.Tick(deltaTime);

	DT += deltaTime;
	NewTimeStamp = (Rotation.Yaw + Rotation.Pitch*256)/256;
	if (NewTimeStamp > TimeStamp || (TimeStamp - NewTimeStamp > 5000))
	{
		TimeStamp = NewTimeStamp;
		DT = 0.00;
	}
}

defaultproperties
{
	ControllerClass=class'TimeStamp_Controller'
	bAcceptsProjectors=false
	bAlwaysRelevant=true
	NetPriority=50.000000
	bCanBeDamaged=false
	bCanTeleport=false
	bDisturbFluidSurface=false
	bCollideActors=false
	bCollideWorld=false
	bBlockActors=false
	bBlockPlayers=false
	bProjTarget=false
	Physics=PHYS_None
}