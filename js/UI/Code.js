// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['UI/Modal', 'coffee', 'jqtree'], function(Modal, CoffeeScript) {
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
        this.getTree = __bind(this.getTree, this);
        this.onNodeClicked = __bind(this.onNodeClicked, this);
        this.onCreateLi = __bind(this.onCreateLi, this);
        this.createPullRequestSubmit = __bind(this.createPullRequestSubmit, this);
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
        this.onCreateDirec = __bind(this.onCreateDirec, this);
        this.onCreateFile = __bind(this.onCreateFile, this);
        this.openFile = __bind(this.openFile, this);
        this.createFork = __bind(this.createFork, this);
        this.forkCreationResponse = __bind(this.forkCreationResponse, this);
        this.loadCustomFork = __bind(this.loadCustomFork, this);
        this.loadFork = __bind(this.loadFork, this);
        this.loadOwnFork = __bind(this.loadOwnFork, this);
        this.loadMainRepo = __bind(this.loadMainRepo, this);
        this.listForks = __bind(this.listForks, this);
        this.displayForks = __bind(this.displayForks, this);
        this.forkRowClicked = __bind(this.forkRowClicked, this);
        this.getUserFork = __bind(this.getUserFork, this);
        var commitBtnJ, createDirectoryBtnJ, createFileBtnJ, createPullRequestBtnJ, listForksBtnJ, loadCustomForkBtnJ, runBtnJ, undoChangesBtnJ;
        this.codeJ = $('#Code');
        this.runForkBtnJ = this.codeJ.find('button.run-fork');
        this.loadOwnForkBtnJ = this.codeJ.find('li.user-fork');
        listForksBtnJ = this.codeJ.find('li.list-forks');
        loadCustomForkBtnJ = this.codeJ.find('li.custom-fork');
        this.createForkBtnJ = this.codeJ.find('li.create-fork');
        this.loadOwnForkBtnJ.hide();
        this.createForkBtnJ.hide();
        this.getForks(this.getUserFork);
        this.runForkBtnJ.click(this.runFork);
        this.loadOwnForkBtnJ.click(this.loadOwnFork);
        loadCustomForkBtnJ.click(this.loadCustomFork);
        listForksBtnJ.click(this.listForks);
        this.createForkBtnJ.click(this.createFork);
        createFileBtnJ = this.codeJ.find('li.create-file');
        createDirectoryBtnJ = this.codeJ.find('li.create-directory');
        runBtnJ = this.codeJ.find('button.run');
        undoChangesBtnJ = this.codeJ.find('button.undo-changes');
        commitBtnJ = this.codeJ.find('button.commit');
        createPullRequestBtnJ = this.codeJ.find('button.pull-request');
        createFileBtnJ.click(this.onCreateFile);
        createDirectoryBtnJ.click(this.onCreateDirectory);
        runBtnJ.click(this.runFork);
        undoChangesBtnJ.click(this.onUndoChanges);
        commitBtnJ.click(this.onCommitClicked);
        createPullRequestBtnJ.click(this.createPullRequest);
        this.fileBrowserJ = this.codeJ.find('.files');
        this.files = [];
        this.nDirsToLoad = 1;
        if (R.repositoryOwner != null) {
          this.loadFork({
            owner: R.repositoryOwner
          });
        } else {
          this.loadMainRepo();
        }
        return;
      }

      FileManager.prototype.request = function(request, callback, method, data, params, headers) {
        Dajaxice.draw.githubRequest(callback, {
          githubRequest: request,
          method: method,
          data: data,
          params: params,
          headers: headers
        });
      };

      FileManager.prototype.getUserFork = function(forks) {
        var fork, hasFork, _i, _len;
        forks = this.checkError(forks);
        if (!forks) {
          return;
        }
        hasFork = false;
        for (_i = 0, _len = forks.length; _i < _len; _i++) {
          fork = forks[_i];
          if (fork.owner.login === R.me) {
            this.loadOwnForkBtnJ.show();
            this.createForkBtnJ.hide();
            hasFork = true;
            break;
          }
        }
        if (!hasFork) {
          this.loadOwnForkBtnJ.hide();
          this.createForkBtnJ.show();
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

      FileManager.prototype.loadMainRepo = function(event) {
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
        });
      };

      FileManager.prototype.loadFork = function(data) {
        this.owner = data.owner;
        this.getMasterBranch();
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

      FileManager.prototype.coffeeToJsPath = function(coffeePath) {
        return coffeePath.replace(/^coffee/, 'js').replace(/coffee$/, 'js');
      };

      FileManager.prototype.getJsFile = function(file) {
        return this.getFileFromPath(this.coffeeToJsPath(file.path));
      };

      FileManager.prototype.getFileFromPath = function(path) {
        var file, _i, _len, _ref;
        _ref = this.gitTree.tree;
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

      FileManager.prototype.loadFile = function(path, callback) {
        this.request('https://api.github.com/repos/arthursw/romanesco-client-code/contents/' + path, callback);
      };

      FileManager.prototype.openFile = function(file) {
        var node;
        file = this.checkError(file);
        if (!file) {
          return;
        }
        node = this.getNodeFromPath(file.path);
        node.source = atob(file.content);
        R.showCodeEditor(node);
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
          content: ''
        };
        this.gitTree.tree.push(file);
        if (type === 'blob') {
          jsFile = Utils.clone(file);
          jsFile.path = this.coffeeToJsPath(file.path);
          this.gitTree.tree.push(jsFile);
        }
        return file;
      };

      FileManager.prototype.onCreate = function(type) {
        var defaultName, name, newNode, parentNode;
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
        defaultName = type === 'blob' ? 'NewScript.coffee' : 'NewDirectory';
        name = this.createName(defaultName, parentNode);
        newNode = {
          label: name,
          children: [],
          leaves: {},
          source: '',
          file: this.createGitFile(parentNode.file.path + '/' + name, type),
          id: this.tree.id++
        };
        newNode = this.fileBrowserJ.tree('appendNode', newNode, parentNode);
        this.fileBrowserJ.tree('selectNode', newNode);
        parentNode.leaves[newNode.name] = newNode;
        this.onNodeDoubleClicked({
          node: newNode
        });
        R.showCodeEditor(newNode);
      };

      FileManager.prototype.onCreateFile = function() {
        this.onCreate('blob');
      };

      FileManager.prototype.onCreateDirec = function() {
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
        parent.children.push(node);
        delete previousParent.leaves[node.name];
        Utils.Array.remove(previousParent.children, node);
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
        node.source = source;
        node.file.content = source;
        jsFile = this.getJsFile(node.file);
        if (compiledSource != null) {
          jsFile.content = compiledSource;
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

      FileManager.prototype.deleteFile = function(node) {
        var child, jsFile, _i, _len, _ref;
        if (node.file.type === 'tree') {
          _ref = node.children;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            child = _ref[_i];
            this.deleteFile(child);
          }
        }
        Utils.Array.remove(this.gitTree.tree, node.file);
        if (node.file.type === 'blob') {
          jsFile = this.getJsFile(node.file);
          Utils.Array.remove(this.gitTree.tree, jsFile);
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
        Utils.LocalStorage.set('files:' + this.owner, this.gitTree);
      };

      FileManager.prototype.checkError = function(response) {
        if (response.status < 200 || response.status >= 300) {
          R.alertManager.alert('Error: ' + response.content.message, 'error');
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
        this.getMasterBranch();
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
          name: 'branch',
          placeholder: 'master',
          label: 'Branch',
          required: true,
          submitShortcut: true
        });
        modal.addTextInput({
          name: 'body',
          placeholder: 'Please pull this in!',
          label: 'Message',
          required: false
        });
        modal.show();
      };

      FileManager.prototype.createPullRequestSubmit = function(data) {
        data = {
          title: data.title,
          head: this.owner + ':' + data.branch,
          base: 'master',
          body: data.body
        };
        this.request('https://api.github.com/repos/arthursw/romanesco-client-code/pulls', this.checkError, 'post', data);
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
        if (event.node.source != null) {
          R.showCodeEditor(event.node);
        } else {
          this.loadFile(event.node.file.path, this.openFile);
        }
      };


      /* Load files */

      FileManager.prototype.getMasterBranch = function() {
        this.commit = {};
        this.request('https://api.github.com/repos/' + this.owner + '/romanesco-client-code/branches/master', this.getTree);
      };

      FileManager.prototype.getTree = function(master) {
        var _ref, _ref1, _ref2;
        master = this.checkError(master);
        if (!master) {
          return;
        }
        if (((_ref = master.commit) != null ? (_ref1 = _ref.commit) != null ? (_ref2 = _ref1.tree) != null ? _ref2.url : void 0 : void 0 : void 0) == null) {
          return R.alertManager.alert('Error reading master branch.', 'error');
        }
        this.runForkBtnJ.text(this.owner !== 'arthursw' ? this.owner : 'Main repository');
        this.commit.lastCommitSha = master.commit.sha;
        this.request(master.commit.commit.tree.url + '?recursive=1', this.checkIfTreeExists);
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
              submit: this.readTree,
              data: savedGitTree
            });
            message = 'Do you want to load the changes which have not been committed yet (stored on your computer)?\n';
            message += '<strong>Warning: the repository has changed since you made the changes!</strong>\n';
            message += 'Consider checking the new version of the repository before committing your changes.';
            modal.addText(message);
            modal.show();
            this.readTree(content);
          } else {
            this.readTree(savedGitTree);
          }
        } else {
          this.readTree(content);
        }
      };

      FileManager.prototype.readTree = function(content) {
        var tree, treeExists;
        this.gitTree = content.data || content;
        treeExists = this.tree != null;
        tree = this.buildTree(content.tree);
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
        }
        this.tree = this.fileBrowserJ.tree('getTree');
        this.tree.name = 'coffee';
        this.tree.file = {
          name: 'coffee',
          path: 'coffee',
          type: 'tree'
        };
        this.tree.id = content.tree.length;
        this.updateLeaves(this.tree);
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
            js = R.codeEditor.compile(node.source);
            if (js == null) {
              return false;
            }
            jsFile.content = js;
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
            delete f.size;
            delete f.url;
            delete f.name;
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
          parent: this.commit.lastCommitSha
        };
        this.request('https://api.github.com/repos/' + this.owner + '/romanesco-client-code/git/commits', this.updateHead, 'post', data);
      };

      FileManager.prototype.updateHead = function(commit) {
        commit = this.checkError(commit);
        if (!commit) {
          return;
        }
        this.request('https://api.github.com/repos/' + this.owner + '/romanesco-client-code/git/refs/heads/master', this.checkCommit, 'patch', {
          sha: commit.sha, force: true
        });
      };

      FileManager.prototype.checkCommit = function(commit) {
        commit = this.checkError(commit);
        if (!commit) {
          return;
        }
        R.alertManager.alert('Successfully committed!', 'success');
        Utils.LocalStorage.set('files:' + this.owner, null);
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

}).call(this);
