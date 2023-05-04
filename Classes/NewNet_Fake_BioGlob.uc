class NewNet_Fake_BioGlob extends BioGlob;

simulated function Destroyed()
{
	if (Fear != None)
		Fear.Destroy();
	
	if (Trail != None)
		Trail.Destroy();

	Super(Projectile).Destroyed();
}

defaultproperties
{
}