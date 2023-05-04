class NewNet_ClassicSniperRifle extends ClassicSniperRifle
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
	NewNet_ClassicSniperFire(FireMode[0]).bUseEnhancedNetCode = false;
	NewNet_ClassicSniperFire(FireMode[0]).PingDT = 0.00;
}

simulated function ClientStartFire(int Mode)
{
	if (Mode == 1)
	{
		FireMode[mode].bIsFiring = true;
		if (PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ToggleZoom();
	}
	else
	{
		SuperClientStartFire(Mode);
	}
}

simulated event SuperClientStartFire(int Mode)
{
	if (Level.NetMode != NM_Client || !BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
		Super(Weapon).ClientStartFire(Mode);
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

	if (NewNet_ClassicSniperFire(FireMode[Mode]) != None)
	{
		NewNet_ClassicSniperFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
		NewNet_ClassicSniperFire(FireMode[Mode]).bUseEnhancedNetCode = true;
	}

	ServerStartFire(Mode);
}

defaultproperties
{
	FireModeClass(0)=class'NewNet_ClassicSniperFire'
	PickupClass=class'NewNet_ClassicSniperRiflePickup'
}