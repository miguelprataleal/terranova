package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.registerClassAlias;
	import flash.text.TextField;
	
	import fl.containers.UILoader;
	import fl.controls.Button;
	import fl.controls.List;
	import fl.controls.TextInput;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.Strong;

	public class Menu
	{
		private var _sharedObject : SharedObject;
		private var inputDialog : InputDialog;
		
		private var _musicaBackground : Sound;
		private var _soundChannel : SoundChannel;
		
		private var _main : MovieClip;
		private var _container : MovieClip;
		
		private var _settingsButton : UILoader;
		
		public function Menu(main : MovieClip)
		{
			_main = main;
			_container = new MovieClip();

			_musicaBackground = new Sound();
			_musicaBackground.load(new URLRequest("media/musica/Heart_of_Machine.mp3"));
			_soundChannel = _musicaBackground.play();
			_main.gotoAndStop(1);

			
			registerClassAlias("Jogador", Jogador);

			initSharedObject();
			init();
		}
		

		
		private function init() : void {
			SettingsPanel.loadSettings();
			
			var title : TextField = new TextField();
			title.width = 640;
			title.defaultTextFormat = Pretty.TITLE_1;
			
			title.text = "TERRA NOVA";
			
			title.x = 0;
			title.y = 20;
			_container.addChild(title);

			var novoJogoButton : Button = new Button();
			novoJogoButton.label = "Novo Jogo";
			novoJogoButton.setStyle("textFormat", Pretty.BODY_BOLD);
			novoJogoButton.width = 170;
			novoJogoButton.height = 40;
			novoJogoButton.x = _main.stage.stageWidth/2 - novoJogoButton.width/2;
			novoJogoButton.y = 200;
			novoJogoButton.addEventListener(MouseEvent.CLICK, novoJogo);
			_container.addChild(novoJogoButton);
			
			
			
			var carregarJogoButton : Button = new Button();
			carregarJogoButton.label = "Carregar Jogo";
			carregarJogoButton.setStyle("textFormat", Pretty.BODY_BOLD);
			carregarJogoButton.width = 170;
			carregarJogoButton.height = 40;
			carregarJogoButton.x = _main.stage.stageWidth/2 - carregarJogoButton.width/2;
			carregarJogoButton.y = 260;
			_container.addChild(carregarJogoButton);
			carregarJogoButton.addEventListener(MouseEvent.CLICK, carregaJogoButtonClicked);

			_settingsButton = new UILoader;
			_settingsButton.source = "media/menu/menu2_32.png";
			_settingsButton.scaleContent = false;
			_settingsButton.x = 15;
			_settingsButton.y = _main.stage.stageHeight - 32 - 15;
			_settingsButton.addEventListener(MouseEvent.CLICK, settings);
			_settingsButton.addEventListener(MouseEvent.MOUSE_OVER, overButton);
			_settingsButton.addEventListener(MouseEvent.MOUSE_OUT, outButton);

			_container.addChild(_settingsButton);
			
			
			_main.addChild(_container);
			
			

			
		}
		
		public function initSharedObject() {
			_sharedObject = SharedObject.getLocal("TerraNovaSaved");

			// se array de jogadores ainda nao tiver sido instanciado em disco, instancializa aqui
			// se esta condição nao fosse adicionada, o jogo iria apagar informação previamente gravada
			// numa sessao anterior
			if (_sharedObject.data.jogadores == null)
				_sharedObject.data.jogadores = new Vector.<Jogador>();
		}
		
		public function novoJogo(e : MouseEvent) {
			
			inputDialog = new InputDialog(_main, "Escreve aqui o teu nome:");
			inputDialog.okButton.addEventListener(MouseEvent.CLICK, okInput);
			inputDialog.cancelarButton.addEventListener(MouseEvent.CLICK, cancelaInput);

			
			_container.filters= [ new BlurFilter(10, 10, BitmapFilterQuality.HIGH) ];
			_main.addChild(inputDialog);
		}
		
		
		
		public function okInput (e : MouseEvent) {
			var jogadorErrado : TextField = new TextField();
			jogadorErrado.defaultTextFormat = Pretty.ERRO;
			jogadorErrado.x =  inputDialog.inputText.x;
			jogadorErrado.y = inputDialog.inputText.y + inputDialog.inputText.height + 1;
			jogadorErrado.width = inputDialog.inputText.width;
			jogadorErrado.height = 18;

			jogadorErrado.text = "Nome de Jogador inválido ou já existente.";
			jogadorErrado.visible = false;
			inputDialog.addChild(jogadorErrado);
			
			if (inputDialog.inputText.text == "") {
				jogadorErrado.visible = true;
			}
			else {
				var encontrado : Boolean = false;
				for (var i : uint = 0; i < _sharedObject.data.jogadores.length && !encontrado; i++) {
					if (inputDialog.inputText.text == _sharedObject.data.jogadores[i].nome)
						encontrado = true;
				}
				
				if (encontrado) {
					trace("JOGADOR JA EXISTE");
					jogadorErrado.visible = true;
				}
				else {
					trace("JOGADOR VALIDO");
					var novoJogador : Jogador = new Jogador(inputDialog.inputText.text, new Vector.<uint>);
					// ALTERAR
					// deep copy do jogador para ficheiro
					_sharedObject.data.jogadores.push(new Jogador(novoJogador.nome, new Vector.<uint>));
					_sharedObject.flush();
					/////////////
					
					_soundChannel.stop();
					new Niveis(_main, novoJogador);
					_container.filters= [];
					_main.removeChild(inputDialog);
					_main.removeChild(_container);
					
					
				}
			}
		}
		
		
		public function cancelaInput (e : MouseEvent) {
			
			_main.removeChild(e.target.parent);
			_container.filters= [];
			
			
		}
		
		/**
		 * 
		 */
		public function carregaJogoButtonClicked(e : MouseEvent) {
			
			// lista nomes de jogadores em cache
			var loadDialog : LoadDialog = new LoadDialog(this._main);
			
			for (var i : uint = 0; i < _sharedObject.data.jogadores.length; i++) {
				loadDialog.list.addItem({label: _sharedObject.data.jogadores[i].nome, data: i});
			}
			
			loadDialog.list.addEventListener(Event.CHANGE, loadJogador); 
			
			_container.filters= [ new BlurFilter(10, 10, BitmapFilterQuality.HIGH) ];
			_main.addChild(loadDialog);
			voltarButton(loadDialog);


			
		}
		
		/**
		 * Carregga jogador
		 */
		public function loadJogador(e : Event) {
			e.target.removeEventListener(Event.CHANGE, loadJogador);
			_container.filters= [];

			var novoJogador : Jogador = new Jogador(_sharedObject.data.jogadores[e.target.selectedItem.data].nome, _sharedObject.data.jogadores[e.target.selectedItem.data].temposMaximos);

			_soundChannel.stop();
			new Niveis(_main, novoJogador);
			
			_main.removeChild(e.target.parent);
			_main.removeChild(_container);
			
		}
		
		
		public function settings(e : MouseEvent) {
			_settingsButton.alpha = 1;
			_settingsButton.removeEventListener(MouseEvent.CLICK, settings);
			_settingsButton.removeEventListener(MouseEvent.MOUSE_OVER, overButton);
			_settingsButton.removeEventListener(MouseEvent.MOUSE_OUT, outButton);
			
			_container.filters= [ new BlurFilter(10, 10, BitmapFilterQuality.HIGH) ];

			var settingsPanel : SettingsPanel = new SettingsPanel(this._main, this);
			voltarButton(settingsPanel);

		}
		
		public function voltarButton(screen : MovieClip) {
			var voltarButton : UILoader = new UILoader();
			voltarButton.maintainAspectRatio = true;
			voltarButton.scaleContent = false;
			voltarButton.source = "media/header/backArrow_20.png";
			voltarButton.x = -40;
			voltarButton.y = 10;
			voltarButton.addEventListener(MouseEvent.CLICK, voltarButtonClick);
			voltarButton.addEventListener(MouseEvent.MOUSE_OVER, overButton);
			voltarButton.addEventListener(MouseEvent.MOUSE_OUT, outButton);
			screen.addChild(voltarButton);
			
			new Tween(voltarButton, "x", Strong.easeInOut, -40, 10, 0.25, true);
			voltarButton.addEventListener(MouseEvent.CLICK, voltarButtonClick);
			_main.addChild(screen);
		}
		
		private function voltarButtonClick (e : MouseEvent) {
			_settingsButton.addEventListener(MouseEvent.CLICK, settings);
			_settingsButton.addEventListener(MouseEvent.MOUSE_OVER, overButton);
			_settingsButton.addEventListener(MouseEvent.MOUSE_OUT, outButton);
			
			var tween : Tween = new Tween(e.currentTarget, "x", Strong.easeInOut, 10, -40, 0.25, true);
			tween.addEventListener(TweenEvent.MOTION_FINISH, tweenFinish);
			

			
		}
		
		private function overButton (e : MouseEvent) {
			e.currentTarget.alpha = 0.8;
		}
		
		private function outButton (e : MouseEvent) {
			e.currentTarget.alpha = 1;
		}
		
		
		private function tweenFinish (e : TweenEvent) {
			_main.removeChild(e.currentTarget.obj.parent);
			_container.filters= [];
		}
		
		

		
		
		/******************************************************
		 * GETTERS & SETTERS
		 ******************************************************/
		
		public function get main():MovieClip
		{
			return _main;
		}
		
		public function set main(value:MovieClip):void
		{
			_main = value;
		}
		
		public function get sharedObject():SharedObject
		{
			return _sharedObject;
		}
		
		public function set sharedObject(value:SharedObject):void
		{
			_sharedObject = value;
		}

		
		

	}
}