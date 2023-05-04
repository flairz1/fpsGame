class fpsHud extends HudCTeamDeathMatch
	Config(fpsGameClient);

//	note: Engine.Canvas
// DrawTile( Material Mat, float XL, float YL, float U, float V, float UL, float VL );
// DrawTileClipped( Material Mat, float XL, float YL, float U, float V, float UL, float VL );

var UTComp_HudSettings HudS;

//	timer
var fpsGRI GRI;
var localized string s_BossTime, s_KillZone, s_MonsCount, s_BossCount;
var float f_Blink, f_Pulse;

//	radar
var float LastRadarUpdate;
var array<Pawn> RadarCache;

//	cardinal points
var localized string Cardinal_North, Cardinal_East, Cardinal_South, Cardinal_West;

exec function NextStats()
{
	if (ScoreBoard == none || bShowScoreBoard == false)
		Super.NextStats();
	else
		ScoreBoard.NextStats();
}

function DisplayEnemyName(Canvas C, PlayerReplicationInfo PRI)
{
	PlayerOwner.ReceiveLocalizedMessage(class'UTComp_PlayerNameMessage', 0, PRI);
}

simulated function UpdatePrecacheMaterials()
{
	Level.AddPrecacheMaterial(Material'fpsGame.fps.xRadar');
	Level.AddPrecacheMaterial(Material'HudContent.Generic.HUD');
	Super.UpdatePrecacheMaterials();
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	foreach AllObjects(class'UTComp_HudSettings', HudS)
		break;

	if (HudS == none)
		Warn(self @ "HudSettings object not found!");
}

simulated function DrawSpectatingHud(Canvas C)
{
	Super.DrawSpectatingHud(C);
	DrawTimer(C);
}

simulated function DrawHudPassA(Canvas C)
{
	Super.DrawHudPassA(C);

	if (PawnOwner != none)
		DrawRadarPassA(C);
}

simulated function DrawHudPassB(Canvas C)
{
	Super.DrawHudPassB(C);

	if (PawnOwner != none)
		DrawRadarPassB(C);
}

simulated function ShowTeamScorePassA(Canvas C);

simulated function ShowTeamScorePassC(Canvas C)
{
	DrawBossTime(C);
	DrawKillZone(C);
}

