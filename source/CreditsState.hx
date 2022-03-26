package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import sys.FileSystem;
import lime.utils.Assets;
import flixel.math.FlxRandom;
import flixel.tweens.FlxEase;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = 1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Dynamic> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	public static var Error404EasterEggTriggered = false;
	var triggeredFunnyMemeSpinAlt = false;

	override function create()
	{
		triggeredFunnyMemeSpinAlt = FlxG.random.bool(4.2069);
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		trace("finding mod shit");
		if (FileSystem.exists(Paths.mods())) {
			trace("mods folder");
			if (FileSystem.exists(Paths.modFolders("data/credits.txt"))){
				trace("credit file");
				var firstarray:Array<String> = CoolUtil.coolTextFile(Paths.modFolders("data/credits.txt"));
				trace("found credit shit");
				
				for(i in firstarray){
					var arr:Array<String> = i.split("::");
					trace(arr);
					creditsStuff.push(arr);
				}
			}
		}
		
		#end
		var pisspoop = [ //Name - Icon name - Description - Link - BG Color
		['Vs Dracobot'],
		['Dracobot', 'draco_psych_icon', 'Director, Spriter, Charter and Animator', 'https://mobile.twitter.com/Dracobot950', '0xFFFFDD33'],
		['Lyre101',	'lyre_psychengine_credit_icon',	'Composer', 'https://www.youtube.com/channel/UCBtV3r4Q1-jXdm_j1GgQYtg', '0xFFFFDD33'],
		['Mojo', 'mojo_psych_icon', 'Composer','https://gamebanana.com/mods/325970', '0xFFFFDD33'],
		['T1GD', 'T1GD_psych_icon', 'Composer', 'https://www.youtube.com/channel/UCsJgo-wOhHe9R9TvScLejsA/featured', '0xFFFFDD33'],
		['Numbskill', 'numbskilll_psych_icon', 'Dracobot Voice Actor', 'https://twitter.com/Numbskill4Real', '0xFFFFDD33'],
		['AshoXD', 'credit-icons', 'Composer, Charter and Animator', 'https://twitter.com/ashomoment', '0xFFFFDD33'],//asho why u icon just called credit-icons.png what
		['RushFox', 'stupid_dumb_fuck', 'Coder for Update 2', 'https://greyslamgrimlock.newgrounds.com/', '0xFFFFDD33'],
		['Psych Engine Team'],
		['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',					'https://twitter.com/Shadow_Mario_',	'0xFFFFDD33'],
		['RiverOaken',			'riveroaken',		'Main Artist/Animator of Psych Engine',				'https://twitter.com/river_oaken',		'0xFFC30085'],
		[''],
		['Engine Contributors'],
		['shubs',				'shubs',			'New Input System Programmer',						'https://twitter.com/yoshubs',			'0xFF4494E6'],
		['PolybiusProxy',		'polybiusproxy',	'.MP4 Video Loader Extension',						'https://twitter.com/polybiusproxy',	'0xFFE01F32'],
		['gedehari',			'gedehari',			'Chart Editor\'s Sound Waveform base',				'https://twitter.com/gedehari',			'0xFFFF9300'],
		['Keoiki',				'keoiki',			'Note Splash Animations',							'https://twitter.com/Keoiki_',			'0xFFFFFFFF'],
		['SandPlanet',			'sandplanet',		'Mascot\'s Owner\nMain Supporter of the Engine',		'https://twitter.com/SandPlanetNG',	'0xFFD10616'],
		['bubba',				'bubba',		'Guest Composer for "Hot Dilf"',	'https://www.youtube.com/channel/UCxQTnLmv0OAS63yzk9pVfaw',	'0xFF61536A'],
		[''],
		["Funkin' Crew"],
		['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",				'https://twitter.com/ninja_muffin99',	'0xFFF73838'],
		['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",					'https://twitter.com/PhantomArcade3K',	'0xFFFFBB1B'],
		['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",					'https://twitter.com/evilsk8r',			'0xFF53E52C'],
		['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",					'https://twitter.com/kawaisprite',		'0xFF6475F3']
	];
		
		
				for(i in pisspoop){
					creditsStuff.push(i);
				}
			
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
			optionText.isMenuItem = true;
			optionText.screenCenter(X);
			if(isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			//optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(isSelectable) {
				var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
			}
		}

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		bg.color = Std.parseInt(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();
		super.create();

		Conductor.changeBPM(182);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		persistentUpdate = true;
		
	}

	override function beatHit()
	{
		FlxG.log.add('ROK');
		Conductor.songPosition = FlxG.sound.music.time;
		if (Error404EasterEggTriggered)
		{
			trace('Speen');
			for (i in iconArray)
			{
				i.angleAdd = 0;
				if (triggeredFunnyMemeSpinAlt)
					FlxTween.tween(i, {angleAdd: 360}, 0.3);
				else
					FlxTween.tween(i, {angleAdd: 360}, 0.2, {ease: FlxEase.quintOut});
			}
		}

	}
	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
			trace(Error404EasterEggTriggered);
		}

		if (controls.BACK)
		{
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		if(controls.ACCEPT) {
			CoolUtil.browserLoad(creditsStuff[curSelected][3]);
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int =  Std.parseInt(creditsStuff[curSelected][4]);
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}
		descText.text = creditsStuff[curSelected][2];
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}
