package states;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;
import cutscenes.DialogueBoxPsych;
import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;
import substates.PauseSubState;
import substates.GameOverSubstate;
#if !flash
import openfl.filters.ShaderFilter;
#end
import shaders.ErrorHandledShader;
import objects.VideoSprite;
import objects.Note.EventNote;
import objects.*;
import states.stages.*;
import states.stages.objects.*;
#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end
#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end
import cutscenes.DialogueBox;

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState {
	public static var webmHandler:WebmHandler;

	public static var rep:Replay;
	public static var loadRep:Bool = false;
	public static var playCutscene:Bool = false;

	var grpDieStage:FlxTypedGroup<FlxSprite>;
	var grpSlaughtStage:FlxTypedGroup<FlxSprite>;

	var SAD:FlxTypedGroup<FlxSprite>;
	var SADorder:Int = 0;
	private var camFaker:FlxObject;

	// Will decide if she's even allowed to headbang at all depending on the song
	private var allowedToHeadbang:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;

	// BotPlay text
	private var botPlayState:FlxText;
	// Replay shit
	private var saveNotes:Array<Float> = [];
	// Shader
	private var filteron:Bool = false;
	var ch = 2 / 1000;
	var shadersLoaded:Bool = false;
	// stage stuff
	var hellbg:FlxSprite;
	var hellcrab:FlxSprite;
	var crabbg:FlxSprite;
	var blackscreentra:FlxSprite;
	var ass:FlxSprite = new FlxSprite(0, 0);
	var assbf:FlxSprite = new FlxSprite(0, 0);
	var BW:FlxTypedGroup<FlxSprite>;
	var NBW:FlxTypedGroup<FlxSprite>;

	public static var BWE:Bool = false;

	var suf:String = "";

	var waaaa:FlxSprite;
	var unregisteredHypercam:FlxSprite;

	var dadTrail:FlxTrail;

	var mini:FlxSprite;
	var mordecai:FlxSprite;
	var thirdBop:FlxSprite;

	public static var didTheSex:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var coolGlowyLights:FlxTypedGroup<FlxSprite>;
	var coolGlowyLightsMirror:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;
	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	public var fuckingVolume:Float = 1;

	var songStarted = false;

	public var grpIcons:FlxTypedGroup<HealthIcon>;

	public static var cpuStrums:FlxTypedGroup<FlxSprite> = null;
	public static var cerbStrums:FlxTypedGroup<FlxSprite> = null;

	var iconP1Prefix:String;
	var iconP2Prefix:String;

	var useCamChange:Bool = true;

	var healthColorSwitch1:Bool = false;
	var healthColorSwitch2:Bool = false;

	var cerbMode:Bool = false;

	var areYouReady:FlxTypedGroup<FlxSprite>;

	public static var misses:Int = 0;

	private var accuracy:Float = 0.00;
	private var accuracyDefault:Float = 0.00;

	public static var theFunne:Bool = true;

	public static var shits:Int = 0;
	public static var bads:Int = 0;

	var realOffsetX:Float = 0;

	public static var goods:Int = 0;
	public static var sicks:Int = 0;

	var halloweenBG:FlxSprite;

	var pc:Character;

	#if windows
	// Discord RPC variables
	var iconRPC:String = "";
	var weekNames:Array<String> = ['Tutorial', 'B&B', 'ITB', 'BT'];
	#end

	var faker:Character;

	var coolCameraMode:Bool = false;

	var resyncingVocals:Bool = true;

	public static var goValue:FlxPoint = new FlxPoint(100, 100);
	public static var goBFValue:FlxPoint = new FlxPoint(100, 100);

	public var videoSprite:FlxSprite;
	public var useVideo:Bool = false;

	public var dialogue:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function set_stageUI(value:String):String {
		uiPrefix = uiPostfix = "";
		if (value != "normal") {
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel"))
				uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;
	public var secondaryVocals:FlxSound;

	public var dad:Character = null;
	public var dad2:Character = null;
	public var gf:Character = null;
	public var hasDad2:Bool = false;
	public var usesDad2Chart:Bool = false;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;

	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;

	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua> = [];
	#end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end

	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;

	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;

	override public function create() {
		// trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		Paths.clearStoredMemory();
		if (nextReloadAll) {
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; // Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = ['note_left', 'note_down', 'note_up', 'note_right'];

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if (SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) // Backward compatibility
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage) {
			case 'stage':
				new StageWeek1(); // Week 1
			case 'spooky':
				new Spooky(); // Week 2
			case 'philly':
				new Philly(); // Week 3
			case 'limo':
				new Limo(); // Week 4
			case 'mall':
				new Mall(); // Week 5 - Cocoa, Eggnog
			case 'mallEvil':
				new MallEvil(); // Week 5 - Winter Horrorland
			case 'school':
				new School(); // Week 6 - Senpai, Roses
			case 'schoolEvil':
				new SchoolEvil(); // Week 6 - Thorns
			case 'tank':
				new Tank(); // Week 7 - Ugh, Guns, Stress
			case 'phillyStreets':
				new PhillyStreets(); // Weekend 1 - Darnell, Lit Up, 2Hot
			case 'phillyBlazin':
				new PhillyBlazin(); // Weekend 1 - Blazin

			case 'dead':
				{
					defaultCamZoom = 0.7;
					curStage = 'dead';
				}
			case 'day':
				{
					defaultCamZoom = 0.75;
					curStage = 'day';
					var bg1:FlxSprite = new FlxSprite(-970, -580).loadGraphic(Paths.image('day/BG1', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1240, -650).loadGraphic(Paths.image('day/BG2', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.5, 0.5);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					add(bg2);

					if (storyDifficulty == 3) {
						mini = new FlxSprite(-270, -90);
						mini.frames = Paths.getSparrowAtlas('day/ex_crowd', 'shared');
						mini.animation.addByPrefix('idle', 'bobidlebig', 24, false);
						mini.animation.play('idle');
						// mini.scale.set(0.5, 0.5);
						// mini.scrollFactor.set(0.6, 0.6);
						add(mini);

						mordecai = new FlxSprite(141, 103);
					} else {
						mini = new FlxSprite(849, 189);
						mini.frames = Paths.getSparrowAtlas('day/mini', 'shared');
						mini.animation.addByPrefix('idle', 'mini', 24, false);
						mini.animation.play('idle');
						mini.scale.set(0.4, 0.4);
						mini.scrollFactor.set(0.6, 0.6);
						add(mini);

						mordecai = new FlxSprite(130, 160);
						mordecai.frames = Paths.getSparrowAtlas('day/bluskystv', 'shared');
						mordecai.animation.addByIndices('walk1', 'bluskystv', [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], '', 24, false);
						mordecai.animation.addByIndices('walk2', 'bluskystv', [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28], '', 24, false);
						mordecai.animation.play('walk1');
						mordecai.scale.set(0.4, 0.4);
						mordecai.scrollFactor.set(0.6, 0.6);
						add(mordecai);
					}

					var bg3:FlxSprite = new FlxSprite(-630, -330).loadGraphic(Paths.image('day/BG3', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.active = false;
					add(bg3);
				}
			case 'die':
				{
					defaultCamZoom = 0.75;
					curStage = 'die';

					grpDieStage = new FlxTypedGroup<FlxSprite>();
					add(grpDieStage);

					var bg1:FlxSprite = new FlxSprite(-970, -580).loadGraphic(Paths.image('day/happy/happy_sky', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					grpDieStage.add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1240, -650).loadGraphic(Paths.image('day/happy/happy_back', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.5, 0.5);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					grpDieStage.add(bg2);

					var bg3:FlxSprite = new FlxSprite(-630, -330).loadGraphic(Paths.image('day/happy/happy_front', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.active = false;
					grpDieStage.add(bg3);
				}
			case 'dieinhell':
				{
					defaultCamZoom = 0.75;
					curStage = 'dieinhell';

					grpDieStage = new FlxTypedGroup<FlxSprite>();
					add(grpDieStage);

					var bg1:FlxSprite = new FlxSprite(-1650, -2180).loadGraphic(Paths.image('day/hell/sky', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					grpDieStage.add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1540, -1650).loadGraphic(Paths.image('day/hell/mainbg', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.5, 0.5);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					grpDieStage.add(bg2);

					var bg3:FlxSprite = new FlxSprite(-1490, -1740).loadGraphic(Paths.image('day/hell/pavement_poop', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.active = false;
					grpDieStage.add(bg3);

					hellbg = new FlxSprite(0, 0).loadGraphic(Paths.image('day/hell/hell', 'shared'));
					hellbg.antialiasing = true;
					hellbg.visible = false;
					hellbg.scale.set(1.9, 1.9);
					hellbg.scrollFactor.set(0.9, 0.9);
					hellbg.active = false;
					add(hellbg);

					crabbg = new FlxSprite(0, 0).loadGraphic(Paths.image('day/hell/crab', 'shared'));
					crabbg.antialiasing = true;
					crabbg.visible = false;
					crabbg.scale.set(1.9, 1.9);
					crabbg.scrollFactor.set(0.9, 0.9);
					crabbg.active = false;
					add(crabbg);

					hellcrab = new FlxSprite(-570, 380);
					hellcrab.frames = Paths.getSparrowAtlas('day/hell/ElPepe', 'shared');
					hellcrab.animation.addByPrefix('idle', 'Mr Krab', 24, true);
					hellcrab.animation.play('idle');
					hellcrab.scale.set(0.5, 0.5);
					hellcrab.visible = false;
					add(hellcrab);
				}
			case 'sunset':
				{
					defaultCamZoom = 0.75;
					curStage = 'sunset';
					var bg1:FlxSprite = new FlxSprite(-970, -580).loadGraphic(Paths.image('sunset/BG1', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1240, -680).loadGraphic(Paths.image('sunset/BG2', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.5, 0.5);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					add(bg2);

					if (storyDifficulty == 3) {
						mini = new FlxSprite(-270, -90);
						mini.frames = Paths.getSparrowAtlas('sunset/ex_crowd_sunset', 'shared');
						mini.animation.addByPrefix('idle', 'bobidlebig', 24, false);
						mini.animation.play('idle');
						// mini.scale.set(0.5, 0.5);
						// mini.scrollFactor.set(0.6, 0.6);
						add(mini);

						mordecai = new FlxSprite(141, 103);
					} else {
						mini = new FlxSprite(817, 190);
						mini.frames = Paths.getSparrowAtlas('sunset/femboy and edgy jigglypuff', 'shared');
						mini.animation.addByPrefix('idle', 'femboy', 24, false);
						mini.animation.play('idle');
						mini.scale.set(0.5, 0.5);
						mini.scrollFactor.set(0.6, 0.6);
						add(mini);

						var mordecai:FlxSprite = new FlxSprite(141, 103);
						mordecai.frames = Paths.getSparrowAtlas('sunset/jacob', 'shared');
						mordecai.animation.addByPrefix('idle', 'jacob', 24, false);
						mordecai.animation.play('idle');
						mordecai.scale.set(0.5, 0.5);
						mordecai.scrollFactor.set(0.6, 0.6);
						add(mordecai);
					}

					var bg3:FlxSprite = new FlxSprite(-630, -330).loadGraphic(Paths.image('sunset/BG3', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.active = false;
					add(bg3);
				}
			case 'sunshit':
				{
					defaultCamZoom = 0.75;
					curStage = 'sunshit';

					grpDieStage = new FlxTypedGroup<FlxSprite>();
					add(grpDieStage);

					var bg1:FlxSprite = new FlxSprite(-970, -580).loadGraphic(Paths.image('sunset/happy/bosip_sky', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					grpDieStage.add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1240, -680).loadGraphic(Paths.image('sunset/happy/bosip_back', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.5, 0.5);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					grpDieStage.add(bg2);

					var bg3:FlxSprite = new FlxSprite(-630, -330).loadGraphic(Paths.image('sunset/happy/bosip_front', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.active = false;
					grpDieStage.add(bg3);
				}
			case 'sunsuck':
				{
					defaultCamZoom = 0.75;
					curStage = 'sunsuck';
					if (FileSystem.exists(Paths.txt("ronald mcdonald slide/preload" + suf))) {
						var characters:Array<String> = CoolUtil.preloadfile(Paths.txt("ronald mcdonald slide/preload" + suf));
						trace('Load Assets');
						for (i in 0...characters.length) {
							var data:Array<String> = characters[i].split(' ');
							dad = new Character(0, 0, data[0]);
							trace('found ' + data[0]);
						}
					}
					grpDieStage = new FlxTypedGroup<FlxSprite>();
					add(grpDieStage);

					var bg1:FlxSprite = new FlxSprite(-1650, -2480).loadGraphic(Paths.image('sunset/hell/sky', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					grpDieStage.add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1540, -1950).loadGraphic(Paths.image('sunset/hell/mainbgron', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.5, 0.5);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					grpDieStage.add(bg2);

					var bg3:FlxSprite = new FlxSprite(-1490, -2040).loadGraphic(Paths.image('sunset/hell/pavement_yeah', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.active = false;
					grpDieStage.add(bg3);

					blackscreentra = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
					blackscreentra.scale.set(1.6, 1.6);
					blackscreentra.cameras = [camHUD];
					blackscreentra.visible = false;
					ass.frames = Paths.getSparrowAtlas('sunset/hell/omni_ron', 'shared');
					ass.animation.addByPrefix('trans', 'ron_dumpy instance 1', 24, false);
					ass.animation.addByPrefix('back', 'ron_dumpy_bye_bye instance 1', 24, false);
					ass.x = -200;
					ass.alpha = 1;
					ass.setGraphicSize(796, 946);
					ass.y -= 100;

					assbf.frames = Paths.getSparrowAtlas('sunset/hell/omni_bf', 'shared');
					assbf.animation.addByPrefix('trans', 'bf_buff_ex_transformation instance 1', 24, false);
					assbf.animation.addByPrefix('back', 'bf_return instance 1', 24, false);
					assbf.x = 741;
					assbf.y -= 50;
					assbf.setGraphicSize(728, 911);

					// assbf.y -= 50;
					add(blackscreentra);
				}
			case 'smp':
				{
					defaultCamZoom = 0.6;
					curStage = 'smp';
					var bg1:FlxSprite = new FlxSprite(-1218, -1184).loadGraphic(Paths.image('day/smp/5', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1218, -1095).loadGraphic(Paths.image('day/smp/4', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.8, 0.8);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					add(bg2);

					var bg3:FlxSprite = new FlxSprite(-1218, -1184).loadGraphic(Paths.image('day/smp/3', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.scrollFactor.set(0.8, 0.8);
					bg3.active = false;
					add(bg3);

					var bg4:FlxSprite = new FlxSprite(-1218, -1184).loadGraphic(Paths.image('day/smp/2', 'shared'));
					bg4.antialiasing = true;
					bg4.scale.set(0.8, 0.8);
					bg4.active = false;
					add(bg4);

					var bg5:FlxSprite = new FlxSprite(-1218, -1184).loadGraphic(Paths.image('day/smp/1', 'shared'));
					bg5.antialiasing = true;
					bg5.scale.set(0.8, 0.8);
					bg5.active = false;
					add(bg5);
				}
			case 'night':
				{
					defaultCamZoom = 0.75;
					curStage = 'night';
					var theEntireFuckingStage:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
					add(theEntireFuckingStage);

					var bg1:FlxSprite = new FlxSprite(-970, -580).loadGraphic(Paths.image('night/BG1', 'shared'));
					bg1.antialiasing = true;
					bg1.scale.set(0.8, 0.8);
					bg1.scrollFactor.set(0.3, 0.3);
					bg1.active = false;
					theEntireFuckingStage.add(bg1);

					var bg2:FlxSprite = new FlxSprite(-1240, -650).loadGraphic(Paths.image('night/BG2', 'shared'));
					bg2.antialiasing = true;
					bg2.scale.set(0.5, 0.5);
					bg2.scrollFactor.set(0.6, 0.6);
					bg2.active = false;
					theEntireFuckingStage.add(bg2);

					mini = new FlxSprite(818, 189);
					mini.frames = Paths.getSparrowAtlas('night/bobsip', 'shared');
					mini.animation.addByPrefix('idle', 'bobsip', 24, false);
					mini.animation.play('idle');
					mini.scale.set(0.5, 0.5);
					mini.scrollFactor.set(0.6, 0.6);
					if (storyDifficulty != 3)
						theEntireFuckingStage.add(mini);

					var bg3:FlxSprite = new FlxSprite(-630, -330).loadGraphic(Paths.image('night/BG3', 'shared'));
					bg3.antialiasing = true;
					bg3.scale.set(0.8, 0.8);
					bg3.active = false;
					theEntireFuckingStage.add(bg3);

					var bg4:FlxSprite = new FlxSprite(-1390, -740).loadGraphic(Paths.image('night/BG4', 'shared'));
					bg4.antialiasing = true;
					bg4.scale.set(0.6, 0.6);
					bg4.active = false;
					theEntireFuckingStage.add(bg4);

					var bg5:FlxSprite = new FlxSprite(-34, 90);
					bg5.antialiasing = true;
					bg5.scale.set(1.4, 1.4);
					bg5.frames = Paths.getSparrowAtlas('night/pixelthing', 'shared');
					bg5.animation.addByPrefix('idle', 'pixelthing', 24);
					bg5.animation.play('idle');
					add(bg5);

					pc = new Character(115, 166, 'pc');
					pc.debugMode = true;
					pc.antialiasing = true;
					add(pc);
				}
			case 'sans':
				{
					defaultCamZoom = 0.75;
					curStage = 'sans';
					var theEntireFuckingStage:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
					add(theEntireFuckingStage);

					/*var bg1:FlxSprite = new FlxSprite(-970, -580).loadGraphic(Paths.image('night/BG1', 'shared'));
						bg1.antialiasing = true;
						bg1.scale.set(0.8, 0.8);
						bg1.scrollFactor.set(0.3, 0.3);
						bg1.active = false;
						theEntireFuckingStage.add(bg1);

						var bg2:FlxSprite = new FlxSprite(-1240, -650).loadGraphic(Paths.image('night/BG2', 'shared'));
						bg2.antialiasing = true;
						bg2.scale.set(0.5, 0.5);
						bg2.scrollFactor.set(0.6, 0.6);
						bg2.active = false;
						theEntireFuckingStage.add(bg2); */

					var bg6:FlxSprite = new FlxSprite(-1358, -790).loadGraphic(Paths.image("sans/1", 'shared'));
					bg6.antialiasing = true;
					bg6.scale.set(0.6, 0.6);
					bg6.scrollFactor.set(0.6, 0.6);
					bg6.active = false;
					theEntireFuckingStage.add(bg6);

					var bg7:FlxSprite = new FlxSprite(-1248, -740).loadGraphic(Paths.image("sans/2", 'shared'));
					bg7.antialiasing = true;
					bg7.scale.set(0.6, 0.6);
					bg7.active = false;
					theEntireFuckingStage.add(bg7);

					var bg8:FlxSprite = new FlxSprite(-1220, -740).loadGraphic(Paths.image("sans/3", 'shared'));
					bg8.antialiasing = true;
					bg8.scale.set(0.6, 0.6);
					bg8.active = false;
					bg8.scrollFactor.set(1.2, 1.2);
					theEntireFuckingStage.add(bg8);

					var bg4:FlxSprite = new FlxSprite(-1411, -740).loadGraphic(Paths.image("sans/Amor's room", 'shared'));
					bg4.antialiasing = true;
					bg4.scale.set(0.6, 0.6);
					bg4.active = false;
					theEntireFuckingStage.add(bg4);

					if (storyDifficulty == 3) {
						var mini:FlxSprite = new FlxSprite(990, -100);
						mini.frames = Paths.getSparrowAtlas('sans/expaps', 'shared');
						mini.animation.addByPrefix('idle', 'papy0', 24, false);
						mini.animation.play('idle');
					} else {
						var mini:FlxSprite = new FlxSprite(980, -138);
						mini.frames = Paths.getSparrowAtlas('sans/Papyrus', 'shared');
						mini.animation.addByPrefix('idle', 'Papyrus', 24, false);
						mini.animation.play('idle');
					}

					mini.scale.set(0.5, 0.5);
					theEntireFuckingStage.add(mini);

					var mordecai:FlxSprite = new FlxSprite(835, 40);
					if (storyDifficulty == 3) {
						mordecai.frames = Paths.getSparrowAtlas('sans/expaps', 'shared');
						mordecai.animation.addByPrefix('idle', 'frisky0', 24, false);
						mordecai.animation.play('idle');
					} else {
						mordecai.frames = Paths.getSparrowAtlas('sans/Frisk', 'shared');
						mordecai.animation.addByPrefix('idle', 'Frisk', 24, false);
						mordecai.animation.play('idle');
					}
					mordecai.scale.set(0.5, 0.5);
					theEntireFuckingStage.add(mordecai);

					var bg5:FlxSprite = new FlxSprite(-34, 90);
					bg5.antialiasing = true;
					bg5.scale.set(1.4, 1.4);
					bg5.frames = Paths.getSparrowAtlas('night/pixelthing', 'shared');
					bg5.animation.addByPrefix('idle', 'pixelthing', 24);
					bg5.animation.play('idle');
					add(bg5);

					pc = new Character(115, 166, 'pc');
					pc.debugMode = true;
					pc.antialiasing = true;
					add(pc);
				}
			case 'ITB':
				defaultCamZoom = 0.70;
				curStage = 'ITB';
				var bg17:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 5', 'shared'));
				bg17.antialiasing = true;
				bg17.scrollFactor.set(0.3, 0.3);
				bg17.active = false;
				add(bg17);

				var bg16:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 4', 'shared'));
				bg16.antialiasing = true;
				bg16.scrollFactor.set(0.4, 0.4);
				bg16.active = false;
				add(bg16);

				var bg15:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 3', 'shared'));
				bg15.antialiasing = true;
				bg15.scrollFactor.set(0.6, 0.6);
				bg15.active = false;
				add(bg15);

				var bg14:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 2', 'shared'));
				bg14.antialiasing = true;
				bg14.scrollFactor.set(0.7, 0.7);
				bg14.active = false;
				add(bg14);

				var bg1:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (back tree)', 'shared'));
				bg1.antialiasing = true;
				bg1.scrollFactor.set(0.7, 0.7);
				bg1.active = false;
				add(bg1);

				var bg13:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (Tree)', 'shared'));
				bg13.antialiasing = true;
				bg13.active = false;
				add(bg13);

				var bg4:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (flower and grass)', 'shared'));
				bg4.antialiasing = true;
				bg4.active = false;
				add(bg4);

				phillyCityLights = new FlxTypedGroup<FlxSprite>();
				add(phillyCityLights);

				var bg9:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/layer 1 (light 1)', 'shared'));
				bg9.antialiasing = true;
				bg9.scrollFactor.set(0.8, 0.8);
				bg9.alpha = 0;
				bg9.active = false;
				phillyCityLights.add(bg9);

				var bg10:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (Light 2)', 'shared'));
				bg10.antialiasing = true;
				bg10.scrollFactor.set(0.8, 0.8);
				bg10.alpha = 0;
				bg10.active = false;
				phillyCityLights.add(bg10);

				var bg5:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (Grass 2)', 'shared'));
				bg5.antialiasing = true;
				bg5.active = false;
				add(bg5);

				switch (SONG.song.toLowerCase()) {
					case 'yap squad' | 'intertwined':
						var mini:FlxSprite = new FlxSprite(-571, -68);
						mini.frames = Paths.getSparrowAtlas('ITB/itb_crowd_back', 'shared');
						mini.animation.addByPrefix('idle', 'itb_crowd_back', 24, false);
						mini.animation.play('idle');
						mini.scale.set(0.55, 0.55);
						add(mini);
				}
			case 'ITB-Glitch':
				defaultCamZoom = 0.70;
				curStage = 'ITB-Glitch';
				var bg17:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/glitch/ash1', 'shared'));
				bg17.antialiasing = true;
				bg17.scrollFactor.set(0.3, 0.3);
				bg17.active = false;
				add(bg17);

				/*massiveLine = new FlxTypedGroup<FlxSprite>();
					add(massiveLine); */
				/*var theLine:FlxSprite = new FlxSprite(-1200, -100);
					theLine.frames = Paths.getSparrowAtlas('ITB/glitch/line', 'shared');
					theLine.animation.addByPrefix('idle', 'line idle', 24, false); */

				var bg14:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/glitch/ash2', 'shared'));
				bg14.antialiasing = true;
				bg14.scrollFactor.set(0.7, 0.7);
				bg14.active = false;
				add(bg14);

				var bg5:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/glitch/ash3', 'shared'));
				bg5.antialiasing = true;
				bg5.active = false;
				add(bg5);

				var bg7:FlxSprite = new FlxSprite(-701, -340).loadGraphic(Paths.image('ITB/glitch/ash4', 'shared'));
				bg7.antialiasing = true;
				// bg7.scale.set(0.6, 0.6);
				bg7.active = false;
				add(bg7);
			case 'ITB-Party':
				defaultCamZoom = 0.70;
				curStage = 'ITB-Party';
				var bg17:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/party/BLU1', 'shared'));
				bg17.antialiasing = true;
				bg17.scrollFactor.set(0.3, 0.3);
				bg17.active = false;
				add(bg17);

				var bg16:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/party/BLU1_1', 'shared'));
				bg16.antialiasing = true;
				bg16.scrollFactor.set(0.4, 0.4);
				bg16.active = false;
				add(bg16);

				var bg15:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/party/BLU1_2', 'shared'));
				bg15.antialiasing = true;
				bg15.scrollFactor.set(0.6, 0.6);
				bg15.active = false;
				add(bg15);

				var bg14:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/party/BLU2', 'shared'));
				bg14.antialiasing = true;
				bg14.scrollFactor.set(0.7, 0.7);
				bg14.active = false;
				add(bg14);

				var bg1:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/party/BLU3', 'shared'));
				bg1.antialiasing = true;
				// bg1.scrollFactor.set(0.7, 0.7);
				bg1.active = false;
				add(bg1);

				var bg7:FlxSprite = new FlxSprite(-701, -340).loadGraphic(Paths.image('ITB/party/light0', 'shared'));
				bg7.antialiasing = true;
				// bg7.scale.set(0.6, 0.6);
				bg7.active = false;
				//	add(bg7);

				phillyCityLights = new FlxTypedGroup<FlxSprite>();

				add(phillyCityLights);

				for (i in 0...2) {
					var light:FlxSprite = new FlxSprite(-701, -340).loadGraphic(Paths.image('ITB/party/light' + i, 'shared'));
					// light.scrollFactor.set(0.3, 0.3);
					light.visible = true;
					// light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					light.antialiasing = true;
					phillyCityLights.add(light);
				}

				var bg13:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/party/BLU4', 'shared'));
				bg13.antialiasing = true;

				bg13.active = false;
				add(bg13);
			case 'ITB-Hell':
				defaultCamZoom = 0.70;
				curStage = 'ITB-Hell';
				var bg17:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/hell/JGHOST 1', 'shared'));
				bg17.antialiasing = true;
				bg17.scrollFactor.set(0.3, 0.3);
				bg17.active = false;
				add(bg17);

				var bg16:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/hell/JGHOST 1_2', 'shared'));
				bg16.antialiasing = true;
				bg16.scrollFactor.set(0.4, 0.4);
				bg16.active = false;
				add(bg16);

				var bg14:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/hell/JGHOST 2', 'shared'));
				bg14.antialiasing = true;
				bg14.scrollFactor.set(0.7, 0.7);
				bg14.active = false;
				add(bg14);

				var bg1:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/hell/JGHOST 3', 'shared'));
				bg1.antialiasing = true;
				// bg1.scrollFactor.set(0.7, 0.7);
				bg1.active = false;
				add(bg1);

				var bg13:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/hell/JGHOST 4', 'shared'));
				bg13.antialiasing = true;
				bg13.active = false;
				add(bg13);
			case 'ITB-Anime':
				defaultCamZoom = 0.70;
				curStage = 'ITB-Anime';
				NBW = new FlxTypedGroup<FlxSprite>();
				BW = new FlxTypedGroup<FlxSprite>();
				add(NBW);
				add(BW);
				var bg17:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 1', 'shared'));
				bg17.antialiasing = true;
				bg17.scrollFactor.set(0.3, 0.3);
				bg17.active = false;
				NBW.add(bg17);

				var bg16:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 1_2', 'shared'));
				bg16.antialiasing = true;
				bg16.scrollFactor.set(0.4, 0.4);
				bg16.active = false;
				NBW.add(bg16);

				var bg15:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 1_3', 'shared'));
				bg15.antialiasing = true;
				bg15.scrollFactor.set(0.5, 0.5);
				bg15.active = false;
				NBW.add(bg15);

				var bg14:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 2', 'shared'));
				bg14.antialiasing = true;
				bg14.scrollFactor.set(0.7, 0.7);
				bg14.active = false;
				NBW.add(bg14);

				var bg1:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 3', 'shared'));
				bg1.antialiasing = true;
				// bg1.scrollFactor.set(0.7, 0.7);
				bg1.active = false;
				NBW.add(bg1);

				var bg13:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 4', 'shared'));
				bg13.antialiasing = true;
				bg13.active = false;
				NBW.add(bg13);

				// BW
				var bg17BW:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 1 BW', 'shared'));
				bg17BW.antialiasing = true;
				bg17BW.scrollFactor.set(0.3, 0.3);
				bg17BW.active = false;
				BW.add(bg17BW);

				var bg16BW:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 1_2 BW', 'shared'));
				bg16BW.antialiasing = true;
				bg16BW.scrollFactor.set(0.4, 0.4);
				bg16BW.active = false;
				BW.add(bg16BW);

				var bg15BW:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 1_3 BW', 'shared'));
				bg15BW.antialiasing = true;
				bg15BW.scrollFactor.set(0.5, 0.5);
				bg15BW.active = false;
				BW.add(bg15BW);

				var bg14BW:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 2 BW', 'shared'));
				bg14BW.antialiasing = true;
				bg14BW.scrollFactor.set(0.7, 0.7);
				bg14BW.active = false;
				BW.add(bg14BW);

				var bg1BW:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 3 BW', 'shared'));
				bg1BW.antialiasing = true;
				// bg1BW.scrollFactor.set(0.7, 0.7);
				bg1BW.active = false;
				BW.add(bg1BW);

				var bg13BW:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/anime/MINI 4 BW', 'shared'));
				bg13BW.antialiasing = true;
				bg13BW.active = false;
				BW.add(bg13BW);
				BW.visible = true;

				for (i in BW) {
					i.y += FlxG.height * 2;
				}
		}

		var gfVersion:String = 'gf';

		switch (SONG.gfVersion) {
			case 'gf-car':
				gfVersion = 'gf-car';
			case 'gf-christmas':
				gfVersion = 'gf-christmas';
			case 'gf-pixel':
				gfVersion = 'gf-pixel';
			case 'gf-bob':
				gfVersion = 'gf-bob';
			case 'gf-ronsip':
				gfVersion = 'gf-ronsip';
			case 'gf-bosip':
				gfVersion = 'gf-bosip';
			case 'sapnap':
				gfVersion = 'sapnap';
			case 'gf-night':
				gfVersion = 'gf-night';
			case 'gf-ex':
				gfVersion = 'gf-ex';
			case 'gf-night-ex':
				gfVersion = 'gf-night-ex';
			case 'gf-but-bosip':
				gfVersion = 'gf-but-bosip';
				gfSpeed = 2;
				trace('shithdhfdof');
			default:
				gfVersion = 'gf';
		}
		if (FileSystem.exists(Paths.txt(SONG.song.toLowerCase() + "/preload" + suf))) {
			var characters:Array<String> = CoolUtil.preloadfile(Paths.txt(SONG.song.toLowerCase() + "/preload" + suf));
			trace('Load Assets');
			for (i in 0...characters.length) {
				var data:Array<String> = characters[i].split(' ');
				dad = new Character(0, 0, data[0]);
				trace('found ' + data[0]);
			}
		}

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);
		if (!FlxG.save.data.lowDetail) {
			switch (SONG.song.toLowerCase()) {
				case 'yap squad':
					var dog:FlxSprite = new FlxSprite(0, 0);
					dog.antialiasing = true;
					dog.frames = Paths.getSparrowAtlas('ITB/hell/Jghostending', 'shared');
					dog.animation.addByPrefix('idle', 'Jghostending', 24, false);
					dog.animation.play('idle');
				case 'ronald mcdonald slide':
					waaaa = new FlxSprite().loadGraphic(Paths.image('sunset/happy/waaaaa', 'shared'));
					add(waaaa);
					waaaa.cameras = [camHUD];
					waaaa.visible = false;

					unregisteredHypercam = new FlxSprite().loadGraphic(Paths.image('sunset/happy/unregistered-hypercam-2-png-Transparent-Images-Free',
						'shared'));
					add(unregisteredHypercam);
					unregisteredHypercam.cameras = [camHUD];
					unregisteredHypercam.visible = false;

					if (!FlxG.save.data.lowDetail) {
						SAD = new FlxTypedGroup<FlxSprite>();
						SAD.cameras = [camHUD];
						add(SAD);

						for (i in 0...4) {
							var suffix:String = '';
							switch (i) {
								case 0:
									suffix = 'AMOR';
								case 1:
									suffix = 'BF';
								case 2:
									suffix = 'BOB';
								case 3:
									suffix = 'BOSIP';
							}
							var spr = new FlxSprite().loadGraphic(Paths.image('sad/original size/SAD ' + suffix, 'shared'));
							spr.cameras = [camHUD];
							spr.screenCenter();
							spr.alpha = 0;
							SAD.add(spr);
						}
					}

					var angyRonsip:FlxSprite = new FlxSprite(-1200, -100);
					angyRonsip.frames = Paths.getSparrowAtlas('sunset/happy/RON_dies_lmaoripbozo_packwatch', 'shared');

				case 'jump-out':
					dad = new Character(100, 100, 'verb');
					boyfriend = new Character(100, 100, 'bf-anders');

					if (!FlxG.save.data.lowDetail) {
						SAD = new FlxTypedGroup<FlxSprite>();
						SAD.cameras = [camHUD];
						add(SAD);

						for (i in 0...4) {
							var suffix:String = '';
							switch (i) {
								case 0:
									suffix = 'AMOR';
								case 1:
									suffix = 'BF';
								case 2:
									suffix = 'BOB';
								case 3:
									suffix = 'BOSIP';
							}
							var spr = new FlxSprite().loadGraphic(Paths.image('sad/original size/SAD ' + suffix, 'shared'));
							spr.cameras = [camHUD];
							spr.screenCenter();
							spr.alpha = 0;
							SAD.add(spr);
						}
					}

					grpSlaughtStage = new FlxTypedGroup<FlxSprite>();
					add(grpSlaughtStage);

					var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('onslaught/scary_sky'));
					bg.updateHitbox();
					bg.active = false;
					bg.antialiasing = true;
					bg.scrollFactor.set(0.1, 0.7);
					grpSlaughtStage.add(bg);

					var ground:FlxSprite = new FlxSprite(-537, -158).loadGraphic(Paths.image('onslaught/GlitchedGround'));
					ground.updateHitbox();
					ground.active = false;
					ground.antialiasing = true;
					grpSlaughtStage.add(ground);
					bg.y += FlxG.height * 2;
					ground.y += FlxG.height * 2;
				case 'conscience':
					if (storyDifficulty == 3) {
						gf = new Character(400, 130, 'gf-bw');

						dad = new Character(100, 100, 'minishoey-bw');
						boyfriend = new Character(770, 450, 'bf-bw');
					}
			}
		}
		if (storyDifficulty == 3 && SONG.song.toLowerCase() == 'conscience') {
			gf = new Character(400, 130, 'gf-ex');
		}
		dad = new Character(100, 100, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		switch (SONG.gfVersion) {
			case 'gf-bosip':
				gf.y -= 40;
				gf.x -= 30;
			case 'sapnap':
				gf.y -= 40;
				gf.x -= 30;
			case 'gf-night-ex':
				gf.x -= 30;
				gf.y -= 40;
			case 'gf-ronsip':
				gf.x -= 820;
				gf.y -= 700;
			case 'gf-but-bosip':
				gf.x += 350;
				gf.y -= 30;
			case 'none':
				gf.visible = false;
		}

		switch (SONG.player2) {
			case 'gf' | 'gf-ex':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				/*gf.x += 200;
					gf.y -= 50; */
				if (isStoryMode) {
					camPos.x += 600;
					// tweenCamIn();
				}

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'deadbf':
				dad.y += 350;
			case 'verb':
				dad.y += 330;
			case 'abungus':
				dad.y += 20;
			case 'bob-cool' | 'gloopy' | 'gloopy-ex':
				camPos.x += 600;
				dad.y += 280;
			case 'bob-cool-ex':
				camPos.y -= 300;
			case 'jghost':
				dad.x -= 40;
				dad.y -= 20;
			case 'scruffy':
				dad.x -= 40;
				dad.y += 100;
			case 'jghost-ex':
				// dad.x -= 60;
				dad.y -= 90;
			case 'bluskys':
				dad.y += 100;
			case 'bluskys-ex':
				dad.y += 100;
			case 'minishoey':
				dad.y += 50;
			case 'minishoey-ex':
				dad.y += 0;
			case 'ash':
				dad.y += 20;
			case 'ash2':
				dad.y -= 100;
				dad.x -= 230;
			case 'ash-ex':
				dad.x -= 30;
				dad.y += 80;
			case 'cerberus':
				dad.y += 230;
				dad.x += 50;
			case 'cerbera':
				dad.y += 420;
				dad.x += 50;
			case 'pc':
				dad.y += 350;
			case 'bob':
				dad.y += 50;
			case 'bob-ex':
				dad.y += 80;
			case 'cj':
				dad.y += 20;
			case 'bosip':
				dad.y -= 50;
			case 'bosip-ex':
				dad.y += 0;
			case 'bobal':
				dad.y += 160;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'ronsip' | 'ronsip-ex':
				dad.y += 100;
		}

		boyfriend = new Character(770, 450, SONG.player1);
		dadTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		// add(dadTrail);
		dadTrail.visible = false;
		// REPOSITIONING PER STAGE
		trace(dad);
		trace(gf);
		trace(boyfriend);
		if (FlxG.save.data.lowDetail) {
			switch (SONG.song.toLowerCase()) {
				case 'copy-cat':
					dad.y -= 50;
					dad.x -= 240;
					boyfriend.y -= 760;
					gf.y -= 600;
					boyfriend.x += 300;
					gf.scale.set(0.7, 0.7);
					dad.scale.set(1.3, 1.3);
					defaultCamZoom = 0.6;
					trace('Really? Low Detail?');
				case 'jump-in' | 'jump-out' | 'swing' | 'ronald mcdonald slide':
					dad.x -= 150;
					dad.y -= 11;
					boyfriend.x += 191;
					boyfriend.y -= 20;
					if (SONG.player1 == 'bf-bob') {
						boyfriend.x -= 60;
						boyfriend.y -= 70;
					}

					gf.x -= 70;
					gf.y -= 50;
					camPos.x = 536.63;
					camPos.y = 449.94;
					defaultCamZoom = 0.75;
				case 'split':
					defaultCamZoom = 0.75;
					dad.x -= 370;
					dad.y + 39;
					boyfriend.x += 191;
					boyfriend.y -= 20;
					gf.x += 300;
					gf.y -= 50;
				case 'oblique fracture':
					defaultCamZoom = 0.75;
					dad.x -= 370;
					dad.y + 39;
					boyfriend.x += 101;
					boyfriend.y -= 60;
					gf.x += 300;
					gf.y -= 50;
				case 'groovy brass' | 'conscience' | 'yap squad' | 'intertwined':
					defaultCamZoom = 0.70;
					dad.x -= 380;
					dad.y -= 10;
					gf.x -= 239;
					gf.y -= 0;
					gf.scrollFactor.set(1, 1);
					camPos.x = 272.46;
					camPos.y = 420.96;
			}
		}

		switch (curStage) {
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;
				if (FlxG.save.data.distractions) {
					resetFastCar();
					add(fastCar);
				}

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'dead':
				boyfriend.x += 300;
			case 'schoolEvil':
				if (FlxG.save.data.distractions) {
					// trailArea.scrollFactor.set();
					var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
					// evilTrail.changeValuesEnabled(false, false, false, false);
					// evilTrail.changeGraphic()
					add(evilTrail);
					// evilTrail.scrollFactor.set(1.1, 1.1);
				}

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'day' | 'sunset' | 'sunshit' | 'die' | 'dieinhell' | 'sunsuck':
				dad.x -= 150;
				dad.y -= 11;
				boyfriend.x += 191;
				boyfriend.y -= 20;
				if (SONG.player1 == 'bf-bob') {
					boyfriend.x -= 60;
					boyfriend.y -= 70;
				}
				//	if (SONG.player2 == 'gloopy-ex') {
				//	dad.y += 200;
				//	}
				gf.x -= 70;
				gf.y -= 50;
				camPos.x = 536.63;
				camPos.y = 449.94;
				trace(dad.x);
				trace(dad.y);

			case 'smp':
				dad.y -= 50;
				dad.x -= 240;
				boyfriend.y -= 760;
				gf.y -= 600;
				boyfriend.x += 300;
				gf.scale.set(0.7, 0.7);
				dad.scale.set(1.3, 1.3);
			case 'night':
				dad.x -= 370;
				dad.y + 39;
				boyfriend.x += 191;
				boyfriend.y -= 20;
				gf.x += 300;
				gf.y -= 50;
			case 'sans':
				dad.x -= 370;
				dad.y + 39;
				boyfriend.x += 101;
				boyfriend.y -= 60;
				gf.x += 300;
				gf.y -= 50;
			case 'ITB' | 'ITB-Glitch' | 'ITB-Party' | 'ITB-Hell' | 'ITB-Anime':
				dad.x -= 380;
				dad.y -= 10;
				gf.x -= 239;
				gf.y -= 0;
				gf.scrollFactor.set(1, 1);
				camPos.x = 272.46;
				camPos.y = 420.96;
				// gfOffset.set(-239, -130);
		}
		switch (SONG.player1) {
			case 'bf-sans':
				boyfriend.y -= 120;
				boyfriend.x -= 50;
			case 'bf-worriedbob':
				boyfriend.y = 130;
			case 'bf-bob-george':
				boyfriend.x -= 165;
				boyfriend.y -= 175;
			case 'bf-anders':
				boyfriend.y -= 330;
				boyfriend.x -= 150;
			case 'bf-ex-new':
				boyfriend.x -= 70;
				boyfriend.y += 30;
		}
		add(gf);
		if (!FlxG.save.data.lowDetail) {
			switch (curStage) {
				case 'ITB':
					var bg8:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (Lamp)', 'shared'));
					bg8.antialiasing = true;
					// bg8.scale.set(0.6, 0.6);
					// bg8.scrollFactor.set(0.8, 0.8);
					bg8.active = false;
					add(bg8);

					var bg6:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (Grass)', 'shared'));
					bg6.antialiasing = true;
					// bg6.scrollFactor.set(0.9, 0.9);
					// bg6.scale.set(0.6, 0.6);
					bg6.active = false;
					add(bg6);

					var bg7:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('ITB/Layer 1 (Ground)', 'shared'));
					bg7.antialiasing = true;
					// bg7.scale.set(0.6, 0.6);
					bg7.active = false;
					add(bg7);

					switch (SONG.song.toLowerCase()) {
						case 'conscience' | 'yap squad' | 'intertwined':
							mordecai = new FlxSprite(-1531, -230);
							mordecai.frames = Paths.getSparrowAtlas('ITB/itb_crowd_middle', 'shared');
							mordecai.animation.addByPrefix('idle', 'itb_crowd_middle', 24, false);
							mordecai.animation.play('idle');
							mordecai.scale.set(0.6, 0.6);
							add(mordecai);
					}
				case 'ITB-Glitch':
				// nothing
				// case 'ITB-Party':

				case 'ITB-Hell':
					// nothing
			}
		}
		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dad);
		add(boyfriend);
		BWE = false;
		//		if (curStage == 'sunsuck')
		//		add(blackscreentra);
		switch (SONG.song.toLowerCase()) {
			case 'intertwined':
				if (storyDifficulty == 3) {
					dad2 = new Character(0, 520, 'cerbera-ex');
				} else {
					dad2 = new Character(0, 520, 'cerbera');
					thirdBop = new FlxSprite(-1560, 542);
					thirdBop.scale.set(0.6, 0.6);
					thirdBop.scrollFactor.set(1.3, 1.3);
					thirdBop.frames = Paths.getSparrowAtlas('ITB/itb_crowd_front', 'shared');
					thirdBop.animation.addByPrefix('idle', 'itb_crowd_front', 24, false);
					thirdBop.animation.play('idle');
					if (!FlxG.save.data.lowDetail)
						add(thirdBop);
				}
				add(dad2);
				hasDad2 = true;
			case 'yap squad':
				if (storyDifficulty == 3) {
					dad2 = new Character(-490, 200, 'cerberus-ex');
					add(dad2);
				} else {
					dad2 = new Character(-200, 400, 'cerberus');
					add(dad2);
					remove(dad);
					add(dad);
				}
				hasDad2 = true;
				usesDad2Chart = true;
			case 'conscience':
				if (storyDifficulty == 3) {
					dad2 = new Character(dad.x, dad.y, 'minishoey-bw');
					add(dad2);
					hasDad2 = true;
					dad2.visible = false;
				}
		}
		if (curStage == 'day') {
			phillyTrain = new FlxSprite(200, 200).loadGraphic(Paths.image('day/PP_truck', 'shared'));
			phillyTrain.scale.set(1.2, 1.2);
			phillyTrain.visible = false;
			add(phillyTrain);
		}
		if (curStage == 'sunset') {
			phillyTrain = new FlxSprite(200, 200).loadGraphic(Paths.image('sunset/CJ_car', 'shared'));
			phillyTrain.scale.set(1.2, 1.2);
			phillyTrain.visible = false;
			add(phillyTrain);
		}

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		if (isPixelStage)
			introSoundsSuffix = '-pixel';

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if (!stageData.hide_girlfriend) {
			if (SONG.gfVersion == null || SONG.gfVersion.length < 1)
				SONG.gfVersion = 'gf'; // Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		if (stageData.objects != null && stageData.objects.length > 0) {
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup,
				boyfriendGroup, this);
			for (key => spr in list)
				if (!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		} else {
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder)) {
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null) {
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		// CHARACTER SCRIPTS
		if (gf != null)
			startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);
		#end

		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(comboGroup);
		add(uiGroup);
		add(noteGroup);

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if (ClientPrefs.data.downScroll)
			timeTxt.y = FlxG.height - 44;
		if (ClientPrefs.data.timeBarType == 'Song Name')
			timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		noteGroup.add(strumLineNotes);

		if (ClientPrefs.data.timeBarType == 'Song Name') {
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		generateSong();

		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if (ClientPrefs.data.downScroll)
			botplayTxt.y = healthBar.y + 70;

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];

		startingSong = true;

		if (isStoryMode) {
			switch (StringTools.replace(curSong, " ", "-").toLowerCase()) {
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer) {
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer) {
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween) {
									startCountdown();
								}
							});
						});
					});
				case 'jump-in':
					if (playCutscene) {
						FlxTransitionableState.skipNextTransIn = false;
						FlxTransitionableState.skipNextTransOut = false;
						LoadingState.loadAndSwitchState(new VideoState("assets/videos/Cutscene1Subtitles.webm", new PlayState()));
						FlxG.log.add('FUCKKKKK');
						playCutscene = false;
					} else {
						camHUD.visible = true;
						camGame.visible = true;
						startCountdown();
					}
				case 'groovy-brass':
					if (playCutscene) {
						FlxTransitionableState.skipNextTransIn = false;
						FlxTransitionableState.skipNextTransOut = false;
						LoadingState.loadAndSwitchState(new VideoState("assets/videos/ITB/Subtitles ITB-1.webm", new PlayState()));
						playCutscene = false;
					} else {
						camHUD.visible = true;
						camGame.visible = true;
						startCountdown();
					}
				case 'copy-cat':
					if (playCutscene) {
						FlxTransitionableState.skipNextTransIn = false;
						FlxTransitionableState.skipNextTransOut = false;
						LoadingState.loadAndSwitchState(new VideoState("assets/videos/bob takeover/Subtitles-Onslaught-1.webm", new PlayState()));
						playCutscene = false;
					} else {
						camHUD.visible = true;
						camGame.visible = true;
						startCountdown();
					}
				case 'jump-out':
					schoolIntro(doof);
				case 'ronald-mcdonald-slide':
					schoolIntro(doof);
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				default:
					startCountdown();
			}
		} else {
			switch (curSong.toLowerCase()) {
				case 'gameover':
					FlxG.save.data.playedGO = true;
					dad.visible = false;
					boyfriend.visible = false;
					faker = new Character(goBFValue.x, goBFValue.y, 'deadbf-extra');
					add(faker);
					faker.debugMode = true;
					faker.playAnim('idle', true);
					realOffsetX = 0;
					camFaker.setPosition(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
					dad.setPosition(goBFValue.x, goBFValue.y);
					boyfriend.setPosition(dad.x + 1350, dad.y + 40);
					// FlxG.sound.play(Paths.sound('fnf_loss_sfx', 'shared'));
					canPause = true;
					// camFollow.setPosition(0, 0);
					// camGame.setPosition(0, 0);
					generateStaticArrows(0);
					generateStaticArrows(1);
					camHUD.alpha = 0;
					startTimer = new FlxTimer().start(0);
					openSubState(new GameOverFakeSubstate(goBFValue.x, goBFValue.y));
				default:
					startCountdown();
			}
		}

		if (!loadRep)
			rep = new Replay("na");

		if (curStage == 'night' || curStage == 'sans') {
			phillyCityLights = new FlxTypedGroup<FlxSprite>();
			add(phillyCityLights);

			coolGlowyLights = new FlxTypedGroup<FlxSprite>();
			add(coolGlowyLights);
			coolGlowyLightsMirror = new FlxTypedGroup<FlxSprite>();
			add(coolGlowyLightsMirror);
			for (i in 0...4) {
				var light:FlxSprite = new FlxSprite().loadGraphic(Paths.image('night/light' + i, 'shared'));
				light.scrollFactor.set(0, 0);
				light.cameras = [camHUD];
				light.visible = false;
				light.updateHitbox();
				light.antialiasing = true;
				phillyCityLights.add(light);

				var glow:FlxSprite = new FlxSprite().loadGraphic(Paths.image('night/Glow' + i, 'shared'));
				glow.scrollFactor.set(0, 0);
				glow.cameras = [camHUD];
				glow.visible = false;
				glow.updateHitbox();
				glow.antialiasing = true;
				coolGlowyLights.add(glow);

				var glow2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('night/Glow' + i, 'shared'));
				glow2.scrollFactor.set(0, 0);
				glow2.cameras = [camHUD];
				glow2.visible = false;
				glow2.updateHitbox();
				glow2.antialiasing = true;
				coolGlowyLightsMirror.add(glow2);
			}
		}
		super.create();
		var areYouReady:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
		add(areYouReady);
		for (i in 0...3) {
			var shit:FlxSprite = new FlxSprite();
			switch (i) {
				case 0:
					shit = new FlxSprite().loadGraphic(Paths.image('ARE', 'shared'));
				case 1:
					shit = new FlxSprite().loadGraphic(Paths.image('YOU', 'shared'));
				case 2:
					shit = new FlxSprite().loadGraphic(Paths.image('READY', 'shared'));
			}
			shit.cameras = [camHUD];
			shit.visible = false;
			areYouReady.add(shit);
		}

		trace(dad.x);
		trace(dad.y);

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder)) {
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		if (eventNotes.length > 0) {
			for (event in eventNotes)
				event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		// PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if (ClientPrefs.data.hitsoundVolume > 0)
			Paths.sound('hitsound');
		if (!ClientPrefs.data.ghostTapping)
			for (i in 1...4)
				Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if (Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		stagesFunc(function(stage:BaseStage) stage.createPost());
		callOnScripts('onCreatePost');

		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching

		// `super.create()` is intentionally called earlier in this method.
		// Removing the duplicate call here keeps initialization order intact.
		Paths.clearUnusedMemory();

		cacheCountdown();
		cachePopUpScore();

		if (eventNotes.length < 1)
			checkEventNote();
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	function fuckUpHealth(v:Float) {
		health = v;
	}

	public function focusOut() {
		if (paused)
			return;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if (FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
	}

	public function focusIn() {
		// nada
	}

	public function backgroundVideo(source:String) // for background videos
	{
		#if cpp
		useVideo = true;

		FlxG.stage.window.onFocusOut.add(focusOut);
		FlxG.stage.window.onFocusIn.add(focusIn);

		var ourSource:String = "assets/videos/DO NOT DELETE OR GAME WILL CRASH/dontDelete.webm";
		// WebmPlayer.SKIP_STEP_LIMIT = 90;
		var str1:String = "WEBM SHIT";
		webmHandler = new WebmHandler();
		webmHandler.source(ourSource);
		webmHandler.makePlayer();

		BackgroundVideo.setWebm(webmHandler);

		BackgroundVideo.get().source(source);
		BackgroundVideo.get().clearPause();
		if (BackgroundVideo.isWebm) {
			BackgroundVideo.get().updatePlayer();
		}
		BackgroundVideo.get().show();

		if (BackgroundVideo.isWebm) {
			BackgroundVideo.get().restart();
		} else {
			BackgroundVideo.get().play();
		}

		videoSprite = new FlxSprite(0, 0);
		videoSprite.makeGraphic(1280, 720, FlxColor.BLACK); // placeholder until video loads
		videoSprite.dirty = true;
		// videoSprite.setGraphicSize(Std.int(videoSprite.width * 1.2));
		videoSprite.scrollFactor.set();
		videoSprite.cameras = [camHUD];
		remove(gf);
		remove(boyfriend);
		remove(dad);
		add(videoSprite);
		add(gf);
		add(boyfriend);
		add(dad);

		trace('poggers');

		if (!songStarted)
			webmHandler.pause();
		else
			webmHandler.resume();
		#end
	}

	public function makeBackgroundTheVideo(source:String) // for background videos
	{
		#if cpp
		useVideo = true;

		FlxG.stage.window.onFocusOut.add(focusOut);
		FlxG.stage.window.onFocusIn.add(focusIn);

		var ourSource:String = "assets/videos/DO NOT DELETE OR GAME WILL CRASH/dontDelete.webm";
		// WebmPlayer.SKIP_STEP_LIMIT = 90;
		var str1:String = "WEBM SHIT";
		webmHandler = new WebmHandler();
		webmHandler.source(ourSource);
		webmHandler.makePlayer();
		webmHandler.webm.name = str1;

		BackgroundVideo.setWebm(webmHandler);

		BackgroundVideo.get().source(source);
		BackgroundVideo.get().clearPause();
		if (BackgroundVideo.isWebm) {
			BackgroundVideo.get().updatePlayer();
		}
		BackgroundVideo.get().show();

		if (BackgroundVideo.isWebm) {
			BackgroundVideo.get().restart();
		} else {
			BackgroundVideo.get().play();
		}

		videoSprite = new FlxSprite(0, 0);
		videoSprite.makeGraphic(1280, 720, FlxColor.BLACK); // placeholder until video loads
		videoSprite.dirty = true;
		videoSprite.setGraphicSize(Std.int(videoSprite.width * 1.4));
		videoSprite.scrollFactor.set();
		// videoSprite.cameras = [camHUD];
		remove(gf);
		remove(boyfriend);
		remove(dad);
		add(videoSprite);
		add(gf);
		add(boyfriend);
		add(dad);

		trace('poggers');

		if (!songStarted)
			webmHandler.pause();
		else
			webmHandler.resume();
		#end
	}

	function set_songSpeed(value:Float):Float {
		if (generatedMusic) {
			var ratio:Float = value / songSpeed; // funny word huh
			if (ratio != 1) {
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float {
		#if FLX_PITCH
		if (generatedMusic) {
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; // funny word huh
			if (ratio != 1) {
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#if VIDEOS_ALLOWED
		if (videoCutscene != null && videoCutscene.videoSprite != null)
			videoCutscene.videoSprite.bitmap.rate = value;
		#end
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch (type) {
			case 0:
				if (!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String) {
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if (FileSystem.exists(replacePath)) {
			luaFile = replacePath;
			doPush = true;
		} else {
			luaFile = Paths.getSharedPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if (Assets.exists(luaFile))
			doPush = true;
		#end

		if (doPush) {
			for (script in luaArray) {
				if (script.scriptName == luaFile) {
					doPush = false;
					break;
				}
			}
			if (doPush)
				new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(replacePath)) {
			scriptFile = replacePath;
			doPush = true;
		} else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if (FileSystem.exists(scriptFile))
				doPush = true;
		}

		if (doPush) {
			if (Iris.instances.exists(scriptFile))
				doPush = false;

			if (doPush)
				initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String):Dynamic
		return variables.get(tag);

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;

	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true) {
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile) {
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if (forMidSong)
				videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong) {
				function onVideoEnd() {
					if (!isDead
						&& generatedMusic
						&& PlayState.SONG.notes[Std.int(curStep / 16)] != null
						&& !endingSong
						&& !isCameraOnForcedPos) {
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead)
				GameOverSubstate.instance.add(videoCutscene);
			else
				add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else
			addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else
			FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		#end
		return null;
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void {
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	function cacheCountdown() {
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch (stageUI) {
			case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
			case "normal": ["ready", "set", "go"];
			default: [
					'${uiPrefix}UI/ready${uiPostfix}',
					'${uiPrefix}UI/set${uiPostfix}',
					'${uiPrefix}UI/go${uiPostfix}'
				];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void {
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		// pre lowercasing the song name (schoolIntro)
		var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
		}
		if (songLowercase == 'roses' || songLowercase == 'thorns') {
			remove(black);

			if (songLowercase == 'thorns') {
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer) {
			black.alpha -= 0.15;

			if (black.alpha > 0) {
				tmr.reset(0.3);
			} else {
				if (dialogueBox != null) {
					inCutscene = true;
					add(dialogueBox);
				} else
					startCountdown();

				remove(black);
			}
		});
	}

	public function startCountdown() {
		if (startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if (ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0)
				skipArrowStartTween = true;

			canPause = true;
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				// if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			} else if (skipCountdown) {
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer) {
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch (stageUI) {
					case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
					case "normal": ["ready", "set", "go"];
					default: [
							'${uiPrefix}UI/ready${uiPostfix}',
							'${uiPrefix}UI/set${uiPostfix}',
							'${uiPrefix}UI/go${uiPostfix}'
						];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter) {
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				if (!skipArrowStartTween) {
					notes.forEachAlive(function(note:Note) {
						if (ClientPrefs.data.opponentStrums || note.mustPress) {
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if (ClientPrefs.data.middleScroll && !note.mustPress)
								note.alpha *= 0.35;
						}
					});
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite {
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween) {
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic) {
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxBasic) {
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxBasic) {
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float) {
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true) {
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && !cpuControlled && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function updateScoreText() {
		var str:String = Language.getPhrase('rating_$ratingName', ratingName);
		if (totalPlayed != 0) {
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' (${percent}%) - ' + Language.getPhrase(ratingFC);
		}

		var tempScore:String;
		if (!instakillOnMiss)
			tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [songScore, songMisses, str]);
		else
			tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [songScore, str]);
		scoreTxt.text = tempScore;
	}

	public dynamic function fullComboFunction() {
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = "";
		if (songMisses == 0) {
			if (bads > 0 || shits > 0)
				ratingFC = 'FC';
			else if (goods > 0)
				ratingFC = 'GFC';
			else if (sicks > 0)
				ratingFC = 'SFC';
		} else {
			if (songMisses < 10)
				ratingFC = 'SDCB';
			else
				ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void {
		if (!ClientPrefs.data.scoreZoom)
			return;

		if (scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float) {
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time - Conductor.offset;
		#if FLX_PITCH
		FlxG.sound.music.pitch = playbackRate;
		#end
		FlxG.sound.music.play();

		if (Conductor.songPosition < vocals.length) {
			vocals.time = time - Conductor.offset;
			#if FLX_PITCH
			vocals.pitch = playbackRate;
			#end
			vocals.play();
		} else
			vocals.pause();

		if (Conductor.songPosition < opponentVocals.length) {
			opponentVocals.time = time - Conductor.offset;
			#if FLX_PITCH
			opponentVocals.pitch = playbackRate;
			#end
			opponentVocals.play();
		} else
			opponentVocals.pause();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function nooooron():Void {
		if (FlxG.save.data.beatBob == null || FlxG.save.data.beatBob == false) {
			FlxG.save.data.beatBob = true;
		}
		for (i in strumLineNotes)
			i.visible = false;
		healthBar.visible = false;
		iconP2.visible = false;
		iconP1.visible = false;
		camZooming = false;
		resyncingVocals = false;
		canPause = false;
		FlxG.sound.music.stop();
		vocals.stop();
		var dialogue = CoolUtil.coolTextFile(Paths.txt('ronald mcdonald slide/AAAAAAAAAAAAA'));
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing = killron;
		doof.cameras = [camHUD];
		add(doof);
	}

	function startSong():Void {
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH
		FlxG.sound.music.pitch = playbackRate;
		#end
		FlxG.sound.music.onComplete = finishSong.bind();

		if (SONG.song.toLowerCase() == 'ronald mcdonald slide' && isStoryMode)
			FlxG.sound.music.onComplete = nooooron;
			/*else if (curStage.startsWith('ITB-') && storyDifficulty == 3)
					FlxG.sound.music.onComplete = endanimation;
				else if (curStage == 'day' && storyDifficulty == 3)
					FlxG.sound.music.onComplete = endanimation;
				else if (curStage == 'sunset' && storyDifficulty == 3)
					FlxG.sound.music.onComplete = endanimation; */
			//	else if (curStage == 'night' && storyDifficulty == 3)
		//	FlxG.sound.music.onComplete = endanimation;
		else
			FlxG.sound.music.onComplete = endSong;

		secondaryVocals.play();
		vocals.play();
		opponentVocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if (!paused) {
			if (storyDifficulty == 3)
				FlxG.sound.playMusic(Paths.instEX(PlayState.SONG.song), 1, false);
			else
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		}

		if (paused) {
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if (autoUpdateRPC)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');

		if (useVideo && !FlxG.save.data.lowDetail)
			BackgroundVideo.get().resume();
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns:Int = 4;

	private function generateSong():Void {
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch (songSpeedType) {
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			if (storyDifficulty == 3) {
				vocals = new FlxSound().loadEmbedded(Paths.voicesEX(PlayState.SONG.song));
				if (SONG.player2 == 'bob' && SONG.song.toLowerCase() == 'swing' || SONG.player2 == 'bob-ex' && SONG.song.toLowerCase() == 'swing') {
					secondaryVocals = new FlxSound().loadEmbedded(Paths.voicesEXcharacter(PlayState.SONG.song, 'bob'));
					vocals = new FlxSound().loadEmbedded(Paths.voicesEXcharacter(PlayState.SONG.song, 'bf'));
				} else
					secondaryVocals = new FlxSound();
			} else {
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				secondaryVocals = new FlxSound();
			}
		else {
			vocals = new FlxSound();
			secondaryVocals = new FlxSound();
		}
		secondaryVocals.volume = 1;
		trace('loaded vocals');

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(secondaryVocals);
		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		// pre lowercasing the song name (generateSong)
		var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
		}
		// Per song offset check
		#if windows
		var songPath = 'assets/data/' + songLowercase + '/';

		/*for(file in sys.FileSystem.readDirectory(songPath))
			{
				var path = haxe.io.Path.join([songPath, file]);
				if(!sys.FileSystem.isDirectory(path))
				{
					if(path.endsWith('.offset'))
					{
						trace('Found offset file: ' + path);
						songOffset = Std.parseFloat(file.substring(0, file.indexOf('.off')));
						break;
					}else {
						trace('Offset file not found. Creating one @: ' + songPath);
						sys.io.File.saveContent(songPath + songOffset + '.offset', '');
					}
				}
		}*/
		#end
		if (hasDad2 && usesDad2Chart) {
			var dad2NoteData = dad2SONG.notes;
			dad2Notes = new FlxTypedGroup<Note>();
			for (section in dad2NoteData) {
				var coolSection:Int = Std.int(section.lengthInSteps / 4);
				for (songNotes in section.sectionNotes) {
					var daStrumTime:Float = songNotes[0];
					if (daStrumTime < 0)
						daStrumTime = 0;
					var daNoteData:Int = Std.int(songNotes[1]);
					var gottaHitNote:Bool = section.mustHitSection;
					var daType = songNotes[3];
					if (songNotes[1] > 3) {
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (dad2Notes.members.length > 0)
						oldNote = dad2Notes.members[Std.int(dad2Notes.members.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, daType);
					swagNote.sustainLength = songNotes[2];
					dad2Notes.add(swagNote);
				}
			}
		}

		if (storyDifficulty == 3) {
			// var abelSongData = abelSONG;
			var effectNoteData = effectSONG.notes;
			effectNotes = new FlxTypedGroup<Note>();
			for (section in effectNoteData) {
				var coolSection:Int = Std.int(section.lengthInSteps / 4);
				for (songNotes in section.sectionNotes) {
					var daStrumTime:Float = songNotes[0];
					if (daStrumTime < 0)
						daStrumTime = 0;
					var daNoteData:Int = Std.int(songNotes[1]);
					var gottaHitNote:Bool = section.mustHitSection;
					var daType = songNotes[3];
					if (songNotes[1] > 3) {
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (effectNotes.members.length > 0)
						oldNote = effectNotes.members[Std.int(effectNotes.members.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, daType);
					swagNote.sustainLength = songNotes[2];
					effectNotes.add(swagNote);
				}
			}
		}
		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData) {
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0] + FlxG.save.data.offset + songOffset;
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3) {
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var daType = songNotes[3];
				var swagNote:Note;
				if (gottaHitNote) {
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, daType, boyfriend.noteSkin);
				} else {
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, daType, dad.noteSkin);
				}
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var sustainNote:Note;
					if (gottaHitNote) {
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, daType,
							boyfriend.noteSkin);
					} else {
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, daType,
							dad.noteSkin);
					}
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					switch (sustainNote.noteType) {
						case 'drop' | 'are' | 'you' | 'ready' | 'kill' | '4' | '5' | '6' | '7':
							sustainNote.mustPress = false;
						default:
							sustainNote.mustPress = gottaHitNote;
					}

					if (sustainNote.mustPress) {
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}
				switch (swagNote.noteType) {
					case 'drop' | 'are' | 'you' | 'ready' | 'kill' | '4' | '5' | '6' | '7':
						swagNote.mustPress = false;
					default:
						swagNote.mustPress = gottaHitNote;
				}

				if (swagNote.mustPress) {
					swagNote.x += FlxG.width / 2; // general offset
				} else {}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;

		var songData = SONG;

		Conductor.bpm = songData.bpm;
		curSong = songData.song;
		if (secondaryVocals != null) {
			secondaryVocals.destroy();
		}
		if (vocals != null) {
			vocals.destroy();
		}
		if (opponentVocals != null) {
			opponentVocals.destroy();
		}
		secondaryVocals = new FlxSound();
		vocals = new FlxSound();
		opponentVocals = new FlxSound();
	}

	function loadEXVocals(songName:String):Void {
		vocals = new FlxSound();
		vocals.loadEmbedded(Paths.voicesEX(songName));
	}

	function loadSwingBobVocals(songName:String):Void {
		secondaryVocals = new FlxSound();
		secondaryVocals.loadEmbedded(Paths.voicesEXcharacter(songName, 'bob'));
		vocals = new FlxSound();
		vocals.loadEmbedded(Paths.voicesEXcharacter(songName, 'bf'));
	}

	function loadPlayerVocals(songName:String, bfVocalsFile:String):Void {
		var playerKey = (bfVocalsFile == null || bfVocalsFile.length < 1) ? "Player" : bfVocalsFile;
		var playerVocals = Paths.voices(songName, playerKey);
		vocals = new FlxSound();
		vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songName));
	}

// called only once per different event (Used for precaching)
function eventPushed(event:EventNote) {
	eventPushedUnique(event);
	if (eventsPushed.contains(event.event)) {
		return;
	}

	stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
	eventsPushed.push(event.event);
}

// called by every event with the same name
function eventPushedUnique(event:EventNote) {
	switch (event.event) {
		case "Change Character":
			var charType:Int = 0;
			switch (event.value1.toLowerCase()) {
				case 'gf' | 'girlfriend':
					charType = 2;
				case 'dad' | 'opponent':
					charType = 1;
				default:
					var val1:Int = Std.parseInt(event.value1);
					if (Math.isNaN(val1))
						val1 = 0;
					charType = val1;
			}

			var newCharacter:String = event.value2;
			addCharacterToList(newCharacter, charType);

		case 'Play Sound':
			Paths.sound(event.value1); // Precache sound
	}
	stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
}

function eventEarlyTrigger(event:EventNote):Float {
	var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
	if (returnedValue != null && returnedValue != 0) {
		return returnedValue;
	}

	switch (event.event) {
		case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
			return 280; // Plays 280ms before the actual position
	}
	return 0;
}

public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
	return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

function makeEvent(event:Array<Dynamic>, i:Int) {
	final subEvent:EventNote = {
		strumTime: event[0] + ClientPrefs.data.noteOffset,
		event: event[1][i][0],
		value1: event[1][i][1],
		value2: event[1][i][2]
	};
	eventNotes.push(subEvent);
	eventPushed(subEvent);
	callOnScripts('onEventPushed', [
		subEvent.event,
		subEvent.value1 != null ? subEvent.value1 : '',
		subEvent.value2 != null ? subEvent.value2 : '',
		subEvent.strumTime
	]);
}

public var skipArrowStartTween:Bool = false; // for lua

private function generateStaticArrows(player:Int):Void {
	var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
	var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
	for (i in 0...4) {
		// FlxG.log.add(i);
		var targetAlpha:Float = 1;
		if (player < 1) {
			if (!ClientPrefs.data.opponentStrums)
				targetAlpha = 0;
			else if (ClientPrefs.data.middleScroll)
				targetAlpha = 0.35;
		}

		var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
		babyArrow.downScroll = ClientPrefs.data.downScroll;
		if (!isStoryMode && !skipArrowStartTween) {
			// babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
		} else
			babyArrow.alpha = targetAlpha;

		if (player == 1)
			playerStrums.add(babyArrow);
		else {
			if (ClientPrefs.data.middleScroll) {
				babyArrow.x += 310;
				if (i > 1) { // Up and Right
					babyArrow.x += FlxG.width / 2 + 25;
				}
			}
			opponentStrums.add(babyArrow);
		}

		strumLineNotes.add(babyArrow);
		babyArrow.playerPosition();
	}
}

override function openSubState(SubState:FlxSubState) {
	stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
	if (paused) {
		if (FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
			secondaryVocals.pause();
		}
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
			tmr.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
			twn.active = false);
	}

	super.openSubState(SubState);
}

public var canResync:Bool = true;

override function closeSubState() {
	super.closeSubState();

	stagesFunc(function(stage:BaseStage) stage.closeSubState());
	if (paused) {
		if (FlxG.sound.music != null && !startingSong && canResync) {
			resyncVocals();
		}
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
			tmr.active = true);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
			twn.active = true);

		paused = false;
		callOnScripts('onResume');
		resetRPC(startTimer != null && startTimer.finished);
	}
}

#if DISCORD_ALLOWED
override public function onFocus():Void {
	super.onFocus();
	if (!paused && health > 0) {
		resetRPC(Conductor.songPosition > 0.0);
	}
}

override public function onFocusLost():Void {
	super.onFocusLost();
	if (!paused && health > 0 && autoUpdateRPC) {
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
	}
}
#end

// Updating Discord Rich Presence.
public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things

function resetRPC(?showTime:Bool = false) {
	#if DISCORD_ALLOWED
	if (!autoUpdateRPC)
		return;

	if (showTime)
		DiscordClient.changePresence(detailsText, SONG.song
			+ " ("
			+ storyDifficultyText
			+ ")", iconP2.getCharacter(), true,
			songLength
			- Conductor.songPosition
			- ClientPrefs.data.noteOffset);
	else
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
	#end
}

function resyncVocals():Void {
	if (resyncingVocals) {
		vocals.pause();
		secondaryVocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
		secondaryVocals.time = Conductor.songPosition;
		secondaryVocals.play();

		#if windows
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end
	} else {
		if (FlxG.save.data.songPosition) {}
		Conductor.songPosition = 0;
		FlxG.sound.music.time = 0;
	}
}

public var paused:Bool = false;
public var canReset:Bool = true;
var startedCountdown:Bool = false;
var canPause:Bool = true;
var freezeCamera:Bool = false;
var allowDebugKeys:Bool = true;
var nps:Int = 0;
var maxNPS:Int = 0;
public static var songRate = 1.5;

override public function update(elapsed:Float) {
	if (!inCutscene && !paused && !freezeCamera) {
		FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
		var idleAnim:Bool = (boyfriend.getAnimationName().startsWith('idle')
			|| boyfriend.getAnimationName().startsWith('danceLeft')
			|| boyfriend.getAnimationName().startsWith('danceRight'));
		if (!startingSong && !endingSong && idleAnim) {
			boyfriendIdleTime += elapsed;
			if (boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
				boyfriendIdled = true;
			}
		} else {
			boyfriendIdleTime = 0;
		}
	} else
		FlxG.camera.followLerp = 0;
	callOnScripts('onUpdate', [elapsed]);

	super.update(elapsed);

	setOnScripts('curDecStep', curDecStep);
	setOnScripts('curDecBeat', curDecBeat);

	if (botplayTxt != null && botplayTxt.visible) {
		botplaySine += 180 * elapsed;
		botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
	}

	if (controls.PAUSE && startedCountdown && canPause) {
		var ret:Dynamic = callOnScripts('onPause', null, true);
		if (ret != LuaUtils.Function_Stop) {
			openPauseMenu();
		}
	}

	if (!endingSong && !inCutscene && allowDebugKeys) {
		if (controls.justPressed('debug_1'))
			openChartEditor();
		else if (controls.justPressed('debug_2'))
			openCharacterEditor();
	}

	if (healthBar.bounds.max != null && health > healthBar.bounds.max)
		health = healthBar.bounds.max;

	updateIconsScale(elapsed);
	updateIconsPosition();

	if (startedCountdown && !paused) {
		Conductor.songPosition += elapsed * 1000 * playbackRate;
		if (Conductor.songPosition >= Conductor.offset) {
			Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
			var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
			if (timeDiff > 1000 * playbackRate)
				Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
		}
	}

	if (startingSong) {
		if (startedCountdown && Conductor.songPosition >= Conductor.offset)
			startSong();
		else if (!startedCountdown)
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
	} else if (!paused && updateTime) {
		var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
		songPercent = (curTime / songLength);

		var songCalc:Float = (songLength - curTime);
		if (ClientPrefs.data.timeBarType == 'Time Elapsed')
			songCalc = curTime;

		var secondsTotal:Int = Math.floor(songCalc / 1000);
		if (secondsTotal < 0)
			secondsTotal = 0;

		if (ClientPrefs.data.timeBarType != 'Song Name')
			timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
	}

	if (camZooming) {
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
	}

	FlxG.watch.addQuick("secShit", curSection);
	FlxG.watch.addQuick("beatShit", curBeat);
	FlxG.watch.addQuick("stepShit", curStep);

	// RESET = Quick Game Over Screen
	if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong) {
		health = 0;
		trace("RESET = True");
	}
	doDeathCheck();

	if (unspawnNotes[0] != null) {
		var time:Float = spawnTime * playbackRate;
		if (songSpeed < 1)
			time /= songSpeed;
		if (unspawnNotes[0].multSpeed < 1)
			time /= unspawnNotes[0].multSpeed;

		while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time) {
			var dunceNote:Note = unspawnNotes[0];
			notes.insert(0, dunceNote);
			dunceNote.spawned = true;

			callOnLuas('onSpawnNote', [
				notes.members.indexOf(dunceNote),
				dunceNote.noteData,
				dunceNote.noteType,
				dunceNote.isSustainNote,
				dunceNote.strumTime
			]);
			callOnHScript('onSpawnNote', [dunceNote]);

			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.splice(index, 1);
		}
	}

	if (generatedMusic) {
		if (!inCutscene) {
			if (!cpuControlled)
				keysCheck();
			else
				playerDance();

			if (notes.length > 0) {
				if (startedCountdown) {
					var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
					var i:Int = 0;
					while (i < notes.length) {
						var daNote:Note = notes.members[i];
						if (daNote == null)
							continue;

						var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
						if (!daNote.mustPress)
							strumGroup = opponentStrums;

						var strum:StrumNote = strumGroup.members[daNote.noteData];
						daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

						if (daNote.mustPress) {
							if (cpuControlled
								&& !daNote.blockHit
								&& daNote.canBeHit
								&& (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
								goodNoteHit(daNote);
						} else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
							opponentNoteHit(daNote);

						if (daNote.isSustainNote && strum.sustainReduce)
							daNote.clipToStrumNote(strum);

						// Kill extremely late notes and cause misses
						if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
							if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
								noteMiss(daNote);

							daNote.active = daNote.visible = false;
							invalidateNote(daNote);
						}
						if (daNote.exists)
							i++;
					}
				} else {
					notes.forEachAlive(function(daNote:Note) {
						daNote.canBeHit = false;
						daNote.wasGoodHit = false;
					});
				}
			}
		}
		checkEventNote();

		notes.forEachAlive(function(daNote:Note) {
			// instead of doing stupid y > FlxG.height
			// we be men and actually calculate the time :)
			if (daNote.tooLate) {
				daNote.active = false;
				daNote.visible = false;
			} else {
				daNote.visible = true;
				daNote.active = true;
			}

			if (!daNote.mustPress && daNote.wasGoodHit) {
				if (SONG.song != 'Tutorial')
					camZooming = true;

				var altAnim:String = "";

				if (SONG.notes[Math.floor(curStep / 16)] != null) {
					if (SONG.notes[Math.floor(curStep / 16)].altAnim)
						altAnim = '-alt';
				}
				switch (daNote.noteType) {
					case 'drop':
						if (SONG.song.toLowerCase() == 'groovy brass')
							useCamChange = false;
						camFollow.x = 272.46;
						camFollow.y = 420.96;
						dad.playAnim('drop', true);
						if (SONG.song.toLowerCase() == 'split' && storyDifficulty == 3 && !FlxG.save.data.lowDetail) {
							var ded:FlxSprite = new FlxSprite(dad.x, dad.y);
							dad.alpha = 0;
							//	camHUD.visible = false;
							ded.frames = Paths.getSparrowAtlas('night/amor_falling_lol', 'shared');
							ded.animation.addByPrefix('idle', 'amor_falling_lol instance 1', 24, false);
							ded.animation.play('idle');
							ded.y -= 100;
							ded.x -= 100;
							add(ded);
						}
					case 'are':
						switch (SONG.song.toLowerCase()) {
							case 'jump-out':
								if (storyDifficulty != 3 && !FlxG.save.data.lowDetail) {
									remove(dad);
									dad = new Character(-50, 439, 'verb');
									iconP2Prefix = 'verb';
									grpIcons.remove(iconP2);
									iconP2 = new HealthIcon('verb', false);
									iconP2.y = healthBar.y - (iconP2.height / 2);
									iconP2.cameras = [camHUD];
									grpIcons.add(iconP2);
									add(dad);
								} else {
									if (!FlxG.save.data.lowDetail)
										remove(boyfriend);
									boyfriend = new Character(900, 700, 'little-man');
									remove(gf);
									add(gf);
									add(boyfriend);
								}
							case 'ronald mcdonald slide':
								if (!FlxG.save.data.lowDetail) {
									var elShader = new PixelateShader();
									#if (openfl >= "8.0.0")
									elShader.data.uBlocksize.value = [5, 5];
									#else
									elShader.uBlocksize = [5, 5];
									#end
									dad.shader = elShader;
									boyfriend.shader = elShader;
									gf.shader = elShader;
									var bgShader = new PixelateShader();
									#if (openfl >= "8.0.0")
									bgShader.data.uBlocksize.value = [10, 10];
									#else
									bgShader.uBlocksize = [10, 10];
									#end
									for (i in grpDieStage)
										i.shader = bgShader;

									unregisteredHypercam.visible = true;
								}

							default:
								if (FlxG.save.data.flashing && !FlxG.save.data.lowDetail) {
									areYouReady.members[0].visible = true;
									phillyCityLights.forEach(function(light:FlxSprite) {
										light.visible = false;
									});
									phillyCityLights.members[0].visible = true;
									phillyCityLights.members[0].alpha = 1;
									FlxTween.tween(phillyCityLights.members[0], {alpha: 0}, 0.2, {});
								}
						}
					case 'you':
						switch (SONG.song.toLowerCase()) {
							case 'jump-out' | 'ronald mcdonald slide':
								if (!FlxG.save.data.lowDetail) {
									for (i in SAD) {
										i.alpha = 0;
										if (SAD.members.indexOf(i) == SADorder) {
											i.alpha = 1;
										}
									}
									SADorder++;
									if (SADorder > 3)
										SADorder = 0;
								}
							default:
								if (FlxG.save.data.flashing && !FlxG.save.data.lowDetail) {
									areYouReady.members[1].visible = true;
									phillyCityLights.forEach(function(light:FlxSprite) {
										light.visible = false;
									});
									phillyCityLights.members[0].visible = true;
									phillyCityLights.members[0].alpha = 1;
									FlxTween.tween(phillyCityLights.members[0], {alpha: 0}, 0.2, {});
								}
						}

					case 'ready':
						switch (SONG.song.toLowerCase()) {
							case 'ronald mcdonald slide':
								if (!FlxG.save.data.lowDetail)
									backgroundVideo("assets/videos/stop_posting_about_among_us.webm");

								remove(dad);
								dad = new Character(-50, 109, 'abungus', false, true);
								grpIcons.remove(iconP2);
								iconP2Prefix = 'abungus';
								iconP2 = new HealthIcon('abungus', false);
								iconP2.y = healthBar.y - (iconP2.height / 2);
								iconP2.cameras = [camHUD];
								grpIcons.add(iconP2);

								remove(gf);
								add(gf);
								add(dad);
								healthBar.visible = false;
								iconP2.visible = false;
								iconP1.visible = false;
							case 'jump-out':
								if (storyDifficulty != 3 && !FlxG.save.data.lowDetail) {
									backgroundVideo("assets/videos/sandwitch.webm");
								} else if (!FlxG.save.data.lowDetail) {
									backgroundVideo("assets/videos/Bagel.webm");
								}
							default:
								if (FlxG.save.data.flashing && !FlxG.save.data.lowDetail) {
									areYouReady.members[2].visible = true;
									phillyCityLights.forEach(function(light:FlxSprite) {
										light.visible = false;
									});
									phillyCityLights.members[0].visible = true;
									phillyCityLights.members[0].alpha = 1;
									FlxTween.tween(phillyCityLights.members[0], {alpha: 0}, 0.2, {});
								}
						}
					case 'kill':
						if (!FlxG.save.data.lowDetail) {
							switch (SONG.song.toLowerCase()) {
								case 'ronald mcdonald slide':
									if (useVideo && !FlxG.save.data.lowDetail) {
										BackgroundVideo.get().stop();
										FlxG.stage.window.onFocusOut.remove(focusOut);
										FlxG.stage.window.onFocusIn.remove(focusIn);
										PlayState.instance.remove(PlayState.instance.videoSprite);
										useVideo = false;
									}
									waaaa.visible = false;
									unregisteredHypercam.visible = false;

									for (i in grpDieStage)
										i.shader = null;

									dad.shader = null;
									boyfriend.shader = null;
									gf.shader = null;

									if (dad.curCharacter != 'ronsip') {
										remove(dad);
										dad = new Character(-50, 189, 'ronsip', false, true);
										grpIcons.remove(iconP2);
										iconP2Prefix = 'ronsip';
										iconP2 = new HealthIcon('ronsip', false);
										iconP2.y = healthBar.y - (iconP2.height / 2);
										iconP2.cameras = [camHUD];
										grpIcons.add(iconP2);

										remove(gf);
										add(gf);
										add(dad);
									}

									if (boyfriend.curCharacter != 'bf') {
										remove(boyfriend);
										boyfriend = new Character(961, 430, 'bf');
										grpIcons.remove(iconP1);
										iconP1Prefix = 'bf';
										iconP1 = new HealthIcon('bf', true);
										iconP1.y = healthBar.y - (iconP1.height / 2);
										iconP1.cameras = [camHUD];
										grpIcons.add(iconP1);
										remove(gf);
										add(gf);
										add(boyfriend);
									}
								case 'jump-out':
									if (storyDifficulty != 3) {
										if (useVideo && !FlxG.save.data.lowDetail) {
											BackgroundVideo.get().stop();
											FlxG.stage.window.onFocusOut.remove(focusOut);
											FlxG.stage.window.onFocusIn.remove(focusIn);
											PlayState.instance.remove(PlayState.instance.videoSprite);
											useVideo = false;
										}
										dad.playAnim('idle');
										if (dad.curCharacter != 'gloopy') {
											remove(dad);
											dad = new Character(-50, 369, 'gloopy', false, true);
											grpIcons.remove(iconP2);
											iconP2Prefix = 'gloopy';
											iconP2 = new HealthIcon('gloopy', false);
											iconP2.y = healthBar.y - (iconP2.height / 2);
											iconP2.cameras = [camHUD];
											grpIcons.add(iconP2);

											remove(gf);
											add(gf);
											add(dad);
										}

										if (boyfriend.curCharacter != 'bf') {
											remove(boyfriend);
											boyfriend = new Character(961, 430, 'bf');
											grpIcons.remove(iconP1);
											iconP1Prefix = 'bf';
											iconP1 = new HealthIcon('bf', true);
											iconP1.y = healthBar.y - (iconP1.height / 2);
											iconP1.cameras = [camHUD];
											grpIcons.add(iconP1);
											remove(gf);
											add(gf);
											add(boyfriend);
										}
									} else {
										if (useVideo && !FlxG.save.data.lowDetail) {
											BackgroundVideo.get().stop();
											FlxG.stage.window.onFocusOut.remove(focusOut);
											FlxG.stage.window.onFocusIn.remove(focusIn);
											PlayState.instance.remove(PlayState.instance.videoSprite);
											useVideo = false;
										}
										dad.playAnim('idle');
										if (dad.curCharacter != 'gloopy-ex') {
											remove(dad);
											dad = new Character(-50, 369, 'gloopy-ex', false, true);
											grpIcons.remove(iconP2);
											iconP2Prefix = 'gloopy-ex';
											iconP2 = new HealthIcon('gloopy-ex', false);
											iconP2.y = healthBar.y - (iconP2.height / 2);
											iconP2.cameras = [camHUD];
											grpIcons.add(iconP2);

											remove(gf);
											add(gf);
											add(dad);
										}

										if (boyfriend.curCharacter != 'bf') {
											remove(boyfriend);
											boyfriend = new Character(770, 450, 'bf-ex-new');
											grpIcons.remove(iconP1);
											iconP1Prefix = 'bf-ex';
											iconP1 = new HealthIcon('bf-ex', true);
											iconP1.y = healthBar.y - (iconP1.height / 2);
											iconP1.cameras = [camHUD];
											grpIcons.add(iconP1);
											remove(gf);
											add(gf);
											add(boyfriend);
											FlxG.camera.zoom = defaultCamZoom;
											// camtween.cancel();
										}
										filteron = false;
									}

								default:
									for (i in areYouReady) {
										i.visible = false;
									}
									useCamChange = true;
							}
						}
					case '4':
						switch (SONG.song.toLowerCase()) {
							case 'ronald mcdonald slide':
								if (storyDifficulty != 3 && !FlxG.save.data.lowDetail) {
									if (useVideo && !FlxG.save.data.lowDetail) {
										BackgroundVideo.get().stop();
										FlxG.stage.window.onFocusOut.remove(focusOut);
										FlxG.stage.window.onFocusIn.remove(focusIn);
										PlayState.instance.remove(PlayState.instance.videoSprite);
										useVideo = false;
									}
									healthBar.visible = true;
									iconP2.visible = true;
									iconP1.visible = true;
								} else if (!FlxG.save.data.lowDetail) {
									remove(dad);
									dad = new Character(100, 300, 'bf-sans');
									dad.x -= 100;
									remove(gf);
									add(gf);
									add(dad);
									iconP2Prefix = 'bf-sans';
									grpIcons.remove(iconP2);
									iconP2 = new HealthIcon('bf-sans', false);
									iconP2.y = healthBar.y - (iconP2.height / 2);
									iconP2.cameras = [camHUD];
									grpIcons.add(iconP2);
									trace(dad);
								}
							case 'jump-out':
								if (storyDifficulty != 3 && !FlxG.save.data.lowDetail) {
									backgroundVideo("assets/videos/TV static noise HD 1080p.webm");
								} else if (!FlxG.save.data.lowDetail) {
									filteron = true;
								}
						}

					case '5':
						if (!FlxG.save.data.lowDetail) {
							switch (SONG.song.toLowerCase()) {
								case 'ronald mcdonald slide':
									waaaa.visible = true;
								case 'jump-out':
									remove(boyfriend);
									boyfriend = new Character(811, 100, 'bf-anders');
									grpIcons.remove(iconP1);
									iconP1Prefix = 'bf-anders';
									iconP1 = new HealthIcon('bf-anders', true);
									iconP1.y = healthBar.y - (iconP1.height / 2);
									iconP1.cameras = [camHUD];
									grpIcons.add(iconP1);
									remove(gf);
									add(gf);
									add(boyfriend);
							}
						}
					case '6':
						if (!FlxG.save.data.lowDetail) {
							switch (SONG.song.toLowerCase()) {
								case 'jump-out':
									for (i in grpSlaughtStage) {
										i.y -= FlxG.height * 2;
									}
									gf.visible = false;
									defaultCamZoom = 0.9;
							}
						}
					case '7':
						if (!FlxG.save.data.lowDetail) {
							switch (SONG.song.toLowerCase()) {
								case 'jump-out':
									for (i in grpSlaughtStage) {
										i.y += FlxG.height * 2;
									}
									gf.visible = true;
									defaultCamZoom = 0.75;
							}
						}

					default:
						cpuStrums.forEach(function(spr:FlxSprite) {
							if (Math.abs(daNote.noteData) == spr.ID) {
								spr.animation.play('confirm', true);
							}
							if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school')) {
								spr.centerOffsets();
								spr.offset.x -= 13;
								spr.offset.y -= 13;
							} else
								spr.centerOffsets();
						});
						if (SONG.song.toLowerCase() == 'intertwined') {
							cerbStrums.forEach(function(spr:FlxSprite) {
								if (Math.abs(daNote.noteData) == spr.ID) {
									spr.animation.play('confirm', true);
								}
								if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school')) {
									spr.centerOffsets();
									spr.offset.x -= 13;
									spr.offset.y -= 13;
								} else
									spr.centerOffsets();
							});
						}
						var daSprite = dad;
						switch (daNote.noteType) {
							case 'cerb':
								daSprite = dad2;
								for (i in cerbStrums) {
									i.visible = true;
								}
								for (i in cpuStrums) {
									i.visible = false;
								}
								if (storyDifficulty == 3 && SONG.song.toLowerCase() == 'intertwined') {
									iconP2Prefix = 'smallashcerb-ex';
								} else {
									iconP2Prefix = 'smallashcerb';
								}

								cerbMode = true;
							case 'duet':
								if (storyDifficulty == 3 && SONG.song.toLowerCase() == 'intertwined') {
									iconP2Prefix = 'ashcerb-ex';
								} else {
									iconP2Prefix = 'ashcerb';
								}
								for (i in cerbStrums) {
									i.visible = false;
									if (cerbStrums.members.indexOf(i) == 3 || cerbStrums.members.indexOf(i) == 1)
										i.visible = true;
								}
								for (i in cpuStrums) {
									i.visible = false;
									if (cpuStrums.members.indexOf(i) == 0 || cpuStrums.members.indexOf(i) == 2)
										i.visible = true;
								}
								switch (Math.abs(daNote.noteData)) {
									case 2:
										dad2.playAnim('singUP' + altAnim, true);
									case 3:
										dad2.playAnim('singRIGHT' + altAnim, true);
									case 1:
										dad2.playAnim('singDOWN' + altAnim, true);
									case 0:
										dad2.playAnim('singLEFT' + altAnim, true);
								}
							default:
								for (i in cerbStrums) {
									i.visible = false;
								}

								if (storyDifficulty == 3 && SONG.song.toLowerCase() == 'intertwined') {
									iconP2Prefix = 'smallcerbash-ex';
								} else if (SONG.song.toLowerCase() == 'intertwined') {
									iconP2Prefix = 'ash';
								}
								cerbMode = false;
								if (storyDifficulty == 3 && SONG.song.toLowerCase() == 'conscience' && hasDad2) {
									switch (Math.abs(daNote.noteData)) {
										case 2:
											dad2.playAnim('singUP' + altAnim, true);
										case 3:
											dad2.playAnim('singRIGHT' + altAnim, true);
										case 1:
											dad2.playAnim('singDOWN' + altAnim, true);
										case 0:
											dad2.playAnim('singLEFT' + altAnim, true);
									}
								}
						}
						if (SONG.player2 == 'gloopy') {
							if (!dad.animation.curAnim.name.startsWith('drop')) {
								switch (Math.abs(daNote.noteData)) {
									case 2:
										daSprite.playAnim('singUP' + altAnim, true);
									case 3:
										daSprite.playAnim('singRIGHT' + altAnim, true);
									case 1:
										daSprite.playAnim('singDOWN' + altAnim, true);
									case 0:
										daSprite.playAnim('singLEFT' + altAnim, true);
								}
							}
						} else {
							if (coolCameraMode) {
								coolCameraMove(Math.abs(daNote.noteData), 80);
							}
							switch (Math.abs(daNote.noteData)) {
								case 2:
									daSprite.playAnim('singUP' + altAnim, true);

								case 3:
									daSprite.playAnim('singRIGHT' + altAnim, true);
								case 1:
									daSprite.playAnim('singDOWN' + altAnim, true);
								case 0:
									daSprite.playAnim('singLEFT' + altAnim, true);
							}
						}
						if (curStage == 'night' || curStage == 'sans') {
							switch (Math.abs(daNote.noteData)) {
								case 2:
									pc.playAnim('singUP', true);
								case 3:
									pc.playAnim('singRIGHT', true);
								case 1:
									pc.playAnim('singDOWN', true);
								case 0:
									pc.playAnim('singLEFT', true);
							}
						}
				}

				if (SONG.needsVoices)
					vocals.volume = 1;

				daNote.active = false;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}

			switch (daNote.noteType) {
				case 'drop' | 'are' | 'you' | 'ready' | 'kill' | '4' | '5' | '6' | '7':
					daNote.visible = false;
			}

			if (daNote.isSustainNote)
				daNote.x += daNote.width / 2 + 17;

			// trace(daNote.y);
			// WIP interpolation shit? Need to fix the pause issue
			// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

			if ((daNote.mustPress && daNote.tooLate && !FlxG.save.data.downscroll || daNote.mustPress && daNote.tooLate && FlxG.save.data.downscroll)
				&& daNote.mustPress) {
				if (daNote.isSustainNote && daNote.wasGoodHit) {
					daNote.kill();
					notes.remove(daNote, true);
				} else {
					health -= 0.075;
					vocals.volume = 0;
				}

				daNote.visible = false;
				daNote.kill();
				notes.remove(daNote, true);
			}
		});
	}
}

// Health icon updaters
dynamic function updateIconsScale(elapsed:Float) {
	var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
	iconP1.scale.set(mult, mult);
	iconP1.updateHitbox();

	var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
	iconP2.scale.set(mult, mult);
	iconP2.updateHitbox();
}

dynamic function updateIconsPosition() {
	var iconOffset:Int = 26;
	iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
	iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
}

var iconsAnimations:Bool = true;

function set_health(value:Float):Float // You can alter how icon animations work here
{
	value = FlxMath.roundDecimal(value, 5); // Fix Float imprecision
	if (!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null) {
		health = value;
		return health;
	}

	// update health bar
	health = value;
	var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max),
		healthBar.bounds.min, healthBar.bounds.max, 0, 100);
	healthBar.percent = (newPercent != null ? newPercent : 0);

	iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0; // If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0; // If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	return health;
}

function openPauseMenu() {
	FlxG.camera.followLerp = 0;
	persistentUpdate = false;
	persistentDraw = true;
	paused = true;

	if (FlxG.sound.music != null) {
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();
	}
	if (!cpuControlled) {
		for (note in playerStrums)
			if (note.animation.curAnim != null && note.animation.curAnim.name != 'static') {
				note.playAnim('static');
				note.resetAnim = 0;
			}
	}
	openSubState(new PauseSubState());

	#if DISCORD_ALLOWED
	if (autoUpdateRPC)
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
	#end
}

function openChartEditor() {
	canResync = false;
	FlxG.camera.followLerp = 0;
	persistentUpdate = false;
	chartingMode = true;
	paused = true;

	if (FlxG.sound.music != null)
		FlxG.sound.music.stop();
	if (vocals != null)
		vocals.pause();
	if (opponentVocals != null)
		opponentVocals.pause();

	#if DISCORD_ALLOWED
	DiscordClient.changePresence("Chart Editor", null, null, true);
	DiscordClient.resetClientID();
	#end

	MusicBeatState.switchState(new ChartingState());
}

function openCharacterEditor() {
	canResync = false;
	FlxG.camera.followLerp = 0;
	persistentUpdate = false;
	paused = true;

	if (FlxG.sound.music != null)
		FlxG.sound.music.stop();
	if (vocals != null)
		vocals.pause();
	if (opponentVocals != null)
		opponentVocals.pause();

	#if DISCORD_ALLOWED
	DiscordClient.resetClientID();
	#end
	MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
}

public var isDead:Bool = false; // Don't mess with this on Lua!!!
var gameOverTimer:FlxTimer;

function doDeathCheck(?skipHealthCheck:Bool = false) {
	if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && gameOverTimer == null) {
		var ret:Dynamic = callOnScripts('onGameOver', null, true);
		if (ret != LuaUtils.Function_Stop) {
			FlxG.animationTimeScale = 1;
			boyfriend.stunned = true;
			deathCounter++;

			paused = true;
			canResync = false;
			canPause = false;
			#if VIDEOS_ALLOWED
			if (videoCutscene != null) {
				videoCutscene.destroy();
				videoCutscene = null;
			}
			#end

			persistentUpdate = false;
			persistentDraw = false;
			FlxTimer.globalManager.clear();
			FlxTween.globalManager.clear();
			FlxG.camera.setFilters([]);

			if (GameOverSubstate.deathDelay > 0) {
				gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_) {
					vocals.stop();
					opponentVocals.stop();
					FlxG.sound.music.stop();
					openSubState(new GameOverSubstate(boyfriend));
					gameOverTimer = null;
				});
			} else {
				vocals.stop();
				opponentVocals.stop();
				FlxG.sound.music.stop();
				openSubState(new GameOverSubstate(boyfriend));
			}

			// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if DISCORD_ALLOWED
			// Game Over doesn't get his its variable because it's only used here
			if (autoUpdateRPC)
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
			isDead = true;
			return true;
		}
	}
	return false;
}

function checkEventNote() {
	while (eventNotes.length > 0) {
		var leStrumTime:Float = eventNotes[0].strumTime;
		if (Conductor.songPosition < leStrumTime) {
			return;
		}

		var value1:String = '';
		if (eventNotes[0].value1 != null)
			value1 = eventNotes[0].value1;

		var value2:String = '';
		if (eventNotes[0].value2 != null)
			value2 = eventNotes[0].value2;

		triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
		eventNotes.shift();
	}
}

public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
	var flValue1:Null<Float> = Std.parseFloat(value1);
	var flValue2:Null<Float> = Std.parseFloat(value2);
	if (Math.isNaN(flValue1))
		flValue1 = null;
	if (Math.isNaN(flValue2))
		flValue2 = null;

	switch (eventName) {
		case 'Hey!':
			var value:Int = 2;
			switch (value1.toLowerCase().trim()) {
				case 'bf' | 'boyfriend' | '0':
					value = 0;
				case 'gf' | 'girlfriend' | '1':
					value = 1;
			}

			if (flValue2 == null || flValue2 <= 0)
				flValue2 = 0.6;

			if (value != 0) {
				if (dad.curCharacter.startsWith('gf')) { // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
					dad.playAnim('cheer', true);
					dad.specialAnim = true;
					dad.heyTimer = flValue2;
				} else if (gf != null) {
					gf.playAnim('cheer', true);
					gf.specialAnim = true;
					gf.heyTimer = flValue2;
				}
			}
			if (value != 1) {
				boyfriend.playAnim('hey', true);
				boyfriend.specialAnim = true;
				boyfriend.heyTimer = flValue2;
			}

		case 'Set GF Speed':
			if (flValue1 == null || flValue1 < 1)
				flValue1 = 1;
			gfSpeed = Math.round(flValue1);

		case 'Add Camera Zoom':
			if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
				if (flValue1 == null)
					flValue1 = 0.015;
				if (flValue2 == null)
					flValue2 = 0.03;

				FlxG.camera.zoom += flValue1;
				camHUD.zoom += flValue2;
			}

		case 'Play Animation':
			// trace('Anim to play: ' + value1);
			var char:Character = dad;
			switch (value2.toLowerCase().trim()) {
				case 'bf' | 'boyfriend':
					char = boyfriend;
				case 'gf' | 'girlfriend':
					char = gf;
				default:
					if (flValue2 == null)
						flValue2 = 0;
					switch (Math.round(flValue2)) {
						case 1: char = boyfriend;
						case 2: char = gf;
					}
			}

			if (char != null) {
				char.playAnim(value1, true);
				char.specialAnim = true;
			}

		case 'Camera Follow Pos':
			if (camFollow != null) {
				isCameraOnForcedPos = false;
				if (flValue1 != null || flValue2 != null) {
					isCameraOnForcedPos = true;
					if (flValue1 == null)
						flValue1 = 0;
					if (flValue2 == null)
						flValue2 = 0;
					camFollow.x = flValue1;
					camFollow.y = flValue2;
				}
			}

		case 'Alt Idle Animation':
			var char:Character = dad;
			switch (value1.toLowerCase().trim()) {
				case 'gf' | 'girlfriend':
					char = gf;
				case 'boyfriend' | 'bf':
					char = boyfriend;
				default:
					var val:Int = Std.parseInt(value1);
					if (Math.isNaN(val))
						val = 0;

					switch (val) {
						case 1: char = boyfriend;
						case 2: char = gf;
					}
			}

			if (char != null) {
				char.idleSuffix = value2;
				char.recalculateDanceIdle();
			}

		case 'Screen Shake':
			var valuesArray:Array<String> = [value1, value2];
			var targetsArray:Array<FlxCamera> = [camGame, camHUD];
			for (i in 0...targetsArray.length) {
				var split:Array<String> = valuesArray[i].split(',');
				var duration:Float = 0;
				var intensity:Float = 0;
				if (split[0] != null)
					duration = Std.parseFloat(split[0].trim());
				if (split[1] != null)
					intensity = Std.parseFloat(split[1].trim());
				if (Math.isNaN(duration))
					duration = 0;
				if (Math.isNaN(intensity))
					intensity = 0;

				if (duration > 0 && intensity != 0) {
					targetsArray[i].shake(intensity, duration);
				}
			}

		case 'Change Character':
			var charType:Int = 0;
			switch (value1.toLowerCase().trim()) {
				case 'gf' | 'girlfriend':
					charType = 2;
				case 'dad' | 'opponent':
					charType = 1;
				default:
					charType = Std.parseInt(value1);
					if (Math.isNaN(charType)) charType = 0;
			}

			switch (charType) {
				case 0:
					if (boyfriend.curCharacter != value2) {
						if (!boyfriendMap.exists(value2)) {
							addCharacterToList(value2, charType);
						}

						var lastAlpha:Float = boyfriend.alpha;
						boyfriend.alpha = 0.00001;
						boyfriend = boyfriendMap.get(value2);
						boyfriend.alpha = lastAlpha;
						iconP1.changeIcon(boyfriend.healthIcon);
					}
					setOnScripts('boyfriendName', boyfriend.curCharacter);

				case 1:
					if (dad.curCharacter != value2) {
						if (!dadMap.exists(value2)) {
							addCharacterToList(value2, charType);
						}

						var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
						var lastAlpha:Float = dad.alpha;
						dad.alpha = 0.00001;
						dad = dadMap.get(value2);
						if (!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
							if (wasGf && gf != null) {
								gf.visible = true;
							}
						} else if (gf != null) {
							gf.visible = false;
						}
						dad.alpha = lastAlpha;
						iconP2.changeIcon(dad.healthIcon);
					}
					setOnScripts('dadName', dad.curCharacter);

				case 2:
					if (gf != null) {
						if (gf.curCharacter != value2) {
							if (!gfMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = gf.alpha;
							gf.alpha = 0.00001;
							gf = gfMap.get(value2);
							gf.alpha = lastAlpha;
						}
						setOnScripts('gfName', gf.curCharacter);
					}
			}
			reloadHealthBarColors();

		case 'Change Scroll Speed':
			if (songSpeedType != "constant") {
				if (flValue1 == null)
					flValue1 = 1;
				if (flValue2 == null)
					flValue2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
				if (flValue2 <= 0)
					songSpeed = newValue;
				else
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							songSpeedTween = null;
						}
					});
			}

		case 'Set Property':
			try {
				var trueValue:Dynamic = value2.trim();
				if (trueValue == 'true' || trueValue == 'false')
					trueValue = trueValue == 'true';
				else if (flValue2 != null)
					trueValue = flValue2;
				else
					trueValue = value2;

				var split:Array<String> = value1.split('.');
				if (split.length > 1) {
					LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], trueValue);
				} else {
					LuaUtils.setVarInArray(this, value1, trueValue);
				}
			} catch (e:Dynamic) {
				var len:Int = e.message.indexOf('\n') + 1;
				if (len <= 0)
					len = e.message.length;
				#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
				addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
				#else
				FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
				#end
			}

		case 'Play Sound':
			if (flValue2 == null)
				flValue2 = 1;
			FlxG.sound.play(Paths.sound(value1), flValue2);
	}

	stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
	callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
}

public function moveCameraSection(?sec:Null<Int>):Void {
	if (sec == null)
		sec = curSection;
	if (sec < 0)
		sec = 0;

	if (SONG.notes[sec] == null)
		return;

	if (gf != null && SONG.notes[sec].gfSection) {
		moveCameraToGirlfriend();
		callOnScripts('onMoveCamera', ['gf']);
		return;
	}

	var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
	moveCamera(isDad);
	if (isDad)
		callOnScripts('onMoveCamera', ['dad']);
	else
		callOnScripts('onMoveCamera', ['boyfriend']);
}

public function moveCameraToGirlfriend() {
	camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
	camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
	camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
	tweenCamIn();
}

var cameraTwn:FlxTween;

public function moveCamera(isDad:Bool) {
	if (isDad) {
		if (dad == null)
			return;
		camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
		camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
		camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
		tweenCamIn();
	} else {
		if (boyfriend == null)
			return;
		camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
		camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
		camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}
}

function tweenCamIn() {
	if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
		cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
			ease: FlxEase.elasticInOut,
			onComplete: function(twn:FlxTween) {
				cameraTwn = null;
			}
		});
	}
}

public function finishSong(?ignoreNoteOffset:Bool = false):Void {
	updateTime = false;
	FlxG.sound.music.volume = 0;

	vocals.volume = 0;
	vocals.pause();
	opponentVocals.volume = 0;
	opponentVocals.pause();

	if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
		endCallback();
	} else {
		finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
			endCallback();
		});
	}
}

function coolCameraMove(i:Float, intensity:Int) {
	switch (i) {
		case 2:
			camFollow.y -= intensity;
		case 3:
			camFollow.x += intensity;
		case 1:
			camFollow.y += intensity;
		case 0:
			camFollow.x -= intensity;
	}
}

function killron():Void {
	dad.visible = false;
	camHUD.visible = false;
	var angyRonsip:FlxSprite = new FlxSprite(-1200, -100);
	angyRonsip.frames = Paths.getSparrowAtlas('sunset/happy/RON_dies_lmaoripbozo_packwatch', 'shared');
	angyRonsip.animation.addByIndices('idle', 'rip my boy ron', [0], '', 24, false);
	angyRonsip.animation.addByPrefix('die', 'rip my boy ron', 24, false);
	angyRonsip.animation.play('idle');

	add(angyRonsip);
	FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {
		ease: FlxEase.cubeOut
	});
	var cutsceneCam:FlxObject = new FlxObject(camFollow.x, camFollow.y, 1, 1);
	FlxG.camera.follow(cutsceneCam);
	FlxTween.tween(cutsceneCam, {x: 400.63, y: 500.94}, 1, {
		onComplete: function(tween:FlxTween) {
			new FlxTimer().start(0.45, function(tmr:FlxTimer) {
				angyRonsip.animation.play('die');
				new FlxTimer().start(0.1, function(tmr:FlxTimer) {
					FlxG.sound.play(Paths.sound('ronsip_diesonce'), 1);
					var scream = new FlxSound().loadEmbedded(Paths.sound('third_scream'));
					FlxG.sound.list.add(scream);
					scream.volume = 0.5;
					scream.fadeOut(2, 0);
					scream.play();
				});
				new FlxTimer().start(0.3, function(tmr:FlxTimer) {
					var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
					switch (songHighscore) {
						case 'Dad-Battle':
							songHighscore = 'Dadbattle';
						case 'Philly-Nice':
							songHighscore = 'Philly';
					}
					#if !switch
					Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
					#end
					persistentUpdate = false;
					persistentDraw = false;
					openSubState(new CoolSubstate());
				});
			});
		},
		ease: FlxEase.cubeOut
	});
}

public var transitioning = false;

public function endSong() {
	// Should kill you if you tried to cheat
	if (!startingSong) {
		notes.forEachAlive(function(daNote:Note) {
			if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				health -= 0.05 * healthLoss;
		});
		for (daNote in unspawnNotes) {
			if (daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
				health -= 0.05 * healthLoss;
		}

		if (doDeathCheck()) {
			return false;
		}
	}

	timeBar.visible = false;
	timeTxt.visible = false;
	canPause = false;
	endingSong = true;
	camZooming = false;
	inCutscene = false;
	updateTime = false;

	deathCounter = 0;
	seenCutscene = false;

	#if ACHIEVEMENTS_ALLOWED
	var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
	checkForAchievement([
		weekNoMiss,
		'ur_bad',
		'ur_good',
		'hype',
		'two_keys',
		'toastie'
		#if BASE_GAME_FILES, 'debugger'
		#end
	]);
	#end

	var ret:Dynamic = callOnScripts('onEndSong', null, true);
	if (ret != LuaUtils.Function_Stop && !transitioning) {
		#if !switch
		var percent:Float = ratingPercent;
		if (Math.isNaN(percent))
			percent = 0;
		Highscore.saveScore(Song.loadedSongName, songScore, storyDifficulty, percent);
		#end
		playbackRate = 1;

		if (chartingMode) {
			openChartEditor();
			return false;
		}

		if (isStoryMode) {
			campaignScore += songScore;
			campaignMisses += songMisses;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0) {
				Mods.loadTopMod();
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				#if DISCORD_ALLOWED
				DiscordClient.resetClientID();
				#end

				canResync = false;
				MusicBeatState.switchState(new StoryMenuState());

				// if ()
				if (!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
					StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
					Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

					FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
					FlxG.save.flush();
				}
				changedDifficulty = false;
			} else {
				var difficulty:String = Difficulty.getFilePath();

				trace('LOADING NEXT SONG');
				trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				canResync = false;
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new PlayState(), false, false);
			}
		} else {
			trace('WENT BACK TO FREEPLAY??');
			Mods.loadTopMod();
			#if DISCORD_ALLOWED
			DiscordClient.resetClientID();
			#end

			canResync = false;
			MusicBeatState.switchState(new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			changedDifficulty = false;
		}
		transitioning = true;
	}
	return true;
}

public function KillNotes() {
	while (notes.length > 0) {
		var daNote:Note = notes.members[0];
		daNote.active = false;
		daNote.visible = false;
		invalidateNote(daNote);
	}
	unspawnNotes = [];
	eventNotes = [];
}

var totalPlayed:Int = 0;
var totalNotesHit:Float = 0.0;
var showCombo:Bool = false;
var showComboNum:Bool = true;
var showRating:Bool = true;

// Stores Ratings and Combo Sprites in a group
var comboGroup:FlxSpriteGroup;

// Stores HUD Objects in a Group
var uiGroup:FlxSpriteGroup;

// Stores Note Objects in a Group
var noteGroup:FlxTypedGroup<FlxBasic>;

private function cachePopUpScore() {
	var uiFolder:String = "";
	if (stageUI != "normal")
		uiFolder = uiPrefix + "UI/";

	for (rating in ratingsData)
		Paths.image(uiFolder + rating.image + uiPostfix);
	for (i in 0...10)
		Paths.image(uiFolder + 'num' + i + uiPostfix);
}

private function popUpScore(note:Note = null):Void {
	var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
	vocals.volume = 1;

	if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0) {
		for (spr in comboGroup) {
			if (spr == null)
				continue;

			comboGroup.remove(spr);
			spr.destroy();
		}
	}

	var placement:Float = FlxG.width * 0.35;
	var rating:FlxSprite = new FlxSprite();
	var score:Int = 350;

	// tryna do MS based judgment due to popular demand
	var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

	totalNotesHit += daRating.ratingMod;
	note.ratingMod = daRating.ratingMod;
	if (!note.ratingDisabled)
		daRating.hits++;
	note.rating = daRating.name;
	score = daRating.score;

	if (daRating.noteSplash && !note.noteSplashData.disabled)
		spawnNoteSplashOnNote(note);

	if (!cpuControlled) {
		songScore += score;
		if (!note.ratingDisabled) {
			songHits++;
			totalPlayed++;
			RecalculateRating(false);
		}
	}

	var uiFolder:String = "";
	var antialias:Bool = ClientPrefs.data.antialiasing;
	if (stageUI != "normal") {
		uiFolder = uiPrefix + "UI/";
		antialias = !isPixelStage;
	}

	rating.loadGraphic(Paths.image(uiFolder + daRating.image + uiPostfix));
	rating.screenCenter();
	rating.x = placement - 40;
	rating.y -= 60;
	rating.acceleration.y = 550 * playbackRate * playbackRate;
	rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
	rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
	rating.visible = (!ClientPrefs.data.hideHud && showRating);
	rating.x += ClientPrefs.data.comboOffset[0];
	rating.y -= ClientPrefs.data.comboOffset[1];
	rating.antialiasing = antialias;

	var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
	comboSpr.screenCenter();
	comboSpr.x = placement;
	comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
	comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
	comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
	comboSpr.x += ClientPrefs.data.comboOffset[0];
	comboSpr.y -= ClientPrefs.data.comboOffset[1];
	comboSpr.antialiasing = antialias;
	comboSpr.y += 60;
	comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
	comboGroup.add(rating);

	if (!PlayState.isPixelStage) {
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
	} else {
		rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
	}

	comboSpr.updateHitbox();
	rating.updateHitbox();

	var daLoop:Int = 0;
	var xThing:Float = 0;
	if (showCombo)
		comboGroup.add(comboSpr);

	var separatedScore:String = Std.string(combo).lpad('0', 3);
	for (i in 0...separatedScore.length) {
		var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
		numScore.screenCenter();
		numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
		numScore.y += 80 - ClientPrefs.data.comboOffset[3];

		if (!PlayState.isPixelStage)
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
		else
			numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
		numScore.updateHitbox();

		numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
		numScore.visible = !ClientPrefs.data.hideHud;
		numScore.antialiasing = antialias;

		// if (combo >= 10 || combo == 0)
		if (showComboNum)
			comboGroup.add(numScore);

		FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween) {
				numScore.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});

		daLoop++;
		if (numScore.x > xThing)
			xThing = numScore.x;
	}
	comboSpr.x = xThing + 50;
	FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
		startDelay: Conductor.crochet * 0.001 / playbackRate
	});

	FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
		onComplete: function(tween:FlxTween) {
			comboSpr.destroy();
			rating.destroy();
		},
		startDelay: Conductor.crochet * 0.002 / playbackRate
	});
}

var strumsBlocked:Array<Bool> = [];

private function onKeyPress(event:KeyboardEvent):Void {
	var eventKey:FlxKey = event.keyCode;
	var key:Int = getKeyFromEvent(keysArray, eventKey);

	if (!controls.controllerMode) {
		#if debug
		// Prevents crash specifically on debug without needing to try catch shit
		@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey))
			return;
		#end

		if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
			keyPressed(key);
	}
}

private function keyPressed(key:Int) {
	if (cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned)
		return;

	var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
	if (ret == LuaUtils.Function_Stop)
		return;

	// more accurate hit time for the ratings?
	var lastTime:Float = Conductor.songPosition;
	if (Conductor.songPosition >= 0)
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

	// obtain notes that the player can hit
	var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
		var canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
		return canHit && !n.isSustainNote && n.noteData == key;
	});
	plrInputNotes.sort(sortHitNotes);

	if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
		var funnyNote:Note = plrInputNotes[0]; // front note

		if (plrInputNotes.length > 1) {
			var doubleNote:Note = plrInputNotes[1];

			if (doubleNote.noteData == funnyNote.noteData) {
				// if the note has a 0ms distance (is on top of the current note), kill it
				if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
					invalidateNote(doubleNote);
				else if (doubleNote.strumTime < funnyNote.strumTime) {
					// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
					funnyNote = doubleNote;
				}
			}
		}
		goodNoteHit(funnyNote);
	} else {
		if (ClientPrefs.data.ghostTapping)
			callOnScripts('onGhostTap', [key]);
		else
			noteMissPress(key);
	}

	// Needed for the  "Just the Two of Us" achievement.
	//									- Shadow Mario
	if (!keysPressed.contains(key))
		keysPressed.push(key);

	// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
	Conductor.songPosition = lastTime;

	var spr:StrumNote = playerStrums.members[key];
	if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm') {
		spr.playAnim('pressed');
		spr.resetAnim = 0;
	}
	callOnScripts('onKeyPress', [key]);
}

public static function sortHitNotes(a:Note, b:Note):Int {
	if (a.lowPriority && !b.lowPriority)
		return 1;
	else if (!a.lowPriority && b.lowPriority)
		return -1;

	return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
}

private function onKeyRelease(event:KeyboardEvent):Void {
	var eventKey:FlxKey = event.keyCode;
	var key:Int = getKeyFromEvent(keysArray, eventKey);
	if (!controls.controllerMode && key > -1)
		keyReleased(key);
}

private function keyReleased(key:Int) {
	if (cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length)
		return;

	var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
	if (ret == LuaUtils.Function_Stop)
		return;

	var spr:StrumNote = playerStrums.members[key];
	if (spr != null) {
		spr.playAnim('static');
		spr.resetAnim = 0;
	}
	callOnScripts('onKeyRelease', [key]);
}

public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int {
	if (key != NONE) {
		for (i in 0...arr.length) {
			var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
			for (noteKey in note)
				if (key == noteKey)
					return i;
		}
	}
	return -1;
}

// Hold notes
private function keysCheck():Void {
	// HOLDING
	var holdArray:Array<Bool> = [];
	var pressArray:Array<Bool> = [];
	var releaseArray:Array<Bool> = [];
	for (key in keysArray) {
		holdArray.push(controls.pressed(key));
		pressArray.push(controls.justPressed(key));
		releaseArray.push(controls.justReleased(key));
	}

	// TO DO: Find a better way to handle controller inputs, this should work for now
	if (controls.controllerMode && pressArray.contains(true))
		for (i in 0...pressArray.length)
			if (pressArray[i] && strumsBlocked[i] != true)
				keyPressed(i);

	if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic) {
		if (notes.length > 0) {
			for (n in notes) { // I can't do a filter here, that's kinda awesome
				var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

				if (guitarHeroSustains)
					canHit = canHit && n.parent != null && n.parent.wasGoodHit;

				if (canHit && n.isSustainNote) {
					var released:Bool = !holdArray[n.noteData];

					if (!released)
						goodNoteHit(n);
				}
			}
		}

		if (!holdArray.contains(true) || endingSong)
			playerDance();

		#if ACHIEVEMENTS_ALLOWED
		else
			checkForAchievement(['oversinging']);
		#end
	}

	// TO DO: Find a better way to handle controller inputs, this should work for now
	if ((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
		for (i in 0...releaseArray.length)
			if (releaseArray[i] || strumsBlocked[i] == true)
				keyReleased(i);
}

function noteMiss(daNote:Note):Void { // You didn't hit the key and let it go offscreen, also used by Hurt Notes
	// Dupe note remove
	notes.forEachAlive(function(note:Note) {
		if (daNote != note
			&& daNote.mustPress
			&& daNote.noteData == note.noteData
			&& daNote.isSustainNote == note.isSustainNote
			&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			invalidateNote(note);
	});

	noteMissCommon(daNote.noteData, daNote);
	stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
	var result:Dynamic = callOnLuas('noteMiss', [
		notes.members.indexOf(daNote),
		daNote.noteData,
		daNote.noteType,
		daNote.isSustainNote
	]);
	if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
		callOnHScript('noteMiss', [daNote]);
}

function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
{
	if (ClientPrefs.data.ghostTapping)
		return; // fuck it

	noteMissCommon(direction);
	FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
	callOnScripts('noteMissPress', [direction]);
}

function noteMissCommon(direction:Int, note:Note = null) {
	// score and data
	var subtract:Float = pressMissDamage;
	if (note != null)
		subtract = note.missHealth;

	// GUITAR HERO SUSTAIN CHECK LOL!!!!
	if (note != null && guitarHeroSustains && note.parent == null) {
		if (note.tail.length > 0) {
			note.alpha = 0.35;
			for (childNote in note.tail) {
				childNote.alpha = note.alpha;
				childNote.missed = true;
				childNote.canBeHit = false;
				childNote.ignoreNote = true;
				childNote.tooLate = true;
			}
			note.missed = true;
			note.canBeHit = false;

			// subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
			// i mean its fair :p -Crow
			subtract *= note.tail.length + 1;
			// i think it would be fair if damage multiplied based on how long the sustain is -[REDACTED]
		}

		if (note.missed)
			return;
	}
	if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
		if (note.missed)
			return;

		var parentNote:Note = note.parent;
		if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
			for (child in parentNote.tail)
				if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
		}
	}

	if (instakillOnMiss) {
		vocals.volume = 0;
		opponentVocals.volume = 0;
		doDeathCheck(true);
	}

	var lastCombo:Int = combo;
	combo = 0;

	health -= subtract * healthLoss;
	songScore -= 10;
	if (!endingSong)
		songMisses++;
	totalPlayed++;
	RecalculateRating(true);

	// play character anims
	var char:Character = boyfriend;
	if ((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection))
		char = gf;

	if (char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations) {
		var postfix:String = '';
		if (note != null)
			postfix = note.animSuffix;

		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, direction)))] + 'miss' + postfix;
		char.playAnim(animToPlay, true);

		if (char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad')) {
			gf.playAnim('sad');
			gf.specialAnim = true;
		}
	}
	vocals.volume = 0;
}

