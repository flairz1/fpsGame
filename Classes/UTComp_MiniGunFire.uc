class UTComp_MinigunFire extends MinigunFire;

event ModeDoFire()
{
	local UTComp_PRI uPRI;

	if (xPawn(Weapon.Owner) != None && xPawn(Weapon.Owner).Controller != None)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
		if (uPRI != None)
			uPRI.NormalWepStatsPrim[8] += 1;
	}
	Super.ModeDoFire();
}

defaultproperties
{
}