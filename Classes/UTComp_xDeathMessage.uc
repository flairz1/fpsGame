class UTComp_xDeathMessage extends xDeathMessage
	Config(fpsGameClient);

var config bool bColoredNameDeathMessages, bTeamColoredDeaths;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	local string KillerName, VictimName;
	local UTComp_PRI uPRI;

	if (Class<DamageType>(OptionalObject) == None)
		return "";

	uPRI = class'UTComp_Util'.static.GetUTCompPRI(RelatedPRI_2);

	if (RelatedPRI_2 == None)
	{
		VictimName = default.SomeoneString;
	}
	else if (default.bTeamColoredDeaths)
	{
		if (RelatedPRI_2.Team != None && RelatedPRI_2.Team.TeamIndex == 0)
			VictimName = MakeColorCode(class'BS_xPlayer'.default.MessageRed) $ RelatedPRI_2.PlayerName $ MakeColorCode(class'HUD'.default.GreenColor);
		else if (RelatedPRI_2.Team != None && RelatedPRI_2.Team.TeamIndex == 1)
			VictimName = MakeColorCode(class'BS_xPlayer'.default.MessageBlue) $ RelatedPRI_2.PlayerName $ MakeColorCode(class'HUD'.default.GreenColor);
		else
			VictimName = MakeColorCode(class'HUD'.default.WhiteColor) $ RelatedPRI_2.PlayerName $ MakeColorCode(class'HUD'.default.GreenColor);
	}
	else if (default.bColoredNameDeathMessages)
	{
		if (uPRI != None && uPRI.ColoredName != "")
			VictimName = uPRI.ColoredName $ MakeColorCode(class'HUD'.default.GreenColor);
		else
			VictimName = MakeColorCode(class'HUD'.default.WhiteColor) $ RelatedPRI_2.PlayerName $ MakeColorCode(class'HUD'.default.GreenColor);
	}
	else
	{
		VictimName = RelatedPRI_2.PlayerName;
	}

	if (switch == 1)
	{
		return class'GameInfo'.static.ParseKillMessage(KillerName, VictimName, Class<DamageType>(OptionalObject).static.SuicideMessage(RelatedPRI_2));
	}

	uPRI = class'UTComp_Util'.static.GetUTCompPRI(RelatedPRI_1);

	if (RelatedPRI_1 == None)
	{
		KillerName = default.SomeoneString;
	}
	else if (default.bTeamColoredDeaths)
	{
		if (RelatedPRI_1.Team != None && RelatedPRI_1.Team.TeamIndex == 0)
			KillerName = MakeColorCode(class'BS_xPlayer'.default.MessageRed) $ RelatedPRI_1.PlayerName $ MakeColorCode(class'HUD'.default.GreenColor);
		else if (RelatedPRI_1.Team != None && RelatedPRI_1.Team.TeamIndex == 1)
			KillerName = MakeColorCode(class'BS_xPlayer'.default.MessageBlue) $ RelatedPRI_1.PlayerName $ MakeColorCode(class'HUD'.default.GreenColor);
		else
			KillerName = MakeColorCode(class'HUD'.default.WhiteColor) $ RelatedPRI_1.PlayerName $ MakeColorCode(class'Hud'.default.GreenColor);
	}
	else if (default.bColoredNameDeathMessages)
	{
		if (uPRI != None && uPRI.ColoredName != "")
			KillerName = uPRI.ColoredName $ MakeColorCode(class'HUD'.default.GreenColor);
		else
			KillerName = MakeColorCode(class'HUD'.default.WhiteColor) $ RelatedPRI_1.PlayerName $ MakeColorCode(class'HUD'.default.GreenColor);
	}
	else
	{
		KillerName = RelatedPRI_1.PlayerName;
	}

	return class'GameInfo'.static.ParseKillMessage(KillerName, VictimName, Class<DamageType>(OptionalObject).static.DeathMessage(RelatedPRI_1, RelatedPRI_2));
}

static function string MakeColorCode(color NewColor)
{
	if (NewColor.R == 0)
		NewColor.R = 1;

	if (NewColor.G == 0)
		NewColor.G = 1;

	if (NewColor.B == 0)
		NewColor.B = 1;

	return Chr(0x1B)$Chr(NewColor.R)$Chr(NewColor.G)$Chr(NewColor.B);
}

defaultproperties
{
	bTeamColoredDeaths=true
}