class UTComp_Util extends xUtil;

simulated static function UTComp_PRI GetUTCompPRI(PlayerReplicationInfo PRI)
{
	local LinkedReplicationInfo LinkedPRI;

	if (PRI == None)
		return None;

	if (PRI.CustomReplicationInfo == None)
		return None;

	if (UTComp_PRI(PRI.CustomReplicationInfo) != None)
		return UTComp_PRI(PRI.CustomReplicationInfo);

	for(LinkedPRI = PRI.CustomReplicationInfo.NextReplicationInfo; LinkedPRI != None; LinkedPRI = LinkedPRI.NextReplicationInfo)
	{
		if (UTComp_PRI(LinkedPRI) != None)
			return UTComp_PRI(LinkedPRI);
	}

	return none;
}

static function string MakeColorCode(color NewColor)
{
	if (NewColor.R == 0)
		NewColor.R = 1;
	else if (NewColor.R == 10)
		NewColor.R = 9;
	else
		NewColor.R = Min(250, NewColor.R);

	if (NewColor.G == 0)
		NewColor.G = 1;
	else if (NewColor.G == 10)
		NewColor.G = 9;
	else
		NewColor.G = Min(250, NewColor.G);

	if (NewColor.B == 0)
		NewColor.B = 1;
	else if (NewColor.B == 10)
		NewColor.B = 9;
	else
		NewColor.B = Min(250, NewColor.B);

	return Chr(0x1B) $ Chr(NewColor.R) $ Chr(NewColor.G) $ Chr(NewColor.B);
}

simulated static function UTComp_PRI GetUTCompPRIFor(Controller C)
{
	if (C.PlayerReplicationInfo != None)
		return GetUTCompPRI(C.PlayerReplicationInfo);

	return none;
}

simulated static function UTComp_PRI GetUTCompPRIForPawn(Pawn P)
{
	if (P.PlayerReplicationInfo != None)
		return GetUTCompPRI(P.PlayerReplicationInfo);
	else if (P.Controller != None)
		return GetUTCompPRIFor(P.Controller);

	return none;
}

defaultproperties
{
}