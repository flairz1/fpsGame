class PawnCollisionCopy extends Actor;

var PawnCollisionCopy Next;
var float CrouchHeight;
var float CrouchRadius;
var MutUTComp M;
var Pawn CopiedPawn;
var bool bNormalDestroy;

struct PawnHistoryElement
{
	var vector Location;
	var rotator Rotation;
	var bool bCrouched;
	var float TimeStamp;
	var EPhysics Physics;
};
var array<PawnHistoryElement> PawnHistory;

const MAX_HISTORY_LENGTH = 0.350;
var bool bCrouched;
var InterpCurve LocCurveX, LocCurveY, LocCurveZ;

function SetPawn(Pawn Other)
{
	if (Level.NetMode == NM_Client)
		Warn("Client should never have a collision copy");

	if (Other == none)
	{
		Warn("PawnCopy spawned without proper Other");
		return;
	}
	CopiedPawn=  Other;

	if (M == None)
	{
		foreach DynamicActors(class'MutUTComp', M)
			break;
	}
	CrouchHeight = CopiedPawn.CrouchHeight;
	CrouchRadius = CopiedPawn.CrouchRadius;
	bUseCylinderCollision = CopiedPawn.bUseCylinderCollision;
	bCrouched = CopiedPawn.bIsCrouched;

	if (!bUseCylinderCollision)
		LinkMesh(CopiedPawn.Mesh);
	else
		SetCollisionSize(CopiedPawn.CollisionRadius, CopiedPawn.CollisionHeight);
}

function GoToPawn()
{
	if (CopiedPawn == none)
		return;

	SetLocation(CopiedPawn.Location);
	SetCollisionSize(CopiedPawn.CollisionRadius, CopiedPawn.CollisionHeight);

	if (bUseCylinderCollision)
	{
		if (!bCrouched && CopiedPawn.bIsCrouched)
		{
			SetCollisionSize(CrouchRadius, CrouchHeight);
			bCrouched = true;
		}
		else if (bCrouched && !CopiedPawn.bIsCrouched)
		{
			SetCollisionSize(default.CollisionRadius, default.CollisionHeight);
			bCrouched = false;
		}
	}

	SetCollision(true);
}

function TimeTravelPawn(float deltaTime)
{
	local int i, Floor, Ceiling;
	local bool bFloor, bCeiling;
	local vector V2;
	local float StampDT;

	if (CopiedPawn == none || CopiedPawn.DrivenVehicle != None)
		return;

	StampDT = M.ClientTimeStamp - deltaTime;
	SetCollision(false);

	//We cant backtrack, too recent, just go straight to the pawn
	if (PawnHistory.Length == 0 || PawnHistory[PawnHistory.Length-1].TimeStamp < StampDT)
	{
		GoToPawn();
		return;
	}

	//Sandwich between 2 history parts Ceiling and Floor
	for(i = PawnHistory.Length-1; i >= 0; i--)
	{
		if (PawnHistory[i].TimeStamp >= StampDT)
		{
			bFloor=true;
			Floor = i;
		}
		else
		{
			bCeiling = true;
			Ceiling = i;
			break;
		}
	}

	if (bCeiling)
	{
		V2.X = InterpCurveEval(LocCurveX, StampDT);
		V2.Y = InterpCurveEval(LocCurveY, StampDT);
		V2.Z = InterpCurveEval(LocCurveZ, StampDT);

		SetLocation(V2);
		SetRotation(PawnHistory[Floor].Rotation);

		if (bUseCylinderCollision)
		{
			if (!bCrouched && PawnHistory[Floor].bCrouched && PawnHistory[Ceiling].bCrouched)
			{
				SetCollisionSize(CrouchRadius, CrouchHeight);
				bCrouched = true;
			}
			else if (bCrouched && (!PawnHistory[Floor].bCrouched || !PawnHistory[Ceiling].bCrouched))
			{
				SetCollisionSize(default.CollisionRadius, default.CollisionHeight);
				bCrouched = false;
			}
		}
	}
	else
	{
		if (PawnHistory[Floor].bCrouched)
			SetCollisionSize(CrouchRadius, CrouchHeight);
		else if (xPawn(CopiedPawn) != None)
			SetCollisionSize(default.CollisionRadius, default.CollisionHeight);
		else if (bUseCylinderCollision)
			SetCollisionSize(CopiedPawn.CollisionRadius, CopiedPawn.CollisionHeight);

		SetLocation(PawnHistory[Floor].Location);
		SetRotation(PawnHistory[Floor].Rotation);
	}
	SetCollision(true);
}

