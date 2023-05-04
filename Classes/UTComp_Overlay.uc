class UTComp_Overlay extends Interaction
	Config(fpsGameClient);

var Font InfoFont, LocationFont;
var bool BiggerFont;
var float HealthOffset, ArmorOffset, WeaponIconOffset;
var float PowerupIconOffset, PowerupCountdownOffset;
var float IconScale, CurX, CurY, StrLenX, StrLenY, StrLenLocX, StrLenLocY;
var int OldScreenWidth, OldScreenHeight, OldFontSize;
var int numPlayersRed, numPlayersBlue, numPowerups;

//configs
var config int TheFontSize;
var config bool OverlayEnabled, bDrawIcons, PowerupOverlayEnabled, bAlwaysShowPowerups;
var config float VertPosition, HorizPosition;
var config Color BGColor, InfoTextColor, LocTextColor;

var LevelInfo Level;
var BS_xPlayer PC;
var UTComp_PRI uPRI;
var PlayerReplicationInfo PRI;
var GameReplicationInfo GRI;

// mouse
var Texture MouseCursorTexture;
var float MousePosX, MousePosY;

event NotifyLevelChange()
{
	Master.RemoveInteraction(self);
}

event Initialized()
{
	foreach ViewportOwner.Actor.DynamicActors(class'GameReplicationInfo', GRI)
	{
		if (GRI != None)
			break;
	}

	Level = ViewPortOwner.Actor.Level;
	PC = BS_xPlayer(ViewportOwner.Actor);
	uPRI = PC.UTCompPRI;
	PRI = PC.PlayerReplicationInfo;
}

function float GetWeaponIconWidth()
{
	return 40 * IconScale;
}

function float GetHeaderIconHeight()
{
	return 24.0 * IconScale;
}

function float GetHeaderIconWidth()
{
	return 24.0 * IconScale;
}

function float GetBoxWidth()
{
	return WeaponIconOffset + GetWeaponIconWidth();
}

function float GetBoxHeight(int numPlayers)
{
	local float height;

	height = numPlayers * (StrLenY + StrLenLocY);
	if (default.bDrawIcons)
		height += GetHeaderIconHeight();

	return height;
}

function Click()
{
	local float boxPositionX, boxPositionY, boxWidth, boxHeight;
	local float playerIndex;

	boxPositionX = GetRedBoxPositionX();
	boxPositionY = GetRedBoxPositionY();
	boxWidth = GetBoxWidth();
	boxHeight = GetBoxHeight(numPlayersRed);

	if (boxPositionX <= MousePosX && MousePosX <= (boxPositionX + boxWidth) && boxPositionY <= MousePosY && MousePosY <= (boxPositionY + boxHeight))
	{
		if (bDrawIcons)
			playerIndex = int((MousePosY - boxPositionY - GetHeaderIconHeight()) / (StrLenY + StrLenLocY));
		else
			playerIndex = int((MousePosY - boxPositionY) / (StrLenY + StrLenLocY));

		if (playerIndex >= 0 && playerIndex < 8 && uPRI.OverlayInfoRed[playerIndex].PRI != None)
		{
			PC.ServerGoToTarget(uPRI.OverlayInfoRed[playerIndex].PRI);
			return;
		}
	}

	boxPositionX = GetBlueBoxPositionX();
	boxPositionY = GetBlueBoxPositionY();
	boxWidth = GetBoxWidth();
	boxHeight = GetBoxHeight(numPlayersBlue);

	if (boxPositionX <= MousePosX && MousePosX <= (boxPositionX + boxWidth) && boxPositionY <= MousePosY && MousePosY <= (boxPositionY + boxHeight))
	{
		if (bDrawIcons)
			playerIndex = int((MousePosY - boxPositionY - GetHeaderIconHeight()) / (StrLenY + StrLenLocY));
		else
			playerIndex = int((MousePosY - boxPositionY) / (StrLenY + StrLenLocY));

		if (playerIndex >= 0 && playerIndex < 8 && uPRI.OverlayInfoBlue[playerIndex].PRI != None)
		{
			PC.ServerGoToTarget(uPRI.OverlayInfoBlue[playerIndex].PRI);
			return;
		}
	}

	boxPositionX = GetPowerupBoxPositionX();
	boxPositionY = GetPowerupBoxPositionY();
	boxWidth = GetPowerupBoxWidth();
	boxHeight = GetPowerupBoxHeight();

	if (boxPositionX <= MousePosX && MousePosX <= (boxPositionX + boxWidth) && boxPositionY <= MousePosY && MousePosY <= (boxPositionY + boxHeight))
	{
		playerIndex = int((MousePosY - boxPositionY) / (StrLenY + StrLenLocY));
		if (playerIndex >= 0 && playerIndex < 8 && uPRI.PowerupInfo[playerIndex].Pickup != None)
		{
			PC.ServerGoToTarget(uPRI.PowerupInfo[playerIndex].Pickup);
			return;
		}
	}
}

