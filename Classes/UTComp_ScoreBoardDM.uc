class UTComp_ScoreBoardDM extends ScoreBoardDeathMatch;

var Font SmallerFont;

function DrawNetInfo(Canvas Canvas, int FontReduction, int HeaderOffsetY, int PlayerBoxSizeY, int BoxSpaceY, int BoxTextOffsetY, int OwnerOffset, int PlayerCount, int NetXPos)
{
	local float XL, YL;
	local int i;
	local bool bHaveHalfFont, bDrawFPH, bDrawPL;
	local UTComp_PRI uPRI;

	// draw admins
	if (GRI.bMatchHasBegun)
	{
		Canvas.DrawColor = HUDClass.default.RedColor;
		for(i = 0; i < PlayerCount; i++)
		{
			if (PRIArray[i].bAdmin)
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
				Canvas.DrawText(AdminText, true);
			}
		}

		if ((OwnerOffset >= PlayerCount) && PRIArray[OwnerOffset].bAdmin)
		{
			Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY);
			Canvas.DrawText(AdminText, true);
		}
	}

	Canvas.DrawColor = HUDClass.default.CyanColor;
	Canvas.Font = GetSmallFontFor(Canvas.ClipX, FontReduction);
	Canvas.StrLen("Test", XL, YL);
	BoxTextOffsetY = HeaderOffsetY + 0.5*PlayerBoxSizeY;
	bHaveHalfFont = (YL < 0.5 * PlayerBoxSizeY);

	// if game hasn't begun, draw ready or not ready
	if (!GRI.bMatchHasBegun)
	{
		bDrawPL = PlayerBoxSizeY > 3 * YL;
		for(i = 0; i < PlayerCount; i++)
		{
			if (bDrawPL)
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 1.4 * YL);
				Canvas.DrawText(PingText @ Min(999, 4*PRIArray[i].Ping), true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5 * YL);
				Canvas.DrawText(PLText @ PRIArray[i].PacketLoss, true);
			}
			else if (bHaveHalfFont)
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - YL);
				Canvas.DrawText(PingText @ Min(999,4*PRIArray[i].Ping),true);
			}
			else
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5*YL);
			}

			if (PRIArray[i].bReadyToPlay)
				Canvas.DrawText(ReadyText, true);
			else
				Canvas.DrawText(NotReadyText, true);
		}
		return;
	}

	// draw time and ping
	if (Canvas.ClipX < 512)
	{
		PingText = "";
	}
	else
	{
		PingText = default.PingText;
		bDrawFPH = PlayerBoxSizeY > 3 * YL;
		bDrawPL = PlayerBoxSizeY > 4 * YL;
	}

	if (((FPHTime == 0) || (!UnrealPlayer(Owner).bDisplayLoser && !UnrealPlayer(Owner).bDisplayWinner)) && (GRI.ElapsedTime > 0))
		FPHTime = GRI.ElapsedTime;

	for(i = 0; i < PlayerCount; i++)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRIArray[i]);
		if (!PRIArray[i].bAdmin && !PRIArray[i].bOutOfLives)
 		{
 			if (bDrawPL)
 			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 1.9 * YL);
				Canvas.DrawText(PingText @ Min(999, 4*PRIArray[i].Ping), true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.9 * YL);
				Canvas.DrawText(PLText @ PRIArray[i].PacketLoss, true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY + 0.1 * YL);
				Canvas.DrawText(FPH @ Clamp(3600*PRIArray[i].Score/FMax(1, FPHTime - PRIArray[i].StartTime), -999, 9999), true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY + 1.1 * YL);
				Canvas.DrawText(FormatTime(Max(0, FPHTime - PRIArray[i].StartTime)), true);
			}
			else if (bDrawFPH)
 			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 1.4 * YL);
				Canvas.DrawText(PingText @ Min(999, 4*PRIArray[i].Ping), true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5 * YL);
				Canvas.DrawText(FPH @ Clamp(3600*PRIArray[i].Score/FMax(1, FPHTime - PRIArray[i].StartTime), -999, 9999), true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY + 0.5 * YL);
				Canvas.DrawText(FormatTime(Max(0, FPHTime - PRIArray[i].StartTime)), true);
			}
			else if (bHaveHalfFont)
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - YL);
				Canvas.DrawText(PingText @ Min(999,4*PRIArray[i].Ping), true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
				Canvas.DrawText(FormatTime(Max(0, FPHTime - PRIArray[i].StartTime)), true);
			}
			else
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5*YL);
				Canvas.DrawText(PingText @ Min(999, 4*PRIArray[i].Ping), true);
			}
		}
	}

	if ((OwnerOffset >= PlayerCount) && !PRIArray[OwnerOffset].bAdmin && !PRIArray[OwnerOffset].bOutOfLives)
	{
 		uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRIArray[OwnerOffset]);
		if (bDrawFPH)
 		{
			Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 1.4 * YL);
			Canvas.DrawText(PingText @ Min(999, 4*PRIArray[OwnerOffset].Ping), true);
			Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5 * YL);
			Canvas.DrawText(FormatTime(Max(0, FPHTime - PRIArray[OwnerOffset].StartTime)), true);
		}
		else if (bHaveHalfFont)
		{
			Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - YL);
			Canvas.DrawText(PingText @ Min(999, 4*PRIArray[OwnerOffset].Ping), true);
		}
		else
		{
			Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5*YL);
			Canvas.DrawText(PingText @ Min(999, 4*PRIArray[OwnerOffset].Ping), true);
		}
	}
}

