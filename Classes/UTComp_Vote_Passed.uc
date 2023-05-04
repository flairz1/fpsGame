class UTComp_Vote_Passed extends CriticalEventPlus;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if (switch == 1)
		return "Voting has Passed, Please Revote!";
	return "Voting has Passed!";
}

defaultproperties
{
}