function DrawBackground(Canvas C, int numPlayers, int team)
{
	local float boxSizeX, boxSizeY, iconHeight;

	C.Style = 5;
	C.SetPos(CurX, CurY);
	C.DrawColor = BGColor;
	boxSizeX = GetBoxWidth();
	boxSizeY = GetBoxHeight(numPlayers);

	C.DrawTileStretched(Material'Engine.WhiteTexture', boxSizeX, boxSizeY);

	if (default.bDrawIcons)
	{
		iconHeight = GetHeaderIconHeight();

		C.SetDrawColor(255, 255, 255, 255);

		// Health Icon
		C.SetPos(CurX + HealthOffset + ((ArmorOffset - HealthOffset - GetHeaderIconWidth()) / 2), CurY);
		C.DrawTile(Material'HudContent.Generic.Hud', iconHeight, iconHeight, 75, 167, 48, 48);

		// Armor Icon
		C.SetPos(CurX + ArmorOffset + ((WeaponIconOffset - ArmorOffset - GetHeaderIconWidth()) / 2), CurY);
		C.DrawTile(Material'HudContent.Generic.Hud', iconHeight, iconHeight, 1, 248, 66, 66);

		CurY += GetHeaderIconHeight();
	}
}

function float GetRedBoxPositionX()
{
	return OldScreenWidth * default.HorizPosition;
}

function float GetRedBoxPositionY()
{
	return OldScreenHeight * default.VertPosition;
}

function float GetBlueBoxPositionX()
{
	return OldScreenWidth - (OldScreenWidth * default.HorizPosition) - GetBoxWidth();
}

function float GetBlueBoxPositionY()
{
	return OldScreenHeight * default.VertPosition;
}

