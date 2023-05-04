class UTComp_ScoreBoard extends UTComp_ScoreBoardDM
	Config(fpsGameClient);

var Font MainFont, NotReducedFont, SortaReducedFont, ReducedFont, SoTiny;

var localized string FragLimitTeam;
var int TmpFontSize;
var float tmp1, tmp2, tmp3;
var config bool bEnableColoredNamesOnScoreboard;
var config bool bDrawStats, bDrawPickups;
var config bool bOverrideDisplayStats;

function DrawTitle2(Canvas Canvas)
{
	local string titlestring, scoreinfostring, RestartString;
	local float xl, yl, Full, Height, Top, MedH, SmallH, TitleXL, ScoreInfoXL;

	Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
	Canvas.StrLen("W", xl, MedH);
	Height = MedH;
	Canvas.Font = HUDClass.static.GetConsoleFont(Canvas);
	Canvas.StrLen("W", xl, SmallH);
	Height += SmallH;

	Full = Height;
	Top = Canvas.ClipY-8-Full;

	TitleString = GetTitleString();
	ScoreInfoString = GetDefaultScoreInfoString();

	Canvas.StrLen(TitleString, TitleXL, YL);
	Canvas.DrawColor = HUDClass.default.GoldColor;

	if (UnrealPlayer(Owner).bDisplayLoser)
	{
		ScoreInfoString = class'HUDBase'.default.YouveLostTheMatch;
	}
	else if (UnrealPlayer(Owner).bDisplayWinner)
	{
		ScoreInfoString = class'HUDBase'.default.YouveWonTheMatch;
	}
	else if (PlayerController(Owner).IsDead())
	{
		RestartString = GetRestartString();
		ScoreInfoString = RestartString;
	}
	Canvas.StrLen(ScoreInfoString, ScoreInfoXL, YL);

	Canvas.Font = NotReducedFont;
	Canvas.SetDrawColor(255,150,0,255);
	Canvas.StrLen(TitleString, TitleXL, YL);
	Canvas.SetPos((Canvas.ClipX/2) - (TitleXL/2), Canvas.ClipY*0.03);
	Canvas.DrawText(TitleString);

	Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
	Canvas.StrLen(ScoreInfoString, ScoreInfoXL, YL);
	Canvas.SetPos((Canvas.ClipX/2) - (ScoreInfoXL/2), Top + (Full/2) - (YL/2));
	Canvas.DrawText(ScoreInfoString);
}

function String GetRestartString()
{
	local string RestartString;

	RestartString = Restart;
	if (PlayerController(Owner).PlayerReplicationInfo.bOutOfLives)
		RestartString = OutFireText;
	else if (Level.TimeSeconds - UnrealPlayer(Owner).LastKickWarningTime < 2)
		RestartString = class'GameMessage'.default.KickWarning;

	return RestartString;
}

function String GetTitleString()
{
	local string titlestring;

	if (Level.NetMode == NM_Standalone)
	{
		if (Level.Game.CurrentGameProfile != none)
			titlestring = SkillLevel[Clamp(Level.Game.CurrentGameProfile.BaseDifficulty, 0, 7)];
		else
			titlestring = SkillLevel[Clamp(Level.Game.GameDifficulty, 0, 7)];
	}
	else if (GRI != none && GRI.BotDifficulty >= 0)
	{
		titlestring = SkillLevel[Clamp(GRI.BotDifficulty, 0, 7)];
	}

	return titlestring @ GRI.GameName $ MapName $ Level.Title;
}

function String GetDefaultScoreInfoString()
{
	local string ScoreInfoString;

	if (GRI.MaxLives != 0)
	{
		ScoreInfoString = MaxLives@GRI.MaxLives;
	}
	else if (GRI.GoalScore != 0)
	{
		if (!GRI.bTeamGame)
			ScoreInfoString = FragLimit @ GRI.GoalScore;
		else
			ScoreInfoString = FragLimitTeam @ GRI.GoalScore;
	}

	if (GRI.TimeLimit != 0)
		ScoreInfoString = ScoreInfoString @ spacer @ TimeLimit $ FormatTime(GRI.RemainingTime);
	else
		ScoreInfoString = ScoreInfoString @ spacer @ FooterText @ FormatTime(GRI.ElapsedTime);

	return ScoreInfoString;
}