function TurnOffCollision()
{
	SetCollision(false);
}

function AddPawnToList(Pawn Other)
{
	if (Next == None)
	{
		Next = Spawn(class'PawnCollisionCopy');
		Next.SetPawn(Other);
	}
	else
	{
		Next.AddPawnToList(Other);
	}
}

function PawnCollisionCopy RemoveOldPawns()
{
	if (CopiedPawn == none)
	{
		bNormalDestroy = true;
		Destroy();
		if (Next != None)
			return Next.RemoveOldPawns();
		return none;
	}
	else if (Next != None)
	{
		Next = Next.RemoveOldPawns();
	}

	return self;
}

event TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
	Warn("Pawn collision copy should never take damage");
}

event Destroyed()
{
	Super.Destroyed();
}

function Identify()
{
	if (CopiedPawn == None)
	{
		Log("PCC: No pawn");
	}
	else
	{
		if (CopiedPawn.PlayerReplicationInfo != None)
			Log("PCC: Pawn"@CopiedPawn.PlayerReplicationInfo.PlayerName);
		else
			Log("PCC: Unnamed Pawn");
	}
}

function Tick(float deltaTime)
{
	if (CopiedPawn == None)
		return;

	AddHistory();
	RemoveOutdatedHistory();
}

function AddHistory()
{
	local int i;
	local InterpCurvePoint XPoint, YPoint, ZPoint;

	i = Pawnhistory.Length;
	PawnHistory.Length = i+1;
	PawnHistory[i].Location = CopiedPawn.Location;
	PawnHistory[i].Rotation = CopiedPawn.Rotation;
	PawnHistory[i].bCrouched = CopiedPawn.bIsCrouched;
	PawnHistory[i].TimeStamp = M.ClientTimeStamp;
	PawnHistory[i].Physics = CopiedPawn.Physics;

	XPoint.InVal = M.ClientTimeStamp;
	XPoint.OutVal = CopiedPawn.Location.X;
	LocCurveX.Points.Insert(LocCurveX.Points.Length, 1);
	LocCurveX.Points[LocCurveX.Points.Length-1] = XPoint;

	YPoint.InVal = M.ClientTimeStamp;
	YPoint.OutVal = CopiedPawn.Location.Y;
	LocCurveY.Points.Insert(LocCurveY.Points.Length, 1);
	LocCurveY.Points[LocCurveY.Points.Length-1] = YPoint;

	ZPoint.InVal = M.ClientTimeStamp;
	ZPoint.OutVal = CopiedPawn.Location.Z;
	LocCurveZ.Points.Insert(LocCurveZ.Points.Length, 1);
	LocCurveZ.Points[LocCurveZ.Points.Length-1] = ZPoint;
}

function RemoveOutdatedHistory()
{
	while(PawnHistory.Length > 0 && PawnHistory[0].TimeStamp + MAX_HISTORY_LENGTH < M.ClientTimeStamp)
		PawnHistory.Remove(0,1);

	while(LocCurveX.Points.Length > 0 &&  LocCurveX.Points[0].InVal + MAX_HISTORY_LENGTH < M.ClientTimeStamp)
	{
		LocCurveX.Points.Remove(0, 1);
		LocCurveY.Points.Remove(0, 1);
		LocCurveZ.Points.Remove(0, 1);
	}
}

defaultproperties
{
	bCollideActors=false
	bCollideWorld=false
	bBlockActors=false
	bBlockPlayers=false
	bProjTarget=false
	bBlockProjectiles=false
	bDisturbFluidSurface=false
	bCanBeDamaged=false
	bCanTeleport=false
	CrouchHeight=29.000000
	CrouchRadius=25.000000
	bHidden=true
	bAcceptsProjectors=false
	bSkipActorPropertyReplication=true
	bOnlyDirtyReplication=true
	RemoteRole=ROLE_None
	CollisionRadius=25.000000
	CollisionHeight=44.000000
}