package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxSubState;
import haxe.Json;
import flixel.math.FlxRect;
import haxe.format.JsonParser;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.utils.Assets;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;

using StringTools;

typedef DialogueCharacterFile =
{
	var image:String;
	var dialogue_pos:String;
	var animations:Array<DialogueAnimArray>;
	var graphicsprites:Array<String>;
	var position:Array<Float>;
	var scale:Float;
	var specialFlags:Array<String>;
	var antialiasing:Null<Bool>;
}

typedef DialogueAnimArray =
{
	var anim:String;
	var loop_name:String;
	var loop_offsets:Array<Int>;
	var idle_name:String;
	var idle_offsets:Array<Int>;
}

// Gonna try to kind of make it compatible to Forever Engine,
// love u Shubs no homo :flushedh4:
typedef DialogueFile =
{
	var dialogue:Array<DialogueLine>;
}

typedef DialogueLine =
{
	var portrait:Null<String>;
	var expression:Null<String>;
	var text:Null<String>;
	var boxState:Null<String>;
	var speed:Null<Float>;
	var eventToDo:Null<String>;
}

class DialogueCharacter extends FlxSprite
{
	private static var IDLE_SUFFIX:String = '-IDLE';
	public static var DEFAULT_CHARACTER:String = 'bf';
	public static var DEFAULT_SCALE:Float = 0.7;

	public var jsonFile:DialogueCharacterFile = null;
	#if (haxe >= "4.0.0")
	public var dialogueAnimations:Map<String, DialogueAnimArray> = new Map();
	#else
	public var dialogueAnimations:Map<String, DialogueAnimArray> = new Map<String, DialogueAnimArray>();
	#end

	public var startingPos:Float = 0; // For center characters, it works as the starting Y, for everything else it works as starting X
	public var isGhost:Bool = false; // For the editor
	public var curCharacter:String = 'bf';

	public function new(x:Float = 0, y:Float = 0, character:String = null)
	{
		super(x, y);

		if (character == null)
			character = DEFAULT_CHARACTER;
		this.curCharacter = character;

		reloadCharacterJson(character);

		if (jsonFile.specialFlags != null)
		{
			for (flag in jsonFile.specialFlags)
				switch (flag)
				{
					case "StaticPortrait": // makes so the game doesnt use a sparrow atlas when it really doesnt need to.
						loadGraphic(Paths.image('dialogue/' + jsonFile.image));
				}
		}
		else
		{
			frames = Paths.getSparrowAtlas('dialogue/' + jsonFile.image);
			reloadAnimations();
		}
	}

	public function reloadCharacterJson(character:String)
	{
		var characterPath:String = 'images/dialogue/' + character + '.json';
		var rawJson = null;

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		{
			path = Paths.getPreloadPath('images/dialogue/' + DEFAULT_CHARACTER + '.json');
		}
		rawJson = File.getContent(path);
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		rawJson = Assets.getText(path);
		#end

		jsonFile = cast Json.parse(rawJson);
	}

	public function reloadAnimations()
	{
		dialogueAnimations.clear();
		if (jsonFile.animations != null && jsonFile.animations.length > 0)
		{
			for (anim in jsonFile.animations)
			{
				animation.addByPrefix(anim.anim, anim.loop_name, 24, isGhost);
				animation.addByPrefix(anim.anim + IDLE_SUFFIX, anim.idle_name, 24, true);
				dialogueAnimations.set(anim.anim, anim);
			}
		}
	}