simulated event UpdateScoreBoard(Canvas Canvas)
{
	local PlayerReplicationInfo PRI, OwnerPRI;
	local array<PlayerReplicationInfo> SpecPRI;
	local int i, FontReduction, PlayerCount, numSpecs;
	local int BoxXPos, TitleYPos, OwnerOffset, OwnerPos, NameXPos, ScoreXPos, DeathsXPos, NetXPos;
	local int HeadFoot, MessageFoot, BoxWidth, BoxSpaceY, BoxTextOffsetY, HeaderOffsetY, PlayerBoxSizeY;
	local float XL, YL, MaxScaling, deathsXL, scoreXL, netXL, MaxNamePos, LongestNameLength;
	local string playername[MAXPLAYERS], LongestName;
	local bool bNameFontReduction;
	local Font ReducedFont;
	local UTComp_PRI uPRI;

	OwnerPRI = PlayerController(Owner).PlayerReplicationInfo;
	for(i = 0; i < GRI.PRIArray.Length; i++)
	{
		PRI = GRI.PRIArray[i];
		if (!PRI.bOnlySpectator && (!PRI.bIsSpectator || PRI.bWaitingPlayer))
		{
			if (PRI == OwnerPRI)
				OwnerOffset = i;
			PlayerCount++;
		}
	}
	PlayerCount = Min(PlayerCount, MAXPLAYERS);
	SmallerFont  = GetSmallerFontfor(Canvas, 4);

	// Select best font size and box size to fit as many players as possible on screen
	Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
	Canvas.StrLen("Test", XL, YL);
	BoxSpaceY = 0.25 * YL;
	PlayerBoxSizeY = 1.4 * YL;
	HeadFoot = 5 * YL;
	MessageFoot = 1.4 * HeadFoot;
	if (PlayerCount > (Canvas.ClipY*0.80 - 1.4 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY))
	{
		BoxSpaceY = 0.125 * YL;
		PlayerBoxSizeY = 1.25 * YL;
		if (PlayerCount > (Canvas.ClipY*0.80 - 1.4 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY))
		{
			if (PlayerCount > (Canvas.ClipY*0.80 - 1.4 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY))
				PlayerBoxSizeY = 1.125 * YL;

			if (PlayerCount > (Canvas.ClipY*0.80 - 1.4 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY))
			{
				FontReduction++;
				Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);
				Canvas.StrLen("Test", XL, YL);
				BoxSpaceY = 0.125 * YL;
				PlayerBoxSizeY = 1.125 * YL;
				HeadFoot = 5 * YL;
				if (PlayerCount > (Canvas.ClipY*0.80 - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY))
				{
					FontReduction++;
					Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);
					Canvas.StrLen("Test", XL, YL);
					BoxSpaceY = 0.125 * YL;
					PlayerBoxSizeY = 1.125 * YL;
					HeadFoot = 5 * YL;
					if ((Canvas.ClipY >= 768) && (PlayerCount > (Canvas.ClipY*0.80 - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY)))
					{
						FontReduction++;
						Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);
						Canvas.StrLen("Test", XL, YL);
						BoxSpaceY = 0.125 * YL;
						PlayerBoxSizeY = 1.125 * YL;
						HeadFoot = 5 * YL;
					}
				}
			}
		}
	}

	if (Canvas.ClipX < 512)
		PlayerCount = Min(PlayerCount, 1+(Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY));
	else
		PlayerCount = Min(PlayerCount, (Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY));
	if (OwnerOffset >= PlayerCount)
		PlayerCount -= 1;

	if (FontReduction > 2)
		MaxScaling = 3;
	else
		MaxScaling = 2.125;
	PlayerBoxSizeY = FClamp((1+(Canvas.ClipY*0.80 - 0.67 * MessageFoot))/PlayerCount - BoxSpaceY, PlayerBoxSizeY, MaxScaling * YL);

	bDisplayMessages = !class'UTcomp_ScoreBoard'.default.bDrawStats;
	HeaderOffsetY = 3 * YL;
	BoxWidth = 0.9375 * Canvas.ClipX;
	BoxXPos = 0.5 * (Canvas.ClipX - BoxWidth);
	BoxWidth = Canvas.ClipX - 2*BoxXPos;
	NameXPos = BoxXPos + 0.0625 * BoxWidth;
	ScoreXPos = BoxXPos + 0.5 * BoxWidth;
	DeathsXPos = BoxXPos + 0.6875 * BoxWidth;
	NetXPos = BoxXPos + 0.8125 * BoxWidth;

	// draw background boxes
	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.DrawColor = HUDClass.default.WhiteColor * 0.5;
	for(i = 0; i < PlayerCount; i++)
	{
		Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY)*i);
		Canvas.DrawTileStretched(BoxMaterial, BoxWidth, PlayerBoxSizeY);
	}
	Canvas.Style = ERenderStyle.STY_Translucent;

	// draw title
	Canvas.Style = ERenderStyle.STY_Normal;
	DrawTitle(Canvas, HeaderOffsetY, (PlayerCount+1)*(PlayerBoxSizeY + BoxSpaceY), PlayerBoxSizeY);

	// Draw headers
	TitleYPos = HeaderOffsetY - 1.25*YL;
	Canvas.StrLen(PointsText, ScoreXL, YL);
	Canvas.StrLen(DeathsText, DeathsXL, YL);

	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(NameXPos, TitleYPos);
	Canvas.DrawText(PlayerText, true);
	Canvas.SetPos(ScoreXPos - 0.5*ScoreXL, TitleYPos);
	Canvas.DrawText(PointsText, true);
	Canvas.SetPos(DeathsXPos - 0.5*DeathsXL, TitleYPos);
	Canvas.DrawText(DeathsText, true);

	if (PlayerCount <= 0)
		return;

	// draw player names
	MaxNamePos = 0.9 * (ScoreXPos - NameXPos);
	for(i = 0; i < PlayerCount; i++)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRI(GRI.PRIArray[i]);
		if (class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard == true)
		{
			playername[i] = uPRI.ColoredName;
			if (PlayerName[i] == "")
				PlayerName[i] = GRI.PRIArray[i].PlayerName;
		}
		else
		{
			playername[i] = GRI.PRIArray[i].PlayerName;
		}

		Canvas.StrLen(playername[i], XL, YL);
		if (XL > FMax(LongestNameLength, MaxNamePos))
		{
			LongestName = PlayerName[i];
			LongestNameLength = XL;
		}
	}

	if (OwnerOffset >= PlayerCount)
	{
			uPRI = class'UTComp_Util'.static.GetUTCompPRI(GRI.PRIArray[OwnerOffset]);
		if (class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard == true)
		{
			playername[OwnerOffset] = uPRI.ColoredName;
			if (PlayerName[OwnerOffset] == "")
				PlayerName[OwnerOffset] = GRI.PRIArray[OwnerOffset].PlayerName;
		}
		else
		{
			playername[OwnerOffset] = GRI.PRIArray[OwnerOffset].PlayerName;
		}

		Canvas.StrLen(playername[OwnerOffset], XL, YL);
		if (XL > FMax(LongestNameLength, MaxNamePos))
		{
			LongestName = PlayerName[i];
			LongestNameLength = XL;
		}
	}

	if (LongestNameLength > 0)
	{
		bNameFontReduction = true;
		Canvas.Font = GetSmallerFontFor(Canvas, FontReduction+1);
		Canvas.StrLen(LongestName, XL, YL);
		if (XL > MaxNamePos)
		{
			Canvas.Font = GetSmallerFontFor(Canvas, FontReduction+2);
			Canvas.StrLen(LongestName, XL, YL);
			if (XL > MaxNamePos)
				Canvas.Font = GetSmallerFontFor(Canvas, FontReduction+3);
		}
		ReducedFont = Canvas.Font;
	}

	for(i = 0; i < PlayerCount; i++)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRI(GRI.PRIArray[i]);
		if (class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard == true)
		{
			playername[i] = uPRI.ColoredName;
			if (PlayerName[i] == "")
				PlayerName[i] = GRI.PRIArray[i].PlayerName;
		}
		else
		{
			playername[i] = GRI.PRIArray[i].PlayerName;
		}

		Canvas.StrLen(playername[i], XL, YL);
		if (XL > MaxNamePos)
			playername[i] = Left(playername[i], MaxNamePos/XL * Len(PlayerName[i]));
	}

	if (OwnerOffset >= PlayerCount)
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRI(GRI.PRIArray[OwnerOffset]);
		if (class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard == true)
		{
			playername[OwnerOffset] = uPRI.ColoredName;
			if (PlayerName[OwnerOffset] == "")
				PlayerName[OwnerOffset] = GRI.PRIArray[OwnerOffset].PlayerName;
		}
		else
		{
			playername[OwnerOffset] = GRI.PRIArray[OwnerOffset].PlayerName;
		}

		Canvas.StrLen(playername[OwnerOffset], XL, YL);
		if (XL > MaxNamePos)
			playername[OwnerOffset] = Left(playername[OwnerOffset], MaxNamePos/XL * Len(PlayerName[OwnerOffset]));
	}

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);
	BoxTextOffsetY = HeaderOffsetY + 0.5 * (PlayerBoxSizeY - YL);

	Canvas.DrawColor = HUDClass.default.WhiteColor;
	for(i = 0; i < PlayerCount; i++)
	{
		if (i != OwnerOffset)
		{
			Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
			Canvas.DrawText(playername[i], true);
		}
	}

	if (bNameFontReduction)
		Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);

	// draw scores
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	for(i = 0; i < PlayerCount; i++)
	{
		if (i != OwnerOffset)
		{
			Canvas.SetPos(ScoreXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
			if (GRI.PRIArray[i].bOutOfLives)
				Canvas.DrawText(OutText, true);
			else
				Canvas.DrawText(int(GRI.PRIArray[i].Score), true);
		}
	}

	// draw deaths
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	for(i = 0; i < PlayerCount; i++)
	{
		if (i != OwnerOffset)
		{
			Canvas.SetPos(DeathsXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
			Canvas.DrawText(int(GRI.PRIArray[i].Deaths), true);
		}
	}

	// draw owner line
	if (OwnerOffset >= PlayerCount)
	{
		OwnerPos = (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY;
		// draw extra box
		Canvas.Style = ERenderStyle.STY_Alpha;
		Canvas.DrawColor = HUDClass.default.TurqColor * 0.5;
		Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY)*PlayerCount);
		Canvas.DrawTileStretched(BoxMaterial, BoxWidth, PlayerBoxSizeY);
		Canvas.Style = ERenderStyle.STY_Normal;
	}
	else
	{
		OwnerPos = (PlayerBoxSizeY + BoxSpaceY)*OwnerOffset + BoxTextOffsetY;
	}

	Canvas.DrawColor = HUDClass.default.GoldColor;
	Canvas.SetPos(NameXPos, OwnerPos);
	if (bNameFontReduction)
		Canvas.Font = ReducedFont;

	Canvas.DrawText(playername[OwnerOffset], true);
	if (bNameFontReduction)
		Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);

	Canvas.DrawColor = HUDClass.default.GoldColor;
	Canvas.SetPos(ScoreXPos, OwnerPos);
	if (GRI.PRIArray[OwnerOffset].bOutOfLives)
		Canvas.DrawText(OutText, true);
	else
		Canvas.DrawText(int(GRI.PRIArray[OwnerOffset].Score), true);
	Canvas.SetPos(DeathsXPos, OwnerPos);
	Canvas.DrawText(int(GRI.PRIArray[OwnerOffset].Deaths), true);

	for(i = 0; i < GRI.PRIArray.Length; i++)
	{
		PRIArray[i] = GRI.PRIArray[i];
		if (PRIArray[i].bOnlySpectator)
		{
			SpecPRI[SpecPRI.Length] = PRIArray[i];
			numSpecs++;
		}
	}

	ExtraMarking(Canvas, PlayerCount, OwnerOffset, NameXPos, PlayerBoxSizeY + BoxSpaceY, BoxTextOffsetY);
	if (PlayerCount <= 15)
	{
		DrawStats(Canvas);
		DrawPowerUps(Canvas);
	}

	if (numSpecs > 0)
	{
		for(i = 0; i < numspecs && specPRI[i] != None; i++)
			DrawSpecs(Canvas, SpecPRI[i], i);

		DrawSpecs(Canvas, none, i);
	}

	if (Level.NetMode == NM_Standalone)
		return;

	Canvas.StrLen(NetText, NetXL, YL);
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(NetXPos + 0.5*NetXL, TitleYPos);
	Canvas.DrawText(NetText, true);

	for(i = 0; i < GRI.PRIArray.Length; i++)
	{
		PRIArray[i] = GRI.PRIArray[i];
	}
	DrawNetInfo(Canvas, FontReduction, HeaderOffsetY, PlayerBoxSizeY, BoxSpaceY, BoxTextOffsetY, OwnerOffset, PlayerCount, NetXPos);
	DrawMatchID(Canvas, FontReduction);
}

