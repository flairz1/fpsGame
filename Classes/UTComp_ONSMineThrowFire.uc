class UTComp_ONSMineThrowFire extends ONSMineThrowFire;

event ModeDoFire()
{
	local UTComp_PRI uPRI;

	if (xPawn(Weapon.Owner) != None && xPawn(Weapon.Owner).Controller != None)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
		if (uPRI != None)
			uPRI.NormalWepStatsPrim[4] += 1;
	}
	Super.ModeDoFire();
}

defaultproperties
{
}