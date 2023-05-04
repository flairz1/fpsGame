class UTComp_AssaultRifle extends AssaultRifle
	HideDropDown
	CacheExempt;

simulated function bool ReadyToFire(int Mode)
{
	return Super.ReadyToFire(Mode);
}

defaultproperties
{
}