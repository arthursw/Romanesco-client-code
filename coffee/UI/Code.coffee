define [ 'UI/Modal', 'coffee', 'jqtree' ], (Modal, CoffeeScript) ->

	class FileManager

		constructor: ()->
			@codeJ = $('#Code')

			@runForkBtnJ = @codeJ.find('button.run-fork')
			@loadOwnForkBtnJ = @codeJ.find('li.user-fork')
			@listForksBtnJ = @codeJ.find('li.list-forks')
			@loadCustomForkBtnJ = @codeJ.find('li.custom-fork')
			@createForkBtnJ = @codeJ.find('li.create-fork')

			@loadOwnForkBtnJ.hide()
			@createForkBtnJ.hide()

			@getForks(@getUserFork)

			@runForkBtnJ.click @runFork
			@loadOwnForkBtnJ.click @loadOwnFork
			@loadCustomForkBtnJ.click @loadCustomFork
			@listForksBtnJ.click @listForks
			@createForkBtnJ.click @createFork

			@createFileBtnJ = @codeJ.find('button.create-file')
			@runBtnJ = @codeJ.find('button.run')
			@commitBtnJ = @codeJ.find('button.commit')
			@createPullRequestBtnJ = @codeJ.find('button.pull-request')

			@createFileBtnJ.click @onCreateFile
			@runBtnJ.click @runFork
			@commitBtnJ.click @onCommitClicked
			@createPullRequestBtnJ.click @createPullRequest

			@fileBrowserJ = @codeJ.find('.files')
			@files = []
			@nDirsToLoad = 1

			if R.repositoryOwner?
				@loadFork(owner: R.repositoryOwner)
			else
				@loadMainRepo()
			# $.get('https://api.github.com/repos/arthursw/romanesco-client-code/contents/', @loadFiles)
			# @state = '' + Math.random()
			# parameters =
			# 	client_id: '4140c547598d6588fd37'
			# 	redirect_uri: 'http://localhost:8000/github'
			# 	scope: 'public_repo'
			# 	state: @state
			# $.get( { url: 'https://github.com/login/oauth/authorize', data: parameters }, (result)-> console.log result; return)
			return

		getUserFork: (forks)=>
			forks = @checkError(forks)
			if not forks then return
			hasFork = false
			for fork in forks
				if fork.owner.login == R.me
					@loadOwnForkBtnJ.show()
					@createForkBtnJ.hide()
					hasFork = true
					break
			if not hasFork
				@loadOwnForkBtnJ.hide()
				@createForkBtnJ.show()
			return

		getForks: (callback)->
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/forks', callback)
			return

		forkRowClicked: (event, field, value, row, $element)=>
			@loadFork(row)
			Modal.getModalByTitle('Forks').hide()
			return

		displayForks: (forks)=>
			forks = @checkError(forks)
			if not forks then return
			modal = Modal.createModal( title: 'Forks', submit: null )

			tableData =
				columns: [
					field: 'owner'
					title: 'Owner'
				,
					field: 'date'
					title: 'Date'
				,
					field: 'githubURL'
					title: 'Github URL'
				]
				data: []
				formatter: (value, row, index)->
					return "<a href='#{value}'>value</a>"

			for fork in forks
				date = new Date(fork.updated_at)
				tableData.data.push( owner: fork.owner.login, date: date.toLocaleString(), githubURL: fork.html_url )

			tableJ = modal.addTable(tableData)
			tableJ.on 'click-cell.bs.table', @forkRowClicked
			modal.show()
			return

		listForks: (event)=>
			event?.preventDefault()
			@getForks(@displayForks)
			return

		loadMainRepo: (event)=>
			event?.preventDefault()
			@loadFork(owner: 'arthursw')
			return

		loadOwnFork: (event)=>
			event?.preventDefault()
			@loadFork(owner: R.githubLogin)
			return

		loadFork: (data)=>
			@owner = data.owner
			@request('https://api.github.com/repos/' + @owner + '/romanesco-client-code/contents/', @loadTree)
			return

		loadCustomFork: (event)=>
			event?.preventDefault()
			modal = Modal.createModal( title: 'Load repository', submit: @loadFork )
			modal.addTextInput(name: 'owner', placeholder: 'The login name of the fork owner (ex: george)', label: 'Owner', required: true, submitShortcut: true)
			modal.show()
			return

		forkCreationResponse: (response)=>
			if response.status == 202
				message = 'Congratulation, you just made a new fork!'
				message += 'It should be available in a few seconds at this adress:' + response.url
				message += 'You will then be able to improve or customize it.'
				R.alertManager.alert message, 'success'
			return

		createFork: (event)=>
			event?.preventDefault()
			@request('https://api.github.com/repos/' + R.githubLogin + '/romanesco-client-code/forks', @forkCreationResponse, 'post')
			return

		request: (request, callback, method, data, params, headers)->
			Dajaxice.draw.githubRequest(callback, {githubRequest: request, method: method, data: data, params: params, headers: headers})
			return

		getNodeFromPath: (path)->
			dirs = path.split('/')
			node = @tree
			for dirName, i in dirs
				node = node.leaves[dirName]
			return node

		getParentNode: (file, node)->
			dirs = file.path.split('/')
			file.name = dirs.pop()

			for dirName, i in dirs
				node.leaves[dirName] ?= { leaves: {}, children: [] }
				node = node.leaves[dirName]
			return node

		buildTree: (files)->
			tree = { leaves: {}, children: [] }

			for file, i in files
				parentNode = @getParentNode(file, tree)
				name = file.name
				parentNode.leaves[name] ?= { leaves: {}, children: [] }
				node = parentNode.leaves[name]
				node.type = file.type
				node.path = file.path
				node.sha = file.sha
				node.label = name
				node.id = i
				parentNode.children.push(node)

			tree.id = i
			return tree

		updateTree: (tree=@tree)->
			tree.leaves = {}
			for node, i in tree.children
				tree.leaves[node.name] = node
				@updateTree(node)
			return

		loadTree: (content)=>
			content = @checkError(content)
			if not content then return
			for file in content
				if file.name == 'coffee'
					@request(file.git_url + '?recursive=1', @readTree)
					break
			btnName = if @owner != 'arthursw' then @owner else 'Main repository'
			@runForkBtnJ.text(btnName)
			return

		onCanMoveTo: (moved_node, target_node, position)->
			targetIsFolder = target_node.type == 'tree'
			nameExistsInTargetNode = target_node.leaves[moved_node.name]?
			return (targetIsFolder and not nameExistsInTargetNode) or position != 'inside'

		onCreateLi: (node, liJ)=>
			deleteButtonJ = $("""
			<button type="button" class="close delete" aria-label="Close">
				<span aria-hidden="true">&times;</span>
			</button>
			""")
			deleteButtonJ.attr('data-path', node.path)
			deleteButtonJ.click(@onDeleteFile)
			liJ.find('.jqtree-element').append(deleteButtonJ)
			return

		readTree: (content)=>
			content = @checkError(content)
			if not content then return
			treeExists = @tree?
			@tree = @buildTree(content.tree)

			if treeExists
				@fileBrowserJ.tree('loadData', @tree.children)
			else
				@fileBrowserJ.tree(
					data: @tree.children
					autoOpen: true
					dragAndDrop: true
					onCanMoveTo: @onCanMoveTo
					onCreateLi: @onCreateLi
				)
				@fileBrowserJ.bind('tree.click', @onNodeClicked)
				@fileBrowserJ.bind('tree.dblclick', @onNodeDoubleClicked)
				@fileBrowserJ.bind('tree.move', @onFileMoved)

			@tree = @fileBrowserJ.tree('getTree')
			@tree.path = ''
			@updateTree()
			@load()
			return

		onNodeClicked: (event)=>
			if event.node.type == 'tree'
				elementIsToggler = $(event.click_event.target).hasClass('jqtree-toggler')
				elementIsTitle = $(event.click_event.target).hasClass('jqtree-title-folder')
				if elementIsToggler or elementIsTitle
					@fileBrowserJ.tree('toggle', event.node)
				return
			if event.node.source?
				R.showCodeEditor(event.node)
			else
				@loadFile(event.node.path, @openFile)
			return

		submitNewName: (event)=>
			if event.type == 'keyup' and event.which != 13 then return
			inputGroupJ = $(event.target).parents('.input-group')
			newName = inputGroupJ.find('.name-input').val()
			id = inputGroupJ.attr('data-node-id')
			node = @fileBrowserJ.tree('getNodeById', id)
			if newName == '' then newName = node.name
			inputGroupJ.replaceWith('<span class="jqtree-title jqtree_common">' + newName + '</span>')
			$(node.element).find('button.delete:first').show()
			delete node.parent.leaves[node.name]
			node.parent.leaves[newName] = node
			node.newPath = node.path.replace(node.name, newName)
			node.name = newName
			# @fileBrowserJ.tree('updateNode', node, newName)
			return

		onNodeDoubleClicked: (event)=>
			node = event.node
			inputGroupJ = $("""
			<div class="input-group">
				<input type="text" class="form-control name-input" placeholder="">
				<span class="input-group-btn">
					<button class="btn btn-default" type="button">Ok</button>
				</span>
			</div>
			""")
			inputGroupJ.attr('data-node-id', node.id)
			inputJ = inputGroupJ.find('.name-input')
			inputJ.attr('placeholder', node.name)
			inputJ.keyup @submitNewName
			inputJ.blur @submitNewName
			buttonJ = inputGroupJ.find('.btn')
			buttonJ.click @submitNewName
			$(node.element).find('.jqtree-title:first').replaceWith(inputGroupJ)
			inputJ.focus()
			$(node.element).find('button.delete:first').hide()
			return

		openFile: (file)=>
			file = @checkError(file)
			if not file then return
			path = file.path.replace('coffee/', '')			# @tree is built from the 'coffee' directory
			fileNode = @getNodeFromPath(path)
			fileNode.source = atob(file.content)
			R.showCodeEditor(fileNode)
			return

		createName: (newNode, parentTree)->
			i = 1
			while parentTree.leaves[newNode.label]?
				newNode.label = 'NewScript' + i + '.coffee'
			return

		onCreateFile: ()=>
			node = @fileBrowserJ.tree('getSelectedNode')
			newNode =
				label: 'NewScript.coffee'
				type: 'blob'
				children: []
				leaves: {}
				source: ''
				id: @tree.id++
			parentNode = null
			parentTree = null
			method = 'appendNode'
			# add new node in jqTree
			if node == false
				newNode.path = newNode.label
				parentTree = @tree
			else if node.type == 'tree'
				newNode.path = node.path + '/' + newNode.label
				parentNode = node
				parentTree = parentNode
			else
				newNode.path = if node.parent.path then node.parent.path + '/' + newNode.label else newNode.label
				method = 'addNodeAfter'
				parentNode = node.parent
				parentTree = parentNode or @tree

			@createName(newNode, parentTree)
			newNode = @fileBrowserJ.tree(method, newNode, parentNode)
			# update leaves
			parentTree.leaves[newNode.name] = newNode

			# show in code editor
			R.showCodeEditor(newNode)
			return

		onFileMoved: (event)=>
			console.log('moved_node', event.move_info.moved_node)
			console.log('target_node', event.move_info.target_node)
			console.log('position', event.move_info.position)
			console.log('previous_parent', event.move_info.previous_parent)
			parent = event.move_info.moved_node.parent
			parentPath = if parent? and parent.path != '' then parent.path + '/' else ''
			event.move_info.moved_node.newPath = parentPath + event.move_info.moved_node.name
			@save()
			return

		saveFile: (fileNode, source)->
			fileNode.source = source
			fileNode.update = true
			$(fileNode.element).addClass('modified')
			@save()
			return

		deleteNode: (node)->
			if node.type == 'tree'
				for child in node.children
					@deleteNode(child)
			node.delete = true
			@fileBrowserJ.tree('removeNode', node)
			return

		confirmDeleteFile: (data)=>
			@deleteNode(data.node)
			return

		onDeleteFile: (event)=>
			event.stopPropagation()
			path = $(event.target).closest('button.delete').attr('data-path')
			node = @getNodeFromPath(path)
			if not node? then return
			modal = Modal.createModal( title: 'Delete file?', submit: @confirmDeleteFile, data: node: node )
			modal.addText('Do you really want to delete "' + node.name + '"?')
			modal.show()
			return

		loadFile: (path, callback)->
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/contents/coffee/'+path, callback)
			return

		# Save & load

		getNodes: (tree=@tree, nodes=[])->
			for name, node of tree.leaves
				if node.type == 'tree'
					nodes = @getNodes(node, nodes)
				nodes.push(node)
			return nodes

		save: ()->
			nodes = @getNodes()
			forkFiles = []
			for node in nodes
				if node.type == 'tree' then continue
				if node.source? or node.create? or node.delete?
					file =
						name: node.name
						type: node.type
						path: node.path
						newPath: node.newPath
						update: node.update
						source: node.source
						create: node.create
						delete: node.delete
					forkFiles.push(file)
			files = {}
			files[@owner] = forkFiles
			Utils.LocalStorage.set('files', files)
			return

		load: ()->
			files = Utils.LocalStorage.get('files')
			if files?[@owner]?
				for file in files[@owner]
					node = @getNodeFromPath(file.path)
					node.source = file.source
					node.create = file.create
					node.update = file.update
					node.delete = file.delete
					node.newPath = file.newPath
					$(node.element).addClass('modified')
			return

		# Create, Update & Delete files

		checkError: (response)->
			if response.status < 200 or response.status >= 300
				R.alertManager.alert('Error: ' + response.content.message, 'error')
				return false
			return response.content

		fileToData: (file, commitMessage, content=false, sha=false)->
			data =
				path: 'coffee/' + (file.newPath or file.path)
				message: commitMessage
			if content then data.content = btoa(file.source)
			if sha then data.sha = file.sha
			return data

		requestFile: (file, data, method='put')->
			path = 'coffee/' + file.path
			callback = (response)->
				if not R.fileManager.checkError(response) then return
				if file.newPath?
					file.path = file.newPath
					delete file.newPath
				R.alertManager.alert('Successfully committed ' + file.name + '.', 'success')
				return
			@request('https://api.github.com/repos/' + @owner + '/romanesco-client-code/contents/'+path, callback, method, data)
			return

		createFile: (file, commitMessage)->
			data = @fileToData(file, commitMessage, true)
			@requestFile(file, data)
			return

		updateFile: (file, commitMessage)->
			data = @fileToData(file, commitMessage, true, true)
			$(file.element).removeClass('modified')
			@requestFile(file, data)
			return

		deleteFile: (file, commitMessage)->
			data = @fileToData(file, commitMessage, false, true)
			@requestFile(file, data, 'delete')
			delete file.delete
			return

		# Run, Commit & Push request

		runLastCommit: (branch)=>
			branch = @checkError(branch)
			if not branch then return
			R.repository.owner = @owner
			R.repository.commit = branch.commit.sha
			R.view.updateHash()
			location.reload()
			return

		runFork: (data)=>
			if data?.owner? then @owner = data.owner
			@request('https://api.github.com/repos/' + @owner + '/romanesco-client-code/branches/master', @runLastCommit)
			return

		onCommitClicked: (event)=>
			modal = Modal.createModal( title: 'Commit', submit: @commit )
			modal.addTextInput(name: 'commitMessage', placeholder: 'Added the coffee maker feature.', label: 'Message', required: true, submitShortcut: true)
			modal.show()
			return

		commit: (data)=>
			nodes = @getNodes()
			nothingToCommit = true
			@filesToCommit = 0
			for file in nodes
				if file.delete or file.create or file.update or file.newPath? then @filesToCommit++
				if file.delete
					@deleteFile(file, data.commitMessage)
				else if file.create
					@createFile(file, data.commitMessage)
				else if file.update or file.newPath?
					@updateFile(file, data.commitMessage)
			if @filesToCommit==0
				R.alertManager.alert 'Nothing to commit.', 'Info'
			return

		createPullRequest: ()=>
			modal = Modal.createModal( title: 'Create pull request', submit: @createPullRequestSubmit )
			modal.addTextInput(name: 'title', placeholder: 'Amazing new feature', label: 'Title of the pull request', required: true)
			modal.addTextInput(name: 'branch', placeholder: 'master', label: 'Branch', required: true, submitShortcut: true)
			modal.addTextInput(name: 'body', placeholder: 'Please pull this in!', label: 'Message', required: false)
			modal.show()
			return

		createPullRequestSubmit: (data)=>
			data =
				title: data.title
				head: @owner + ':' + data.branch
				base: 'master'
				body: data.body
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/pulls', @checkError, 'post', data)
			return

		# loadFiles: (content)=>

		# 	for file in content
		# 		@files.push(file)
		# 		if file.type == 'dir'
		# 			@nDirsToLoad++
		# 			@request(file.url, @loadFiles)

		# 	@nDirsToLoad--

		# 	if @nDirsToLoad == 0

		# 		@tree = @buildTree(@files)

		# 		jqTreeData = { children: [] }
		# 		@buildJqTree(@tree, jqTreeData)

		# 		@fileBrowserJ.tree(
		# 			data: jqTreeData.children
		# 			autoOpen: true
		# 			dragAndDrop: true
		# 			onCanMoveTo: (moved_node, target_node, position)-> return target_node.file.type == 'dir'
		# 		)

		# 	return
	#
	# class ModuleCreator
	#
	# 	constructor: ()->
	# 		return

		createButton: (content)->

			source = atob(content.content)

			expressions = CoffeeScript.nodes(source).expressions
			properties = expressions[0]?.args?[1]?.body?.expressions?[0]?.body?.expressions

			if not properties? then return

			for property in properties
				name = property.variable?.properties?[0]?.name?.value
				value = property.value?.base?.value
				if not (value? and name?) then continue
				switch name
					when 'label'
						label = value
					when 'description'
						description = value
					when 'iconURL'
						iconURL = value
					when 'category'
						category = value

			###
			iconResult = /@iconURL = (\'|\"|\"\"\")(.*)(\'|\"|\"\"\")/.exec(source)

			if iconResult? and iconResult.length>=2
				iconURL = iconResult[2]

			descriptionResult = /@description = (\'|\"|\"\"\")(.*)(\'|\"|\"\"\")/.exec(source)

			if descriptionResult? and descriptionResult.length>=2
				description = descriptionResult[2]

			labelResult = /@label = (\'|\"|\"\"\")(.*)(\'|\"|\"\"\")/.exec(source)

			if labelResult? and labelResult.length>=2
				label = labelResult[2]
			###
			file = content.path.replace('coffee/', '')
			file = '"' + file.replace('.coffee', '') + '"'
			console.log '{ name: ' + label + ', popoverContent: ' + description + ', iconURL: ' + iconURL + ', file: ' + file + ', category: ' + category + ' }'
			return

		createButtons: (pathDirectory)->
			for name, node of pathDirectory.leaves
				if node.type != 'tree'
					@loadFile(node.path, @createButton)
				else
					@createButtons(node)
			return

		loadButtons: ()->
			@createButtons(@tree.leaves['Items'].leaves['Paths'])
			return

		registerModule: (@module)->
			@loadFile(@tree.leaves['ModuleLoader'].path, @registerModuleInModuleLoader)
			return

		insertModule: (source, module, position)->
			line = JSON.stringify(module)
			source.insert(line, position)
			return

		registerModuleInModuleLoader: (content)=>
			content = @checkError(content)
			if not content then return
			source = atob(content.content)
			buttonsResult = /buttons = \[/.exec(source)

			if buttonsResult? and buttonsResult.length>1
				@insertModule(source, @module, buttonsResult[1])

			return

	# FileManager.ModuleCreator = ModuleCreator
	return FileManager