function opponentNoteHit(note:Note):Void {
	var result:Dynamic = callOnLuas('opponentNoteHitPre', [
		notes.members.indexOf(note),
		Math.abs(note.noteData),
		note.noteType,
		note.isSustainNote
	]);
	if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
		result = callOnHScript('opponentNoteHitPre', [note]);

	if (result == LuaUtils.Function_Stop)
		return;

	if (songName != 'tutorial')
		camZooming = true;

	if (note.noteType == 'Hey!' && dad.hasAnimation('hey')) {
		dad.playAnim('hey', true);
		dad.specialAnim = true;
		dad.heyTimer = 0.6;
	} else if (!note.noAnimation) {
		var char:Character = dad;
		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))] + note.animSuffix;
		if (note.gfNote)
			char = gf;

		if (char != null) {
			var canPlay:Bool = true;
			if (note.isSustainNote) {
				var holdAnim:String = animToPlay + '-hold';
				if (char.animation.exists(holdAnim))
					animToPlay = holdAnim;
				if (char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop')
					canPlay = false;
			}

			if (canPlay)
				char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}
	}

	if (opponentVocals.length <= 0)
		vocals.volume = 1;
	strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
	note.hitByOpponent = true;

	stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
	var result:Dynamic = callOnLuas('opponentNoteHit', [
		notes.members.indexOf(note),
		Math.abs(note.noteData),
		note.noteType,
		note.isSustainNote
	]);
	if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
		callOnHScript('opponentNoteHit', [note]);

	if (!note.isSustainNote)
		invalidateNote(note);
}

