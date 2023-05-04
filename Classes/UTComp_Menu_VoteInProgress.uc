class UTComp_Menu_VoteInProgress extends UTComp_Menu_MainMenu;

var automated GUIButton bu_VoteYes, bu_VoteNo;
var automated GUILabel l_Vote[5];

event Opened(GUIComponent Sender)
{
	local UTComp_ServerReplicationInfo RepInfo;

	super.Opened(Sender);

	if (RepInfo == None)
	{
		foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	l_Vote[0].Caption = "";
	l_Vote[1].Caption = "A vote has been called to";

	switch (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID)
	{
		case 1:
			l_Vote[2].Caption = "change Brightskins Mode";
			break;

		case 2:
			l_Vote[2].Caption = "change Hitsounds Mode";
			break;

		case 3:
			l_Vote[2].Caption = "change Team Overlay Mode";
			break;

		case 4:
			l_Vote[2].Caption = "Change Enhanced Netcode Mode";
			break;

		default:
			l_Vote[2].Caption = "";
			break;
	}

//	if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID != 6)
//	{
		switch (BS_xPlayer(PlayerOwner()).UTCompPRI.VoteSwitch)
		{
			case 0:
				if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID == 1)
					l_Vote[3].Caption = "Epic Style";
				else if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID != 5)
					l_Vote[3].Caption = "Disabled";
				else
					l_Vote[3].Caption = "";
				break;

			case 1:
				if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID == 1)
					l_Vote[3].Caption = "Bright Epic Style";
				else if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID == 2)
					l_Vote[3].Caption = "Line Of Sight";
				else if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID != 5)
					l_Vote[3].Caption = "Enabled";
				else
					l_Vote[3].Caption = "";
				break;

			case 2:
				if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID == 1)
					l_Vote[3].Caption = "UTComp Style";
				else if (BS_xPlayer(PlayerOwner()).UTCompPRI.CurrentVoteID == 2)
					l_Vote[3].Caption = "Everywhere";
				break;

			default:
				l_Vote[3].Caption = "";
		}
//	}
}

function bool InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case bu_VoteYes:
			BS_xPlayer(PlayerOwner()).VoteYes();
			PlayerOwner().ClientCloseMenu();
			break;

		case bu_VoteNo:
			BS_xPlayer(PlayerOwner()).VoteNo();
			PlayerOwner().ClientCloseMenu();
			break;
	}

	return Super.InternalOnClick(Sender);
}

defaultproperties
{
	Begin Object Class=GUIButton Name=VoteYesButton
		Caption="Vote Yes"
		WinTop=0.700000
		WinLeft=0.300000
		WinWidth=0.250000
		WinHeight=0.100000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_VoteInProgress.InternalOnClick
		OnKeyEvent=VoteYesButton.InternalOnKeyEvent
	End Object
	bu_VoteYes=GUIButton'UTComp_Menu_VoteInProgress.VoteYesButton'

	Begin Object Class=GUIButton Name=votenoButton
		Caption="Vote No"
		WinTop=0.700000
		WinLeft=0.650000
		WinWidth=0.250000
		WinHeight=0.100000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_VoteInProgress.InternalOnClick
		OnKeyEvent=votenoButton.InternalOnKeyEvent
	End Object
	bu_VoteNo=GUIButton'UTComp_Menu_VoteInProgress.votenoButton'

	Begin Object Class=GUILabel Name=VoteLabel0
		Caption="Vote in progress"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.300000
		WinLeft=0.400000
		WinWidth=0.400000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Vote(0)=GUILabel'UTComp_Menu_VoteInProgress.VoteLabel0'

	Begin Object Class=GUILabel Name=VoteLabel1
		TextAlign=TXTA_Center
		TextColor=(B=255,G=255,R=255)
		WinTop=0.400000
		WinLeft=0.400000
		WinWidth=0.400000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Vote(1)=GUILabel'UTComp_Menu_VoteInProgress.VoteLabel1'

	Begin Object Class=GUILabel Name=VoteLabel2
		TextAlign=TXTA_Center
		TextColor=(B=255,G=255,R=255)
		WinTop=0.450000
		WinLeft=0.400000
		WinWidth=0.400000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Vote(2)=GUILabel'UTComp_Menu_VoteInProgress.VoteLabel2'

	Begin Object Class=GUILabel Name=VoteLabel3
		TextAlign=TXTA_Center
		TextColor=(B=25,G=255,R=255)
		WinTop=0.500000
		WinLeft=0.400000
		WinWidth=0.400000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Vote(3)=GUILabel'UTComp_Menu_VoteInProgress.VoteLabel3'

	Begin Object Class=GUILabel Name=VoteLabel4
		TextAlign=TXTA_Center
		TextColor=(B=255,G=255,R=255)
		WinTop=0.550000
		WinLeft=0.400000
		WinWidth=0.400000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Vote(4)=GUILabel'UTComp_Menu_VoteInProgress.VoteLabel4'
}