function DrawSpecs(Canvas C, PlayerReplicationInfo PRI, int i)
{
	local string DrawText;
	local float BoxSizeX, BoxSizeY, StartPosX, StartPosY, bordersize;
	local UTComp_PRI uPRI;

	if (C.SizeX < 630)
		return;

	C.Font = SmallerFont;
	C.StrLen(" 100% / 100%", BoxSizeX, BoxSizeY);
	StartPosX = C.ClipX-BoxSizeX*1.25;
	StartPosY = (C.ClipY*0.9150 - BoxSizeY);
	bordersize = 1.000000;

	if (PRI == none)
	{
		DrawText = "Spectators";
		C.SetPos(StartPosX, StartPosY - (BoxSizeY + BorderSize)*(i-1) - BorderSize);
		C.DrawTileStretched(Material'Engine.WhiteTexture', BoxSizeX, BorderSize);
	}
	else
	{
		DrawText = PRI.PlayerName;
		uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRI);
	}

	if (uPRI == none || uPRI.GetTeamX == 255)
		C.SetDrawColor(10,10,10,155);
	else if (uPRI.GetTeamX == 0)
		C.SetDrawColor(250,0,0,155);
	else if (uPRI.GetTeamX == 1)
		C.SetDrawColor(0,0,250,155);

	C.SetPos(StartPosX, StartPosY - (BoxSizeY + BorderSize)*i);
	C.DrawTileStretched(Material'Engine.WhiteTexture', BoxSizeX, BoxSizeY + BorderSize);
	C.SetDrawColor(255,255,255,255);
	C.DrawTextJustified(DrawText, 1, StartPosX, StartPosY - (BoxSizeY + BorderSize)*i, StartPosX + BoxSizeX,  StartPosY - (BoxSizeY+BorderSize)*i + BoxSizeY);
}

