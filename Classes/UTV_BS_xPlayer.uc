class UTV_BS_xPlayer extends BS_xPlayer;

var string utvOverideUpdate, utvFreeFlight, utvLastTargetName, utvPos;

function LongClientAdjustPosition(
	float TimeStamp,
	name newState,
	EPhysics newPhysics,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	float NewVelX,
	float NewVelY,
	float NewVelZ,
	Actor NewBase,
	float NewFloorX,
	float NewFloorY,
	float NewFloorZ
)
{
	local Actor myTarget;

	Super.LongClientAdjustPosition(TimeStamp, newState, newPhysics, NewLocX,NewLocY,NewLocZ,NewVelX,newVelY, newVelZ, NewBase, NewFloorX, NewFloorY, NewFloorZ);

	if (utvOverideUpdate == "true")
	{
		bUpdatePosition = false;
		if (utvFreeFlight == "true")
		{
			bBehindView = false;
			SetViewTarget(self);
			SetLocation(vector(utvPos));
			if (Pawn != none)
			{
				Pawn.SetLocation(vector(utvPos));
			}
		}
		else
		{
			Target = GetPawnFromName(utvLastTargetName);
			if (myTarget != none)
				SetViewTarget(myTarget);
		}
	}
}

simulated function Pawn GetPawnFromName(string name)
{
	local Pawn tempPawn;

	foreach AllActors(class'Pawn', tempPawn)
	{
		if (tempPawn.PlayerReplicationInfo != none && tempPawn.PlayerReplicationInfo.PlayerName == name)
		{
			return tempPawn;
			break;
		}
	}
	return none;
}

state Spectating
{
    simulated function PlayerMove(float deltaTime)
    {
		local Actor myTarget;

		if (utvOverideUpdate == "true" && !(utvFreeFlight == "true"))
		{
			myTarget = GetPawnFromName(utvLastTargetName);
			if (myTarget != none)
			{
				SetViewTarget(myTarget);
				TargetViewRotation = myTarget.rotation;
			}
		}
		Super.PlayerMove(deltaTime);
	}
}

defaultproperties
{
	utvOverideUpdate="false"
	utvFreeFlight="false"
	bAllActorsRelevant=true
}