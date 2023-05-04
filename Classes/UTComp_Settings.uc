class UTComp_Settings extends Object
	Config(fpsGameClient)
	PerObjectConfig;

var config bool bFirstRun;
var config bool bStats;

var config bool bEnableHitSounds;
var config string FriendlySound;
var config string EnemySound;
var config float HitSoundVolume;
var config bool bCPMAStyleHitsounds;
var config float CPMAPitchModifier;

var config float SavedSpectateSpeed;
var config bool bUseDefaultScoreBoard;
var config bool bShowSelfInTeamOverlay;
var config bool bClientNetcode;
var config bool bAllowColoredMessages;
var config bool bEnableColoredNamesOnEnemies;
var config bool bEnableColoredNamesInTalk;
var config array<byte> DontDrawInStats;

var config int CurrentSelectedColoredName;
var config Color ColorName[20];

var config bool bDisableSpeed, bDisableBooster;
var config bool bDisableInvis, bDisableBerserk;

struct ColoredNamePair
{
	var color SavedColor[20];
	var string SavedName;
};
var config array<ColoredNamePair> ColoredName;

var config array<string> DisallowedEnemyNames;

var config string FallbackCharacterName;
var config bool bEnemyBasedSkins;
var config byte ClientSkinModeRedTeammate;
var config byte ClientSkinModeBlueEnemy;
var config byte PreferredSkinColorRedTeammate;
var config byte PreferredSkinColorBlueEnemy;
var config Color BlueEnemyUTCompSkinColor;
var config Color RedTeammateUTCompSkinColor;
var config bool bBlueEnemyModelsForced;
var config bool bRedTeammateModelsForced;
var config string BlueEnemyModelName;
var config string RedTeammateModelName;
var config bool bEnableDarkSkinning;
var config bool bEnemyBasedModels;
var config bool bUseSlopeAlgorithm;

var config float DesiredNetUpdateRate;
var config int DesiredNetSpeed;

function CheckSettings()
{
	local string PackageName;

	PackageName = string(self.Class);
	PackageName = Left(PackageName, InStr(PackageName, "."));

	if (Left(FriendlySound, 6) ~= "UTComp")
		FriendlySound = PackageName $ Mid(FriendlySound, InStr(FriendlySound, "."));

	if (Left(EnemySound, 6) ~= "UTComp")
		EnemySound = PackageName $ Mid(EnemySound, InStr(EnemySound, "."));

	SaveConfig();
}

defaultproperties
{
	bFirstRun=true
	bStats=true
	bEnableHitSounds=true
	FriendlySound="fpsGame.Sounds.HitSoundFriendly"
	EnemySound="fpsGame.Sounds.HitSound"
	HitSoundVolume=1.000000
	bCPMAStyleHitsounds=true
	CPMAPitchModifier=1.400000
	SavedSpectateSpeed=800.000000
	bShowSelfInTeamOverlay=true
	bClientNetcode=true
	bAllowColoredMessages=true
	bEnableColoredNamesInTalk=true
	CurrentSelectedColoredName=255
	colorname(0)=(B=255,G=255,R=255,A=255)
	colorname(1)=(B=255,G=255,R=255,A=255)
	colorname(2)=(B=255,G=255,R=255,A=255)
	colorname(3)=(B=255,G=255,R=255,A=255)
	colorname(4)=(B=255,G=255,R=255,A=255)
	colorname(5)=(B=255,G=255,R=255,A=255)
	colorname(6)=(B=255,G=255,R=255,A=255)
	colorname(7)=(B=255,G=255,R=255,A=255)
	colorname(8)=(B=255,G=255,R=255,A=255)
	colorname(9)=(B=255,G=255,R=255,A=255)
	colorname(10)=(B=255,G=255,R=255,A=255)
	colorname(11)=(B=255,G=255,R=255,A=255)
	colorname(12)=(B=255,G=255,R=255,A=255)
	colorname(13)=(B=255,G=255,R=255,A=255)
	colorname(14)=(B=255,G=255,R=255,A=255)
	colorname(15)=(B=255,G=255,R=255,A=255)
	colorname(16)=(B=255,G=255,R=255,A=255)
	colorname(17)=(B=255,G=255,R=255,A=255)
	colorname(18)=(B=255,G=255,R=255,A=255)
	colorname(19)=(B=255,G=255,R=255,A=255)
	FallbackCharacterName="Jakob"
	ClientSkinModeRedTeammate=1
	ClientSkinModeBlueEnemy=1
	BlueEnemyUTCompSkinColor=(B=128,A=255)
	RedTeammateUTCompSkinColor=(R=128,A=255)
	BlueEnemyModelName="Jakob"
	RedTeammateModelName="Jakob"
	bEnableDarkSkinning=true
	DesiredNetUpdateRate=90.000000
	DesiredNetSpeed=10000
}