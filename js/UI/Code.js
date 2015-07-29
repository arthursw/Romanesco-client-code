var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['UI/Modal', 'coffee', 'spin', 'jqtree', 'typeahead'], function(Modal, CoffeeScript, Spinner) {
  var FileManager;
  FileManager = (function() {
    function FileManager() {
      this.registerModuleInModuleLoader = __bind(this.registerModuleInModuleLoader, this);
      this.checkCommit = __bind(this.checkCommit, this);
      this.updateHead = __bind(this.updateHead, this);
      this.createCommit = __bind(this.createCommit, this);
      this.commitChanges = __bind(this.commitChanges, this);
      this.readTree = __bind(this.readTree, this);
      this.checkIfTreeExists = __bind(this.checkIfTreeExists, this);
      this.getTreeAndSetCommit = __bind(this.getTreeAndSetCommit, this);
      this.getTree = __bind(this.getTree, this);
      this.onNodeClicked = __bind(this.onNodeClicked, this);
      this.onCreateLi = __bind(this.onCreateLi, this);
      this.diffing = __bind(this.diffing, this);
      this.checkPullRequest = __bind(this.checkPullRequest, this);
      this.createPullRequestSubmit = __bind(this.createPullRequestSubmit, this);
      this.initializeDifferenceValidation = __bind(this.initializeDifferenceValidation, this);
      this.getTreeAndInitializeDifference = __bind(this.getTreeAndInitializeDifference, this);
      this.getMasterBranchForDifferenceValidation = __bind(this.getMasterBranchForDifferenceValidation, this);
      this.createPullRequest = __bind(this.createPullRequest, this);
      this.onUndoChanges = __bind(this.onUndoChanges, this);
      this.undoChanges = __bind(this.undoChanges, this);
      this.onCommitClicked = __bind(this.onCommitClicked, this);
      this.runFork = __bind(this.runFork, this);
      this.runLastCommit = __bind(this.runLastCommit, this);
      this.onDeleteFile = __bind(this.onDeleteFile, this);
      this.confirmDeleteFile = __bind(this.confirmDeleteFile, this);
      this.onNodeDoubleClicked = __bind(this.onNodeDoubleClicked, this);
      this.submitNewName = __bind(this.submitNewName, this);
      this.onFileMove = __bind(this.onFileMove, this);
      this.onCreateDirectory = __bind(this.onCreateDirectory, this);
      this.onCreateFile = __bind(this.onCreateFile, this);
      this.openFile = __bind(this.openFile, this);
      this.createFork = __bind(this.createFork, this);
      this.forkCreationResponse = __bind(this.forkCreationResponse, this);
      this.loadCustomFork = __bind(this.loadCustomFork, this);
      this.loadFork = __bind(this.loadFork, this);
      this.loadOwnFork = __bind(this.loadOwnFork, this);
      this.loadMainRepository = __bind(this.loadMainRepository, this);
      this.listForks = __bind(this.listForks, this);
      this.displayForks = __bind(this.displayForks, this);
      this.forkRowClicked = __bind(this.forkRowClicked, this);
      this.checkHasForkCallback = __bind(this.checkHasForkCallback, this);
      this.displayDesiredFile = __bind(this.displayDesiredFile, this);
      this.queryDesiredFile = __bind(this.queryDesiredFile, this);
      var createDirectoryBtnJ, createFileBtnJ, diffingBtnJ, listForksBtnJ, loadCustomForkBtnJ, runBtnJ, _ref;
      R.githubLogin = R.canvasJ.attr("data-github-login");
      this.codeJ = $('#Code');
      this.scrollbarJ = this.codeJ.find('.mCustomScrollbar');
      this.runForkBtnJ = this.codeJ.find('button.run-fork');
      this.loadOwnForkBtnJ = this.codeJ.find('li.user-fork');
      listForksBtnJ = this.codeJ.find('li.list-forks');
      this.loadMainRepositoryBtnJ = this.codeJ.find('li.main-repository');
      loadCustomForkBtnJ = this.codeJ.find('li.custom-fork');
      this.createForkBtnJ = this.codeJ.find('li.create-fork');
      diffingBtnJ = this.codeJ.find('.diffing');
      this.loadOwnForkBtnJ.hide();
      this.createForkBtnJ.hide();
      this.initializeLoader();
      this.runForkBtnJ.click(this.runFork);
      this.loadOwnForkBtnJ.click(this.loadOwnFork);
      loadCustomForkBtnJ.click(this.loadCustomFork);
      listForksBtnJ.click(this.listForks);
      this.loadMainRepositoryBtnJ.click(this.loadMainRepository);
      diffingBtnJ.click(this.diffing);
      this.createForkBtnJ.click(this.createFork);
      createFileBtnJ = this.codeJ.find('li.create-file');
      createDirectoryBtnJ = this.codeJ.find('li.create-directory');
      runBtnJ = this.codeJ.find('button.run');
      this.undoChangesBtnJ = this.codeJ.find('button.undo-changes');
      this.commitBtnJ = this.codeJ.find('button.commit');
      this.createPullRequestBtnJ = this.codeJ.find('button.pull-request');
      this.hideCommitButtons();
      this.createPullRequestBtnJ.hide();
      createFileBtnJ.click(this.onCreateFile);
      createDirectoryBtnJ.click(this.onCreateDirectory);
      runBtnJ.click(this.runFork);
      this.undoChangesBtnJ.click(this.onUndoChanges);
      this.commitBtnJ.click(this.onCommitClicked);
      this.createPullRequestBtnJ.click(this.createPullRequest);
      this.fileBrowserJ = this.codeJ.find('.files');
      this.files = [];
      this.nDirsToLoad = 1;
      if (((_ref = R.repository) != null ? _ref.owner : void 0) != null) {
        this.loadFork({
          owner: R.repository.owner
        });
      } else {
        this.loadMainRepository();
      }
      this.checkHasFork();
      return;
    }

    FileManager.prototype.initializeLoader = function() {
      var opts;
      opts = {
        lines: 13,
        length: 5,
        width: 4,
        radius: 0,
        scale: 0.25,
        corners: 1,
        color: 'white',
        opacity: 0.15,
        rotate: 0,
        direction: 1,
        speed: 1,
        trail: 42,
        fps: 20,
        zIndex: 2e9,
        className: 'spinner',
        top: '50%',
        left: 'inherit',
        right: '15px',
        shadow: false,
        hwaccel: false,
        position: 'absolute'
      };
      this.spinner = new Spinner(opts).spin(this.runForkBtnJ[0]);
    };

    FileManager.prototype.showLoader = function() {
      this.spinner.spin(this.runForkBtnJ[0]);
      $(this.spinner.el).css({
        right: '15px'
      });
    };

    FileManager.prototype.hideLoader = function() {
      this.spinner.stop();
    };

    FileManager.prototype.showCommitButtons = function() {
      this.undoChangesBtnJ.show();
      this.commitBtnJ.show();
      this.createPullRequestBtnJ.hide();
    };

    FileManager.prototype.initializeFileTypeahead = function() {
      var node, values, _i, _len, _ref;
      values = [];
      _ref = this.getNodes();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        values.push({
          value: node.name,
          path: node.file.path
        });
      }
      if (this.typeaheadFileEngine == null) {
        this.typeaheadFileEngine = new Bloodhound({
          name: 'Files',
          local: values,
          datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
          queryTokenizer: Bloodhound.tokenizers.whitespace
        });
        this.typeaheadFileEngine.initialize();
        this.fileSearchInputJ = this.codeJ.find('input.search-file');
        this.fileSearchInputJ.keyup(this.queryDesiredFile);
      } else {
        this.typeaheadFileEngine.clear();
        this.typeaheadFileEngine.add(values);
      }
    };

    FileManager.prototype.queryDesiredFile = function(event) {
      var query;
      query = this.fileSearchInputJ.val();
      if (query === "") {
        this.fileBrowserJ.find('li').show();
        return;
      }
      this.fileBrowserJ.find('li').hide();
      this.typeaheadFileEngine.get(query, this.displayDesiredFile);
    };

    FileManager.prototype.displayDesiredFile = function(suggestions) {
      var elementJ, matches, node, suggestion, _i, _j, _len, _len1;
      matches = [];
      for (_i = 0, _len = suggestions.length; _i < _len; _i++) {
        suggestion = suggestions[_i];
        node = this.getNodeFromPath(suggestion.path);
        matches.push($(node.element));
      }
      for (_j = 0, _len1 = matches.length; _j < _len1; _j++) {
        elementJ = matches[_j];
        elementJ.parentsUntil(this.fileBrowserJ).show();
        elementJ.show();
      }
    };

    FileManager.prototype.hideCommitButtons = function() {
      this.undoChangesBtnJ.hide();
      this.commitBtnJ.hide();
    };

    FileManager.prototype.request = function(request, callback, method, data, params, headers) {
      Dajaxice.draw.githubRequest(callback, {
        githubRequest: request,
        method: method,
        data: data,
        params: params,
        headers: headers
      });
    };

    FileManager.prototype.checkHasFork = function() {
      if ((R.githubLogin != null) && R.githubLogin !== '') {
        this.request('https://api.github.com/repos/' + R.githubLogin + '/romanesco-client-code/', this.checkHasForkCallback);
      }
    };

    FileManager.prototype.checkHasForkCallback = function(fork) {
      if (fork.status === 404) {
        this.loadOwnForkBtnJ.show();
        this.createForkBtnJ.hide();
      } else {
        this.loadOwnForkBtnJ.show();
        this.createForkBtnJ.hide();
      }
    };

    FileManager.prototype.getForks = function(callback) {
      this.request('https://api.github.com/repos/arthursw/romanesco-client-code/forks', callback);
    };

    FileManager.prototype.forkRowClicked = function(event, field, value, row, $element) {
      this.loadFork(row);
      Modal.getModalByTitle('Forks').hide();
    };

    FileManager.prototype.displayForks = function(forks) {
      var date, fork, modal, tableData, tableJ, _i, _len;
      forks = this.checkError(forks);
      if (!forks) {
        return;
      }
      modal = Modal.createModal({
        title: 'Forks',
        submit: null
      });
      tableData = {
        columns: [
          {
            field: 'owner',
            title: 'Owner'
          }, {
            field: 'date',
            title: 'Date'
          }, {
            field: 'githubURL',
            title: 'Github URL'
          }
        ],
        data: [],
        formatter: function(value, row, index) {
          return "<a href='" + value + "'>value</a>";
        }
      };
      for (_i = 0, _len = forks.length; _i < _len; _i++) {
        fork = forks[_i];
        date = new Date(fork.updated_at);
        tableData.data.push({
          owner: fork.owner.login,
          date: date.toLocaleString(),
          githubURL: fork.html_url
        });
      }
      tableJ = modal.addTable(tableData);
      tableJ.on('click-cell.bs.table', this.forkRowClicked);
      modal.show();
    };

    FileManager.prototype.listForks = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.getForks(this.displayForks);
    };

    FileManager.prototype.loadMainRepository = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.loadFork({
        owner: 'arthursw'
      });
    };

    FileManager.prototype.loadOwnFork = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.loadFork({
        owner: R.githubLogin
      }, true);
    };

    FileManager.prototype.loadFork = function(data) {
      this.owner = data.owner;
      this.getMasterBranch(this.owner);
    };

    FileManager.prototype.loadCustomFork = function(event) {
      var modal;
      if (event != null) {
        event.preventDefault();
      }
      modal = Modal.createModal({
        title: 'Load repository',
        submit: this.loadFork
      });
      modal.addTextInput({
        name: 'owner',
        placeholder: 'The login name of the fork owner (ex: george)',
        label: 'Owner',
        required: true,
        submitShortcut: true
      });
      modal.show();
    };

    FileManager.prototype.forkCreationResponse = function(response) {
      var message;
      if (response.status === 202) {
        message = 'Congratulation, you just made a new fork!';
        message += 'It should be available in a few seconds at this adress:' + response.url;
        message += 'You will then be able to improve or customize it.';
        R.alertManager.alert(message, 'success');
      }
    };

    FileManager.prototype.createFork = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.request('https://api.github.com/repos/' + R.githubLogin + '/romanesco-client-code/forks', this.forkCreationResponse, 'post');
    };

    FileManager.prototype.getFileName = function(file) {
      var dirs;
      dirs = file.path.split('/');
      return dirs[dirs.length - 1];
    };

    FileManager.prototype.coffeeToJsPath = function(coffeePath) {
      return coffeePath.replace(/^coffee/, 'js').replace(/coffee$/, 'js');
    };

    FileManager.prototype.getJsFile = function(file) {
      return this.getFileFromPath(this.coffeeToJsPath(file.path));
    };

    FileManager.prototype.getFileFromPath = function(path, tree) {
      var file, _i, _len, _ref;
      if (tree == null) {
        tree = this.gitTree;
      }
      _ref = tree.tree;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        if (file.path === path) {
          return file;
        }
      }
    };

    FileManager.prototype.getNodeFromPath = function(path) {
      var dirName, dirs, i, node, _i, _len;
      dirs = path.split('/');
      dirs.shift();
      node = this.tree;
      for (i = _i = 0, _len = dirs.length; _i < _len; i = ++_i) {
        dirName = dirs[i];
        node = node.leaves[dirName];
      }
      return node;
    };

    FileManager.prototype.getParentNode = function(file, node) {
      var dirName, dirs, i, _base, _i, _len;
      dirs = file.path.split('/');
      file.name = dirs.pop();
      for (i = _i = 0, _len = dirs.length; _i < _len; i = ++_i) {
        dirName = dirs[i];
        if ((_base = node.leaves)[dirName] == null) {
          _base[dirName] = {
            leaves: {},
            children: []
          };
        }
        node = node.leaves[dirName];
      }
      return node;
    };

    FileManager.prototype.getNodes = function(tree, nodes) {
      var node, _i, _len, _ref;
      if (tree == null) {
        tree = this.tree;
      }
      if (nodes == null) {
        nodes = [];
      }
      _ref = tree.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        nodes.push(node);
        this.getNodes(node, nodes);
      }
      return nodes;
    };

    FileManager.prototype.buildTree = function(files) {
      var file, i, name, node, parentNode, tree, _base, _i, _len;
      tree = {
        leaves: {},
        children: []
      };
      for (i = _i = 0, _len = files.length; _i < _len; i = ++_i) {
        file = files[i];
        parentNode = this.getParentNode(file, tree);
        name = file.name;
        if ((_base = parentNode.leaves)[name] == null) {
          _base[name] = {
            leaves: {},
            children: []
          };
        }
        node = parentNode.leaves[name];
        node.label = name;
        node.id = i;
        node.file = file;
        parentNode.children.push(node);
      }
      tree.id = i;
      return tree;
    };

    FileManager.prototype.updateLeaves = function(tree) {
      var i, node, _i, _len, _ref;
      tree.leaves = {};
      _ref = tree.children;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        node = _ref[i];
        tree.leaves[node.name] = node;
        this.updateLeaves(node);
      }
    };

    FileManager.prototype.loadFile = function(path, callback, owner) {
      if (owner == null) {
        owner = this.owner;
      }
      console.log('load ' + path + ' of ' + owner);
      this.request('https://api.github.com/repos/' + owner + '/romanesco-client-code/contents/' + path, callback);
    };

    FileManager.prototype.openFile = function(file) {
      var node;
      file = this.checkError(file);
      if (!file) {
        return;
      }
      node = this.getNodeFromPath(file.path);
      node.file.content = atob(file.content);
      R.codeEditor.setFile(node);
    };

    FileManager.prototype.createName = function(name, parentNode) {
      var i;
      i = 1;
      while (parentNode.leaves[name] != null) {
        name = 'NewScript' + i + '.coffee';
      }
      return name;
    };

    FileManager.prototype.createGitFile = function(path, type) {
      var file, jsFile;
      file = {
        mode: type === 'blob' ? '100644' : '040000',
        path: path,
        type: type,
        content: '',
        changed: true
      };
      this.gitTree.tree.push(file);
      if (type === 'blob') {
        jsFile = Utils.clone(file);
        jsFile.path = this.coffeeToJsPath(file.path);
        this.gitTree.tree.push(jsFile);
      }
      return file;
    };

    FileManager.prototype.createFile = function(parentNode, type) {
      var defaultName, name, newNode;
      defaultName = type === 'blob' ? 'NewScript.coffee' : 'NewDirectory';
      name = this.createName(defaultName, parentNode);
      newNode = {
        label: name,
        children: [],
        leaves: {},
        file: this.createGitFile(parentNode.file.path + '/' + name, type),
        id: this.tree.id++
      };
      newNode = this.fileBrowserJ.tree('appendNode', newNode, parentNode);
      parentNode.leaves[newNode.name] = newNode;
      return newNode;
    };

    FileManager.prototype.onCreate = function(type) {
      var newNode, parentNode;
      if (type == null) {
        type = 'blob';
      }
      parentNode = this.fileBrowserJ.tree('getSelectedNode');
      if (!parentNode) {
        parentNode = this.fileBrowserJ.tree('getTree');
      }
      if (parentNode.file.type !== 'tree') {
        parentNode = parentNode.parent;
      }
      newNode = this.createFile(parentNode, type);
      this.fileBrowserJ.tree('selectNode', newNode);
      this.onNodeDoubleClicked({
        node: newNode
      });
      R.codeEditor.setFile(newNode);
    };

    FileManager.prototype.onCreateFile = function() {
      this.onCreate('blob');
    };

    FileManager.prototype.onCreateDirectory = function() {
      this.onCreate('tree');
    };

    FileManager.prototype.updatePath = function(node, parent) {
      var child, jsFile, newPath, _i, _len, _ref;
      newPath = parent.file.path + '/' + node.name;
      if (node.file.type === 'blob') {
        jsFile = this.getJsFile(node.file);
        jsFile.path = this.coffeeToJsPath(newPath);
      }
      node.file.path = newPath;
      if (node.file.type === 'tree') {
        _ref = node.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          this.updatePath(child, node);
        }
      }
    };

    FileManager.prototype.moveFile = function(node, previousParent, target, position) {
      var parent;
      parent = position === 'inside' ? target : target.parent;
      parent.leaves[node.name] = node;
      delete previousParent.leaves[node.name];
      this.updatePath(node, parent);
    };

    FileManager.prototype.onFileMove = function(event) {
      var node, position, previousParent, target;
      target = event.move_info.target_node;
      node = event.move_info.moved_node;
      position = event.move_info.position;
      previousParent = event.move_info.previous_parent;
      if (target === previousParent && position === 'inside') {
        return;
      }
      this.moveFile(node, previousParent, target, position);
      this.saveToLocalStorage();
    };

    FileManager.prototype.submitNewName = function(event) {
      var id, inputGroupJ, newName, node;
      if (event.type === 'keyup' && event.which !== 13) {
        return;
      }
      inputGroupJ = $(event.target).parents('.input-group');
      newName = inputGroupJ.find('.name-input').val();
      id = inputGroupJ.attr('data-node-id');
      node = this.fileBrowserJ.tree('getNodeById', id);
      if (newName === '') {
        newName = node.name;
      }
      inputGroupJ.replaceWith('<span class="jqtree-title jqtree_common">' + newName + '</span>');
      $(node.element).find('button.delete:first').show();
      delete node.parent.leaves[node.name];
      node.parent.leaves[newName] = node;
      node.name = newName;
      this.updatePath(node, node.parent);
      this.fileBrowserJ.tree('updateNode', node, newName);
    };

    FileManager.prototype.onNodeDoubleClicked = function(event) {
      var buttonJ, inputGroupJ, inputJ, node;
      node = event.node;
      inputGroupJ = $("<div class=\"input-group\">\n	<input type=\"text\" class=\"form-control name-input\" placeholder=\"\">\n	<span class=\"input-group-btn\">\n		<button class=\"btn btn-default\" type=\"button\">Ok</button>\n	</span>\n</div>");
      inputGroupJ.attr('data-node-id', node.id);
      inputJ = inputGroupJ.find('.name-input');
      inputJ.attr('placeholder', node.name);
      inputJ.keyup(this.submitNewName);
      inputJ.blur(this.submitNewName);
      buttonJ = inputGroupJ.find('.btn');
      buttonJ.click(this.submitNewName);
      $(node.element).find('.jqtree-title:first').replaceWith(inputGroupJ);
      inputJ.focus();
      $(node.element).find('button.delete:first').hide();
    };

    FileManager.prototype.updateFile = function(node, source, compiledSource) {
      var jsFile;
      node.file.content = source;
      node.file.changed = true;
      jsFile = this.getJsFile(node.file);
      if (compiledSource != null) {
        jsFile.content = compiledSource;
        jsFile.changed = true;
        delete jsFile.sha;
        delete jsFile.size;
        delete node.file.compile;
      } else {
        node.file.compile = true;
      }
      delete node.file.sha;
      $(node.element).addClass('modified');
      this.saveToLocalStorage();
    };

    FileManager.prototype.deleteFile = function(node, closeEditor) {
      var jsFile;
      if (closeEditor == null) {
        closeEditor = true;
      }
      if (node.file.type === 'tree') {
        while (node.children.length > 0) {
          this.deleteFile(node.children[0]);
        }
      }
      Utils.Array.remove(this.gitTree.tree, node.file);
      if (node.file.type === 'blob') {
        jsFile = this.getJsFile(node.file);
        Utils.Array.remove(this.gitTree.tree, jsFile);
      }
      delete node.parent.leaves[node.name];
      if (node === R.codeEditor.fileNode) {
        R.codeEditor.clearFile(closeEditor);
      }
      this.fileBrowserJ.tree('removeNode', node);
    };

    FileManager.prototype.confirmDeleteFile = function(data) {
      this.deleteFile(data.data);
    };

    FileManager.prototype.onDeleteFile = function(event) {
      var modal, node, path;
      event.stopPropagation();
      path = $(event.target).closest('button.delete').attr('data-path');
      node = this.getNodeFromPath(path);
      if (node == null) {
        return;
      }
      modal = Modal.createModal({
        title: 'Delete file?',
        submit: this.confirmDeleteFile,
        data: node
      });
      modal.addText('Do you really want to delete "' + node.name + '"?');
      modal.show();
    };

    FileManager.prototype.saveToLocalStorage = function() {
      if (this.owner === R.githubLogin) {
        this.showCommitButtons();
      }
      Utils.LocalStorage.set('files:' + this.owner, this.gitTree);
    };

    FileManager.prototype.loadFromLocalStorage = function(tree) {
      if (this.owner === R.githubLogin) {
        this.showCommitButtons();
      }
      this.readTree(tree.data);
    };

    FileManager.prototype.checkError = function(response) {
      if (response.status < 200 || response.status >= 300) {
        R.alertManager.alert('Error: ' + response.content.message, 'error');
        R.loader.hideLoadingBar();
        this.hideLoader();
        return false;
      }
      return response.content;
    };

    FileManager.prototype.runLastCommit = function(branch) {
      branch = this.checkError(branch);
      if (!branch) {
        return;
      }
      R.repository.owner = this.owner;
      R.repository.commit = branch.commit.sha;
      R.view.updateHash();
      location.reload();
    };

    FileManager.prototype.runFork = function(data) {
      if ((data != null ? data.owner : void 0) != null) {
        this.owner = data.owner;
      }
      this.request('https://api.github.com/repos/' + this.owner + '/romanesco-client-code/branches/master', this.runLastCommit);
    };

    FileManager.prototype.onCommitClicked = function(event) {
      var modal;
      modal = Modal.createModal({
        title: 'Commit',
        submit: this.commitChanges
      });
      modal.addTextInput({
        name: 'commitMessage',
        placeholder: 'Added the coffee maker feature.',
        label: 'Message',
        required: true,
        submitShortcut: true
      });
      modal.show();
    };

    FileManager.prototype.undoChanges = function() {
      Utils.LocalStorage.set('files:' + this.owner, null);
      this.getMasterBranch(this.owner);
    };

    FileManager.prototype.onUndoChanges = function() {
      var modal;
      modal = new Modal({
        title: 'Undo changes?',
        submit: this.undoChanges
      });
      modal.addText('Do you really want to revert your repository to the previous commit? All changes will be lost.');
      modal.show();
    };

    FileManager.prototype.createPullRequest = function() {
      var message, modal;
      if (!this.checkingPullRequest) {
        modal = Modal.createModal({
          title: 'Create pull request',
          submit: this.getMasterBranchForDifferenceValidation
        });
        message = 'To make sure that you publish only what you want, you will validate the changes you made.\n ';
        message += 'This can be especially usefull in case your fork is not up-to-date with the main repository.\n ';
        message += 'Please check each file, and click "Create pull request" again once you are done.\n ';
        modal.addText(message);
        modal.show();
        this.createPullRequestBtnJ.find('.text').text('Create pull request');
        this.checkingPullRequest = true;
      } else {
        if (R.codeEditor.finishDifferenceValidation()) {
          this.checkingPullRequest = false;
          this.pullRequestModal();
        }
      }
    };

    FileManager.prototype.getMasterBranchForDifferenceValidation = function(data) {
      var owner;
      owner = (data.owner != null) && data.owner !== '' ? data.owner : 'arthursw';
      if (owner === this.owner) {
        R.alertManager.alert('The current repository is the same as the one you selected. Please choose a different repository to compare.', 'warning');
        return;
      }
      R.loader.showLoadingBar();
      this.differenceOwner = owner;
      this.getMasterBranch(owner, this.getTreeAndInitializeDifference);
    };

    FileManager.prototype.getTreeAndInitializeDifference = function(master) {
      this.getTree(master, this.initializeDifferenceValidation);
    };

    FileManager.prototype.loadFileContent = function(file) {
      this.request(file.url, (function(_this) {
        return function(blob) {
          blob = _this.checkError(blob);
          if (!blob) {
            return;
          }
          file.content = atob(blob.content);
          $(file).trigger('loaded');
        };
      })(this));
    };

    FileManager.prototype.initializeDifferenceValidation = function(content) {
      var difference, differences, file, forkFile, node, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
      content = this.checkError(content);
      if (!content) {
        return;
      }
      this.hideLoader();
      differences = [];
      _ref = content.tree;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        if (file.type === 'blob' && file.path.indexOf('coffee') === 0) {
          forkFile = this.getFileFromPath(file.path);
          if (forkFile == null) {
            differences.push({
              main: file,
              fork: null
            });
            continue;
          }
          if ((forkFile.sha == null) || forkFile.sha !== file.sha) {
            differences.push({
              main: file,
              fork: forkFile
            });
          }
        }
      }
      _ref1 = this.getNodes();
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        node = _ref1[_j];
        if (node.type === 'blob' && !this.getFileFromPath(node.file.path, content.tree)) {
          differences.push({
            main: null,
            fork: node.file
          });
        }
      }
      for (_k = 0, _len2 = differences.length; _k < _len2; _k++) {
        difference = differences[_k];
        if (difference.fork != null) {
          $((_ref2 = this.getNodeFromPath(difference.fork.path)) != null ? _ref2.element : void 0).addClass('difference');
          if (difference.fork.content == null) {
            this.loadFileContent(difference.fork);
          }
        }
        if (difference.main != null) {
          this.loadFileContent(difference.main);
        }
      }
      if (differences.length > 0) {
        R.codeEditor.initializeDifferenceValidation(differences);
      } else {
        R.loader.hideLoadingBar();
        R.alertManager.alert('Warning: there was no changes detected between the chosen repository and this fork!', 'warning');
        this.pullRequestModal();
      }
    };

    FileManager.prototype.getOrCreateParentNode = function(mainFile) {
      var dirName, dirs, i, node, previousNode, _i, _len;
      dirs = mainFile.path.split('/');
      dirs.pop();
      dirs.shift();
      node = this.tree;
      for (i = _i = 0, _len = dirs.length; _i < _len; i = ++_i) {
        dirName = dirs[i];
        previousNode = node;
        node = node.leaves[dirName];
        if (node == null) {
          node = this.createFile(previousNode, 'tree');
        }
      }
      return node;
    };

    FileManager.prototype.changeDifference = function(difference, newContent) {
      var node, parentNode;
      if (difference.fork == null) {
        parentNode = this.getOrCreateParentNode(difference.main);
        node = this.createFile(parentNode, type);
        this.updateFile(node, newContent);
      } else if ((newContent == null) || newContent === '') {
        node = this.getNodeFromPath(difference.fork.path);
        this.deleteFile(node, false);
      } else {
        node = this.getNodeFromPath(difference.fork.path);
        this.updateFile(node, newContent);
      }
    };

    FileManager.prototype.pullRequestModal = function() {
      var modal;
      modal = Modal.createModal({
        title: 'Create pull request',
        submit: this.createPullRequestSubmit
      });
      modal.addTextInput({
        name: 'title',
        placeholder: 'Amazing new feature',
        label: 'Title of the pull request',
        required: true
      });
      modal.addTextInput({
        name: 'body',
        placeholder: 'Please pull this in!',
        label: 'Message',
        submitShortcut: true,
        required: false
      });
      modal.show();
    };

    FileManager.prototype.createPullRequestSubmit = function(data) {
      data = {
        title: data.title,
        head: this.owner + ':' + (data.branch || 'master'),
        base: 'master',
        body: data.body
      };
      R.loader.showLoadingBar();
      this.request('https://api.github.com/repos/arthursw/romanesco-client-code/pulls', this.checkPullRequest, 'post', data);
    };

    FileManager.prototype.checkPullRequest = function(message) {
      var result, _ref, _ref1;
      result = this.checkError(message);
      if (((_ref = message.content.errors) != null ? (_ref1 = _ref[0]) != null ? _ref1.message : void 0 : void 0) != null) {
        R.alertManager.alert(message.content.errors[0].message, 'error');
      }
      if (!result) {
        return;
      }
      R.loader.hideLoadingBar();
      R.alertManager.alert('Your pull request was successfully created!', 'success');
      this.createPullRequestBtnJ.hide();
      this.createPullRequestBtnJ.find('.text').text('Validate to create pull request');
    };

    FileManager.prototype.diffing = function() {
      var modal;
      modal = new Modal({
        title: 'Diffing',
        submit: this.getMasterBranchForDifferenceValidation
      });
      modal.addTextInput({
        name: 'owner',
        placeholder: 'The owner of the repository that you want to compare. (let blank for main repository)',
        label: 'Owner',
        submitShortcut: true
      });
      modal.show();
    };

    FileManager.prototype.closeDiffing = function(allDifferencesValidated) {
      if (!allDifferencesValidated && this.checkingPullRequest) {
        this.createPullRequestBtnJ.hide();
        this.checkingPullRequest = false;
      }
    };

    FileManager.prototype.onCanMoveTo = function(moved_node, target_node, position) {
      var nameExistsInTargetNode, targetIsFolder;
      targetIsFolder = target_node.file.type === 'tree';
      nameExistsInTargetNode = target_node.leaves[moved_node.name] != null;
      return (targetIsFolder && !nameExistsInTargetNode) || position !== 'inside';
    };

    FileManager.prototype.onCreateLi = function(node, liJ) {
      var deleteButtonJ;
      deleteButtonJ = $("<button type=\"button\" class=\"close delete\" aria-label=\"Close\">\n	<span aria-hidden=\"true\">&times;</span>\n</button>");
      deleteButtonJ.attr('data-path', node.file.path);
      deleteButtonJ.click(this.onDeleteFile);
      liJ.find('.jqtree-element').append(deleteButtonJ);
      if (node.file.type === 'tree' && node.children.length === 0) {
        liJ.addClass('jqtree-folder jqtree-closed');
      }
      if (node.file.changed != null) {
        liJ.addClass('modified');
      }
    };

    FileManager.prototype.onNodeClicked = function(event) {
      var elementIsTitle, elementIsToggler;
      if (event.node.file.type === 'tree') {
        elementIsToggler = $(event.click_event.target).hasClass('jqtree-toggler');
        elementIsTitle = $(event.click_event.target).hasClass('jqtree-title-folder');
        if (elementIsToggler || elementIsTitle) {
          this.fileBrowserJ.tree('toggle', event.node);
        }
        return;
      }
      if (event.node.file.content != null) {
        R.codeEditor.setFile(event.node);
      } else {
        this.loadFile(event.node.file.path, this.openFile);
      }
    };

    FileManager.prototype.onNodeOpened = function(event) {
      $(event.node.element).children('ul').children('li').show();
    };

    FileManager.prototype.onNodeClosed = function(event) {};


    /* Load files */

    FileManager.prototype.getMasterBranch = function(owner, callback) {
      if (owner == null) {
        owner = 'arthursw';
      }
      if (callback == null) {
        callback = this.getTreeAndSetCommit;
      }
      this.showLoader();
      this.request('https://api.github.com/repos/' + owner + '/romanesco-client-code/branches/master', callback);
    };

    FileManager.prototype.getTree = function(master, callback) {
      var _ref, _ref1, _ref2;
      master = this.checkError(master);
      if (!master) {
        return;
      }
      if (((_ref = master.commit) != null ? (_ref1 = _ref.commit) != null ? (_ref2 = _ref1.tree) != null ? _ref2.url : void 0 : void 0 : void 0) == null) {
        return R.alertManager.alert('Error reading master branch.', 'error');
      }
      this.request(master.commit.commit.tree.url + '?recursive=1', callback);
      return master;
    };

    FileManager.prototype.getTreeAndSetCommit = function(master) {
      master = this.getTree(master, this.checkIfTreeExists);
      if (!master) {
        return;
      }
      R.codeEditor.close();
      R.codeEditor.setMode('coding');
      if (this.owner === 'arthursw') {
        this.loadOwnForkBtnJ.show();
        this.loadMainRepositoryBtnJ.hide();
      } else {
        this.loadOwnForkBtnJ.hide();
        this.loadMainRepositoryBtnJ.show();
      }
      this.hideLoader();
      this.runForkBtnJ.text(this.owner !== 'arthursw' ? this.owner : 'Main repository');
      this.commit = {
        lastCommitSha: master.commit.sha
      };
    };

    FileManager.prototype.checkIfTreeExists = function(content) {
      var message, modal, savedGitTree;
      content = this.checkError(content);
      if (!content) {
        return;
      }
      savedGitTree = Utils.LocalStorage.get('files' + this.owner);
      if (savedGitTree != null) {
        if (savedGitTree.sha !== content.sha) {
          modal = new Modal({
            title: 'Load uncommitted changes',
            submit: this.loadFromLocalStorage,
            data: savedGitTree
          });
          message = 'Do you want to load the changes which have not been committed yet (stored on your computer)?\n';
          message += '<strong>Warning: the repository has changed since you made the changes!</strong>\n';
          message += 'Consider checking the new version of the repository before committing your changes.';
          modal.addText(message);
          modal.show();
          this.readTree(content);
        } else {
          this.loadFromLocalStorage({
            data: savedGitTree
          });
        }
      } else {
        this.readTree(content);
      }
    };

    FileManager.prototype.readTree = function(content) {
      var tree, treeExists;
      this.gitTree = content;
      treeExists = this.tree != null;
      tree = this.buildTree(this.gitTree.tree);
      if (treeExists) {
        this.fileBrowserJ.tree('loadData', tree.leaves.coffee.children);
      } else {
        this.fileBrowserJ.tree({
          data: tree.leaves.coffee.children,
          autoOpen: true,
          dragAndDrop: true,
          onCanMoveTo: this.onCanMoveTo,
          onCreateLi: this.onCreateLi
        });
        this.fileBrowserJ.bind('tree.click', this.onNodeClicked);
        this.fileBrowserJ.bind('tree.dblclick', this.onNodeDoubleClicked);
        this.fileBrowserJ.bind('tree.move', this.onFileMove);
        this.fileBrowserJ.bind('tree.open', this.onNodeOpened);
        this.fileBrowserJ.bind('tree.close', this.onNodeClosed);
      }
      this.tree = this.fileBrowserJ.tree('getTree');
      this.tree.name = 'coffee';
      this.tree.file = {
        name: 'coffee',
        path: 'coffee',
        type: 'tree'
      };
      this.tree.id = this.gitTree.tree.length;
      this.updateLeaves(this.tree);
      this.initializeFileTypeahead();
      this.hideLoader();
    };


    /* Commit changes */

    FileManager.prototype.compileCoffee = function() {
      var file, js, jsFile, node, _i, _len, _ref;
      _ref = this.gitTree.tree;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        if (file.compile) {
          jsFile = this.getJsFile(file);
          node = this.getNodeFromPath(file.path);
          js = R.codeEditor.compile(node.file.content);
          if (js == null) {
            return false;
          }
          jsFile.content = js;
          jsFile.changed = true;
          delete jsFile.sha;
          delete jsFile.size;
          delete file.compile;
        }
      }
      return true;
    };

    FileManager.prototype.filterTree = function() {
      var f, file, tree, _i, _len, _ref;
      tree = [];
      _ref = this.gitTree.tree;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        if (file.type !== 'tree') {
          f = Utils.clone(file);
          if (!file.changed) {
            delete f.content;
          }
          delete f.size;
          delete f.url;
          delete f.name;
          delete f.changed;
          tree.push(f);
        }
      }
      return tree;
    };

    FileManager.prototype.commitChanges = function(data) {
      var tree;
      this.commit.message = data.commitMessage;
      if (!this.compileCoffee()) {
        return;
      }
      R.loader.showLoadingBar();
      tree = this.filterTree();
      this.request('https://api.github.com/repos/' + this.owner + '/romanesco-client-code/git/trees', this.createCommit, 'post', {
        tree: tree
      });
    };

    FileManager.prototype.createCommit = function(tree) {
      var data;
      tree = this.checkError(tree);
      if (!tree) {
        return;
      }
      data = {
        message: this.commit.message,
        tree: tree.sha,
        parents: [this.commit.lastCommitSha]
      };
      this.request('https://api.github.com/repos/' + this.owner + '/romanesco-client-code/git/commits', this.updateHead, 'post', data);
    };

    FileManager.prototype.updateHead = function(commit) {
      commit = this.checkError(commit);
      if (!commit) {
        return;
      }
      this.commit.lastCommitSha = commit.sha;
      this.request('https://api.github.com/repos/' + this.owner + '/romanesco-client-code/git/refs/heads/master', this.checkCommit, 'patch', {
        sha: commit.sha
      });
    };

    FileManager.prototype.checkCommit = function(response) {
      var node, _i, _len, _ref;
      response = this.checkError(response);
      if (!response) {
        return;
      }
      Utils.LocalStorage.set('files:' + this.owner, null);
      _ref = this.getNodes();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (node.file.changed) {
          $(node.element).removeClass('modified');
          delete node.file.changed;
        }
      }
      this.hideCommitButtons();
      this.createPullRequestBtnJ.show();
      R.loader.hideLoadingBar();
      R.alertManager.alert('Successfully committed!', 'success');
    };

    FileManager.prototype.createButton = function(content) {
      var category, description, expressions, file, iconURL, label, name, properties, property, source, value, _i, _len, _ref, _ref1, _ref10, _ref11, _ref12, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      source = atob(content.content);
      expressions = CoffeeScript.nodes(source).expressions;
      properties = (_ref = expressions[0]) != null ? (_ref1 = _ref.args) != null ? (_ref2 = _ref1[1]) != null ? (_ref3 = _ref2.body) != null ? (_ref4 = _ref3.expressions) != null ? (_ref5 = _ref4[0]) != null ? (_ref6 = _ref5.body) != null ? _ref6.expressions : void 0 : void 0 : void 0 : void 0 : void 0 : void 0 : void 0;
      if (properties == null) {
        return;
      }
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        property = properties[_i];
        name = (_ref7 = property.variable) != null ? (_ref8 = _ref7.properties) != null ? (_ref9 = _ref8[0]) != null ? (_ref10 = _ref9.name) != null ? _ref10.value : void 0 : void 0 : void 0 : void 0;
        value = (_ref11 = property.value) != null ? (_ref12 = _ref11.base) != null ? _ref12.value : void 0 : void 0;
        if (!((value != null) && (name != null))) {
          continue;
        }
        switch (name) {
          case 'label':
            label = value;
            break;
          case 'description':
            description = value;
            break;
          case 'iconURL':
            iconURL = value;
            break;
          case 'category':
            category = value;
        }
      }

      /*
      			iconResult = /@iconURL = (\'|\"|\"\"\")(.*)(\'|\"|\"\"\")/.exec(source)
      
      			if iconResult? and iconResult.length>=2
      				iconURL = iconResult[2]
      
      			descriptionResult = /@description = (\'|\"|\"\"\")(.*)(\'|\"|\"\"\")/.exec(source)
      
      			if descriptionResult? and descriptionResult.length>=2
      				description = descriptionResult[2]
      
      			labelResult = /@label = (\'|\"|\"\"\")(.*)(\'|\"|\"\"\")/.exec(source)
      
      			if labelResult? and labelResult.length>=2
      				label = labelResult[2]
       */
      file = content.path.replace('coffee/', '');
      file = '"' + file.replace('.coffee', '') + '"';
      console.log('{ name: ' + label + ', popoverContent: ' + description + ', iconURL: ' + iconURL + ', file: ' + file + ', category: ' + category + ' }');
    };

    FileManager.prototype.createButtons = function(pathDirectory) {
      var name, node, _ref;
      _ref = pathDirectory.leaves;
      for (name in _ref) {
        node = _ref[name];
        if (node.type !== 'tree') {
          this.loadFile(node.path, this.createButton);
        } else {
          this.createButtons(node);
        }
      }
    };

    FileManager.prototype.loadButtons = function() {
      this.createButtons(this.tree.leaves['Items'].leaves['Paths']);
    };

    FileManager.prototype.registerModule = function(module) {
      this.module = module;
      this.loadFile(this.tree.leaves['ModuleLoader'].path, this.registerModuleInModuleLoader);
    };

    FileManager.prototype.insertModule = function(source, module, position) {
      var line;
      line = JSON.stringify(module);
      source.insert(line, position);
    };

    FileManager.prototype.registerModuleInModuleLoader = function(content) {
      var buttonsResult, source;
      content = this.checkError(content);
      if (!content) {
        return;
      }
      source = atob(content.content);
      buttonsResult = /buttons = \[/.exec(source);
      if ((buttonsResult != null) && buttonsResult.length > 1) {
        this.insertModule(source, this.module, buttonsResult[1]);
      }
    };

    return FileManager;

  })();
  return FileManager;
});
