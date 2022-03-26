package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.addons.display.FlxTiledSprite;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSave;

class UnlockScreen extends FlxState
{
	var SpritesToMove:FlxSpriteGroup = new FlxSpriteGroup(FlxG.width, Std.int(FlxG.height * 0.361979167) - 32);
    var achievementStatus:Map<String, String> = ["week1done" => "Unlocked Output and Dragonsnaps", "week2done" => "Unlocked Mystery and Orb", "bothweeksdone" => "Unlocked Eyeball"];
	var achievementData:Map<String, String> = ['week1done' => 'Output and Dragonsnaps now possess spots in Freeplay!', 'week2done' => "Olevadon is excited for a rematch! \n Mystery and Orb have appeared in freeplay.", 'bothweeksdone' => 'A mysterious entity has appeared in freeplay.\n Do you dare to take on this blood demon?'];
    public static var messagesToDisplay:Array<String> = [];
    var AchievementAccepted:Bool = false;
	var ChocolateDescription:FlxText;
	var OKText:FlxText;
	var UnlockMusic:FlxSound;
    var BoxSprite:FlxSprite;
	public static var AchievementsArray:Array<String> = [];
	public static var CrusadeAchievementsSaveFile:FlxSave = new FlxSave();

	override public function new()
	{
		super();
		// SpritesToMove =
		// var VanillaText = new FlxText(BoxSprite.x + 165, BoxSprite.y - 32, 0, DateTools.format(Date.now(), "%Y/%m/%d %H:%M"), 25).setFormat(Paths.font('HighlandGothicFLF-Bold.ttf'), 25, FlxColor.WHITE);
		// SpritesToMove.add(VanillaText);
	}

	public static function loadStuff():Array<String>
	{
		CrusadeAchievementsSaveFile.bind('achievements', 'CrusadeAchievements');
		if (CrusadeAchievementsSaveFile.data.CrusadeAchievementsThing != null)
			AchievementsArray = CrusadeAchievementsSaveFile.data.CrusadeAchievementsThing;
		return AchievementsArray;
	}

