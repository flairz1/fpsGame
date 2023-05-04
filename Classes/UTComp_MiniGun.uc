class UTComp_MiniGun extends MiniGun
	HideDropDown
	CacheExempt;

simulated function bool ReadyToFire(int Mode)
{
	return Super.ReadyToFire(Mode);
}

defaultproperties
{
}