simulated function DrawTCMBar(Canvas C , float Scale)
{
	// Border
	C.SetPos(0,0);
	C.Style = 5;
	C.SetDrawColor(255,255,255,180);
	C.DrawTileStretched(Material'Engine.BlackTexture', C.ClipX, C.ClipY*0.066);

	// TCM Logo
	C.SetPos(0,0);
	C.DrawTile(Material'bg_logo', (512*0.75)*Scale, (128*0.75)*Scale, 0, 0, 256, 64);
}

simulated function DrawTeamInfoBox(Canvas C, float StartX, float StartY, int TeamNum, float scale, int mPlayerCount)
{
	local int i, NewPosY;
	local float NewBoxYscale;
	local bool bDraw;

	bDraw = false;
	NewBoxYscale = ((C.ClipY*0.055)*mPlayerCount)+C.ClipY*0.035;
	C.Style = 5;
	if (TeamNum == 0)
		C.SetDrawColor(0,0,255,35);
	else if (TeamNum == 1)
		C.SetDrawColor(255,0,0,35);
	else
		C.SetDrawColor(150,150,150,35);

	// Main Colored background
	C.SetPos(C.ClipX *StartX,C.ClipY*StartY);
	C.DrawTileStretched(Material'Engine.WhiteTexture', C.ClipX*0.472, NewBoxYscale);

	// TitleBar
	C.SetDrawColor(255,255,255,200);
	C.SetPos(C.ClipX *StartX, C.ClipY*StartY);
	C.DrawTileStretched(Material'Engine.BlackTexture', C.ClipX*0.472, C.ClipY*0.035);

	NewPosY = (C.ClipY*(StartY+0.035));
	for(i = 0; i < mPlayerCount; i++)
	{
		if (bDraw)
		{
			bDraw = false;
			C.SetDrawColor(255,255,255,30);
			C.SetPos(C.ClipX *StartX, NewPosY);
			C.DrawTileStretched(Material'Engine.WhiteTexture', C.ClipX*0.472, C.ClipY*0.055);
		}
		else
		{
			bDraw = true;
		}

		NewPosY += (C.ClipY*0.055);
	}

	// Trim for box
	C.SetDrawColor(255,255,255,255);
	C.SetPos(C.ClipX *StartX, C.ClipY*StartY);
	C.DrawTileStretched(Material'Engine.BlackTexture', C.ClipX*0.472, 1);

	C.SetPos(C.ClipX *StartX, C.ClipY*StartY);
	C.DrawTileStretched(Material'Engine.BlackTexture', 1, NewBoxYscale);

	C.SetPos((C.ClipX *StartX + C.ClipX*0.472), C.ClipY*StartY);
	C.DrawTileStretched(Material'Engine.BlackTexture', 1, NewBoxYscale);

	C.SetPos(C.ClipX *StartX, (C.ClipY*StartY + NewBoxYscale));
	C.DrawTileStretched(Material'Engine.BlackTexture', C.ClipX*0.472, 1);

	C.SetPos((C.ClipX *StartX + C.ClipX*0.086), C.ClipY*StartY);
	C.DrawTileStretched(Material'Engine.BlackTexture', 1, NewBoxYscale);

	// scoreboard texture
	C.SetPos(C.ClipX *StartX-(C.ClipX*0.025), C.ClipY*StartY -(C.ClipY*0.030));
	C.DrawTile(Material'sb_main', (256*1.0)*Scale, (64*1.0)*Scale, 0, 0, 1024, 256);
	//C.DrawTile(Material'sb_main',(256*1.0)*Scale,(64*1.0)*Scale,0,0,128,32);
}

