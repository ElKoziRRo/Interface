package bhvr.controller
{
	import flash.events.EventDispatcher;
	import flash.display.MovieClip;
	import bhvr.views.CustomCursor;
	import bhvr.states.GameState;
	import bhvr.states.PauseState;
	import bhvr.states.ConfirmQuitState;
	import bhvr.data.GamePersistantData;
	import bhvr.states.TitleState;
	import bhvr.states.GameLevelState;
	import bhvr.states.ResultState;
	import bhvr.states.GameOverState;
	import bhvr.debug.Log;
	import bhvr.events.EventWithParams;
	import bhvr.constatnts.GameConfig;
	import bhvr.events.GameEvents;
	
	public class StateController extends EventDispatcher
	{
		
		public static const CONFIRM_QUIT:int = -3;
		
		public static const PAUSE:int = -2;
		
		public static const NOT_STARTED:int = -1;
		
		public static const TITLE:int = 0;
		
		public static const LEVEL:int = 1;
		
		public static const RESULT:int = 2;
		
		public static const GAME_OVER:int = 3;
		
		public static const NUMBER_OF_STATES:int = 4;
		 
		
		public var BGSCodeObj:Object;
		
		private var _assets:MovieClip;
		
		private var _cursor:CustomCursor;
		
		private var _states:Vector.<GameState>;
		
		private var _pauseState:PauseState;
		
		private var _confirmQuitState:ConfirmQuitState;
		
		private var _statesReadyNum:int;
		
		private var _currentState:int;
		
		public function StateController(assets:MovieClip, cursor:CustomCursor)
		{
			super();
			this._assets = assets;
			this._cursor = cursor;
			this._states = new Vector.<GameState>();
			this._currentState = NOT_STARTED;
		}
		
		public function initialize() : void
		{
			this._statesReadyNum = 0;
			for(var i:uint = 0; i < NUMBER_OF_STATES; i++)
			{
				this._states.push(this.createState(i));
				this._states[i].BGSCodeObj = this.BGSCodeObj;
				this._states[i].addEventListener(GameState.STATE_CREATED,this.onStateCreated,false,0,true);
				this._states[i].addEventListener(GameState.NAV_CONTINUE,this.onContinue,false,0,true);
				this._states[i].addEventListener(GameState.NAV_BACK,this.onBack,false,0,true);
				this._states[i].addEventListener(GameState.TUTORIAL_REQUESTED,this.onTutorialRequested,false,0,true);
				this._states[i].initialize();
			}
			this._pauseState = this.createState(PAUSE) as PauseState;
			this._pauseState.addEventListener(GameState.STATE_CREATED,this.onStateCreated,false,0,true);
			this._pauseState.addEventListener(PauseState.READY_TO_RESUME,this.onResume,false,0,true);
			this._pauseState.initialize();
			this._confirmQuitState = this.createState(CONFIRM_QUIT) as ConfirmQuitState;
			this._confirmQuitState.addEventListener(GameState.STATE_CREATED,this.onStateCreated,false,0,true);
			this._confirmQuitState.addEventListener(ConfirmQuitState.QUIT,this.onQuitConfirmed,false,0,true);
			this._confirmQuitState.addEventListener(ConfirmQuitState.CANCEL,this.onQuitCancelled,false,0,true);
			this._confirmQuitState.initialize();
			GamePersistantData.reset();
		}
		
		private function createState(state:int) : GameState
		{
			var pauseState:PauseState = null;
			var confirmQuitState:ConfirmQuitState = null;
			var titleState:TitleState = null;
			var gameLevelState:GameLevelState = null;
			var resultState:ResultState = null;
			var gameOverState:GameOverState = null;
			switch(state)
			{
				case PAUSE:
					pauseState = new PauseState(state,this._assets.pauseStateMc);
					return pauseState;
				case CONFIRM_QUIT:
					confirmQuitState = new ConfirmQuitState(state,this._assets.genericPopupMc);
					return confirmQuitState;
				case TITLE:
					titleState = new TitleState(state,this._assets.titleStateMc);
					return titleState;
				case LEVEL:
					gameLevelState = new GameLevelState(state,this._assets.gameLevelStateMc,this._cursor);
					return gameLevelState;
				case RESULT:
					resultState = new ResultState(state,this._assets.resultStateMc);
					return resultState;
				case GAME_OVER:
					gameOverState = new GameOverState(state,this._assets.gameOverStateMc);
					return gameOverState;
				default:
					Log.error("StateController: state " + state + " can\'t be created cause it doesn\'t exist");
					return new GameState(state,null);
			}
		}
		
		private function enterState(state:int) : void
		{
			if(this._currentState != NOT_STARTED)
			{
				this.exitState(this._currentState);
			}
			this._states[state].enter();
			this._currentState = state;
		}
		
		private function exitState(state:int) : void
		{
			this._states[state].exit();
		}
		
		private function onStateCreated(e:EventWithParams) : void
		{
			Log.info("StateController: state " + e.params.target.id + " is ready.");
			this._statesReadyNum++;
			if(this._statesReadyNum == NUMBER_OF_STATES + 2)
			{
				this.enterState(GameConfig.STARTING_STATE);
			}
		}
		
		private function onContinue(e:EventWithParams) : void
		{
			var nextState:int = 0;
			var target:GameState = e.params.target;
			switch(target.id)
			{
				case TITLE:
					this.enterState(LEVEL);
					break;
				case LEVEL:
					nextState = e.params.status == GameEvents.GAME_LEVEL_UP?int(RESULT):int(GAME_OVER);
					this.enterState(nextState);
					break;
				case RESULT:
					GamePersistantData.proceedNextLevel();
					this.enterState(LEVEL);
					break;
				case GAME_OVER:
					GamePersistantData.reset();
					this.enterState(TITLE);
			}
		}
		
		private function onBack(e:EventWithParams) : void
		{
		}
		
		private function onTutorialRequested(e:EventWithParams) : void
		{
			dispatchEvent(e);
		}
		
		private function onResume(e:EventWithParams) : void
		{
			if(this._states != null && this._currentState != NOT_STARTED)
			{
				this._states[this._currentState].Pause(false);
				dispatchEvent(e);
			}
		}
		
		private function onQuitConfirmed(e:EventWithParams) : void
		{
			dispatchEvent(e);
		}
		
		private function onQuitCancelled(e:EventWithParams) : void
		{
			if(this._confirmQuitState != null)
			{
				this._confirmQuitState.exit();
			}
			dispatchEvent(e);
			if(this._pauseState != null)
			{
				this._pauseState.enter();
				if(this._currentState == LEVEL)
				{
					this._pauseState.startExit();
				}
				else
				{
					this._pauseState.exit();
				}
			}
		}
		
		public function dispose() : void
		{
			var gameState:GameState = null;
			for(var i:uint = 0; i < this._states.length; i++)
			{
				gameState = this._states[i];
				gameState.removeEventListener(GameState.STATE_CREATED,this.onStateCreated);
				gameState.removeEventListener(GameState.NAV_CONTINUE,this.onContinue);
				gameState.removeEventListener(GameState.NAV_BACK,this.onBack);
				gameState.removeEventListener(GameState.TUTORIAL_REQUESTED,this.onTutorialRequested);
				gameState.dispose();
			}
			this.BGSCodeObj = null;
		}
		
		public function Pause(paused:Boolean) : void
		{
			if(this._pauseState != null && (this._confirmQuitState == null || !this._confirmQuitState.isActive))
			{
				if(paused)
				{
					if(this._states != null && this._currentState != NOT_STARTED)
					{
						this._states[this._currentState].Pause(paused);
					}
					if(this._currentState == LEVEL)
					{
						this._pauseState.enter();
					}
				}
				else if(this._currentState == LEVEL)
				{
					this._pauseState.startExit();
				}
				else
				{
					this.onResume(new EventWithParams(PauseState.READY_TO_RESUME));
				}
			}
		}
		
		public function ConfirmQuit() : void
		{
			if(this._confirmQuitState != null)
			{
				if(this._states != null)
				{
					if(this._pauseState != null && this._pauseState.isActive)
					{
						this._pauseState.cancel();
					}
					else if(this._currentState != NOT_STARTED)
					{
						this._states[this._currentState].Pause(true);
					}
				}
				this._confirmQuitState.enter();
			}
		}
	}
}