function DrawOtherPowerups(Canvas C)
{
	local UTComp_PRI uPRI;
	local BS_xPlayer UxP;
	local int i, Lines, hundreds, fifties, Health, Adren, amp;
	local float BoxSizeX, BoxSizeY, StartPosX, StartPosY, bordersize;
	local float charoffset, charoffset2;

	if (!class'UTComp_ScoreBoard'.default.bDrawPickups || BS_xPlayer(Owner) == none || BS_xPlayer(Owner).UTCompPRI == none || C.SizeX <= 630)
		return;
	
	UxP = BS_xPlayer(Owner);
	uPRI = UxP.currentStatDraw;

	C.StrLen(" 100% / 100%", BoxSizeX, BoxSizeY);
	StartPosX = C.ClipX - BoxSizeX*3.0;
	StartPosY = C.ClipY*0.9150 - (BoxSizeY + BorderSize);
	bordersize = 1.000000;
	C.StrLen("A", charoffset, charoffset2);
	charoffset = charoffset*0.5;

	if (uPRI.PickedUpFifty > 0)
	{
		fifties += uPRI.PickedUpFifty;
		Lines++;
	}

	if (uPRI.PickedUpHundred > 0)
	{
		hundreds += uPRI.PickedUpHundred;
		Lines++;
	}

	if (uPRI.PickedUpAmp > 0)
	{
		Amp += uPRI.PickedUpAmp;
		Lines++;
	}

	if (uPRI.PickedUpVial > 0)
		Health += 5*uPRI.PickedUpVial;

	if (uPRI.PickedUpHealth > 0)
		Health += 25*uPRI.PickedUpHealth;

	if (uPRI.PickedUpKeg > 0)
		Health += 100*uPRI.PickedUpKeg;

	if (uPRI.PickedUpAdren > 0)
	{
		Adren += 2*uPRI.PickedUpAdren;
		Lines++;
	}

	if (health > 0)
		Lines++;

	if (Lines == 0)
		return;

	C.Style = 5;

	//draw borders
	C.SetDrawColor(255,255,255,255);

	C.SetPos(StartPosX, StartPosY + BoxSizeY);
	C.DrawTileStretched(Material'Engine.WhiteTexture', (BoxSizeX + BorderSize), BorderSize);

	C.SetPos(StartPosX + BoxSizeX, StartPosY - (Lines-1)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (BorderSize + BoxSizeY) * Lines);

	C.SetPos(StartPosX, StartPosY - (Lines-1)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (BorderSize + BoxSizeY) * Lines);
	C.DrawTileStretched(Material'Engine.WhiteTexture', (BoxSizeX + BorderSize), BorderSize);

	//draw background
	C.SetDrawColor(45,45,45,155);
	C.DrawTileStretched(Material'Engine.WhiteTexture', (BoxSizeX + BorderSize), Lines * (BoxSizeY + BorderSize));
	C.SetDrawColor(255,255,255,255);

	C.SetPos(StartPosX + CharOffset, StartPosY);
	if (Adren > 0)
	{
		C.DrawText("Adren:  " $ Adren);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (fifties > 0)
	{
		C.DrawText("50s:    " $ fifties);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (hundreds > 0)
	{
		C.DrawText("100s:   " $ hundreds);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (health > 0)
	{
		C.DrawText("Health: " $ health);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (amp > 0)
		C.DrawText("DD:     " $ amp);
}

function DrawPowerups(Canvas C)
{
	local UTComp_PRI uPRI;
	local BS_xPlayer UxP;
	local int i, Lines, hundreds, fifties, Health, Adren, amp;
	local float BoxSizeX, BoxSizeY, StartPosX, StartPosY, bordersize;
	local float charoffset, charoffset2;

	if (!class'UTComp_ScoreBoard'.default.bDrawPickups || BS_xPlayer(Owner) == none || BS_xPlayer(Owner).UTCompPRI == none || C.SizeX <= 630)
		return;

	UxP = BS_xPlayer(Owner);
	if (UxP.currentStatDraw != none && UxP.currentStatDraw != UxP.UTCompPRI)
	{
		DrawOtherPowerups(C);
		return;
	}
	uPRI = UxP.UTCompPRI;

	C.StrLen(" 100% / 100%", BoxSizeX, BoxSizeY);
	StartPosX = C.ClipX-BoxSizeX*3.0;
	StartPosY = C.ClipY*0.9150 - (BoxSizeY + BorderSize);
	bordersize = 1.000000;
	C.StrLen("A", charoffset, charoffset2);
	charoffset = charoffset*0.5;

	if (uPRI.PickedUpFifty > 0)
	{
		fifties += uPRI.PickedUpFifty;
		Lines++;
	}

	if (uPRI.PickedUpHundred > 0)
	{
		hundreds += uPRI.PickedUpHundred;
		Lines++;
	}

	if (uPRI.PickedUpAmp > 0)
	{
		Amp += uPRI.PickedUpAmp;
		Lines++;
	}

	if (uPRI.PickedUpVial > 0)
		Health += 5*uPRI.PickedUpVial;

	if (uPRI.PickedUpHealth > 0)
		Health += 25*uPRI.PickedUpHealth;

	if (uPRI.PickedUpKeg > 0)
		Health += 100*uPRI.PickedUpKeg;

	if (uPRI.PickedUpAdren > 0)
	{
		Adren += 2*uPRI.PickedUpAdren;
		Lines++;
	}

	if (health > 0)
		Lines++;

	if (Lines == 0)
		return;

	C.Style = 5;

	//draw borders
	C.SetDrawColor(255,255,255,255);

	C.SetPos(StartPosX, StartPosY + BoxSizeY);
	C.DrawTileStretched(Material'Engine.WhiteTexture', (BoxSizeX + BorderSize), BorderSize);

	C.SetPos(StartPosX + BoxSizeX, StartPosY - (Lines-1)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (BorderSize + BoxSizeY) * Lines);

	C.SetPos(StartPosX, StartPosY - (Lines-1)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (BorderSize + BoxSizeY) * Lines);
	C.DrawTileStretched(Material'Engine.WhiteTexture', (BoxSizeX + BorderSize), BorderSize);

	//draw background
	C.SetDrawColor(10,10,10,155);
	C.DrawTileStretched(Material'Engine.WhiteTexture',(BoxSizeX + BorderSize), Lines * (BoxSizeY + BorderSize));
	C.SetDrawColor(255,255,255,255);

      C.SetPos(StartPosX + CharOffset, StartPosY);
	if (Adren > 0)
	{
		C.DrawText("Adren:  " $ Adren);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (fifties > 0)
	{
		C.DrawText("50s:    " $ fifties);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (hundreds > 0)
	{
		C.DrawText("100s:   " $ hundreds);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (health > 0)
	{
		C.DrawText("Health: " $ health);
		i++;
		C.SetPos(StartPosX + CharOffset, StartPosY - i*(BoxSizeY + BorderSize));
	}

	if (amp > 0)
		C.DrawText("DD:     " $ amp);
}

function DrawOtherStats(Canvas C)
{
	local int i, j, NumColumns;
	local float BoxSizeX, BoxSizeY, StartPosX, StartPosY, BorderSize;
	local float StrLenX, StrLenY, TmpX, TmpY, TextOffsetX, TextOffsetY;
	local UTComp_PRI UxP;
	local array<int> toDrawStandard;
	local string DrawString;
	local bool bShouldDraw;
	local UTComp_Settings S;

	bDisplayMessages = !class'UTComp_ScoreBoard'.default.bDrawStats;
	if (!class'UTComp_ScoreBoard'.default.bDrawStats || BS_xPlayer(Owner) == none || BS_xPlayer(Owner).UTCompPRI == none)
		return;

	S = BS_xPlayer(Owner).Settings;
	UxP = BS_xPlayer(Owner).currentStatDraw;
	UxP.UpdatePercentages();

	C.Font = SmallerFont;
	C.StrLen(" 100% / 100%", BoxSizeX, BoxSizeY);
	C.Style = 5;
	BorderSize = 1.000000;
	StartPosX = 0.05*C.ClipX;
	StartPosY = C.ClipY*0.9150;
	StartPosY -= BoxSizeY;
	C.StrLen("/", TextOffsetX, TextOffsetY);

	//Get The Background Size
	for(i = 0; i < arraycount(UxP.NormalWepStatsPrim); i++)
	{
		bShouldDraw = true;
		if (UxP.NormalWepStatsPrim[i] != 0 || UxP.NormalWepStatsAlt[i] != 0 || UxP.NormalWepStatsAltHit[i] != 0 || UxP.NormalWepStatsPrimHit[i] != 0)
		{
			for(j = 0; j < S.DontDrawInStats.Length; j++)
			{
				if (S.DontDrawInStats[j] == i)
					bShouldDraw = false;
			}

			if (bShouldDraw)
			{
				NumColumns++;
				ToDrawStandard[ToDrawStandard.Length] = i;
			}
		}
	}

	if (NumColumns == 0)
		return;

	//Draw Borders
	C.SetDrawColor(255,255,255,255);
	for(i = -1; i <= NumColumns+2; i++)
	{
		C.SetPos(StartPosX, StartPosY - i*(BoxSizeY + BorderSize) - BorderSize);
		C.DrawTileStretched(Material'Engine.WhiteTexture', 5*(BoxSizeX + BorderSize), BorderSize);
	}
	C.SetPos(StartPosX, StartPosY - (NumColumns+2)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (NumColumns+3)*(BoxSizeY + BorderSize));

	C.SetPos(StartPosX + BoxSizeX + BorderSize, StartPosY - (NumColumns+1)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (NumColumns+1)*(BoxSizeY + BorderSize));

	C.SetPos(StartPosX + 5*(BoxSizeX + BorderSize), StartPosY - (NumColumns+2)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (NumColumns+3)*(BoxSizeY + BorderSize));

	// Draw Background
	C.SetDrawColor(45,45,45,155);
	C.SetPos(StartPosX, StartPosY - (NumColumns+2)*(BoxSizeY + BorderSize) - BorderSize);
	C.DrawTileStretched(Material'Engine.WhiteTexture', 5*(BoxSizeX + BorderSize) + BorderSize, (NumColumns+3)*(BoxSizeY+BorderSize) + BorderSize);

	//Draw Text
	C.SetDrawColor(255,255,255,255);

	//Player Text
	if (class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard == true)
		DrawString = UxP.ColoredName $ class'UTComp_Util'.static.MakeColorCode(C.MakeColor(255,255,255)) @ "(stats)." @ GetNextKeyString();
	else
		DrawString = GetNonColoredName(UxP) @ "(stats)." @ GetNextKeyString();
	C.StrLen(GetNonColoredName(UxP) @ "(stats)." @ GetNextKeyString(), StrLenX, StrLenY);
	C.SetPos(StartPosX + 2.5*(BoxSizeX + BorderSize) - 0.5*StrLenX, StartPosY - (NumColumns+2)*(BorderSize + BoxSizeY));
	C.DrawText(DrawString);

	//Headings
	for(i = 0; i < 5; i++)
	{
		switch(i)
		{
			case 0:
				DrawString = "Weapon:";
				break;
			case 1:
				DrawString = "Hits:";
				break;
			case 2:
			DrawString = "Fired:";
				break;
			case 3:
			DrawString = "Hit %:";
				break;
			case 4:
			DrawString = "Damage:";
				break;
		}
		C.StrLen(DrawString, StrLenX, StrLenY);
		C.SetPos(StartPosX + (i+  0.5)*(BoxSizeX + BorderSize) - 0.5*StrLenX, StartPosY - (NumColumns+1)*(BorderSize + BoxSizeY));
		C.DrawText(DrawString);
	}

	//Standard weps
	for(i = 0; i < NumColumns; i++)
	{
		TmpY = StartPosY - ((i+1)*(BoxSizeY + BorderSize));
		TmpX = StartPosX + BorderSize + 0.5*TextOffsetX;
		if (i < ToDrawStandard.Length)
		{
			j = ToDrawStandard[i];
		}
		else
		{
			break;
		}

		//Wep Name
		DrawString = BS_xPlayer(Owner).NormalWepStatsPrim[j].WepName;
		C.SetPos(TmpX, TmpY);
		C.DrawText(DrawString);

		//Hit
		DrawString = StatView(UxP.NormalWepStatsPrimHit[j]) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= StatView(UxP.NormalWepStatsAltHit[j]);
		if (j == 5)
		{
			if (UxP.NormalWepStatsAltHit[j] > 0)
			{
				if (UxP.NormalWepStatsAltHit[j] > 99)
					DrawString $= "HS";
				else
					DrawString @= "HS";
			}
		}
		C.SetPos(TmpX + (BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);

		//Fired
		DrawString = StatView(UxP.NormalWepStatsPrim[j]) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= StatView(UxP.NormalWepStatsAlt[j]);
		C.SetPos(TmpX + 2*(BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);

		//Pct
		DrawString = PercView(UxP.NormalWepStatsPrimPercent[j]) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= PercView(UxP.NormalWepStatsAltPercent[j]);
		C.SetPos(TmpX + 3*(BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);

		//Damage
		DrawString = StatView(UxP.NormalWepStatsPrimDamage[j]) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= StatView(UxP.NormalWepStatsAltDamage[j]);
		C.SetPos(TmpX + 4*(BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);
	}

	TmpY = StartPosY + (BoxSizeY + BorderSize);
	TmpX = StartPosX + BorderSize + 0.5*TextOffsetX;
	C.SetPos(TmpX + 1*(BorderSize + BoxSizeX), TmpY - BoxSizeY-BorderSize);
	C.DrawText("Damage Received:" @ UxP.DamR);
	C.SetPos(TmpX + 3*(BorderSize + BoxSizeX), TmpY - BoxSizeY-BorderSize);
	C.DrawText("Damage Given:" @ UxP.DamG);
}

function string GetNonColoredName(UTComp_PRI uPRI)
{
	local int i;

	for(i = 0; i < GRI.PRIArray.Length; i++)
	{
		if (class'UTComp_util'.static.GetUTCompPRI(GRI.PRIArray[i]) == uPRI)
			return GRI.PRIArray[i].Playername;
	}
	return uPRI.ColoredName;
}

function DrawStats(Canvas C)
{
	local int i, j, k, NumColumns;
	local float BoxSizeX, BoxSizeY, StartPosX, StartPosY, BorderSize;
	local float StrLenX, StrLenY, TmpX, TmpY, TextOffsetX, TextOffsetY;
	local BS_xPlayer UxP;
	local array<int> toDrawStandard;
	local string DrawString;
	local bool bShouldDraw;
	local UTComp_Settings S;

	bDisplayMessages = !class'UTComp_ScoreBoard'.default.bDrawStats;
	if (!class'UTComp_ScoreBoard'.default.bDrawStats || BS_xPlayer(Owner) == none || BS_xPlayer(Owner).UTCompPRI == none)
		return;

	S = BS_xPlayer(Owner).Settings;
	UxP = BS_xPlayer(Owner);

	if (UXP.currentStatDraw != none && (UxP.currentStatDraw != UxP.UTCompPRI))
	{
		DrawOtherStats(C);
		return;
	}

	UxP.UpdatePercentages();

	C.Font = SmallerFont;
	C.StrLen(" 100% / 100%", BoxSizeX, BoxSizeY);
	C.Style = 5;
	BorderSize = 1.000000;
	StartPosX = 0.05*C.ClipX;
	StartPosY = C.ClipY*0.9150;
	StartPosY -= BoxSizeY;
	C.StrLen("/", TextOffsetX, TextOffsetY);

	//Get The Background Size
	for(i = 0; i < arraycount(UxP.UTCompPRI.NormalWepStatsPrim); i++)
	{
		bShouldDraw = true;
		if (UxP.UTCompPRI.NormalWepStatsPrim[i] != 0 || UxP.UTCompPRI.NormalWepStatsAlt[i] != 0 || UxP.NormalWepStatsAlt[i].Hits != 0 || UxP.NormalWepStatsPrim[i].Hits != 0)
		{
			for(j = 0; j < S.DontDrawInStats.Length; j++)
			{
				if (S.DontDrawInStats[j] == i)
					bShouldDraw = false;
			}

			if (bShouldDraw)
			{
				NumColumns++;
				ToDrawStandard[ToDrawStandard.Length] = i;
			}
		}
	}

	NumColumns += UxP.CustomWepStats.Length;
	if (NumColumns == 0)
		return;

	//Draw Borders
	C.SetDrawColor(255,255,255,255);
	for(i = -1; i <= NumColumns+2; i++)
	{
		C.SetPos(StartPosX, StartPosY - i*(BoxSizeY + BorderSize) - BorderSize);
		C.DrawTileStretched(Material'Engine.WhiteTexture', 5*(BoxSizeX + BorderSize), BorderSize);
	}
	C.SetPos(StartPosX, StartPosY - (NumColumns+2)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (NumColumns+3)*(BoxSizeY + BorderSize));

	C.SetPos(StartPosX + BoxSizeX + BorderSize, StartPosY - (NumColumns+1)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (NumColumns+1)*(BoxSizeY + BorderSize));

	C.SetPos(StartPosX + 5*(BoxSizeX + BorderSize), StartPosY - (NumColumns+2)*(BoxSizeY + BorderSize));
	C.DrawTileStretched(Material'Engine.WhiteTexture', BorderSize, (NumColumns+3)*(BoxSizeY + BorderSize));

	// Draw Background
	C.SetDrawColor(10,10,10,155);
	C.SetPos(StartPosX, StartPosY - (NumColumns+2)*(BoxSizeY + BorderSize) - BorderSize);
	C.DrawTileStretched(Material'Engine.WhiteTexture', 5*(BoxSizeX + BorderSize) + BorderSize, (NumColumns+3)*(BoxSizeY + BorderSize) + BorderSize);

	//Draw Text
	C.SetDrawColor(255,255,255,255);

	if (class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard == true)
		DrawString = UxP.UTCompPRI.ColoredName $ class'UTComp_Util'.static.MakeColorCode(C.MakeColor(255,255,255)) @ "(stats)." @ GetNextKeyString();
	else
		DrawString = GetNonColoredName(UxP.UTCompPRI) @ "(stats)." @ GetNextKeyString();
	
	C.StrLen(GetNonColoredName(UxP.UTCompPRI) @ "(stats)." @ GetNextKeyString(), StrLenX, StrLenY);
	C.SetPos(StartPosX + 2.5*(BoxSizeX + BorderSize) - 0.5*StrLenX, StartPosY - (NumColumns+2)*(BorderSize + BoxSizeY));
	C.DrawText(DrawString);

	//Headings
	for(i = 0; i < 5; i++)
	{
		switch (i)
		{
			case 0:
				DrawString = "Weapon:";
				break;
			case 1:
				DrawString = "Hits:";
				break;
			case 2:
				DrawString = "Fired:";
				break;
			case 3:
				DrawString = "Hit %:";
				break;
			case 4:
				DrawString = "Damage:";
				break;
		}
		C.StrLen(DrawString, StrLenX, StrLenY);
		C.SetPos(StartPosX + (i + 0.5)*(BoxSizeX + BorderSize) - 0.5*StrLenX, StartPosY - (NumColumns+1)*(BorderSize + BoxSizeY));
		C.DrawText(DrawString);
	}

	//Standard weps
	for(i = 0; i < NumColumns; i++)
	{
		TmpY = StartPosY - ((i+1)*(BoxSizeY + BorderSize));
		TmpX = StartPosX + BorderSize + 0.5*TextOffsetX;
		if (i < ToDrawStandard.Length)
		{
			j = ToDrawStandard[i];
		}
		else
		{
			break;
		}

		//Wep Name
		DrawString = UxP.NormalWepStatsPrim[j].WepName;
		C.SetPos(TmpX, TmpY);
		C.DrawText(DrawString);

		//Hit
		DrawString = StatView(UxP.NormalWepStatsPrim[j].Hits) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= StatView(UxP.NormalWepStatsAlt[j].Hits);
		if (j == 5)
		{
			if (UxP.NormalWepStatsAlt[j].Hits > 0)
			{
				if (UxP.NormalWepStatsAlt[j].Hits > 99)
					DrawString $= "HS";
				else
					DrawString @= "HS";
			}
		}
		C.SetPos(TmpX + (BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);

		//Fired
		DrawString = StatView(UxP.UTCompPRI.NormalWepStatsPrim[j]) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= StatView(UxP.UTCompPRI.NormalWepStatsAlt[j]);
		C.SetPos(TmpX + 2*(BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);

		//Pct
		DrawString = PercView(UxP.NormalWepStatsPrim[j].Percent) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= PercView(UxP.NormalWepStatsAlt[j].Percent);
		C.SetPos(TmpX + 3*(BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);

		//Damage
		DrawString = StatView(UxP.NormalWepStatsPrim[j].Damage) @ "/";
		C.StrLen(DrawString, StrLenX, StrLenY);
		DrawString @= StatView(UxP.NormalWepStatsAlt[j].Damage);
		C.SetPos(TmpX + 4*(BorderSize + BoxSizeX) + (0.5*boxSizeX) - StrLenX, TmpY);
		C.DrawText(DrawString);
	}

	//Custom Weps
	while (i < NumColumns)
	{

		TmpY = StartPosY - ((i+1)*(BoxSizeY + BorderSize));
		TmpX = StartPosX + BorderSize + 0.5*TextOffsetX;
		if (k >= UxP.CustomWepStats.Length)
			break;

		//Wep Name
		C.SetPos(TmpX, TmpY);
		if (UxP.CustomWepStats[k].WepName != "")
			C.DrawText(UxP.CustomWepStats[k].WepName);
		else
			C.DrawText("Custom " $ k);
		TmpX += BoxSizeX*0.4;

		//Hit
		C.SetPos(TmpX + (BorderSize + BoxSizeX), TmpY);
		C.DrawText(UxP.CustomWepStats[k].Hits);

		//Fired
		C.SetPos(TmpX + 2*(BorderSize + BoxSizeX), TmpY);
		C.DrawText("");

		//Pct
		C.SetPos(TmpX + 3*(BorderSize + BoxSizeX), TmpY);
		C.DrawText("");

		//Damage
		C.SetPos(TmpX + 4*(BorderSize + BoxSizeX), TmpY);
		C.DrawText(UxP.CustomWepStats[k].Damage);
		i++;
		k++;
	}

	TmpY = StartPosY + (BoxSizeY + BorderSize);
	TmpX = StartPosX + BorderSize + 0.5*TextOffsetX;
	C.SetPos(TmpX + 1*(BorderSize + BoxSizeX), TmpY - BoxSizeY-BorderSize);
	C.DrawText("Damage Received:" @ UxP.UTCompPRI.DamR);
	C.SetPos(TmpX + 3*(BorderSize + BoxSizeX), TmpY - BoxSizeY-BorderSize);
	C.DrawText("Damage Given:" @ UxP.DamG);
}

function string GetNextKeyString()
{
	local string key;
	local color Col;

	key = class'GameInfo'.static.GetKeyBindName("NextStats", BS_xPlayer(Owner));
	Col.R = 255;
	Col.G = 255;
	Col.B = 255;

	return "Press" @ key @ "for next player.";
}

function string StatView(coerce string S)
{
	if (S ~= "0" || S ~= "0.00")
		return "";
	else
		return S;
}

function string PercView(coerce string S)
{
	if (S ~= "0")
		return "";
	else
		return S $ "%";
}

simulated function NextStats()
{
	if (BS_xPlayer(Owner) != none)
		BS_xPlayer(Owner).StatNext();
}

defaultproperties
{
}