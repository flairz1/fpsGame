class NewNet_MiniGun extends UTComp_MiniGun
	HideDropDown
	CacheExempt
	Config(fpsGameClient);

var TimeStamp_Pawn T;
var MutUTComp M;

replication
{
	reliable if (Role < ROLE_Authority)
		NewNet_ServerStartFire;
}

function DisableNet()
{
	NewNet_MiniGunFire(FireMode[0]).bUseEnhancedNetCode = false;
	NewNet_MiniGunFire(FireMode[0]).PingDT = 0.00;
	NewNet_MiniGunAltFire(FireMode[1]).bUseEnhancedNetCode = false;
	NewNet_MiniGunAltFire(FireMode[1]).PingDT = 0.00;
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

	if (NewNet_MiniGunFire(FireMode[Mode]) != None)
	{
		NewNet_MiniGunFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
		NewNet_MiniGunFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	}
	else if (NewNet_MiniGunAltFire(FireMode[Mode]) != None)
	{
		NewNet_MiniGunAltFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
		NewNet_MiniGunAltFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	}

	ServerStartFire(Mode);
}

defaultproperties
{
	FireModeClass(0)=class'NewNet_MiniGunFire'
	FireModeClass(1)=class'NewNet_MiniGunAltFire'
	PickupClass=class'NewNet_MiniGunPickup'
}