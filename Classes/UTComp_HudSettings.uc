class UTComp_HudSettings extends Object
	Config(fpsGameClient)
	PerObjectConfig;

var config bool bMatchHudColor;

//	fpsHud variables
var config Color RadarColour;
var config bool bDrawCardinalPoints;
var config float RadarPosX, RadarPosY, RadarScale;

defaultproperties
{
	bDrawCardinalPoints=false
	RadarColour=(R=0,G=0,B=0,A=220)
	RadarPosX=94.000000
	RadarPosY=17.500000
	RadarScale=20.000000
}