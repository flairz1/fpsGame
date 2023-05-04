class UTComp_SpinnyWeap extends SpinnyWeap;

function Tick(float deltaTime)
{
	local vector V, X, Y, Z;
	local vector X2, Y2;
	local rotator R, R2;

	R = Rotation;

	//changed from SpinnyWeap so that it rotates around the players viewing direction, not just absolute
	R2.Yaw = deltaTime * SpinRate/Level.TimeDilation;
	GetAxes(R, X, Y, Z);
	V = vector(R2);
	X2 = V.X*X + V.Y*Y;
	Y2 = V.X*Y - V.Y*X;
	R2 = OrthoRotation(X2, Y2, Z);

	SetRotation(R2);
	CurrentTime += deltaTime/Level.TimeDilation;

	// if desired, play some random animations
	if (bPlayRandomAnims && CurrentTime >= NextAnimTime)
		PlayNextAnim();
}

defaultproperties
{
	bHidden=true
}