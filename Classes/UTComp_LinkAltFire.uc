class UTComp_LinkAltFire extends LinkAltFire;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local LinkProjectile Proj;
	local UTComp_PRI uPRI;

	if (xPawn(Weapon.Owner) != None && xPawn(Weapon.Owner).Controller != None)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
		if (uPRI != None)
			uPRI.NormalWepStatsPrim[9] += 1;
	}

	Start += Vector(Dir) * 10.0 * LinkGun(Weapon).Links;
	Proj = Weapon.Spawn(class'XWeapons.LinkProjectile',,, Start, Dir);
	if (Proj != None)
	{
		Proj.Links = LinkGun(Weapon).Links;
		Proj.LinkAdjust();
	}
	return Proj;
}

defaultproperties
{
}