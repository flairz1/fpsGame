class MutFPSGame extends DMMutator
	HideDropDown
	CacheExempt;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	bSuperRelevant = 0;
	if (Pawn(Other) != none)
	{
		Pawn(Other).bAutoActivate = true;
	}
	else if (GameObjective(Other) != none)
	{
		Other.bHidden = true;
		GameObjective(Other).bDisabled = true;
		GameObjective(Other).DefenderTeamIndex = 255;
		GameObjective(Other).StartTeam = 255;
		Other.SetCollision(false, false, false);
	}
	else if (GameObject(Other) != none)
	{
		return false;
	}

	return true;
}

defaultproperties
{
}