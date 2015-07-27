define(['Utils/Utils', 'Utils/Global', 'Utils/FontManager', 'Loader', 'Socket', 'City', 'Rasterizers/RasterizerManager', 'UI/Sidebar', 'UI/Code', 'UI/Modal', 'UI/AlertManager', 'UI/Controllers/ControllerManager', 'Commands/CommandManager', 'View/View', 'Tools/ToolManager'], function(Utils, Global, FontManager, Loader, Socket, City, RasterizerManager, Sidebar, FileManager, Modal, AlertManager, ControllerManager, CommandManager, View, ToolManager) {
  console.log('Arthur-test-account speaking! again again');

  /*
  	 * Romanesco documentation #
  
  	Romanesco is an experiment about freedom, creativity and collaboration.
  
  	tododoc
  	tododoc: define RItems
  
  	The source code is divided in files:
  	 - [main.coffee](http://main.html) which is where the initialization
  	 - [path.coffee](http://path.html)
  	 - etc
  
  	Notations:
  	 - override means that the method extends functionnalities of the inherited method (super is called at some point)
  	 - redefine means that it totally replace the method (super is never called)
   */
  $(document).ready(function() {
    R.catchErrors = false;
    R.ignoreSockets = false;
    R.currentPaths = {};
    R.paths = new Object();
    R.items = new Object();
    R.locks = [];
    R.divs = [];
    R.sortedPaths = [];
    R.sortedDivs = [];
    R.animatedItems = [];
    R.cars = {};
    R.currentDiv = null;
    R.selectedItems = [];
    R.socket = new Socket();
    R.sidebar = new Sidebar();
    R.view = new View();
    R.loader = new Loader();
    R.alertManager = new AlertManager();
    R.controllerManager = new ControllerManager();
    R.controllerManager.createGlobalControllers();
    R.rasterizerManager = new RasterizerManager();
    R.rasterizerManager.initializeRasterizers();
    R.commandManager = new CommandManager();
    R.toolManager = new ToolManager();
    R.fileManager = new FileManager();
    R.fontManager = new FontManager();
    R.view.initializePosition();
    R.sidebar.initialize();
    if (typeof window.setPageFullyLoaded === "function") {
      window.setPageFullyLoaded(true);
    }
  });
  R.showCodeEditor = function(fileNode) {
    if (R.codeEditor == null) {
      require(['UI/Editor'], function(CodeEditor) {
        R.codeEditor = new CodeEditor();
        if (fileNode) {
          R.codeEditor.setFile(fileNode);
        }
        R.codeEditor.open();
      });
    } else {
      if (fileNode) {
        R.codeEditor.setFile(fileNode);
      }
      R.codeEditor.open();
    }
  };
});
