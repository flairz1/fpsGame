class UTComp_LinkGun extends LinkGun
	HideDropDown
	CacheExempt;

simulated function bool ReadyToFire(int Mode)
{
	return Super.ReadyToFire(Mode);
}

defaultproperties
{
}