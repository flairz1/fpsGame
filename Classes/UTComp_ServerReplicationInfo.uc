class UTComp_ServerReplicationInfo extends ReplicationInfo;

var bool b_NoVoting;
var bool b_BrightskinsVoting;
var bool b_HitsoundsVoting;
var bool b_TeamOverlayVoting;
var bool b_PickupsOverlayVoting;
var bool b_NetcodeVoting;

var byte i_Brightskins;
var byte i_Hitsounds;

var bool b_TeamOverlay;
var bool b_PickupsOverlay;
var bool b_NewScoreboard;
var bool b_WeaponStats;
var bool b_PickupStats;
var bool b_Netcode;

var string VotingNames[15];
var string VotingOptions[15];
var PlayerReplicationInfo LinePRI[10];

var bool bShieldFix;

var int MinNetSpeed;
var int MaxNetSpeed;

replication
{
	reliable if (Role == ROLE_Authority)
		b_NoVoting, b_BrightskinsVoting, b_HitsoundsVoting,
		b_TeamOverlayVoting, b_PickupsOverlayVoting, b_NetcodeVoting,
		i_Brightskins, i_Hitsounds,
		b_TeamOverlay, b_PickupsOverlay, b_Netcode,
		MinNetSpeed, MaxNetSpeed,
		VotingNames, VotingOptions, LinePRI;
}

defaultproperties
{
//	b_NoVoting=true
//	b_BrightskinsVoting=true
//	b_HitsoundsVoting=true
//	b_TeamOverlayVoting=true
//	b_PickupsOverlayVoting=true
//	i_Brightskins=3
//	i_Hitsounds=1
//	b_TeamOverlay=true
//	b_PickupsOverlay=true
//	b_NewScoreboard=true
//	b_WeaponStats=true
//	b_PickupStats=true
}