function PostRender(Canvas C)
{
	local int i, numplayers;

	if (uPRI == None)
	{
		uPRI = PC.UTCompPRI;
		PRI = PC.PlayerReplicationInfo;
	}

	if (uPRI == None || ViewportOwner.Actor.myHud.bShowScoreBoard || ViewportOwner.Actor.myHud.bShowLocalStats || !default.OverlayEnabled)
		return;

	if ((C.SizeX != OldScreenWidth) || (C.SizeY != OldScreenHeight) || InfoFont == None || LocationFont == None || OldFontSize != default.TheFontSize)
	{
		GetFonts(C);
		OldFontSize = default.TheFontSize;
		OldScreenWidth = C.SizeX;
		OldScreenHeight = C.SizeY;
		C.Font = InfoFont;
		C.StrLen("X", StrLenX, StrLenY);
		C.Font = LocationFont;
		C.StrLen("X", StrLenLocX, StrLenLocY);
		IconScale = StrLenY/16.0;

		if (BiggerFont)
		{
			HealthOffset = 10 * StrLenX;
			ArmorOffset = 14 * StrLenX;
			WeaponIconOffset = 18 * StrLenX;

			PowerupIconOffset = StrLenX;
			PowerupCountdownOffset = 5 * StrLenX;
		}
		else
		{
			HealthOffset = 15 * StrLenX;
			ArmorOffset = 19 * StrLenX;
			WeaponIconOffset = 23 * StrLenX;

			PowerupIconOffset = StrLenX;
			PowerupCountdownOffset = 10 * StrLenX;
		}
	}

	CurX = GetRedBoxPositionX();
	CurY = GetRedBoxPositionY();

	if ((PRI.Team != none && PRI.Team.TeamIndex == 0) || PRI.bOnlySpectator)
	{
		for(i = 0; i < 8; i++)
		{
			if (uPRI.OverlayInfoRed[i].PRI != None)
				numPlayers++;
		}

		numPlayersRed = numPlayers;
		if (numPlayers > 0)
		{
			DrawBackground(C, numPlayers, 0);
			DrawPlayerNames(C, uPRI, 0);
			DrawHealth(C, uPRI, 0);
			DrawArmor(C, uPRI, 0);
			DrawIcons(C, uPRI, 0);
			DrawLocation(C, uPRI, 0);
		}

		// switch to the other side in case we have to draw the blue team, in spec mode.
		CurX = GetBlueBoxPositionX();
		CurY = GetBlueBoxPositionY();
	}

	if ((PRI.Team != none && PRI.Team.TeamIndex == 1) || PRI.bOnlySpectator)
	{
		numPlayers = 0;
		for(i = 0; i < 8; i++)
		{
			if (uPRI.OverlayInfoBlue[i].PRI != None)
				numPlayers++;
		}

		numPlayersBlue = numPlayers;
		if (numPlayers > 0)
		{
			DrawBackground(C, numPlayers, 1);
			DrawPlayerNames(C, uPRI, 1);
			DrawHealth(C, uPRI, 1);
			DrawArmor(C, uPRI, 1);
			DrawIcons(C, uPRI, 1);
			DrawLocation(C, uPRI, 1);
		}
	}

	DrawPowerups(C, PRI);

	PC.LastHUDSizeX = C.SizeX;
	PC.LastHUDSizeY = C.SizeY;

	if (PC.IsInState('PlayerMousing'))
		DrawMouseCursor(C);
}

function string GetFriendlyPowerupName(Pickup Pickup, int team)
{
	local string friendlyName;

	if (team == 0)
		friendlyName = "RED ";
	else if (team == 1)
		friendlyName = "BLUE ";
	else
		friendlyName = "MID ";

	if (UDamagePack(Pickup) != None)
		friendlyName = friendlyName$"Amp";
	else if (SuperHealthPack(Pickup) != None)
		friendlyName = friendlyName$"Keg";
	else if (SuperShieldPack(Pickup) != None)
		friendlyName = friendlyName$"100";

	return friendlyName;
}

simulated function String FormatTime( int Seconds )
{
	local int Minutes, Hours;
	local string Time;

	if (Seconds <= 0)
		return "UP!";

	if (Seconds > 3600)
	{
		Hours = Seconds / 3600;
		Seconds -= Hours * 3600;

		Time = Hours $ ":";
	}

	Minutes = Seconds / 60;
	Seconds -= Minutes * 60;

	if (Minutes >= 10)
		Time = Time $ Minutes $ ":";
	else
		Time = Time $ "0" $ Minutes $ ":";

	if (Seconds >= 10)
		Time = Time $ Seconds;
	else
		Time = Time $ "0" $ Seconds;

	return Time;
}

function float GetPowerupIconHeight()
{
	return 24.0 * IconScale;
}

function float GetPowerupBoxWidth()
{
	return PowerupCountdownOffset + (9 * StrLenLocX);
}

function float GetPowerupBoxHeight()
{
	return numPowerups * (StrLenY + StrLenLocY);
}

function float GetPowerupBoxPositionY()
{
	return OldScreenHeight * 0.45;
}

function float GetPowerupBoxPositionX()
{
	return OldScreenWidth * default.HorizPosition;
}