    public static function saveAndUnlockStuff()
    {
		CrusadeAchievementsSaveFile.bind('achievements', 'CrusadeAchievements');
         // awful shit code //keep in mind this is for the actual new achievements to seperate them from the already unlocked ones.
		if (CrusadeAchievementsSaveFile != null && CrusadeAchievementsSaveFile.data.CrusadeAchievementsThing != null)
			AchievementsArray = CrusadeAchievementsSaveFile.data.CrusadeAchievementsThing;
		switch (WeekData.getWeekFileName())
		{
			case 'weekd':
				if (!AchievementsArray.contains('week1done'))
				{
					AchievementsArray[0] = 'week1done';
					messagesToDisplay.push('week1done');
				}
				if (AchievementsArray.contains('week2done') && !AchievementsArray.contains('bothweeksdone'))
				{
					AchievementsArray[2] = 'bothweeksdone';
					messagesToDisplay.push('bothweeksdone');
				}
			case 'weeko':
				if (!AchievementsArray.contains('week2done'))
				{
					AchievementsArray[1] = 'week2done';
					messagesToDisplay.push('week2done');
				}
				if (AchievementsArray.contains('week1done') && !AchievementsArray.contains('bothweeksdone'))
 				{
					AchievementsArray[2] = 'bothweeksdone';
					messagesToDisplay.push('bothweeksdone');
				}
		}
		trace(messagesToDisplay);
        if (messagesToDisplay.length > 0) 
        { 
			CrusadeAchievementsSaveFile.data.CrusadeAchievementsThing = AchievementsArray;
			FlxTransitionableState.skipNextTransIn = true;
			FlxG.save.flush();
			FlxG.switchState(new UnlockScreen());
        }
		else
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			MusicBeatState.switchState(new StoryMenuState());
		}
    }

    override public function create()
    {
		super.create();
        UnlockMusic = new FlxSound().loadEmbedded(Paths.music('unlock', 'week7'));
        FlxG.sound.list.add(UnlockMusic);
		BoxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('achievebox'));
		ChocolateDescription = new FlxText(BoxSprite.x + 80, BoxSprite.y + 45, 910, 'This should not appear, what should I do if it does', 25).setFormat(Paths.font('HighlandGothicFLF-Bold.ttf'), 25, FlxColor.WHITE, CENTER);
		var VanillaText = new FlxText(BoxSprite.x + 165, BoxSprite.y - 32, 0, DateTools.format(Date.now(), "%Y/%m/%d %H:%M"), 25).setFormat(Paths.font('HighlandGothicFLF-Bold.ttf'), 25, FlxColor.WHITE);
		SpritesToMove.add(BoxSprite);
        SpritesToMove.add(VanillaText);
        SpritesToMove.add(ChocolateDescription);
		var ConfirmBox = new FlxSprite(0, 0).loadGraphic(Paths.image('achievebox_ok'));
        ConfirmBox.updateHitbox();
        ConfirmBox.x += 435;
        ConfirmBox.y += 90;
		OKText = new FlxText(ConfirmBox.x + 87, ConfirmBox.y + 18, 0, 'OK', 69).setFormat(Paths.font('HighlandGothicFLF-Bold.ttf'), 36, FlxColor.WHITE, CENTER);
		SpritesToMove.add(ConfirmBox);
		SpritesToMove.add(OKText);
        add(SpritesToMove);
		showNewAchievement();
        
    }
    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.keys.justPressed.ENTER && !AchievementAccepted)
        {
			AchievementAccepted = true;
            FlxFlicker.flicker(OKText, 0);
            new FlxTimer().start(2, function(onTimer:FlxTimer){removeAchievement();});
            FlxG.sound.play(Paths.sound('accept', 'week7'));
            //FLxTImer.start(3, )
			//if (messagesToDisplay.length > 1)
			//	showNewAchievement();
        }
    }
    function showNewAchievement()
    {
        FlxFlicker.stopFlickering(OKText);
        AchievementAccepted = false;
        UnlockMusic.stop();
		UnlockMusic.play();
		SpritesToMove.x = FlxG.width;
		FlxTween.tween(SpritesToMove, {x: FlxG.width * 0.0808823529}, 0.166666667);
		var achievementThing = messagesToDisplay.pop();
		#if desktop
		DiscordClient.changePresence(achievementStatus[achievementThing], null);
		#end
		ChocolateDescription.text = achievementData[achievementThing];
		ChocolateDescription.y = (BoxSprite.y + 45) - (ChocolateDescription.height * 0.25) * (achievementData[achievementThing].split('\n')).length;
    }
    function removeAchievement()
    {
		FlxTween.tween(SpritesToMove, {x: -FlxG.width}, 0.166666667, {onComplete: function(tween:FlxTween)
		{
			if (messagesToDisplay.length > 0)
			{
				showNewAchievement();
			}
			else
			{
				FlxTransitionableState.skipNextTransOut = true;
                FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.sound.music.fadeTween = null;
                MusicBeatState.switchState(new StoryMenuState());
            }
        }
    });
    }
}


class WarnyScreeny extends FlxState
{
	var FuckShit:FlxSound = new FlxSound().loadEmbedded(Paths.sound('pixelText', 'shared'));
	var WarningStrip:FlxTiledSprite;
    override public function create()
    {
		WarningStrip = new FlxTiledSprite(Paths.image('warning', 'shared'), FlxG.width, FlxG.height, true, false);
        WarningStrip.antialiasing = true;
		var WarningStripOverlay:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xBF000000);
		var TextWarning:FlxText = new FlxText(FlxG.width * 0.025, FlxG.height * 0.20, 0, "WARNING\n\nThis mod contains flashing lights and rapidly moving arrows\nfor the third song of the first week.\nYou cannot turn them off so please play\nor watch at your own risk.\n\n To disable this warning, Press F. \n\n\n TAP THE SCREEN TO CONTINUE", 32);
        TextWarning.alignment = CENTER;
        add(WarningStrip);
        add(WarningStripOverlay);
        add(TextWarning);
        FuckShit.play();
    }
    override public function update(elapsed:Float)
    {
        WarningStrip.scrollX += 0.9;
        
    		#if mobile
		
		if(touch.justPressed)
		{
			FuckShit.loadEmbedded(Paths.sound('cancelMenu'));
            FuckShit.play();
            FlxG.switchState(new TitleState());
        }
        if(FlxG.keys.justPressed.F)
        {
			FuckShit.loadEmbedded(Paths.sound('confirmMenu'));
			FlxG.save.data.warningScreen = false;
			FuckShit.play();
			FlxG.switchState(new TitleState());
        }
    }
}