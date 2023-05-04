class UTComp_FlakCannon extends FlakCannon
	HideDropDown
	CacheExempt;

simulated function bool ReadyToFire(int Mode)
{
	return Super.ReadyToFire(Mode);
}

defaultproperties
{
}