function DrawPowerups(Canvas C, PlayerReplicationInfo PRI)
{
	local int i;
	local float nextRespawn, iconHeight;

	if (!PRI.bOnlySpectator || !default.PowerupOverlayEnabled)
		return;

	iconHeight = GetPowerupIconHeight();

	numPowerups = 0;
	for(i = 0; i < 8; i++)
	{
		if (uPRI.PowerupInfo[i].Pickup == None)
			break;
		numPowerups++;
	}

	C.DrawColor = BGColor;
	CurX = GetPowerupBoxPositionX();
	CurY = GetPowerupBoxPositionY();

	C.SetPos(CurX, CurY);
	C.DrawTileStretched(Material'Engine.WhiteTexture', GetPowerupBoxWidth(), GetPowerupBoxHeight());
	C.DrawColor = default.InfoTextColor;

	for(i = 0; i < 8; i++)
	{
		if (uPRI.PowerupInfo[i].Pickup == None)
			break;

		nextRespawn = (uPRI.PowerupInfo[i].NextRespawnTime - Level.GRI.ElapsedTime) / Level.TimeDilation;

		if (!bAlwaysShowPowerups && nextRespawn > 10)
			break;

		C.Font = LocationFont;

		// icon
		C.SetPos(CurX + PowerupIconOffset, CurY);
		if (UDamagePack(uPRI.PowerupInfo[i].Pickup) != None)
			C.DrawTile(Material'HudContent.Generic.Hud', iconHeight, iconHeight, 0, 164, 73, 82);
		else if (SuperShieldPack(uPRI.PowerupInfo[i].Pickup) != None)
			C.DrawTile(Material'HudContent.Generic.Hud', iconHeight, iconHeight, 1, 248, 66, 66);
		else if (SuperHealthPack(uPRI.PowerupInfo[i].Pickup) != None)
			C.DrawTile(Material'HudContent.Generic.Hud', iconHeight, iconHeight, 75, 167, 48, 48);

		// name + location
		C.SetPos(CurX + PowerupCountdownOffset, CurY + StrLenLocY);
		C.DrawText(GetFriendlyPowerupName(uPRI.PowerupInfo[i].Pickup, uPRI.PowerupInfo[i].Team));

		// Countdown
		C.Font = InfoFont;
		C.SetPos(CurX + PowerupCountdownOffset, CurY);
		C.DrawText(FormatTime(nextRespawn));

		CurY += StrLenLocY + StrLenY;
	}
}

function bool GetNewNetEnabled()
{
	local UTComp_ServerReplicationInfo SRI;

	foreach ViewportOwner.Actor.DynamicActors(class'UTComp_ServerReplicationInfo', SRI)
		break;

	if (SRI == none)
		return false;

	return SRI.b_Netcode;
}

function string MakeColorCode(color aColor)
{
	return Chr(0x1b) $ Chr(Max(aColor.R, 1)) $ Chr(Max(aColor.G, 1)) $ Chr(Max(aColor.B, 1));
}

function GetPlayerNameInfo(UTComp_PRI uPRI, int index, int team, out PlayerReplicationInfo PRI, out byte hasDD)
{
	hasDD = 0;

	if (team == 0)
	{
		PRI = uPRI.OverlayInfoRed[index].PRI;
		hasDD = uPRI.bHasDDRed[index];
	}
	else
	{
		PRI = uPRI.OverlayInfoBlue[index].PRI;
		hasDD = uPRI.bHasDDBlue[index];
	}
}

function DrawPlayerNames(Canvas C, UTComp_PRI uPRI, int team)
{
	local int i;
	local float oldClipX, lenX, lenY;
	local PlayerReplicationInfo oPRI;
	local byte hasDD;

	oldClipX = C.ClipX;
	C.ClipX = CurX + HealthOffset;

	C.Font = InfoFont;
	for(i = 0; i < 8; i++)
	{
		GetPlayerNameInfo(uPRI, i, team, oPRI, hasDD);
		if (oPRI == None)
			break;

		if (hasDD == 1)
			C.SetDrawColor(255,0,255);
		else
			C.DrawColor = default.InfoTextColor;

		C.StrLen(oPRI.PlayerName, lenX, lenY);
		if (lenX > HealthOffset)
			C.Font = LocationFont;
		else
			C.Font = InfoFont;

		C.SetPos(CurX, CurY + (StrLenY + StrLenLocY) * i);
		C.DrawTextClipped(oPRI.PlayerName);
	}

	C.ClipX = oldClipX;
}

function GetHealthInfo(UTComp_PRI uPRI, int index, int team, out PlayerReplicationInfo PRI, out int health)
{
	if (team == 0)
	{
		PRI = uPRI.OverlayInfoRed[index].PRI;
		health = uPRI.OverlayInfoRed[index].Health;
	}
	else
	{
		PRI = uPRI.OverlayInfoBlue[index].PRI;
		health = uPRI.OverlayInfoBlue[index].Health;
	}
}