function goodNoteHit(note:Note):Void {
	if (note.wasGoodHit)
		return;
	if (cpuControlled && note.ignoreNote)
		return;

	var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
	var leData:Int = Math.round(Math.abs(note.noteData));
	var leType:String = note.noteType;

	var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
	if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
		result = callOnHScript('goodNoteHitPre', [note]);

	if (result == LuaUtils.Function_Stop)
		return;

	note.wasGoodHit = true;

	if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
		FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

	if (!note.hitCausesMiss) // Common notes
	{
		if (!note.noAnimation) {
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))] + note.animSuffix;

			var char:Character = boyfriend;
			var animCheck:String = 'hey';
			if (note.gfNote) {
				char = gf;
				animCheck = 'cheer';
			}

			if (char != null) {
				var canPlay:Bool = true;
				if (note.isSustainNote) {
					var holdAnim:String = animToPlay + '-hold';
					if (char.animation.exists(holdAnim))
						animToPlay = holdAnim;
					if (char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop')
						canPlay = false;
				}

				if (canPlay)
					char.playAnim(animToPlay, true);
				char.holdTimer = 0;

				if (note.noteType == 'Hey!') {
					if (char.hasAnimation(animCheck)) {
						char.playAnim(animCheck, true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
				}
			}
		}

		if (!cpuControlled) {
			var spr = playerStrums.members[note.noteData];
			if (spr != null)
				spr.playAnim('confirm', true);
		} else
			strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		vocals.volume = 1;

		if (!note.isSustainNote) {
			combo++;
			if (combo > 9999)
				combo = 9999;
			popUpScore(note);
		}
		var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
		if (guitarHeroSustains && note.isSustainNote)
			gainHealth = false;
		if (gainHealth)
			health += note.hitHealth * healthGain;
	} else // Notes that count as a miss if you hit them (Hurt notes for example)
	{
		if (!note.noMissAnimation) {
			switch (note.noteType) {
				case 'Hurt Note':
					if (boyfriend.hasAnimation('hurt')) {
						boyfriend.playAnim('hurt', true);
						boyfriend.specialAnim = true;
					}
			}
		}

		noteMiss(note);
		if (!note.noteSplashData.disabled && !note.isSustainNote)
			spawnNoteSplashOnNote(note);
	}

	stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
	var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
	if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
		callOnHScript('goodNoteHit', [note]);
	if (!note.isSustainNote)
		invalidateNote(note);
}

