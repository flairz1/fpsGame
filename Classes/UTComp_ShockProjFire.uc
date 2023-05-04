class UTComp_ShockProjFire extends ShockProjFire;

event ModeDoFire()
{
	local UTComp_PRI uPRI;

	if (xPawn(Weapon.Owner) != None && xPawn(Weapon.Owner).Controller != None)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
		if (uPRI != None)
			uPRI.NormalWepStatsAlt[10] += 1;
	}
	Super.ModeDoFire();
}

defaultproperties
{
	ProjectileClass=class'UTComp_ShockProjectile'
}