simulated event UpdateScoreBoard(Canvas C)
{
	local PlayerReplicationInfo PRI, OwnerPRI;
	local PlayerReplicationInfo RedPRI[MAXPLAYERS], BluePRI[MaxPlayers], SpecPRI[MaxPlayers];
	local int i, j, BluePlayerCount, RedPlayerCount, RedOwnerOffset, BlueOwnerOffset, maxTiles, numspecs;
	local float MyScale;
	local bool bOwnerDrawn;

	MainFont = HUDClass.static.GetMediumFontFor(C);
	NotReducedFont = GetSmallerFontfor(C, TmpFontSize);
	SortaReducedFont = GetSmallerFontfor(C, 2);
	ReducedFont = GetSmallerFontfor(C, 3);
	SmallerFont = GetSmallerFontfor(C, 4);
	SoTiny = GetSmallerFontfor(C, 5);
	maxTiles = 8;
	if (Owner != none)
		OwnerPRI = PlayerController(Owner).PlayerReplicationInfo;
	RedOwnerOffset = -1;
	BlueOwnerOffset = -1;

	if (!GRI.bTeamGame && GRI.PRIArray.Length > 10)
	{
		for(i = 0; i < GRI.PRIArray.Length; i++)
		{
			PRI = GRI.PRIArray[i];
			if (!PRI.bOnlySpectator)
				j++;
		}

		if (j > 10)
		{
			Super.UpdateScoreBoard(C);
			return;
		}
	}

	for(i = 0; i < GRI.PRIArray.Length; i++)
	{
		PRI = GRI.PRIArray[i];
		if (PRI.bOnlySpectator)
		{
			SpecPRI[numSpecs] = PRI;
			numSpecs++;
		}

		if (!PRI.bOnlySpectator || PRI.bWaitingPlayer)
		{
			if (PRI.Team == none)
			{
				if (RedPlayerCount < MAXPLAYERS)
				{
					RedPRI[RedPlayerCount] = PRI;
					if (PRI == OwnerPRI)
						RedOwnerOffset = RedPlayerCount;
					RedPlayerCount++;
				}
			}
			else if (PRI.Team.TeamIndex == 0)
			{
				if (RedPlayerCount < MAXPLAYERS)
				{
					RedPRI[RedPlayerCount] = PRI;
					if (PRI == OwnerPRI)
						RedOwnerOffset = RedPlayerCount;
					RedPlayerCount++;
				}
			}
			else if (BluePlayerCount < MAXPLAYERS)
			{
				BluePRI[BluePlayerCount] = PRI;
				if (PRI == OwnerPRI)
					BlueOwnerOffset = BluePlayerCount;
				BluePlayerCount++;
			}
		}
	}

	MyScale = C.ClipX/1600;
	DrawTCMBar(C, MyScale);
	DrawTitle2(C);
	//if (GRI.bTeamGame)
	//{
	//	DrawTeamInfoBox(C, 0.02, 0.12, 1, MyScale, Min(RedPlayerCount, maxTiles));  // RedTeam
	//	DrawTeamInfoBox(C, 0.514, 0.12, 0, MyScale, Min(BluePlayerCount, maxTiles)); // BlueTeam
	//}
	//else
	//{
		DrawTeamInfoBox(C, 0.252, 0.12, 2, MyScale, Min(RedPlayerCount, maxTiles)); // Deathmatch Team
	//}
	C.SetDrawColor(255,255,255,255);

	C.Font = MainFont;
/*
	if (GRI.bTeamGame)
	{
		C.SetPos((C.ClipX/2)/2, C.ClipY*0.085);	// Red
		C.DrawText(int(GRI.Teams[0].Score));
		C.SetPos(((C.ClipX/2)+(C.ClipX/2)/2), C.ClipY*0.085);	// Blue
		C.DrawText(int(GRI.Teams[1].Score));

		C.Font = SmallerFont;
		C.SetPos((C.ClipX/2)/2 + C.ClipX*0.1150, C.ClipY*0.130);// Red
		C.DrawText("Avg ping:" @ GetAverageTeamPing(0));
		C.SetPos(((C.ClipX/2)+(C.ClipX/2)/2+C.ClipX*0.1150), C.ClipY*0.130);// Blue
		C.DrawText("Avg ping:" @ GetAverageTeamPing(1));
		C.Font = MainFont;
	}
*/
	if ((FPHTime == 0 || (!UnrealPlayer(Owner).bDisplayLoser && !UnrealPlayer(Owner).bDisplayWinner)) && GRI.ElapsedTime > 0)
		FPHTime = GRI.ElapsedTime;

/*
	if (GRI.bTeamGame)
	{
		for(i = 0; i < RedPlayerCount && i < maxTiles; i++)
		{
			if (!RedPRI[i].bOnlySpectator)
			{
				if (i == (maxTiles-1) && !bOwnerDrawn && OwnerPRI.Team != none && OwnerPRI.Team.TeamIndex == 0 && !OwnerPRI.bOnlySpectator)
					DrawPlayerInformation(C, OwnerPRI, C.ClipX*(0.003), (C.ClipY*0.055)*i, MyScale);
				else
					DrawPlayerInformation(C, RedPRI[i], C.ClipX*(0.003), (C.ClipY*0.055)*i, MyScale);

				if (RedPRI[i] == OwnerPRI)
					bOwnerDrawn = true;
			}
		}
	}
	else
	{
*/
		for(i = 0; i < RedPlayerCount && i < maxTiles; i++)
		{
			if (!RedPRI[i].bOnlySpectator)
			{
				if (i == (maxTiles-1) && !bOwnerDrawn && !OwnerPRI.bOnlySpectator)
					DrawPlayerInformation(C, OwnerPRI, C.Clipx*0.236, (C.ClipY*0.055)*i, MyScale);
				else
					DrawPlayerInformation(C, RedPRI[i], C.Clipx*0.236, (C.ClipY*0.055)*i, MyScale);

				if (RedPRI[i] == OwnerPRI)
					bOwnerDrawn = true;
			}
		}
//	}

	for(i = 0; i < BluePlayerCount && i < maxTiles; i++)
	{
		if (!BluePRI[i].bOnlySpectator)
		{
			if (i == (maxTiles-1) && !bOwnerDrawn && OwnerPRI.Team != none && OwnerPRI.Team.TeamIndex == 1 && !OwnerPRI.bOnlySpectator)
				DrawPlayerInformation(C, OwnerPRI, C.ClipX*0.496, (C.ClipY*0.055)*i, MyScale);
			else
				DrawPlayerInformation(C, BluePRI[i], C.ClipX*0.496, (C.ClipY*0.055)*i, MyScale);

			if (BluePRI[i] == OwnerPRI)
				bOwnerDrawn = true;
		}
	}
	DrawStats(C);
	DrawPowerups(C);

	if (numSpecs > 0)
	{
		ArrangeSpecs(SpecPRI);
		for(i = 0; i < numspecs && SpecPRI[i] != none; i++)
			DrawSpecs(C, SpecPRI[i], i);

		DrawSpecs(C, none, i);
	}
}