function invalidateNote(note:Note):Void {
	note.kill();
	notes.remove(note, true);
	note.destroy();
}

function spawnNoteSplashOnNote(note:Note) {
	if (note != null) {
		var strum:StrumNote = playerStrums.members[note.noteData];
		if (strum != null)
			spawnNoteSplash(strum.x, strum.y, note.noteData, note, strum);
	}
}

function spawnNoteSplash(x:Float = 0, y:Float = 0, ?data:Int = 0, ?note:Note, ?strum:StrumNote) {
	var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
	splash.babyArrow = strum;
	splash.spawnSplashNote(x, y, data, note);
	grpNoteSplashes.add(splash);
}

override function destroy() {
	if (psychlua.CustomSubstate.instance != null) {
		closeSubState();
		resetSubState();
	}

	#if LUA_ALLOWED
	for (lua in luaArray) {
		lua.call('onDestroy', []);
		lua.stop();
	}
	luaArray = null;
	FunkinLua.customFunctions.clear();
	#end

	#if HSCRIPT_ALLOWED
	for (script in hscriptArray)
		if (script != null) {
			if (script.exists('onDestroy'))
				script.call('onDestroy');
			script.destroy();
		}

	hscriptArray = null;
	#end
	stagesFunc(function(stage:BaseStage) stage.destroy());

	#if VIDEOS_ALLOWED
	if (videoCutscene != null) {
		videoCutscene.destroy();
		videoCutscene = null;
	}
	#end

	FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
	FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

	FlxG.camera.setFilters([]);

	#if FLX_PITCH
	FlxG.sound.music.pitch = 1;
	#end
	FlxG.animationTimeScale = 1;

	Note.globalRgbShaders = [];
	backend.NoteTypesConfig.clearNoteTypesData();

	NoteSplash.configs.clear();
	instance = null;
	super.destroy();
}