function DrawRadarPassA(Canvas C)
{
	local float Dist, RadarWidth, DotSize, OffsetY, XL, YL, OffsetScale;
	local float RadarSize, RadarXPos, RadarYPos;
	local vector Start, DotPos, ViewX, ViewY, Z;

	if (PawnOwner == none)
		return;

	RadarSize = (HudS.RadarScale * 0.01) * HUDScale;
	RadarXPos = (HudS.RadarPosX * 0.01);
	RadarYPos = (HudS.RadarPosY * 0.01);

	RadarWidth = 0.5 * RadarSize * C.ClipX;
	C.Style = ERenderStyle.STY_Alpha;

	C.DrawColor = HudS.RadarColour;
	C.SetPos(RadarXPos * C.ClipX - RadarWidth, RadarYPos * C.ClipY + RadarWidth);
	C.DrawTile(Material'fpsGame.fps.xRadar', RadarWidth, RadarWidth, 0, 512, 512, -512);
	C.SetPos(RadarXPos * C.ClipX, RadarYPos * C.ClipY + RadarWidth);
	C.DrawTile(Material'fpsGame.fps.xRadar', RadarWidth, RadarWidth, 512, 512, -512, -512);
	C.SetPos(RadarXPos * C.ClipX - RadarWidth, RadarYPos * C.ClipY);
	C.DrawTile(Material'fpsGame.fps.xRadar', RadarWidth, RadarWidth, 0, 0, 512, 512);
	C.SetPos(RadarXPos * C.ClipX, RadarYPos * C.ClipY);
	C.DrawTile(Material'fpsGame.fps.xRadar', RadarWidth, RadarWidth, 512, 0, -512, 512);

	Start = PawnOwner.Location;
	OffsetY = RadarYPos + RadarWidth/C.ClipY;
	C.DrawColor = WhiteColor;
	OffsetScale = RadarSize * 0.000167;	//0.0000835

	GetAxes(PawnOwner.GetViewRotation(), ViewX, ViewY, Z);

	if (HudS.bDrawCardinalPoints)
	{
		Dist = 5500;
		C.Font = GetConsoleFont(C);

		C.StrLen(Cardinal_North, XL, YL);
		DotPos = GetRadarDotPosition(C, Vect(0,-100,0), ViewX, ViewY, Dist * OffsetScale, OffsetY);
		C.SetPos(DotPos.X - 0.5 * XL, DotPos.Y - 0.5 * YL);
		C.DrawText(Cardinal_North, false);

		C.StrLen(Cardinal_East, XL, YL);
		DotPos = GetRadarDotPosition(C, Vect(100,0,0), ViewX, ViewY, Dist * OffsetScale, OffsetY);
		C.SetPos(DotPos.X - 0.5 * XL, DotPos.Y - 0.5 * YL);
		C.DrawText(Cardinal_East, false);

		C.StrLen(Cardinal_South, XL, YL);
		DotPos = GetRadarDotPosition(C, Vect(0,100,0), ViewX, ViewY, Dist * OffsetScale, OffsetY);
		C.SetPos(DotPos.X - 0.5 * XL, DotPos.Y - 0.5 * YL);
		C.DrawText(Cardinal_South, false);

		C.StrLen(Cardinal_West, XL, YL);
		DotPos = GetRadarDotPosition(C, Vect(-100,0,0), ViewX, ViewY, Dist * OffsetScale, OffsetY);
		C.SetPos(DotPos.X - 0.5 * XL, DotPos.Y - 0.5 * YL);
		C.DrawText(Cardinal_West, false);
	}

	C.DrawColor = WhiteColor;
	DotSize = 12 * C.ClipX * HUDScale/1600;
	DotPos = GetRadarDotPosition(C, PawnOwner.Location - Start, ViewX, ViewY, 0.f, OffsetY);
	C.SetPos(DotPos.X - 0.5 * DotSize, DotPos.Y - 0.5 * DotSize);
	C.DrawTile(Material'HudContent.Generic.HUD', DotSize, DotSize, 340, 432, 78, 78);
}

