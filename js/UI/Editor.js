var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['coffee', 'typeahead'], function(CoffeeScript) {
  var CodeEditor, Console;
  CodeEditor = (function() {
    function CodeEditor() {
      this.changeDifference = __bind(this.changeDifference, this);
      this.onDifferenceChange = __bind(this.onDifferenceChange, this);
      this.onCopyFile = __bind(this.onCopyFile, this);
      this.onNextDifference = __bind(this.onNextDifference, this);
      this.onPreviousDifference = __bind(this.onPreviousDifference, this);
      this.updateCurrentDifference = __bind(this.updateCurrentDifference, this);
      this.aceDiffLoaded = __bind(this.aceDiffLoaded, this);
      this.save = __bind(this.save, this);
      this.onChange = __bind(this.onChange, this);
      this.runFile = __bind(this.runFile, this);
      this.onLoadLinkedFile = __bind(this.onLoadLinkedFile, this);
      this.readLinkedFile = __bind(this.readLinkedFile, this);
      this.close = __bind(this.close, this);
      this.onMouseUp = __bind(this.onMouseUp, this);
      this.resize = __bind(this.resize, this);
      this.setFullSize = __bind(this.setFullSize, this);
      this.setHalfSize = __bind(this.setHalfSize, this);
      this.onHandleDown = __bind(this.onHandleDown, this);
      this.nextCommand = __bind(this.nextCommand, this);
      this.previousCommand = __bind(this.previousCommand, this);
      this.executeCommand = __bind(this.executeCommand, this);
      var closeBtnJ, handleJ, runBtnJ;
      this.mode = 'coding';
      this.editorJ = $("#codeEditor");
      this.editorJ.bind("transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", this.resize);
      if (R.sidebar.sidebarJ.hasClass("r-hidden")) {
        this.editorJ.addClass("r-hidden");
      }
      handleJ = this.editorJ.find(".editor-handle");
      handleJ.mousedown(this.onHandleDown);
      handleJ.find('.handle-left').click(this.setHalfSize);
      handleJ.find('.handle-right').click(this.setFullSize);
      this.fileNameJ = this.editorJ.find(".header .fileName input");
      this.linkFileInputJ = this.editorJ.find("input.link-file");
      this.linkFileInputJ.change(this.linkFile);
      closeBtnJ = this.editorJ.find("button.close-editor");
      closeBtnJ.click(this.close);
      this.codeJ = this.editorJ.find(".code");
      this.diffJ = this.editorJ.find(".acediff");
      this.codeJ.show();
      this.diffJ.hide();
      this.footerJ = this.editorJ.find(".footer");
      this.diffFooterJ = this.footerJ.find('.diff');
      this.diffFooterJ.hide();
      runBtnJ = this.editorJ.find("button.submit.run");
      runBtnJ.click(this.runFile);
      this.console = new Console(this);
      return;
    }

    CodeEditor.prototype.initializeEditor = function(callback, args) {
      this.initialized = false;
      require(['ace/ace'], (function(_this) {
        return function(ace) {
          _this.aceLoaded(ace);
          callback.apply(_this, args);
        };
      })(this));
    };

    CodeEditor.prototype.aceLoaded = function(ace) {
      this.editor = ace.edit(this.codeJ[0]);
      this.editor.$blockScrolling = Infinity;
      this.editor.setOptions({
        enableBasicAutocompletion: true,
        enableSnippets: true,
        enableLiveAutocompletion: false
      });
      ace.config.set("packaged", true);
      ace.config.set("basePath", require.toUrl("ace"));
      this.editor.setTheme("ace/theme/monokai");
      this.editor.getSession().setUseSoftTabs(false);
      this.editor.getSession().setMode("ace/mode/coffee");
      this.editor.getSession().setValue("class NewPath extends R.PrecisePath\n  @label = 'NewPath'\n  @description = \"A fancy path.\"\n\n  drawBegin: ()->\n\n    @initializeDrawing(false)\n\n    @path = @addPath()\n    return\n\n  drawUpdateStep: (length)->\n\n    point = @controlPath.getPointAt(length)\n    @path.add(point)\n    return\n\n  drawEnd: ()->\n    return\n", 1);
      this.editor.commands.addCommand({
        name: 'execute',
        bindKey: {
          win: 'Ctrl-Shift-Enter',
          mac: 'Command-Shift-Enter',
          sender: 'editor|cli'
        },
        exec: this.runFile
      });
      this.editor.commands.addCommand({
        name: 'execute-command',
        bindKey: {
          win: 'Ctrl-Enter',
          mac: 'Command-Enter',
          sender: 'editor|cli'
        },
        exec: this.executeCommand
      });
      this.editor.commands.addCommand({
        name: 'previous-command',
        bindKey: {
          win: 'Ctrl-Up',
          mac: 'Command-Up',
          sender: 'editor|cli'
        },
        exec: this.previousCommand
      });
      this.editor.commands.addCommand({
        name: 'next-command',
        bindKey: {
          win: 'Ctrl-Down',
          mac: 'Command-Down',
          sender: 'editor|cli'
        },
        exec: this.nextCommand
      });
      this.initialized = true;
    };


    /* set mode (coding or diffing) */

    CodeEditor.prototype.setMode = function(mode) {
      this.mode = mode;
      switch (this.mode) {
        case 'diffing':
          this.codeJ.hide();
          this.diffJ.show();
          this.diffFooterJ.show();
          this.console.hide();
          this.setFullSize();
          break;
        case 'coding':
          this.codeJ.show();
          this.diffJ.hide();
          this.diffFooterJ.hide();
          this.console.show();
          R.fileManager.closeDiffing(this.allDifferencesValidated());
      }
    };


    /* commande manager in console mode */

    CodeEditor.prototype.addCommand = function(command) {
      this.commandQueue.push(command);
      if (this.commandQueue.length > this.MAX_COMMANDS) {
        this.commandQueue.shift();
      }
      this.commandIndex = this.commandQueue.length;
    };

    CodeEditor.prototype.executeCommand = function(env, args, request) {
      var command;
      command = this.editor.getValue();
      if (command.length === 0) {
        return;
      }
      this.addCommand(command);
      this.runFile();
      this.editor.setValue('');
    };

    CodeEditor.prototype.previousCommand = function(env, args, request) {
      var command, cursorPosition;
      cursorPosition = this.editor.getCursorPosition();
      if (cursorPosition.row === 0 && cursorPosition.column === 0) {
        if (this.commandIndex === this.commandQueue.length) {
          command = this.editor.getValue();
          if (command.length > 0) {
            this.addCommand(command);
            this.commandIndex--;
          }
        }
        if (this.commandIndex > 0) {
          this.commandIndex--;
          this.editor.setValue(this.commandQueue[this.commandIndex]);
        }
      } else {
        this.editor.gotoLine(0, 0);
      }
    };

    CodeEditor.prototype.nextCommand = function(env, args, request) {
      var cursorPosition, lastColumn, lastRow;
      cursorPosition = this.editor.getCursorPosition();
      lastRow = this.editor.getSession().getLength() - 1;
      lastColumn = this.editor.getSession().getLine(lastRow).length;
      if (cursorPosition.row === lastRow && cursorPosition.column === lastColumn) {
        if (this.commandIndex < this.commandQueue.length - 1) {
          this.commandIndex++;
          this.editor.setValue(this.commandQueue[this.commandIndex]);
        }
      } else {
        this.editor.gotoLine(lastRow + 1, lastColumn + 1);
      }
    };


    /* mouse interaction */

    CodeEditor.prototype.onHandleDown = function() {
      this.draggingEditor = true;
      $("body").css({
        'user-select': 'none'
      });
    };

    CodeEditor.prototype.setHalfSize = function() {
      this.editorJ.css({
        right: '50%'
      });
      this.resize();
    };

    CodeEditor.prototype.setFullSize = function() {
      this.editorJ.css({
        right: 0
      });
      this.resize();
    };

    CodeEditor.prototype.resize = function() {
      this.editor.resize();
    };

    CodeEditor.prototype.onMouseMove = function(event) {
      if (this.draggingEditor) {
        this.editorJ.css({
          right: Math.max(0, window.innerWidth - event.pageX)
        });
      }
      this.console.onMouseMove(event);
    };

    CodeEditor.prototype.onMouseUp = function(event) {
      var _ref;
      if (this.draggingEditor) {
        if ((_ref = this.editor) != null) {
          _ref.resize();
        }
      }
      this.draggingEditor = false;
      this.console.onMouseUp(event);
      $("body").css({
        'user-select': 'text'
      });
    };


    /* open close */

    CodeEditor.prototype.open = function() {
      this.editorJ.show();
      this.editorJ.addClass('visible');
      this.console.setNativeLogs();
    };

    CodeEditor.prototype.close = function() {
      this.editorJ.hide();
      this.editorJ.removeClass('visible');
      this.console.resetNativeLogs();
    };


    /* file linker */

    CodeEditor.prototype.linkFile = function(evt) {
      var files, _ref, _ref1;
      evt.stopPropagation();
      evt.preventDefault();
      if (this.linkFileInputJ.hasClass('link-file')) {
        this.linkFileInputJ.removeClass('link-file').addClass('unlink-file');
        this.editorJ.find('span.glyphicon-floppy-open').removeClass('glyphicon-floppy-open').addClass('glyphicon-floppy-remove');
        this.linkFileInputJ.hide();
        this.editorJ.find('button.link-file').on('click', this.linkFile);
        files = ((_ref = evt.dataTransfer) != null ? _ref.files : void 0) || ((_ref1 = evt.target) != null ? _ref1.files : void 0);
        this.linkedFile = files[0];
        this.fileReader = new FileReader();
        this.lookForChangesInterval = setInterval(this.readFile, 1000);
      } else if (this.linkFileInputJ.hasClass('unlink-file')) {
        this.linkFileInputJ.removeClass('unlink-file').addClass('link-file');
        this.editorJ.find('span.glyphicon-floppy-remove').removeClass('glyphicon-floppy-remove').addClass('glyphicon-floppy-open');
        this.linkFileInputJ.show();
        this.editorJ.find('button.link-file').off('click', this.linkFile);
        clearInterval(this.lookForChangesInterval);
        this.fileReader = null;
        this.linkedFile = null;
        this.readFile = null;
      }
    };

    CodeEditor.prototype.readLinkedFile = function() {
      this.fileReader.readAsText(this.linkedFile);
    };

    CodeEditor.prototype.onLoadLinkedFile = function() {
      this.editor.getSession().setValue(event.target.result);
    };


    /* set, compile and run scripts */

    CodeEditor.prototype.clearFile = function(closeEditor) {
      if (closeEditor == null) {
        closeEditor = true;
      }
      this.setFile(null);
      if (closeEditor) {
        this.close();
      }
    };

    CodeEditor.prototype.setFile = function(node) {
      var _ref;
      R.codeEditor.open();
      this.fileNameJ.val(node.name);
      if (this.mode === 'coding') {
        this.node = node;
        this.setSource((node != null ? (_ref = node.file) != null ? _ref.content : void 0 : void 0) || '');
      } else if (this.mode === 'diffing') {
        this.setDifferenceFromNode(node);
      }
    };

    CodeEditor.prototype.setSource = function(source) {
      if (!this.initialized) {
        return this.initializeEditor(this.setSource, [source]);
      }
      this.editor.getSession().off('change', this.onChange);
      this.editor.getSession().setValue(source);
      this.editor.getSession().on('change', this.onChange);
    };

    CodeEditor.prototype.compile = function(source) {
      var errorMessage, location, message;
      if (source == null) {
        source = this.editor.getValue();
      }
      try {
        return CoffeeScript.compile(source, {
          bare: true
        });
      } catch (_error) {
        location = _error.location, message = _error.message;
        if (location != null) {
          errorMessage = "Error on line " + (location.first_line + 1) + ": " + message;
          if (message === "unmatched OUTDENT") {
            errorMessage += "\nThis error is generally due to indention problem or unbalanced parenthesis/brackets/braces.";
          }
        }
        console.error(errorMessage);
        return null;
      }
    };

    CodeEditor.prototype.run = function(script) {
      var error, result;
      try {
        result = eval(script);
        console.log(result);
      } catch (_error) {
        error = _error;
        console.error(error);
        throw error;
        return null;
      }
      return script;
    };

    CodeEditor.prototype.define = function(modulesNames, f) {
      var args, module, moduleName, _i, _len;
      args = [];
      for (_i = 0, _len = modulesNames.length; _i < _len; _i++) {
        moduleName = modulesNames[_i];
        module = modules[moduleName];
        if (module == null) {
          R.alertManager.alert('module ' + moduleName + ' does not exist.');
        }
        args.push(module);
      }
      f.apply(window, args);
    };

    CodeEditor.prototype.runFile = function() {
      var code, js, modules, requirejsDefine, _ref, _ref1, _ref2;
      if ((typeof require !== "undefined" && require !== null ? (_ref = require.s) != null ? (_ref1 = _ref.contexts) != null ? (_ref2 = _ref1._) != null ? _ref2.defined : void 0 : void 0 : void 0 : void 0) == null) {
        R.alertManager.alert('requirejs not loaded?');
        return;
      }
      code = this.editor.getValue();
      js = this.compile(code);
      if (!js) {
        return;
      }
      if (this.mode === 'coding' && (this.node != null)) {
        R.fileManager.updateFile(this.node, code, js);
      }
      requirejsDefine = window.define;
      modules = require.s.contexts._.defined;
      window.define = this.define;
      this.run(js);
      window.define = requirejsDefine;
    };

    CodeEditor.prototype.onChange = function() {
      if (this.node != null) {
        Utils.deferredExecution(R.codeEditor.save, 'save:' + this.node.path);
      }
    };

    CodeEditor.prototype.save = function() {
      if (this.node != null) {
        R.fileManager.updateFile(this.node, this.editor.getValue());
      }
    };

    CodeEditor.messages = {
      fileDoesNotExist: {
        onMainRepository: '# The file does not exist on the main repository',
        onFork: '# The file does not exist on the fork'
      }
    };

    CodeEditor.prototype.initializeDifferenceValidation = function(differences) {
      this.differences = differences;
      if (!this.initialized) {
        return this.initializeEditor(this.initializeDifferenceValidation, [this.differences]);
      }
      require(['aceDiff'], this.aceDiffLoaded);
    };

    CodeEditor.prototype.aceDiffLoaded = function(AceDiff) {
      var closeDiffingBtnJ;
      this.diffJ.find('.left-repository-name').text(R.fileManager.differenceOwner === 'arthursw' ? 'Main repository' : R.fileManager.differenceOwner);
      this.diffJ.find('.right-repository-name').text(R.fileManager.owner === 'arthursw' ? 'Main repository' : R.fileManager.owner);
      this.open();
      this.setMode('diffing');
      if (!this.differenceInitialized) {
        closeDiffingBtnJ = this.diffJ.find('button.close-diffing');
        closeDiffingBtnJ.click((function(_this) {
          return function() {
            return _this.setMode('coding');
          };
        })(this));
        this.previousBtnJ = this.diffFooterJ.find('button.previous');
        this.nextBtnJ = this.diffFooterJ.find('button.next');
        this.copyMainBtnJ = this.diffFooterJ.find('button.copy-main');
        this.previousBtnJ.click(this.onPreviousDifference);
        this.nextBtnJ.click(this.onNextDifference);
        this.copyMainBtnJ.click(this.onCopyFile);
        this.aceDiff = new AceDiff({
          mode: "ace/mode/coffee",
          theme: "ace/theme/monokai",
          right: {
            copyLinkEnabled: false
          },
          left: {
            editable: false
          }
        });
        this.differenceInitialized = true;
      }
      this.allDifferencesValidatedMessageDisplayed = false;
      this.setCurrentDifference(0);
    };

    CodeEditor.prototype.setCurrentDifference = function(i) {
      this.currentDifference = Utils.clamp(0, i, this.differences.length - 1);
      this.updateCurrentDifference();
    };

    CodeEditor.prototype.allDifferencesValidated = function() {
      var difference, _i, _len, _ref;
      if (this.differences == null) {
        true;
      }
      _ref = this.differences;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        difference = _ref[_i];
        if (!difference.checked) {
          return false;
        }
      }
      return true;
    };

    CodeEditor.prototype.updateCurrentDifference = function() {
      var difference, leftEditor, rightEditor, _ref, _ref1;
      difference = this.differences[this.currentDifference];
      if ((difference.main != null) && (difference.main.content == null)) {
        R.loader.showLoadingBar();
        $(difference.main).one('loaded', this.updateCurrentDifference);
        return;
      }
      if ((difference.fork != null) && (difference.fork.content == null)) {
        R.loader.showLoadingBar();
        $(difference.fork).one('loaded', this.updateCurrentDifference);
        return;
      }
      R.loader.hideLoadingBar();
      difference.checked = true;
      if (difference.main == null) {
        this.copyMainBtnJ.find('.text').text("Delete file on fork");
      } else if (difference.fork == null) {
        this.copyMainBtnJ.find('.text').text("Create file on fork");
      } else {
        this.copyMainBtnJ.find('.text').text("Replace file on this fork");
      }
      if (this.currentDifference <= 0) {
        this.previousBtnJ.addClass("disabled");
      } else {
        this.previousBtnJ.removeClass("disabled");
      }
      if (this.currentDifference >= this.differences.length - 1) {
        this.nextBtnJ.addClass("disabled");
      } else {
        this.nextBtnJ.removeClass("disabled");
      }
      rightEditor = this.aceDiff.getEditors().right.getSession();
      leftEditor = this.aceDiff.getEditors().left.getSession();
      rightEditor.off('change', this.onDifferenceChange);
      leftEditor.setValue(((_ref = difference.main) != null ? _ref.content : void 0) || this.constructor.messages.fileDoesNotExist.onMainRepository);
      rightEditor.setValue(((_ref1 = difference.fork) != null ? _ref1.content : void 0) || this.constructor.messages.fileDoesNotExist.onFork);
      rightEditor.on('change', this.onDifferenceChange);
      this.fileNameJ.val(R.fileManager.getFileName(difference.fork || difference.main));
      if (this.allDifferencesValidated() && !this.allDifferencesValidatedMessageDisplayed) {
        this.allDifferencesValidatedMessageDisplayed = true;
        R.alertManager.alert('You can now create your pull request.', 'success');
      }
    };

    CodeEditor.prototype.setDifferenceFromNode = function(node) {
      var difference, i, _i, _len, _ref;
      _ref = this.differences;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        difference = _ref[i];
        if (difference.fork === node.file) {
          this.setCurrentDifference(i);
          return;
        }
      }
      R.alertManager.alert('This file does not differ.', 'warning');
    };

    CodeEditor.prototype.onPreviousDifference = function() {
      this.setCurrentDifference(--this.currentDifference);
    };

    CodeEditor.prototype.onNextDifference = function() {
      this.setCurrentDifference(++this.currentDifference);
    };

    CodeEditor.prototype.onCopyFile = function() {
      var _ref;
      this.aceDiff.getEditors().right.setValue((_ref = this.differences[this.currentDifference].main) != null ? _ref.content : void 0);
    };

    CodeEditor.prototype.onDifferenceChange = function() {
      Utils.deferredExecution(this.changeDifference, 'changeDifference');
    };

    CodeEditor.prototype.changeDifference = function() {
      var content;
      content = this.aceDiff.getEditors().right.getValue();
      if (content === this.constructor.messages.fileDoesNotExist.onFork) {
        content = null;
      }
      R.fileManager.changeDifference(this.differences[this.currentDifference], content);
    };

    CodeEditor.prototype.finishDifferenceValidation = function() {
      var difference, i, _i, _len, _ref;
      _ref = this.differences;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        difference = _ref[i];
        if (!difference.checked) {
          R.alertManager.alert('You have not validated a difference.', 'warning');
          this.setCurrentDifference(i);
          return false;
        } else {
          $(difference.fork.element).removeClass('difference');
        }
      }
      this.setMode('coding');
      return true;
    };

    return CodeEditor;

  })();
  Console = (function() {
    function Console(codeEditor) {
      var consoleHandleJ;
      this.codeEditor = codeEditor;
      this.onMouseUp = __bind(this.onMouseUp, this);
      this.onConsoleHandleDown = __bind(this.onConsoleHandleDown, this);
      this.toggle = __bind(this.toggle, this);
      this.consoleJ = this.codeEditor.editorJ.find(".console");
      this.consoleContentJ = this.consoleJ.find(".content");
      consoleHandleJ = this.codeEditor.editorJ.find(".console-handle");
      this.consoleToggleBtnJ = consoleHandleJ.find(".close");
      this.consoleToggleBtnJ.click(this.toggle);
      consoleHandleJ.mousedown(this.onConsoleHandleDown);
      this.height = 200;
      return;
    }

    Console.prototype.show = function() {
      this.consoleJ.show();
    };

    Console.prototype.hide = function() {
      this.consoleJ.hide();
    };

    Console.prototype.close = function(height) {
      if (height == null) {
        height = null;
      }
      this.height = height || this.consoleJ.height();
      this.consoleJ.css({
        height: 0
      }).addClass('closed');
      this.consoleToggleBtnJ.find('.glyphicon').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-up');
      this.codeEditor.resize();
    };

    Console.prototype.open = function(consoleHeight) {
      if (consoleHeight == null) {
        consoleHeight = null;
      }
      if (this.consoleJ.hasClass('closed')) {
        this.consoleJ.removeClass("highlight");
        this.consoleJ.css({
          height: consoleHeight || this.consoleHeight
        }).removeClass('closed');
        this.consoleToggleBtnJ.find('.glyphicon').removeClass('glyphicon-chevron-up').addClass('glyphicon-chevron-down');
        this.codeEditor.resize();
      }
    };

    Console.prototype.toggle = function() {
      if (this.consoleJ.hasClass('closed')) {
        this.open();
      } else {
        this.close();
      }
    };


    /* mouse interaction */

    Console.prototype.onConsoleHandleDown = function() {
      this.draggingConsole = true;
      $("body").css({
        'user-select': 'none'
      });
    };

    Console.prototype.onMouseMove = function(event) {
      var bottom, footerHeight, height, minHeight;
      if (this.draggingConsole) {
        footerHeight = this.codeEditor.footerJ.outerHeight();
        bottom = this.codeEditor.editorJ.outerHeight() - footerHeight;
        height = Math.min(bottom - event.pageY, window.innerHeight - footerHeight);
        this.consoleJ.css({
          height: height
        });
        minHeight = 20;
        if (this.consoleJ.hasClass('closed')) {
          if (height > minHeight) {
            this.open(height);
          }
        } else {
          if (height <= minHeight) {
            this.close(200);
          }
        }
      }
    };

    Console.prototype.onMouseUp = function(event) {
      if (this.draggingConsole) {
        this.codeEditor.editor.resize();
      }
      this.draggingConsole = false;
    };


    /* log functions */

    Console.prototype.logMessage = function(message) {
      this.nativeLog(message);
      if (typeof message !== 'string' || !message instanceof String) {
        message = JSON.stringify(message);
      }
      this.consoleContentJ.append($("<p>").append(message));
      this.consoleContentJ.scrollTop(this.consoleContentJ[0].scrollHeight);
      if (this.consoleJ.hasClass("closed")) {
        this.consoleJ.addClass("highlight");
      }
    };

    Console.prototype.logError = function(message) {
      this.nativeError(message);
      this.consoleContentJ.append($("<p>").append(message).addClass("error"));
      this.consoleContentJ.scrollTop(this.consoleContentJ[0].scrollHeight);
      this.openConsole();
      message = "An error occured, you can open the debug console (Command + Option + I)";
      message += " to have more information about the problem.";
      R.alertManager.alert(message, "info");
    };

    Console.prototype.setNativeLogs = function() {
      this.nativeLog = console.log;
      this.nativeError = console.error;
    };

    Console.prototype.resetNativeLogs = function() {
      console.log = this.nativeLog;
      console.error = this.nativeError;
    };

    return Console;

  })();
  return CodeEditor;
});