var lastStepHit:Int = -1;

override function stepHit() {
	super.stepHit();

	if (curStep == lastStepHit) {
		return;
	}

	lastStepHit = curStep;
	setOnScripts('curStep', curStep);
	callOnScripts('onStepHit');

	if (storyDifficulty != 3 && !FlxG.save.data.lowDetail) {
		if (curSong.toLowerCase() == 'split' && curStep == 124 && camZooming || curSong.toLowerCase() == 'split' && curStep == 126 && camZooming
			|| curSong.toLowerCase() == 'split' && curStep == 1144 && camZooming || curSong.toLowerCase() == 'split' && curStep == 1147 && camZooming
			|| curSong.toLowerCase() == 'split' && curStep == 1150 && camZooming) {
			FlxG.camera.zoom += 0.05;
			camHUD.zoom += 0.01;
		}
	}

	if (!FlxG.save.data.lowDetail)
		switch (SONG.song.toLowerCase()) {
			case 'ronald mcdonald slide':
				if (storyDifficulty != 3)
					switch (curStep) {
						case 1535:
							makeBackgroundTheVideo("assets/videos/space.webm");
					}
				else
					switch (curStep) {
						case 18:
							if (!FlxG.save.data.lowDetail) backgroundVideo("assets/videos/ronsip.webm");
						case 48:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;
						// assclap('bf');
						// shakeCam(0.05);
						case 64 | 324:
							if (!FlxG.save.data.lowDetail) {
								for (i in SAD) {
									i.alpha = 0;
									if (SAD.members.indexOf(i) == SADorder) {
										i.alpha = 1;
									}
								}
								SADorder++;
								if (SADorder > 3)
									SADorder = 0;
							}
						case 192:
							//	assclap(2,false);
							remove(dad);
							dad = new Character(100, 400, 'he-man');

							remove(gf);
							add(gf);
							add(dad);
							trace(dad);
						case 272:
							remove(dad);
							dad = new Character(100, 200, 'ronsip-ex');

							remove(gf);
							add(gf);
							add(dad);
						case 848:
							if (!FlxG.save.data.lowDetail) backgroundVideo("assets/videos/num.webm");
						case 863:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;
						case 1152:
							remove(blackscreentra);
							add(blackscreentra);
							blackscreentra.visible = true;
						case 1155:
							blackscreentra.visible = false;
						case 1157:
							blackscreentra.visible = true;
						case 1160:
							blackscreentra.visible = false;
						case 1323:
							remove(dad);
							dad = new Character(100, 200, 'ronsip-ex');

							remove(gf);
							add(gf);
							add(dad);
							iconP2Prefix = 'ronsip-ex';
							grpIcons.remove(iconP2);
							iconP2 = new HealthIcon('ronsip-ex', false);
							iconP2.y = healthBar.y - (iconP2.height / 2);
							iconP2.cameras = [camHUD];
							grpIcons.add(iconP2);
							trace(dad);
						case 1776:
							if (!FlxG.save.data.lowDetail) backgroundVideo("assets/videos/screen.webm");
						case 1904:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;

						case 2264 | 2328 | 2359:
							assclap('bf');
							shakeCam(0.02);
						case 2272 | 2338 | 2370:
							back('bf');
						case 2295:
							assclap('both');
							shakeCam(0.05);
						case 2304:
							back('both');
						case 2610:
							remove(dad);
							dad = new Character(100, 150, 'npesta');

							remove(gf);
							add(gf);
							add(dad);
					}
			case 'conscience':
				if (storyDifficulty == 3)
					switch (curStep) {
						case 1104:
							camGame.flash(FlxColor.WHITE, 0.7);
							if (!FlxG.save.data.lowDetail) {
								for (i in BW) {
									i.y -= FlxG.height * 2;
								}
								BWE = true;
							}

							remove(gf);
							gf = new Character(gf.x, gf.y, 'gf-bw');
							add(gf);
							dad.visible = false;
							dad2.visible = true;
							remove(boyfriend);
							boyfriend = new Character(boyfriend.x, boyfriend.y, 'bf-bw');
							add(boyfriend);
						case 1360:
							camGame.flash(FlxColor.BLACK, 0.7);
							for (i in BW) {
								i.y += FlxG.height * 2;
							}
							BWE = false;
							remove(gf);
							gf = new Character(gf.x, gf.y, 'gf-ex');
							add(gf);
							dad.visible = true;
							dad2.visible = false;
							remove(boyfriend);
							boyfriend = new Character(boyfriend.x, boyfriend.y, 'bf-ex-new');
							add(boyfriend);
					}
			case 'yap squad':
				if (storyDifficulty == 3) {
					switch (curStep) {
						case 415 | 423 | 441 | 456 | 651 | 774 | 943 | 974 | 1002 | 1036 | 1439 | 1451 | 1465 | 1679 | 1808:
							dad2.dance();
					}
				}
			case 'jump-out':
				if (storyDifficulty == 3)
					switch (curStep) {
						case 326:
							if (!FlxG.save.data.lowDetail) backgroundVideo("assets/videos/pizza.webm");
						case 347:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;
						case 686:
							if (!FlxG.save.data.lowDetail) backgroundVideo("assets/videos/TV static noise HD 1080p.webm");
						case 688:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;
							hellbg.visible = true;
							remove(dad);
							dad = new Character(-400, 380, 'boki');
							dad.y -= 200;
							remove(gf);
							add(gf);
							add(dad);
							defaultCamZoom = 0.6;
						case 812:
							if (!FlxG.save.data.lowDetail)
								backgroundVideo("assets/videos/TV static noise HD 1080p.webm");

							hellbg.visible = false;
						case 816:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;
							remove(dad);
							dad = new Character(100, 380, 'gloopy-ex');
							remove(gf);
							add(gf);
							add(dad);
							defaultCamZoom = 0.75;
						case 943:
							if (!FlxG.save.data.lowDetail) backgroundVideo("assets/videos/TV static noise HD 1080p.webm");
						case 944:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;
							hellcrab.visible = true;
							crabbg.visible = true;
						case 1072:
							// WaterMelon
							if (!FlxG.save.data.lowDetail) backgroundVideo("assets/videos/watermelon.webm");
						case 1088:
							if (!FlxG.save.data.lowDetail)
								BackgroundVideo.get().stop();

							FlxG.stage.window.onFocusOut.remove(focusOut);
							FlxG.stage.window.onFocusIn.remove(focusIn);
							PlayState.instance.remove(PlayState.instance.videoSprite);
							useVideo = false;
							hellcrab.visible = false;
							crabbg.visible = false;
						case 1195 | 1200 | 1202 | 1204 | 1208 | 1209 | 1210 | 1211:
							if (!FlxG.save.data.lowDetail) {
								for (i in SAD) {
									i.alpha = 0;
									if (SAD.members.indexOf(i) == SADorder) {
										i.alpha = 1;
									}
								}
								SADorder++;
								if (SADorder > 3)
									SADorder = 0;
							}
						case 1318:
							FlxTween.tween(boyfriend, {alpha: 0}, 0.1, {
								ease: FlxEase.cubeOut
							});
						case 1375:
							FlxTween.tween(boyfriend, {alpha: 1}, 0.1, {
								ease: FlxEase.cubeOut
							});
						case 1465:
							if (!FlxG.save.data.lowDetail) {
								for (i in SAD) {
									i.alpha = 0;
									if (SAD.members.indexOf(i) == SADorder) {
										i.alpha = 1;
									}
								}
								SADorder++;
								if (SADorder > 3)
									SADorder = 0;
							}
					}
		}
	// yes this updates every step.
	// yes this is bad
	// but i'm doing it to update misses and accuracy
	#if windows
	// Song duration in a float, useful for the time left feature
	songLength = FlxG.sound.music.length;

	// Updating Discord Rich Presence (with Time Left)
	DiscordClient.changePresence(detailsText
		+ " "
		+ SONG.song
		+ " ("
		+ storyDifficultyText
		+ ") "
		+ Ratings.GenerateLetterRank(accuracy),
		"Acc: "
		+ HelperFunctions.truncateFloat(accuracy, 2)
		+ "% | Score: "
		+ songScore
		+ " | Misses: "
		+ misses, iconRPC, true,
		songLength
		- Conductor.songPosition);
	#end
}

