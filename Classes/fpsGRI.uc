class fpsGRI extends InvasionGameReplicationInfo;

var int BossTimeLimit, KillZoneLimit;
var int NumMons, NumBoss;
var bool BossWave;

replication
{
	reliable if (Role == ROLE_Authority)
		BossTimeLimit, KillZoneLimit, NumMons, NumBoss, BossWave;
}

defaultproperties
{
}