function ArrangeSpecs(out PlayerReplicationInfo PRI[MAXPLAYERS])
{}

simulated function string GetAverageTeamPing(byte team)
{
	local float avg;
	local int i, NumSamples;

	for(i = 0; i < GRI.PRIArray.Length; i++)
	{
		if (!GRI.PRIArray[i].bOnlySpectator && GRI.PRIArray[i].Team != none && GRI.PRIArray[i].Team.TeamIndex == team)
		{
			Avg += GRI.PRIArray[i].Ping;
			NumSamples++;
		}
	}

	if (NumSamples == 0)
		return "";

	return string(int(4.0*Avg/float(NumSamples)));
}

simulated function DrawPlayerInformation(Canvas C, PlayerReplicationInfo PRI, float XOffset, float YOffset, float Scale)
{
	local float tmpEff, oldClipX;
	local int i, otherteam;
	local PlayerReplicationInfo OwnerPRI;
	local UTComp_PRI uPRI;
	local string AdminString;

	if (Owner != none)
		OwnerPRI = PlayerController(Owner).PlayerReplicationInfo;

	uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRI);

	if (PRI.bAdmin)
		AdminString = "Admin";

//	Draw Player name
	C.Font = NotReducedFont;
	C.SetPos(C.ClipX*0.188+XOffset, (C.ClipY*0.159)+YOffset);
	oldClipX = C.ClipX;
	C.ClipX = C.ClipX*0.470+XOffset;

	if (default.bEnableColoredNamesOnScoreboard && uPRI != none && uPRI.ColoredName != "")
	{
		C.DrawTextClipped(uPRI.ColoredName $ AdminString);
	}
	else
	{
		C.SetDrawColor(255,255,255,255);
		C.DrawTextClipped(PRI.PlayerName $ AdminString);
	}
	C.ClipX = OldClipX;

	for(i = 0; i < MAXPLAYERS; i++)
	{
		if (PRI == OwnerPRI)
			C.SetDrawColor(255,255,0,255);
		else
			C.SetDrawColor(255,255,255,255);
	}