var lastBeatHit:Int = -1;

override function beatHit() {
	if (lastBeatHit >= curBeat) {
		// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
		return;
	}

	if (generatedMusic)
		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

	iconP1.scale.set(1.2, 1.2);
	iconP2.scale.set(1.2, 1.2);

	iconP1.updateHitbox();
	iconP2.updateHitbox();

	characterBopper(curBeat);

	super.beatHit();
	lastBeatHit = curBeat;

	setOnScripts('curBeat', curBeat);
	callOnScripts('onBeatHit');
}

function characterBopper(beat:Int):Void {
	if (gf != null
		&& beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
		&& !gf.getAnimationName().startsWith('sing')
		&& !gf.stunned)
		gf.dance();
	if (boyfriend != null
		&& beat % boyfriend.danceEveryNumBeats == 0
		&& !boyfriend.getAnimationName().startsWith('sing')
		&& !boyfriend.stunned)
		boyfriend.dance();
	if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
		dad.dance();
}

function playerDance():Void {
	var anim:String = boyfriend.getAnimationName();
	if (boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration
		&& anim.startsWith('sing') && !anim.endsWith('miss'))
		boyfriend.dance();
}

override function sectionHit() {
	if (SONG.notes[curSection] != null) {
		if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			moveCameraSection();

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms) {
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}

		if (SONG.notes[curSection].changeBPM) {
			Conductor.bpm = SONG.notes[curSection].bpm;
			setOnScripts('curBpm', Conductor.bpm);
			setOnScripts('crochet', Conductor.crochet);
			setOnScripts('stepCrochet', Conductor.stepCrochet);
		}
		setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
		setOnScripts('altAnim', SONG.notes[curSection].altAnim);
		setOnScripts('gfSection', SONG.notes[curSection].gfSection);
	}
	super.sectionHit();

	setOnScripts('curSection', curSection);
	callOnScripts('onSectionHit');
}