simulated function DrawRadarPassB(Canvas C)
{
	local Pawn P;
	local vector Start, DotPos, ViewX, ViewY, Z;
	local float Dist, RadarWidth, RadarSize, DotSize, OffsetY;
	local float MaxSmartRange, EnemyRange, OffsetScale;
	local int i;

	if (PawnOwner == none)
		return;

	Start = PawnOwner.Location;
	RadarSize = (HudS.RadarScale * 0.01) * HUDScale;
	RadarWidth = 0.5 * RadarSize * C.ClipX;
	OffsetY = (HudS.RadarPosY * 0.01) + RadarWidth/C.ClipY;
	MaxSmartRange = 30000;
	EnemyRange = 5500;
	DotSize = 20 * C.ClipX * HUDScale/1600;
	C.Style = ERenderStyle.STY_Additive;
	OffsetScale = RadarSize * 0.000167;	//0.0000835

	GetAxes(PawnOwner.GetViewRotation(), ViewX, ViewY, Z);

	if (Level.TimeSeconds > LastRadarUpdate + 1)
	{
		LastRadarUpdate = Level.TimeSeconds;
		RadarCache.Length = 0;

		foreach DynamicActors(class'Pawn', P)
		{
			if (P.Health > 0)
			{
				RadarCache[RadarCache.Length] = P;
				Dist = GetRadarDotDist(P.Location - Start, ViewX, ViewY);
				if (Dist < MaxSmartRange)
				{
					Dist = ApplySmartRangeDist(Dist * 1.50);
					if (Monster(P) != none)
					{
						EnemyRange = FMin(EnemyRange, Dist);
						C.DrawColor = C.MakeColor(200,220,64) * (1.f - f_Pulse) + C.MakeColor(220,255,64) * f_Pulse;
						if (Monster(P).bBoss == true)
							C.DrawColor = C.MakeColor(128,64,200) * (1.f - f_Pulse) + C.MakeColor(128,0,200) * f_Pulse;
					}
					else
					{
						C.DrawColor = C.MakeColor(0,0,200) * (1.f - f_Pulse) + C.MakeColor(64,200,200) * f_Pulse;
					}

					DotPos = GetRadarDotPosition(C, P.Location - Start, ViewX, ViewY, Dist * OffsetScale, OffsetY);
					C.SetPos(DotPos.X - 0.5 * DotSize, DotPos.Y - 0.5 * DotSize);
					C.DrawTile(Material'HudContent.Generic.HUD', DotSize, DotSize, 340, 432, 78, 78);
				}
			}
		}
	}
	else
	{
		for(i = 0; i < RadarCache.Length; i++)
		{
			P = RadarCache[i];
			if (P != none && P.Health > 0)
			{
				Dist = GetRadarDotDist(P.Location - Start, ViewX, ViewY);
				if (Dist < MaxSmartRange)
				{
					Dist = ApplySmartRangeDist(Dist * 1.50);
					if (Monster(P) != none)
					{
						EnemyRange = FMin(EnemyRange, Dist);
						C.DrawColor = C.MakeColor(200,220,64) * (1.f - f_Pulse) + C.MakeColor(220,255,64) * f_Pulse;
						if (Monster(P).bBoss == true)
							C.DrawColor = C.MakeColor(128,64,200) * (1.f - f_Pulse) + C.MakeColor(128,0,200) * f_Pulse;
					}
					else
					{
						C.DrawColor = C.MakeColor(0,0,200) * (1.f - f_Pulse) + C.MakeColor(64,200,200) * f_Pulse;
					}

					DotPos = GetRadarDotPosition(C, P.Location-Start, ViewX, ViewY, Dist * OffsetScale, OffsetY);
					C.SetPos(DotPos.X - 0.5 * DotSize, DotPos.Y - 0.5 * DotSize);
					C.DrawTile(Material'HudContent.Generic.HUD', DotSize, DotSize, 340, 432, 78, 78);
				}
			}
		}
	}
}

function float ApplySmartRangeDist(float Dist)
{
	if (Dist > 3000)		   //0.25
		Dist = (Dist - 3000) * 0.75 + 2000;
	else if (Dist > 1000)
		Dist = (Dist - 1000) * 0.50 + 1000;

	return FMin(Dist, 5500);
}

function float GetRadarDotDist(Vector Dist, Vector ViewX, Vector ViewY)
{
	local vector DotProjected;

	DotProjected.X = Dist Dot Normal(ViewX);
	DotProjected.Y = Dist Dot Normal(ViewY);

	return VSize(DotProjected);
}

function vector GetRadarDotPosition(Canvas C, Vector Dist, Vector ViewX, Vector ViewY, float OffsetScale, float OffsetY)
{
	local vector ScreenPosition, DotProjected;

	DotProjected.X = Normal(Dist) Dot Normal(ViewX);
	DotProjected.Y = Normal(Dist) Dot Normal(ViewY);

	ScreenPosition.X = ((HudS.RadarPosX * 0.01) * C.ClipX + OffsetScale * C.ClipX * DotProjected.Y);
	ScreenPosition.Y = (OffsetY * C.ClipY - OffsetScale * C.ClipX * DotProjected.X);

	return ScreenPosition;
}

simulated function DrawTextWithBackground(Canvas C, String Text, Color TextColor, float XO, float YO)
{
	local float XL, YL, XL2, YL2;

	C.StrLen(Text, XL, YL);

	XL2 = XL + 64 * ResScaleX;
	YL2 = YL + 8 * ResScaleY;

	C.DrawColor = C.MakeColor(0, 0, 0, 150);
	C.SetPos(XO - XL2 * 0.5, YO - YL2 * 0.5);
	C.DrawTile(Texture'HudContent.Generic.HUD', XL2, YL2, 168, 211, 166, 44);

	C.DrawColor = TextColor;
	C.SetPos(XO - XL * 0.5, YO - YL * 0.5);
	C.DrawText(Text, false);
}

