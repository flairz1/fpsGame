class NewNet_BioRifle extends UTComp_BioRifle
	HideDropDown
	CacheExempt
	Config(fpsGameClient);

const MAX_PROJECTILE_FUDGE = 0.075;

var TimeStamp_Pawn T;
var MutUTComp M;
var int CurIndex, ClientCurIndex;

replication
{
	reliable if (Role < ROLE_Authority)
		NewNet_ServerStartFire;

	unreliable if (Role == ROLE_Authority && bNetOwner)
		CurIndex;
}

function DisableNet()
{
	NewNet_BioFire(FireMode[0]).bUseEnhancedNetCode = false;
	NewNet_BioFire(FireMode[0]).PingDT = 0.00;
	NewNet_BioChargedFire(FireMode[1]).bUseEnhancedNetCode = false;
	NewNet_BioChargedFire(FireMode[1]).PingDT = 0.00;
}

simulated event ClientStartFire(int Mode)
{
	if (Level.NetMode != NM_Client || !BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
		Super.ClientStartFire(Mode);
	else
		NewNet_ClientStartFire(Mode);
}

simulated event NewNet_ClientStartFire(int Mode)
{
	if (Pawn(Owner).Controller.IsInState('GameEnded') || Pawn(Owner).Controller.IsInState('RoundEnded'))
		return;

	if (Role < ROLE_Authority)
	{
		if (StartFire(Mode))
		{
			if (T == None)
			{
				foreach DynamicActors(class'TimeStamp_Pawn', T)
					break;
			}

			NewNet_ServerStartFire(Mode, T.TimeStamp, T.DT);
		}
	}
	else
	{
		StartFire(Mode);
	}
}

function NewNet_ServerStartFire(byte Mode, byte ClientTimeStamp, float DT)
{
	if (M == None)
	{
		foreach DynamicActors(class'MutUTComp', M)
			break;
	}

	if (NewNet_BioFire(FireMode[Mode]) != None)
	{
		NewNet_BioFire(FireMode[Mode]).PingDT = FMin(M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT, MAX_PROJECTILE_FUDGE);
		NewNet_BioFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	}
	else if (NewNet_BioChargedFire(FireMode[Mode]) != None)
	{
		NewNet_BioChargedFire(FireMode[Mode]).PingDT = FMin(M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT, MAX_PROJECTILE_FUDGE);
		NewNet_BioChargedFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	}

	ServerStartFire(Mode);
}

defaultproperties
{
	FireModeClass(0)=class'NewNet_BioFire'
	FireModeClass(1)=class'NewNet_BioChargedFire'
	PickupClass=class'NewNet_BioRiflePickup'
}