class NewNet_Fake_ShockProjectile extends ShockProjectile;

simulated function Destroyed()
{
	if (ShockBallEffect != None)
		ShockBallEffect.Destroy();

	Super(Projectile).Destroyed();
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	if (NewNet_ShockProjectile(Other) != None)
		return;

	Super.ProcessTouch(Other, HitLocation);
}

defaultproperties
{
	bCollideActors=false
}