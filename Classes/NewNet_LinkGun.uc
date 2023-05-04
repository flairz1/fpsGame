class NewNet_LinkGun extends UTComp_LinkGun
	HideDropDown
	CacheExempt
	Config(fpsGameClient);

var TimeStamp_Pawn T;
var MutUTComp M;

const MAX_PROJECTILE_FUDGE = 0.075;
var int CurIndex;

replication
{
	reliable if (Role < ROLE_Authority)
		NewNet_ServerStartFire;

	unreliable if (Role == ROLE_Authority && bNetOwner)
		CurIndex;
}

function DisableNet()
{
	NewNet_LinkAltFire(FireMode[0]).bUseEnhancedNetCode = false;
	NewNet_LinkAltFire(FireMode[0]).PingDT = 0.00;
	NewNet_LinkFire(FireMode[1]).bUseEnhancedNetCode = false;
	NewNet_LinkFire(FireMode[1]).PingDT = 0.00;
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

	if (NewNet_LinkAltFire(FireMode[Mode]) != None)
	{
		NewNet_LinkAltFire(FireMode[Mode]).PingDT = FMin(M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT, MAX_PROJECTILE_FUDGE);
		NewNet_LinkAltFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	}
	else if (NewNet_LinkFire(FireMode[Mode]) != None)
	{
		NewNet_LinkFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
		NewNet_LinkFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	}

	ServerStartFire(Mode);
}

simulated function DispatchClientEffect(Vector V, rotator R)
{
	if (Level.NetMode != NM_Client)
		return;

	Spawn(class'LinkProjectile',,,V,R);
}

defaultproperties
{
	FireModeClass(0)=class'NewNet_LinkAltFire'
	FireModeClass(1)=class'NewNet_LinkFire'
	PickupClass=class'NewNet_LinkGunPickup'
}