function DrawHealth(Canvas C, UTComp_PRI uPRI, int team)
{
	local int i, health;
	local PlayerReplicationInfo oPRI;

	C.Font = InfoFont;
	for(i = 0; i < 8; i++)
	{
		GetHealthInfo(uPRI, i, team, oPRI, health);
		if (oPRI == None)
			return;

		if (health >= 100)
			C.SetDrawColor(0,255,0,255);
		else if (health >= 45 && health < 100)
			C.SetDrawColor(255,255,0,255);
		else if (health < 45)
			C.SetDrawColor(255,0,0,255);

		if (health < 1000)
			C.DrawTextJustified(health, 1, CurX + HealthOffset, CurY + (StrLenY + StrLenLocY)*i, CurX + ArmorOffset, CurY + StrLenY*(i+1) + StrLenLocY*i);
		else
			C.DrawTextJustified(Left(string(health), Len(health)-3)$"K", 1, CurX + HealthOffset, CurY + (StrLenY + StrLenLocY)*i, CurX + ArmorOffset, CurY + StrLenY*(i+1) + StrLenLocY*i);
	}
}

function GetArmorInfo(UTComp_PRI uPRI, int index, int team, out PlayerReplicationInfo PRI, out byte armor)
{
	if (team == 0)
	{
		PRI = uPRI.OverlayInfoRed[index].PRI;
		armor = uPRI.OverlayInfoRed[index].Armor;
	}
	else
	{
		PRI = uPRI.OverlayInfoBlue[index].PRI;
		armor = uPRI.OverlayInfoBlue[index].Armor;
	}
}

function DrawArmor(Canvas C, UTComp_PRI uPRI, int team)
{
	local int i;
	local byte armor;
	local PlayerReplicationInfo oPRI;

	C.SetDrawColor(255,255,255,255);
	for(i = 0; i < 8; i++)
	{
		GetArmorInfo(uPRI, i, team, oPRI, armor);
		if (oPRI == None)
			return;

		C.DrawTextJustified(armor, 1, CurX + ArmorOffset, CurY + (StrLenY + StrLenLocY)*i, CurX + WeaponIconOffset, CurY + StrLenY*(i+1) + StrLenLocY*i);
	}
}

function Texture GetWeaponIcon(byte weapon)
{
	switch (weapon)
	{
		case 1:
			return Texture'Icons.w_ShieldGun';
			break;
		Case 2:
			return Texture'Icons.w_AssaultRifle';
			break;
		Case 3:
			return Texture'Icons.w_BioRifle';
			break;
		Case 4:
			return Texture'Icons.w_ShockRifle';
			break;
		Case 5:
			return Texture'Icons.w_LinkGun';
			break;
		Case 6:
			return Texture'Icons.w_Minigun';
			break;
		Case 7:
			return Texture'Icons.w_FlakCannon';
			break;
		Case 8:
			return Texture'Icons.w_RocketLauncher';
			break;
		Case 9:
			return Texture'Icons.w_LightningGun';
			break;
		Case 10:
			return Texture'Icons.w_SniperRifle';
			break;
		Case 11:
			return Texture'Icons.w_DualAssaultRifle';
			break;
		Case 12:
			return Texture'Icons.w_MineLayer';
			break;
		Case 13:
			return Texture'Icons.w_GrenadeLauncher';
			break;
		Case 14:
			return Texture'Icons.w_Avril';
			break;
		Case 15:
			return Texture'Icons.w_Redeemer';
			break;
		Case 16:
			return Texture'Icons.w_Painter';
			break;
		Case 17:
			return Texture'Icons.w_Translocator';
			break;
		Case 21:
			return Texture'Icons.v_Manta';
			break;
		Case 22:
			return Texture'Icons.v_Goliath';
			break;
		Case 23:
			return Texture'Icons.v_Scorpion';
			break;
		Case 24:
			return Texture'Icons.v_HellBender';
			break;
		Case 25:
			return Texture'Icons.v_Leviathan';
			break;
		Case 26:
			return Texture'Icons.v_Raptor';
			break;
		case 27:
			return Texture'Icons.v_Cicada';
			break;
		case 28:
			return Texture'Icons.v_Paladin';
			break;
		case 29:
			return Texture'Icons.v_SPMA';
			break;
		default:
			return None;
	}
}