simulated function Tick(float deltaTime)
{
	Super.Tick(deltaTime);

	f_Blink += deltaTime;
	while(f_Blink > 0.50)
		f_Blink -= 0.50;

	f_Pulse = Abs(1.f - 4 * f_Blink);

	if (GRI != none)
		return;

	if (GRI == none && PlayerOwner.GameReplicationInfo != none)
		GRI = fpsGRI(PlayerOwner.GameReplicationInfo);
}

simulated function DrawBossTime(Canvas C)
{
	local Color myColor;
	local float Seconds;
	local int BC;

	if (PlayerOwner == none || GRI == none || GRI.BossTimeLimit <= 0)
		return;

	C.Font  = GetFontSizeIndex(C, 0);
	C.Style = ERenderStyle.STY_Alpha;
	if (GRI.BossTimeLimit < 61)
		myColor = RedColor * (1.f - f_Pulse) + WhiteColor * f_Pulse;
	else if (GRI.BossTimeLimit < 121)
		myColor = GoldColor * (1.f - f_Pulse) + WhiteColor * f_Pulse;
	else if (GRI.BossTimeLimit < 181)
		myColor = GreenColor * (1.f - f_Pulse) + WhiteColor * f_Pulse;
	else
		myColor = GreenColor;

	Seconds = Max(0, GRI.BossTimeLimit);
	BC = GRI.NumBoss;
	DrawTextWithBackground(C, s_BossTime @ ScoreBoard.FormatTime(Seconds), myColor, C.ClipX * 0.5, C.ClipY * 0.15);

	C.Font  = GetFontSizeIndex(C, -2);
	C.Style = ERenderStyle.STY_Alpha;
	myColor = RedColor;
	DrawTextWithBackground(C, s_BossCount @ BC, myColor, C.ClipX * 0.5, C.ClipY * 0.20);
}

simulated function DrawKillZone(Canvas C)
{
	local Color myColor;
	local float Seconds;
	local int MC;

	if (PlayerOwner == none || GRI == none || GRI.KillZoneLimit <= 0)
		return;

	C.Font  = GetFontSizeIndex(C, 0);
	C.Style = ERenderStyle.STY_Alpha;
	if (GRI.KillZoneLimit < 21)
		myColor = RedColor * (1.f - f_Pulse) + WhiteColor * f_Pulse;
	else if (GRI.KillZoneLimit < 41)
		myColor = GoldColor * (1.f - f_Pulse) + WhiteColor * f_Pulse;
	else if (GRI.KillZoneLimit < 61)
		myColor = GreenColor * (1.f - f_Pulse) + WhiteColor * f_Pulse;
	else
		myColor = GreenColor;

	Seconds = Max(0, GRI.KillZoneLimit);
	MC = GRI.NumMons;
	DrawTextWithBackground(C, s_KillZone @ ScoreBoard.FormatTime(Seconds), myColor, C.ClipX * 0.5, C.ClipY * 0.15);

	C.Font  = GetFontSizeIndex(C, -2);
	C.Style = ERenderStyle.STY_Alpha;
	myColor = RedColor;
	DrawTextWithBackground(C, s_MonsCount @ MC, myColor, C.ClipX * 0.5, C.ClipY * 0.20);
}

function bool CustomCrosshairsAllowed()
{
	return true;
}

function bool CustomCrosshairColorAllowed()
{
	return true;
}

function bool CustomHUDColorAllowed()
{
	return true;
}

defaultproperties
{
	Cardinal_North="N"
	Cardinal_East="E"
	Cardinal_South="S"
	Cardinal_West="W"
	s_BossTime="Boss Time:"
	s_KillZone="Kill Zone:"
	s_MonsCount="Monsters:"
	s_BossCount="Bosses:"
	YouveLostTheMatch="The Invasion Continues"
}