	public function playAnim(animName:String = null, playIdle:Bool = false)
	{
		var leAnim:String = animName;
		if (animName == null || !dialogueAnimations.exists(animName))
		{ // Anim is null, get a random animation
			var arrayAnims:Array<String> = [];
			for (anim in dialogueAnimations)
			{
				arrayAnims.push(anim.anim);
			}
			if (arrayAnims.length > 0)
			{
				leAnim = arrayAnims[FlxG.random.int(0, arrayAnims.length - 1)];
			}
		}

		if (dialogueAnimations.exists(leAnim)
			&& (dialogueAnimations.get(leAnim).loop_name == null
				|| dialogueAnimations.get(leAnim).loop_name.length < 1
				|| dialogueAnimations.get(leAnim).loop_name == dialogueAnimations.get(leAnim).idle_name))
		{
			playIdle = true;
		}
		animation.play(playIdle ? leAnim + IDLE_SUFFIX : leAnim, false);
		if (dialogueAnimations.exists(leAnim))
		{
			var anim:DialogueAnimArray = dialogueAnimations.get(leAnim);
			if (playIdle)
			{
				offset.set(anim.idle_offsets[0], anim.idle_offsets[1]);
				// trace('Setting idle offsets: ' + anim.idle_offsets);
			}
			else
			{
				offset.set(anim.loop_offsets[0], anim.loop_offsets[1]);
				// trace('Setting loop offsets: ' + anim.loop_offsets);
			}
		}
		else
		{
			offset.set(0, 0);
			trace('Offsets not found! Dialogue character is badly formatted, anim: '
				+ leAnim
				+ ', '
				+ (playIdle ? 'idle anim' : 'loop anim'));
		}
	}

	public function animationIsLoop():Bool
	{
		if (animation.curAnim == null)
			return false;
		return !animation.curAnim.name.endsWith(IDLE_SUFFIX);
	}
}

// TO DO: Clean code? Maybe? idk
class DialogueBoxPsych extends FlxSubState
{
	var SkipText = new FlxSprite(FlxG.width * 0.85, FlxG.height * 0.035);
	var SkipTextHighlight = new FlxSprite(FlxG.width * 0.85, FlxG.height * 0.035);

	var dialogue:Alphabet;
	var dialogueList:DialogueFile = null;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var bgFade:FlxSprite = null;
	var box:FlxSprite;

	var textToType:String = '';

	var arrayCharacters:Array<DialogueCharacter> = [];

	var currentText:Int = 0;
	var offsetPos:Float = -600;

	var SkipCoolThing:Float = 0;

	var textBoxTypes:Array<String> = ['normal', 'angry', 'blank'];

	// var charPositionList:Array<String> = ['left', 'center', 'right'];
	var SpawnedStuff:FlxTypedGroup<Dynamic> = new FlxTypedGroup<Dynamic>();
	var SpawnedStuffBGLayer:FlxTypedGroup<Dynamic> = new FlxTypedGroup<Dynamic>();
	var HighPriority:FlxTypedGroup<Dynamic> = new FlxTypedGroup<Dynamic>();
	var CharacterShit:FlxTypedGroup<Dynamic> = new FlxTypedGroup<Dynamic>();

	public function new(dialogueList:DialogueFile, ?song:String = null, ?library:String = null)
	{
		super();

		if (song != null && song != '')
		{
			FlxG.sound.playMusic(Paths.music(song, library), 0);
			FlxG.sound.music.fadeIn(2, 0, 1);
		}

		SkipText.frames = Paths.getSparrowAtlas('funny monkey movie');
		SkipTextHighlight.frames = Paths.getSparrowAtlas('woa cool');

		bgFade = new FlxSprite(-500, -500).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
		bgFade.scrollFactor.set();
		bgFade.visible = true;
		bgFade.alpha = 0;
		FlxTween.tween(bgFade, {alpha: 0.5}, 1); // shadow mario or whoever scripted the bg fade JUST USE A TWEEN PLEEASEEEEEEEEEEEEEE
		// i had to change into a tween so its reusable for the blackout effect.
		add(bgFade);
		add(SpawnedStuffBGLayer);
		add(CharacterShit);
		add(SpawnedStuff);
		add(HighPriority);
		HighPriority.add(SkipText);
		HighPriority.add(SkipTextHighlight);

		SkipTextHighlight.clipRect = new FlxRect(FlxG.width * 0.85, SkipTextHighlight.y, SkipTextHighlight.width, SkipTextHighlight.height);

		this.dialogueList = dialogueList;
		spawnCharacters();

		box = new FlxSprite(70, 370);
		box.frames = Paths.getSparrowAtlas('speech_bubble');
		box.scrollFactor.set();
		box.antialiasing = ClientPrefs.globalAntialiasing;
		box.animation.addByPrefix('normal', 'speech bubble normal', 12);
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 12, false);
		box.animation.addByPrefix('angry', 'AHH speech bubble normal', 12);
		box.animation.addByPrefix('angryOpen', 'speech bubble loud open', 12, false);
		box.animation.addByPrefix('center-normal', 'speech bubble middle', 12);
		box.animation.addByPrefix('center-normalOpen', 'Speech Bubble Middle Open', 12, false);
		box.animation.addByPrefix('center-angry', 'AHH speech bubble middle', 12);
		box.animation.addByPrefix('center-angryOpen', 'speech bubble loud open middle', 12, false);
		box.animation.addByPrefix('blankOpen', "Speech Bubble Blank Open", 12, false);
		box.animation.addByPrefix('blank', "speech bubble blank", 12, true);
		box.animation.play('normal', true);
		box.visible = false;
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		HighPriority.add(box);

