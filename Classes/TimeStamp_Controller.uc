class TimeStamp_Controller extends Controller;

var int TimeStamp;

function Tick(float deltaTime)
{
	if (Pawn == none)
	{
		Pawn = Spawn(PawnClass);
		Possess(Pawn);
	}

	if (Pawn == none)
		return;
}

defaultproperties
{
	PawnClass=class'TimeStamp_Pawn'
}