function GetWeaponInfo(UTComp_PRI uPRI, int index, int team, out PlayerReplicationInfo PRI, out byte weapon)
{
	if (team == 0)
	{
		PRI = uPRI.OverlayInfoRed[index].PRI;
		weapon = uPRI.OverlayInfoRed[index].Weapon;
	}
	else
	{
		PRI = uPRI.OverlayInfoBlue[index].PRI;
		weapon = uPRI.OverlayInfoBlue[index].Weapon;
	}
}

function DrawIcons(Canvas C, UTComp_PRI uPRI, int team)
{
	local int i;
	local Texture WepIcon;
	local PlayerReplicationInfo oPRI;
	local byte weapon;

	C.SetDrawColor(255, 255, 255, 255);
	for(i = 0; i < 8; i++)
	{
		GetWeaponInfo(uPRI, i, team, oPRI, weapon);
		if (oPRI == None)
			break;

		WepIcon = GetWeaponIcon(weapon);
		if (WepIcon != None)
		{
			C.SetPos(CurX + WeaponIconOffset, CurY + (StrLenY + StrLenLocY)*i);
			C.DrawIcon(WepIcon, IconScale);
		}
	}
}

function GetLocationInfo(UTComp_PRI uPRI, int index, int team, out PlayerReplicationInfo PRI)
{
	if (team == 0)
		PRI = uPRI.OverlayInfoRed[index].PRI;
	else
		PRI = uPRI.OverlayInfoBlue[index].PRI;
}

function DrawLocation(Canvas C, UTComp_PRI uPRI, int team)
{
	local int i;
	local float oldClipX;
	local PlayerReplicationInfo oPRI;

	C.DrawColor = default.LocTextColor;
	C.Font = LocationFont;
	oldClipX = C.ClipX;
	C.ClipX = CurX + WeaponIconOffset + 40.0*IconScale;
	for(i = 0; i < 8; i++)
	{
		GetLocationInfo(uPRI, i, team, oPRI);
		if (oPRI == None)
			break;

		C.SetPos(CurX, CurY + StrLenY*(i+1) + StrLenLocY*i);
		C.DrawTextClipped(oPRI.GetLocationName());
	}

	C.ClipX = oldClipX;
}

function GetFonts(Canvas C)
{
	InfoFont = GetFont(AutoPickFont((C.SizeX), default.TheFontSize), 1);
	LocationFont = GetFont(AutoPickFont((C.SizeX), default.TheFontSize-1), 1);
}

