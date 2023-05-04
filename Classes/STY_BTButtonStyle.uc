class STY_BTButtonStyle extends STY2SquareButton;

//description:
//	Img(0) Blurry	(component has no focus at all)
//	Img(1) Watched	(when Mouse is hovering over it)
//	Img(2) Focused	(component is selected)
//	Img(3) Pressed	(component is being pressed)
//	Img(4) Disabled	(component is disabled)

defaultproperties
{
	KeyName="BTButtonStyle"
	FontColors(0)=(B=200,G=200,R=200)
	FontColors(1)=(G=180,R=180)
	FontColors(3)=(G=255)
	FontColors(4)=(B=60,G=60,R=60)
	ImgColors(0)=(B=10,G=10,R=10,A=160)
	ImgColors(1)=(B=10,G=10,R=10,A=140)
	ImgColors(2)=(B=10,G=10,R=10,A=140)
	ImgColors(3)=(B=10,G=10,R=10,A=160)
	ImgColors(4)=(B=10,G=10,R=10,A=80)
	Images(0)=Texture'fpsGame.mats.bt_button'
	Images(1)=Texture'fpsGame.mats.bt_watch'
	Images(2)=Texture'fpsGame.mats.bt_watch'
	Images(3)=Texture'fpsGame.mats.bt_button'
	Images(4)=Texture'fpsGame.mats.bt_none'
}