//	DrawScore
	if (PRI.Score > 99)
		C.Font = SortaReducedFont;
	else
		C.Font = NotReducedFont;

	if (PRI.bOutOfLives)
	{
		C.SetPos(C.ClipX*0.0190+XOffset, (C.ClipY*0.159)+YOffset);
		C.DrawText("OUT");
	}
	else
	{
		C.DrawTextJustified(int(PRI.Score), 0, C.ClipX*0.0190+XOffset, C.ClipY*0.159+YOffset, C.ClipX*0.068+XOffset, C.ClipY*0.204+Yoffset);
	}

	if (PRI.Team != none && PRI.Team.TeamIndex == 0)
		OtherTeam = 1;
	else
		OtherTeam = 0;

//	flag state
	if (PRI.Team != none && (GRI.FlagState[OtherTeam] != EFlagState.FLAG_Home) && (GRI.FlagState[OtherTeam] != EFlagState.FLAG_Down) && (PRI.HasFlag != none || PRI == GRI.FlagHolder[PRI.Team.TeamIndex]))
	{
		C.SetDrawColor(255,255,255,255);
		C.SetPos(C.ClipX*0.41+XOffset, (C.ClipY*0.159)+YOffset);
		C.DrawTile(Material'xInterface.S_FlagIcon', 90*scale, 64*Scale, 0, 0, 90, 64);
	}

//	Player Deaths
	if (PRI.Deaths > 99)
		C.Font = SmallerFont;
	else
		C.Font = ReducedFont;
	C.SetDrawColor(255,0,0,255);
	C.SetPos(C.ClipX*0.070+XOffset, (C.ClipY*0.159)+YOffset);
	C.DrawText(int(PRI.Deaths));

//	Player Effeciency
	if (uPRI.RealKills - PRI.Deaths > 99)
		C.Font = SmallerFont;
	else
		C.Font = ReducedFont;
	C.SetPos(C.ClipX*0.070+XOffset, (C.ClipY*0.187)+YOffset);
	C.SetDrawColor(0,200,255,255);
	tmpEff = (uPRI.RealKills - PRI.Deaths);
	C.DrawText(int(tmpEff));

//	Net Info
	C.Font = SmallerFont;
	if (PRI == OwnerPRI)
		C.SetDrawColor(255,255,0,255);
	else
		C.SetDrawColor(255,255,255,255);

	if (Level.NetMode != NM_Standalone)
	{
		C.SetPos(C.ClipX*0.108+XOffset, (C.ClipY*tmp1)+YOffset);
		C.DrawText("Ping:" $ Min(999, 4*PRI.Ping));

		C.SetPos(C.ClipX*0.108+XOffset, (C.ClipY*tmp2)+YOffset);
		C.DrawText("P/L :" $ PRI.PacketLoss);
	}

	C.SetPos(C.ClipX*0.108+XOffset, (C.ClipY*tmp3)+YOffset);
	C.DrawText(FormatTime(Max(0, FPHTime - PRI.StartTime)));

//	Location Name, Hide if Player is using HUDTeamoverlay
	if (OwnerPRI.bOnlySpectator || (PRI.Team != none && OwnerPRI.Team != none && PRI.Team.TeamIndex == OwnerPRI.Team.TeamIndex))
	{
		C.SetDrawColor(255,150,0,255);
		C.SetPos(C.ClipX*0.21+XOffset, (C.ClipY*tmp3)+YOffset);
		C.DrawText(Left(PRI.GetLocationName(), 30));
	}
}

defaultproperties
{
	FragLimitTeam="SCORE LIMIT:"
	TmpFontSize=1
	tmp1=0.156000
	tmp2=0.172000
	tmp3=0.189000
	bEnableColoredNamesOnScoreboard=true
	bDrawStats=true
	bDrawPickups=true
}