simulated function string AutoPickFont(int ScrWidth, int SizeModifier)
{
	local string FontArrayNames[9];
	local int i, FontScreenWidthMedium[9], recommendedfont;

/*	// ScreenWidths to look at
	FontScreenWidthMedium[0] = 2048;
	FontScreenWidthMedium[1] = 1600;
	FontScreenWidthMedium[2] = 1280;
	FontScreenWidthMedium[3] = 1024;
	FontScreenWidthMedium[4] = 800;
	FontScreenWidthMedium[5] = 640;
	FontScreenWidthMedium[6] = 512;
	FontScreenWidthMedium[7] = 400;
	FontScreenWidthMedium[8] = 320;

	FontArrayNames[0] = "2K4Fonts.Verdana34";
	FontArrayNames[1] = "2K4Fonts.Verdana28";
	FontArrayNames[2] = "2K4Fonts.Verdana24";
	FontArrayNames[3] = "2K4Fonts.Verdana20";
	FontArrayNames[4] = "2K4Fonts.Verdana16";
	FontArrayNames[5] = "2K4Fonts.Verdana14";
	FontArrayNames[6] = "2K4Fonts.Verdana12";
	FontArrayNames[7] = "2K4Fonts.Verdana8";
	FontArrayNames[8] = "2K4Fonts.FontSmallText";
*/
	FontScreenWidthMedium[0] = 2048;
	FontScreenWidthMedium[1] = 1600;
	FontScreenWidthMedium[2] = 1280;
	FontScreenWidthMedium[3] = 1024;
	FontScreenWidthMedium[4] = 800;
	FontScreenWidthMedium[5] = 640;
	FontScreenWidthMedium[6] = 512;
	FontScreenWidthMedium[7] = 400;
	FontScreenWidthMedium[8] = 320;

	FontArrayNames[0] = "2K4Fonts.Verdana22";
	FontArrayNames[1] = "2K4Fonts.Verdana20";
	FontArrayNames[2] = "2K4Fonts.Verdana18";
	FontArrayNames[3] = "2K4Fonts.Verdana16";
	FontArrayNames[4] = "2K4Fonts.Verdana14";
	FontArrayNames[5] = "2K4Fonts.Verdana12";
	FontArrayNames[6] = "2K4Fonts.Verdana10";
	FontArrayNames[7] = "2K4Fonts.Verdana8";
	FontArrayNames[8] = "UT2003Fonts.FontMono";

	for(i = 0; i <= 8; i++)
	{
		if (FontScreenWidthMedium[i] >= ScrWidth)
			recommendedfont = Clamp((i - SizeModifier), 0, 8);
	}

	if (recommendedfont == 9)
		Log("Font selection error");

	if (recommendedFont < 8)
		BiggerFont = true;
	else
		BiggerFont = false;

	return FontArrayNames[recommendedfont];
}

simulated function Font GetFont(string FontClassName, float ResX)
{
	local Font fnt;

	fnt = GetGUIFont(FontClassName, ResX);
	if (fnt == None)
		fnt = Font(DynamicLoadObject(FontClassName, class'Font'));

	if (fnt == None)
		Log(Name$" - FONT NOT FOUND '"$FontClassName$"'",'Error');

	return fnt;
}

simulated function Font GetGUIFont( string FontClassName, float ResX )
{
	local class<GUIFont> FntCls;
	local GUIFont Fnt;

	FntCls = class<GUIFont>(DynamicLoadObject(FontClassName, class'Class', true));
	if (FntCls != None)
		Fnt = new(None) FntCls;

	if (Fnt == None)
		return None;

	return Fnt.GetFont(ResX);
}

function string GetLocation(vector tempLoc, PlayerReplicationInfo PRI)
{
	return "";
}

function bool MapIsSupported()
{
	return true;
}

function GetLocClass()
{}

function string GetClosestLocName(vector tempLoc)
{
	return "";
}

function string GetDebugLoc(vector tempLoc)
{
	return "";
}

function DrawMouseCursor(Canvas C)
{
	C.SetDrawColor(255, 255, 255);
	C.Style = 5;

	MousePosX = PC.PlayerMouse.X + C.SizeX / 2.0;
	if (MousePosX < 0)
	{
		PC.PlayerMouse.X -= MousePosX;
		MousePosX = 0;
	}
	else if (MousePosX >= C.SizeX)
	{
		PC.PlayerMouse.X -= (MousePosX - C.SizeX);
		MousePosX = C.SizeX - 1;
	}
	MousePosY = PC.PlayerMouse.Y + C.SizeY / 2.0;
	if (MousePosY < 0)
	{
		PC.PlayerMouse.Y -= MousePosY;
		MousePosY = 0;
	}
	else if (MousePosY >= C.SizeY)
	{
		PC.PlayerMouse.Y -= (MousePosY - C.SizeY);
		MousePosY = C.SizeY - 1;
	}

	C.SetPos(MousePosX, MousePosY);
	C.DrawIcon(MouseCursorTexture, 1.0);

	return;
}

defaultproperties
{
	TheFontSize=-6
	OverlayEnabled=true
	bDrawIcons=true
	PowerupOverlayEnabled=true
	bAlwaysShowPowerups=true
	VertPosition=0.070000
	HorizPosition=0.003000
	BGColor=(B=10,G=10,R=10,A=155)
	InfoTextColor=(B=255,G=255,R=255,A=255)
	LocTextColor=(B=155,G=155,R=155,A=255)
	MouseCursorTexture=Texture'2K4Menus.Cursors.Pointer'
	bVisible=true
}