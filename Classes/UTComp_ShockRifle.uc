class UTComp_ShockRifle extends ShockRifle
	HideDropDown
	CacheExempt;

simulated function bool ReadyToFire(int Mode)
{
	return Super.ReadyToFire(Mode);
}

defaultproperties
{
}