#if LUA_ALLOWED
function startLuasNamed(luaFile:String) {
	#if MODS_ALLOWED
	var luaToLoad:String = Paths.modFolders(luaFile);
	if (!FileSystem.exists(luaToLoad))
		luaToLoad = Paths.getSharedPath(luaFile);

	if (FileSystem.exists(luaToLoad))
	#elseif sys
	var luaToLoad:String = Paths.getSharedPath(luaFile);
	if (OpenFlAssets.exists(luaToLoad))
	#end
	{
		for (script in luaArray)
			if (script.scriptName == luaToLoad)
				return false;

		new FunkinLua(luaToLoad);
		return true;
	}
	return false;
}
#end

#if HSCRIPT_ALLOWED
public function startHScriptsNamed(scriptFile:String) {
	#if MODS_ALLOWED
	var scriptToLoad:String = Paths.modFolders(scriptFile);
	if (!FileSystem.exists(scriptToLoad))
		scriptToLoad = Paths.getSharedPath(scriptFile);
	#else
	var scriptToLoad:String = Paths.getSharedPath(scriptFile);
	#end

	if (FileSystem.exists(scriptToLoad)) {
		if (Iris.instances.exists(scriptToLoad))
			return false;

		initHScript(scriptToLoad);
		return true;
	}
	return false;
}