		startNextDialog();
	}

	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;

	public static var LEFT_CHAR_X:Float = -60;
	public static var RIGHT_CHAR_X:Float = -100;
	public static var DEFAULT_CHAR_Y:Float = 60;

	function spawnCharacters()
	{
		#if (haxe >= "4.0.0")
		var charsMap:Map<String, Bool> = new Map();
		#else
		var charsMap:Map<String, Bool> = new Map<String, Bool>();
		#end
		for (i in 0...dialogueList.dialogue.length)
		{
			if (dialogueList.dialogue[i] != null)
			{
				var charToAdd:String = dialogueList.dialogue[i].portrait;
				if (!charsMap.exists(charToAdd) || !charsMap.get(charToAdd))
				{
					charsMap.set(charToAdd, true);
				}
			}
		}

		for (individualChar in charsMap.keys())
		{
			var x:Float = LEFT_CHAR_X;
			var y:Float = DEFAULT_CHAR_Y;
			var char:DialogueCharacter = new DialogueCharacter(x + offsetPos, y, individualChar);

			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * char.jsonFile.scale));
			char.updateHitbox();
			if (char.jsonFile.antialiasing == null || char.jsonFile.antialiasing)
				char.antialiasing = ClientPrefs.globalAntialiasing;
			char.scrollFactor.set();
			char.alpha = 0.00001;
			CharacterShit.add(char);

			var saveY:Bool = false;
			switch (char.jsonFile.dialogue_pos)
			{
				case 'center':
					char.x = FlxG.width / 2;
					char.x -= char.width / 2;
					y = char.y;
					char.y = FlxG.height + 50;
					saveY = true;
				case 'right':
					x = FlxG.width - char.width + RIGHT_CHAR_X;
					char.x = x - offsetPos;
			}
			x += char.jsonFile.position[0];
			y += char.jsonFile.position[1];
			char.x += char.jsonFile.position[0];
			char.y += char.jsonFile.position[1];
			char.startingPos = (saveY ? y : x);
			arrayCharacters.push(char);
		}
	}

	public static var DEFAULT_TEXT_X = 90;
	public static var DEFAULT_TEXT_Y = 430;

	var scrollSpeed = 4500;
	var daText:Alphabet = null;
	var ignoreThisFrame:Bool = true; // First frame is reserved for loading dialogue images

	public function KILLHAHA()
	{
		destroyAdditionalObjects();
		dialogueEnded = true;
		for (i in 0...textBoxTypes.length)
		{
			var checkArray:Array<String> = ['', 'center-'];
			var animName:String = box.animation.curAnim.name;
			for (j in 0...checkArray.length)
			{
				if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open')
				{
					box.animation.play(checkArray[j] + textBoxTypes[i] + 'Open', true);
				}
			}
		}

		box.animation.curAnim.curFrame = box.animation.curAnim.frames.length - 1;
		box.animation.curAnim.reverse();
		daText.killTheTimer();
		daText.kill();
		remove(daText);
		daText.destroy();
		daText = null;
	}

	override function update(elapsed:Float)
	{
		if (ignoreThisFrame)
		{
			ignoreThisFrame = false;
			super.update(elapsed);
			return;
		}

		if (!dialogueEnded)
		{
			if (PlayerSettings.player1.controls.ACCEPT)
			{
				if (!daText.finishedText)
				{
					if (daText != null)
					{
						daText.killTheTimer();
						daText.kill();
						remove(daText);
						daText.destroy();
					}
					daText = new Alphabet(DEFAULT_TEXT_X, DEFAULT_TEXT_Y, textToType, false, true, 0.0, 0.7);
					HighPriority.add(daText);

					if (skipDialogueThing != null)
					{
						skipDialogueThing();
					}
				}
				else if (currentText >= dialogueList.dialogue.length)
				{
					dialogueEnded = true;
					for (i in 0...textBoxTypes.length)
					{
						var checkArray:Array<String> = ['', 'center-'];
						var animName:String = box.animation.curAnim.name;
						for (j in 0...checkArray.length)
						{
							if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open')
							{
								box.animation.play(checkArray[j] + textBoxTypes[i] + 'Open', true);
							}
						}
					}

					box.animation.curAnim.curFrame = box.animation.curAnim.frames.length - 1;
					box.animation.curAnim.reverse();
					daText.kill();
					remove(daText);
					daText.destroy();
					daText = null;
					updateBoxOffsets(box);
					FlxG.sound.music.fadeOut(1, 0);
				}
				else
				{
					startNextDialog();
				}
				FlxG.sound.play(Paths.sound('dialogueClose'));
			}
			else if (FlxG.keys.justPressed.S)
			{
				FlxTween.tween(SkipText, {y: -125}, 1, {ease: FlxEase.cubeIn});
				KILLHAHA();
			}
			else if (daText.finishedText)
			{
				var char:DialogueCharacter = arrayCharacters[lastCharacter];
				if (char != null && char.animation.curAnim != null && char.animationIsLoop() && char.animation.finished)
				{
					char.playAnim(char.animation.curAnim.name, true);
				}
			}
			else
			{
				var char:DialogueCharacter = arrayCharacters[lastCharacter];
				if (char != null && char.animation.curAnim != null && char.animation.finished)
				{
					char.animation.curAnim.restart();
				}
			}

			if (box.animation.curAnim.finished)
			{
				for (i in 0...textBoxTypes.length)
				{
					var checkArray:Array<String> = ['', 'center-'];
					var animName:String = box.animation.curAnim.name;
					for (j in 0...checkArray.length)
					{
						if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open')
						{
							box.animation.play(checkArray[j] + textBoxTypes[i], true);
						}
					}
				}
				updateBoxOffsets(box);
			}
		}
		else
		{ // Dialogue ending
			if (box != null && box.animation.curAnim.curFrame <= 0)
			{
				box.kill();
				remove(box);
				box.destroy();
				box = null;
			}

			if (bgFade != null)
			{
				bgFade.alpha -= 0.5 * elapsed;
				if (bgFade.alpha <= 0)
				{
					bgFade.kill();
					remove(bgFade);
					bgFade.destroy();
					bgFade = null;
				}
			}

			for (i in 0...arrayCharacters.length)
			{
				var leChar:DialogueCharacter = arrayCharacters[i];
				if (leChar != null)
				{
					switch (arrayCharacters[i].jsonFile.dialogue_pos)
					{
						case 'left':
							leChar.x -= scrollSpeed * elapsed;
						case 'center':
							leChar.y += scrollSpeed * elapsed;
						case 'right':
							leChar.x += scrollSpeed * elapsed;
					}
					leChar.alpha -= elapsed * 10;
				}
			}

			if (box == null && bgFade == null)
			{
				for (i in 0...arrayCharacters.length)
				{
					var leChar:DialogueCharacter = arrayCharacters[0];
					if (leChar != null)
					{
						arrayCharacters.remove(leChar);
						leChar.kill();
						remove(leChar);
						leChar.destroy();
					}
				}
				finishThing();
				destroyAdditionalObjects();
				kill();
			}
		}
		super.update(elapsed);
	}

	var lastCharacter:Int = -1;
	var lastBoxType:String = '';

	function startNextDialog():Void
	{
		var curDialogue:DialogueLine = null;
		do
		{
			curDialogue = dialogueList.dialogue[currentText];
		}
		while (curDialogue == null);

		if (curDialogue.text == null || curDialogue.text.length < 1)
			curDialogue.text = ' ';
		if (curDialogue.boxState == null)
			curDialogue.boxState = 'normal';
		if (curDialogue.speed == null || Math.isNaN(curDialogue.speed))
			curDialogue.speed = 0.05;

		var animName:String = curDialogue.boxState;
		var boxType:String = textBoxTypes[0];
		for (i in 0...textBoxTypes.length)
		{
			if (textBoxTypes[i] == animName)
			{
				boxType = animName;
			}
		}

		var character:Int = 0;
		box.visible = true;
		for (i in 0...arrayCharacters.length)
		{
			if (arrayCharacters[i].curCharacter == curDialogue.portrait)
			{
				character = i;
				break;
			}
		}

		if (daText != null)
		{
			daText.killTheTimer();
			daText.kill();
			remove(daText);
			daText.destroy();
		}

		textToType = curDialogue.text;

		daText = new Alphabet(DEFAULT_TEXT_X, DEFAULT_TEXT_Y, textToType, false, true, curDialogue.speed, 0.7);

		var centerPrefix:String = '';
		var lePosition:String = arrayCharacters[character].jsonFile.dialogue_pos;

		var char:DialogueCharacter = arrayCharacters[character];

		if (char != null)
		{
			if (!char.jsonFile.specialFlags.contains('StaticPortrait'))
			{
				char.playAnim(curDialogue.expression, daText.finishedText);
				if (char.animation.curAnim != null)
				{
					var rate:Float = 24 - (((curDialogue.speed - 0.05) / 5) * 480);
					if (rate < 12)
						rate = 12;
					else if (rate > 48)
						rate = 48;
					char.animation.curAnim.frameRate = rate;
				}
			}
			else
			{
				if (Assets.exists(Paths.image('dialogue/' + curDialogue.expression))
					&& char.jsonFile.graphicsprites != null
					&& char.jsonFile.graphicsprites.contains(curDialogue.expression))
				{
					char.loadGraphic(Paths.image('dialogue/' +
						curDialogue.expression)); // WORKS //saucyy //currently doesnt work since setting char.frames fucking breaks flxsprite
				}
				else
				{
					char.loadGraphic(Paths.image('dialogue/' + char.jsonFile.image));
				}
				switch (curDialogue.eventToDo)
				{
					case 'musickill':
						FlxG.sound.music.pause();
					case 'musiclive':
						FlxG.sound.playMusic(Paths.music('DracoDialogue', 'week7'));
						FlxG.sound.music.play();
					case 'screensky':
						PlayState.snapCamFollowToPos(400, -750);
					case 'blackout2': 
						var Racism = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
						SpawnedStuffBGLayer.add(Racism);
					case 'blackout':
						var Black = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
						SpawnedStuff.add(Black);
					case 'wimdows':
						var WindowsStartup = new FlxSound().loadEmbedded(Paths.sound('Windows XP Startup', 'week7'));
						WindowsStartup.play();
						SpawnedStuff.add(WindowsStartup);
					case "vine boom":
						var bababooey = new FlxSound().loadEmbedded(Paths.sound('Vine Boom Sound Effect (Longer Verison For Real) (Read Description Please)',
							'week7'));
						bababooey.play();
						SpawnedStuff.add(bababooey);
					case 'static':
						var StaticSound = new FlxSound().loadEmbedded(Paths.sound('TheBuzz', 'week7'));
						StaticSound.volume = 1.12;
						StaticSound.looped = true;
						StaticSound.play();
						SpawnedStuff.add(StaticSound); // referring to the variable for the sound itself since if i dont do it this way i cant delete the sound with 'kill'
					case 'loading':
						FlxG.sound.music.pause();
						var FuckShit:Int = 0;
						var CircleLol:FlxSprite = new FlxSprite(char.x + 70, char.y + char.height * 0.25);
						CircleLol.frames = Paths.getSparrowAtlas('loading circle');
						CircleLol.animation.addByPrefix('fuckyou', 'circle lol', 12, true);
						CircleLol.animation.play('fuckyou');
						CircleLol.scale.set(1.2, 1.2);
						CircleLol.antialiasing = true;
						var TheFunkyTimer = new FlxTimer().start(0.05, function(tmr:FlxTimer)
						{
							char.setColorTransform(1, 1, 1, 1, FuckShit, FuckShit, FuckShit);
							if (FuckShit < 145)
							{
								FuckShit += 5;
							}
							else
							{
								SpawnedStuff.add(CircleLol);
								add(CircleLol);
							}
						}, 30);
						SpawnedStuff.add(TheFunkyTimer);
					case 'kill':
						destroyAdditionalObjects();
						arrayCharacters[lastCharacter].setColorTransform(1, 1, 1, 1, 0, 0, 0);

				}
			}
		}
		currentText++;
		switch (boxType)
		{
			case "blank":
				daText.typingSound = "";
				centerPrefix = '';
			default:
				if (lePosition == 'center')
					centerPrefix = 'center-';
				daText.typingSound = arrayCharacters[character].curCharacter;
		}

		if (character != lastCharacter)
		{
			box.animation.play(centerPrefix + boxType + 'Open', true);
			updateBoxOffsets(box);
			box.flipX = (lePosition == 'left');
		}
		else if (boxType != lastBoxType)
		{
			box.animation.play(centerPrefix + boxType, true);
			updateBoxOffsets(box);
		}
		lastBoxType = boxType;
		lastCharacter = character;

		add(daText);

		if (nextDialogueThing != null)
		{
			nextDialogueThing();
		}

		if (lastCharacter != -1 && arrayCharacters.length > 0)
		{
			for (i in 0...arrayCharacters.length)
			{
				var char = arrayCharacters[i];
				if (char != null)
				{
					var FuckinF = offsetPos;
					var AlphaToUse = 0.00001;
					if (i == lastCharacter && boxType != "blank")
					{
						AlphaToUse = 1;
						FuckinF = 0;
					}

					switch (char.jsonFile.dialogue_pos)
					{
						case 'left':
							FlxTween.tween(char, {x: char.startingPos + FuckinF}, 0.15);
						case 'center':
							FlxTween.tween(char, {y: char.startingPos + -FuckinF}, 0.15);
						case 'right':
							FlxTween.tween(char, {x: char.startingPos - FuckinF}, 0.15);
					}
					FlxTween.tween(char, {alpha: AlphaToUse}, 0.15);
				}
			}
		}
	}

	public function destroyAdditionalObjects()
	{
		for (fuck in (SpawnedStuff.members.concat(SpawnedStuffBGLayer.members)))
		{
			fuck.destroy();
		}
	}

	public static function parseDialogue(path:String):DialogueFile
	{
		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end
		return cast Json.parse(rawJson);
	}

	public static function updateBoxOffsets(box:FlxSprite)
	{ // Had to make it static because of the editors
		box.centerOffsets();
		box.updateHitbox();
		if (box.animation.curAnim.name.startsWith('blank'))
		{
			box.offset.set(0, -50);
		}
		else if (box.animation.curAnim.name.startsWith('angry'))
		{
			box.offset.set(50, 65);
		}
		else if (box.animation.curAnim.name.startsWith('center-angry'))
		{
			box.offset.set(50, 30);
		}
		else
		{
			box.offset.set(10, 0);
		}

		if (!box.flipX)
			box.offset.y += 10;
	}
}