class UTComp_Vote_Started extends CriticalEventPlus;

static simulated function ClientReceive (PlayerController P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	P.PlayAnnouncement(Sound'UTCompError', 1, true);
}

defaultproperties
{
}