public function initHScript(file:String) {
	var newScript:HScript = null;
	try {
		newScript = new HScript(null, file);
		if (newScript.exists('onCreate'))
			newScript.call('onCreate');
		trace('initialized hscript interp successfully: $file');
		hscriptArray.push(newScript);
	} catch (e:IrisError) {
		var pos:HScriptInfos = cast {fileName: file, showLine: false};
		Iris.error(Printer.errorToString(e, false), pos);
		var newScript:HScript = cast(Iris.instances.get(file), HScript);
		if (newScript != null)
			newScript.destroy();
	}
}
#end

public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic {
	var returnVal:Dynamic = LuaUtils.Function_Continue;
	if (args == null)
		args = [];
	if (exclusions == null)
		exclusions = [];
	if (excludeValues == null)
		excludeValues = [LuaUtils.Function_Continue];

	var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
	if (result == null || excludeValues.contains(result))
		result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
	return result;
}

public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic {
	var returnVal:Dynamic = LuaUtils.Function_Continue;
	#if LUA_ALLOWED
	if (args == null)
		args = [];
	if (exclusions == null)
		exclusions = [];
	if (excludeValues == null)
		excludeValues = [LuaUtils.Function_Continue];

	var arr:Array<FunkinLua> = [];
	for (script in luaArray) {
		if (script.closed) {
			arr.push(script);
			continue;
		}

		if (exclusions.contains(script.scriptName))
			continue;

		var myValue:Dynamic = script.call(funcToCall, args);
		if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
			&& !excludeValues.contains(myValue)
			&& !ignoreStops) {
			returnVal = myValue;
			break;
		}

		if (myValue != null && !excludeValues.contains(myValue))
			returnVal = myValue;

		if (script.closed)
			arr.push(script);
	}

	if (arr.length > 0)
		for (script in arr)
			luaArray.remove(script);
	#end
	return returnVal;
}

public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic {
	var returnVal:Dynamic = LuaUtils.Function_Continue;

	#if HSCRIPT_ALLOWED
	if (exclusions == null)
		exclusions = new Array();
	if (excludeValues == null)
		excludeValues = new Array();
	excludeValues.push(LuaUtils.Function_Continue);

	var len:Int = hscriptArray.length;
	if (len < 1)
		return returnVal;

	for (script in hscriptArray) {
		@:privateAccess
		if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
			continue;

		var callValue = script.call(funcToCall, args);
		if (callValue != null) {
			var myValue:Dynamic = callValue.returnValue;

			if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
				&& !excludeValues.contains(myValue)
				&& !ignoreStops) {
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;
		}
	}
	#end

	return returnVal;
}

public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
	if (exclusions == null)
		exclusions = [];
	setOnLuas(variable, arg, exclusions);
	setOnHScript(variable, arg, exclusions);
}

public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
	#if LUA_ALLOWED
	if (exclusions == null)
		exclusions = [];
	for (script in luaArray) {
		if (exclusions.contains(script.scriptName))
			continue;

		script.set(variable, arg);
	}
	#end
}

public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
	#if HSCRIPT_ALLOWED
	if (exclusions == null)
		exclusions = [];
	for (script in hscriptArray) {
		if (exclusions.contains(script.origin))
			continue;

		script.set(variable, arg);
	}
	#end
}

function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
	var spr:StrumNote = null;
	if (isDad) {
		spr = opponentStrums.members[id];
	} else {
		spr = playerStrums.members[id];
	}

	if (spr != null) {
		spr.playAnim('confirm', true);
		spr.resetAnim = time;
	}
}

public var ratingName:String = '?';
public var ratingPercent:Float;
public var ratingFC:String;

public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true) {
	setOnScripts('score', songScore);
	setOnScripts('misses', songMisses);
	setOnScripts('hits', songHits);
	setOnScripts('combo', combo);

	var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
	if (ret != LuaUtils.Function_Stop) {
		ratingName = '?';
		if (totalPlayed != 0) // Prevent divide by 0
		{
			// Rating Percent
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
			// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

			// Rating Name
			ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
			if (ratingPercent < 1)
				for (i in 0...ratingStuff.length - 1)
					if (ratingPercent < ratingStuff[i][1]) {
						ratingName = ratingStuff[i][0];
						break;
					}
		}
		fullComboFunction();
	}
	setOnScripts('rating', ratingPercent);
	setOnScripts('ratingName', ratingName);
	setOnScripts('ratingFC', ratingFC);
	setOnScripts('totalPlayed', totalPlayed);
	setOnScripts('totalNotesHit', totalNotesHit);
	updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
}

#if ACHIEVEMENTS_ALLOWED
private function checkForAchievement(achievesToCheck:Array<String> = null) {
	if (chartingMode)
		return;

	var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
	if (cpuControlled)
		return;

	for (name in achievesToCheck) {
		if (!Achievements.exists(name))
			continue;

		var unlock:Bool = false;
		if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
		{
			switch (name) {
				case 'ur_bad':
					unlock = (ratingPercent < 0.2 && !practiceMode);

				case 'ur_good':
					unlock = (ratingPercent >= 1 && !usedPractice);

				case 'oversinging':
					unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

				case 'hype':
					unlock = (!boyfriendIdled && !usedPractice);

				case 'two_keys':
					unlock = (!usedPractice && keysPressed.length <= 2);

				case 'toastie':
					unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

				#if BASE_GAME_FILES
				case 'debugger':
					unlock = (songName == 'test' && !usedPractice);
				#end
			}
		} else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
		{
			if (isStoryMode
				&& campaignMisses + songMisses < 1
				&& Difficulty.getString().toUpperCase() == 'HARD'
				&& storyPlaylist.length <= 1
				&& !changedDifficulty
				&& !usedPractice)
				unlock = true;
		}

		if (unlock)
			Achievements.unlock(name);
	}
}
#end

#if (!flash && sys)
var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
#end

function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader {
	#if (!flash && sys)
	if (!ClientPrefs.data.shaders)
		return new ErrorHandledRuntimeShader(shaderName);

	if (!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName)) {
		FlxG.log.warn('Shader $shaderName is missing!');
		return new ErrorHandledRuntimeShader(shaderName);
	}

	var arr:Array<String> = runtimeShaders.get(shaderName);
	return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
	#else
	FlxG.log.warn("Platform unsupported for Runtime Shaders!");
	return null;
	#end
}

function initLuaShader(name:String, ?glslVersion:Int = 120) {
	if (!ClientPrefs.data.shaders)
		return false;

	#if (!flash && sys)
	if (runtimeShaders.exists(name)) {
		FlxG.log.warn('Shader $name was already initialized!');
		return true;
	}

	for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/')) {
		var frag:String = folder + name + '.frag';
		var vert:String = folder + name + '.vert';
		var found:Bool = false;
		if (FileSystem.exists(frag)) {
			frag = File.getContent(frag);
			found = true;
		} else
			frag = null;

		if (FileSystem.exists(vert)) {
			vert = File.getContent(vert);
			found = true;
		} else
			vert = null;

		if (found) {
			runtimeShaders.set(name, [frag, vert]);
			// trace('Found shader $name!');
			return true;
		}
	}
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
	#else
	FlxG.log.warn('Missing shader $name .frag AND .vert files!');
	#end
	#else
	FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
	#end
	return false;
}

var fastCarCanDrive:Bool = true;

function resetFastCar():Void {
	if (FlxG.save.data.distractions) {
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}
}

function fastCarDrive() {
	if (FlxG.save.data.distractions) {
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer) {
			resetFastCar();
		});
	}
}

var trainMoving:Bool = false;
var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainFinishing:Bool = false;
var trainCooldown:Int = 0;

function trainStart():Void {
	if (FlxG.save.data.distractions) {
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}
}

var startedMoving:Bool = false;

function updateTrainPos():Void {
	if (FlxG.save.data.distractions) {
		if (trainSound.time >= 4700) {
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving) {
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing) {
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}
}

function trainReset():Void {
	if (FlxG.save.data.distractions) {
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}
}

function lightningStrikeShit():Void {
	FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
	halloweenBG.animation.play('lightning');

	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);

	boyfriend.playAnim('scared', true);
	gf.playAnim('scared', true);
}

function assclap(characters:String):Void {
	if (characters == 'ron') {
		dad.alpha = 0;
		ass.setGraphicSize(Std.int(dad.width * 0.7));
		ass.animation.play('trans');
		remove(gf);
		add(gf);
		trace('dad' + ass);
		add(ass);
	} else if (characters == 'bf') {
		boyfriend.alpha = 0;
		assbf.alpha = 1;
		assbf.animation.play('trans');
		trace(assbf);
		remove(gf);
		add(gf);
		add(assbf);
	} else if (characters == 'both') {
		dad.alpha = 0;
		ass.setGraphicSize(Std.int(dad.width * 0.7));
		ass.animation.play('trans');
		boyfriend.alpha = 0;
		assbf.alpha = 1;
		assbf.animation.play('trans');
		remove(gf);
		add(gf);
		add(assbf);
		add(ass);
	}
}

function shakeCam(magnitude:Float):Void {
	FlxG.camera.shake(magnitude);
	camHUD.shake(magnitude);
}

function back(characters:String):Void {
	if (characters == 'bf') {
		dad.alpha = 1;
		boyfriend.alpha = 1;
		assbf.alpha = 0;
	} else if (characters == 'ron') {
		dad.alpha = 1;
		boyfriend.alpha = 1;
		ass.alpha = 0;
	} else if (characters == 'both') {
		dad.alpha = 1;
		boyfriend.alpha = 1;
		ass.alpha = 0;
		assbf.alpha = 0;
	}
}
}

