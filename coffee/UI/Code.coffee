define [ 'coffee', 'jqtree' ], (CoffeeScript) ->

	class FileManager

		constructor: ()->
			@codeJ = $('#Code')

			@loadMainRepoBtnJ = @codeJ.find('button.main-repository')
			@loadOwnForkBtnJ = @codeJ.find('li.user-fork > a')
			@listForksBtnJ = @codeJ.find('li.list-forks > a')
			@loadCustomForkBtnJ = @codeJ.find('li.custom-fork > a')
			@createForkBtnJ = @codeJ.find('li.create-fork > a')

			@loadOwnForkBtnJ.hide()
			@createForkBtnJ.hide()

			@getForks(@getUserFork)

			@loadMainRepoBtnJ.click @loadMainRepo
			@loadOwnForkBtnJ.click @loadOwnFork
			@loadCustomForkBtnJ.click @loadCustomFork
			@listForksBtnJ.click @listForks
			@createForkBtnJ.click @createFork

			@createFileBtnJ = @codeJ.find('button.create-file')
			@runBtnJ = @codeJ.find('button.run')
			@commitBtnJ = @codeJ.find('button.commit')
			@createPullRequestBtnJ = @codeJ.find('button.pull-request')

			@createFileBtnJ.click @onCreateFile
			@runBtnJ.click @run
			@commitBtnJ.click @commit
			@createPullRequestBtnJ.click @createPullRequest

			@fileBrowserJ = @codeJ.find('.files')
			@files = []
			@nDirsToLoad = 1
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
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/forks/', callback)
			return

		forkRowClicked: (field, value, row, $element)=>
			if field == 'githubURL'
				window.location.href = value
			else
				@loadFork(row)
			return

		displayForks: (forks)=>
			modal = Modal.createModal( title: 'Forks', submit: null )

			tableData =
				columns: [
					field: 'author'
					title: 'Author'
				,
					field: 'date'
					title: 'Date'
				,
					field: 'githubURL'
					title: 'Github URL'
				]
				data: []

			for fork in forks
				tableData.data.push( author: fork.author, date: fork.date, githubURL: fork.url )

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
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/contents/', @loadTree)
			return

		loadOwnFork: (event)=>
			event?.preventDefault()
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/contents/', @loadTree)
			return

		loadFork: (data)=>
			@request('https://api.github.com/repos/' + data.author + '/romanesco-client-code/contents/', @loadTree)
			return

		loadCustomFork: (event)=>
			event?.preventDefault()
			modal = Modal.createModal( title: 'Load repository', submit: @loadFork )
			modal.addTextInput(name: 'author', placeholder: 'The login name of the fork owner (ex: george)', label: 'Owner', required: true)
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
			@request('https://api.github.com/repos/' + R.user.githubLogin + '/romanesco-client-code/forks/', @forkCreationResponse, 'post')
			return

		request: (request, callback, method, params, headers)->
			Dajaxice.draw.githubRequest(callback, {githubRequest: request, method: method, params: params, headers: headers})
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
				parentNode.leaves[name].type = file.type
				parentNode.leaves[name].path = file.path
				parentNode.leaves[name].label = name
				parentNode.leaves[name].id = i
				parentNode.children.push(parentNode.leaves[name])

			return tree

		updateTree: (tree=@tree)->
			for node, i in tree.children
				jqNode = @fileBrowserJ.tree('getNodeById', node.id)
				tree.leaves[node.label] = jqNode
				tree.children[i] = jqNode
				@updateTree(node)
			return

		loadTree: (content)=>
			for file in content
				if file.name == 'coffee'
					@request(file.git_url + '?recursive=1', @readTree)
					break
			return

		onCanMoveTo: (moved_node, target_node, position)->
			targetIsFolder = target_node.type == 'tree'
			nameExistsInTargetNode = target_node.leaves[moved_node.label]?
			return (targetIsFolder and not nameExistsInTargetNode) or position != 'inside'

		onCreateLi: (node, liJ)->
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
			@tree = @buildTree(content.tree)

			@fileBrowserJ.tree(
				data: @tree.children
				autoOpen: true
				dragAndDrop: true
				onCanMoveTo: @onCanMoveTo
				onCreateLi: @onCreateLi
			)
			@updateTree()

			@fileBrowserJ.bind('tree.click', @onNodeClicked)
			@fileBrowserJ.bind('tree.move', @onFileMoved)
			return

		onNodeClicked: (event)=>
			if event.node.type == 'tree'
				elementIsToggler = $(event.click_event.target).hasClass('jqtree-toggler')
				elementIsTitle = $(event.click_event.target).hasClass('jqtree-title-folder')
				if elementIsToggler or elementIsTitle
					@fileBrowserJ.tree('toggle', event.node)
				return
			if event.node.content?
				R.showCodeEditor(event.node)
			else
				@loadFile(event.node.path, @openFile)
			return

		openFile: (file)=>
			path = file.path.replace('coffee/', '')			# @tree is built from the 'coffee' directory
			fileNode = @getNodeFromPath(path)
			fileNode.content = file.content
			R.showCodeEditor(fileNode)
			return

		onCreateFile: ()=>
			node = @fileBrowserJ.tree('getSelectedNode')
			newNode =
				label: 'NewScript.coffee'
				type: 'blob'
				children: []
				leaves: {}
				content: ''
			parentNode = null
			# add new node in jqTree
			if node == false
				newNode.path = newNode.label
				newNode = @fileBrowserJ.tree('appendNode', newNode)
				parentNode = @tree
			else if node.type == 'tree'
				newNode.path = node.path + '/' + newNode.label
				newNode = @fileBrowserJ.tree('appendNode', newNode, node)
				parentNode = node
			else
				newNode.path = if node.parent.path then node.parent.path + '/' + newNode.label else newNode.label
				newNode = @fileBrowserJ.tree('addNodeAfter', newNode, node)
				parentNode = node.parent
			# update leaves
			parentNode.leaves[newNode.label] = newNode
			# show in code editor
			R.showCodeEditor(newNode)
			return

		onFileMoved: (event)=>
			console.log('moved_node', event.move_info.moved_node)
			console.log('target_node', event.move_info.target_node)
			console.log('position', event.move_info.position)
			console.log('previous_parent', event.move_info.previous_parent)
			event.move_info.moved_node.oldPath ?= event.move_info.previous_parent.path + '/' + event.move_info.moved_node.label
			@save()
			return

		saveFile: (fileNode, source)->
			fileNode.source = source
			$(fileNode.element).addClass('modified')
			@save()
			return

		onDeleteFile: (event)=>
			path = $(event.target).attr('data-path')
			node = @getNodeFromPath(path)
			node.delete = true
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
			Utils.LocalStorage.set('files', nodes)
			return

		load: ()->
			files = Utils.LocalStorage.get('files')
			@readTree(content: files)
			return

		# Create, Update & Delete files

		checkError: (message)->
			console.log message
			return

		fileToParameters: (file, commitMessage, content=false, sha=false)->
			params =
				path: file.path
				message: commitMessage
			if content then params.content = btoa(file.source)
			if sha then params.sha = file.sha
			return params

		requestFile: (file, params, method='put')->
			path = file.oldPath or file.path
			@request('https://api.github.com/repos/' + @author + '/romanesco-client-code/contents/'+path, @checkError, method, params)
			delete file.oldPath # to improve
			return

		createFile: (file, commitMessage)->
			params = @fileToParameters(file, commitMessage, true)
			@requestFile(file, params)
			return

		updateFile: (file, commitMessage)->
			params = @fileToParameters(file, commitMessage, true, true)
			$(file.element).removeClass('modified')
			@requestFile(file, params)
			return

		deleteFile: (file, commitMessage)->
			params = @fileToParameters(file, commitMessage, false, true)
			@requestFile(file, params, 'delete')
			delete file.delete
			return

		# Run, Commit & Push request

		runLastCommit: (commits)->
			R.repository.commit = _.last(commits).sha
			R.view.updateHash()
			location.reload()
			return

		run: ()=>
			@request('https://api.github.com/repos/' + @author + '/romanesco-client-code/commits/', @runLastCommit)
			return

		commit: (commitMessage)->
			nodes = @getNodes()
			for file in nodes
				if file.delete
					@deleteFile(file, commitMessage)
					continue
				else if file.source?
					if file.new?
						@createFile(file, commitMessage)
					else
						@updateFile(file, commitMessage)
			return

		createPullRequest: ()->
			modal = Modal.createModal( title: 'Create pull request', submit: @createPullRequestSubmit )
			modal.addTextInput(name: 'title', placeholder: 'Amazing new feature', label: 'Title of the pull request', required: true)
			modal.addTextInput(name: 'branch', placeholder: 'master', label: 'Branch', required: true)
			modal.addTextInput(name: 'body', placeholder: 'Please pull this in!', label: 'Message', required: false)
			modal.show()
			return

		createPullRequestSubmit: (data)->
			params =
				title: data.title
				head: @owner + ':' + data.branch
				base: 'master'
				body: data.body
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/pulls/', @checkError, 'post', params)
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
			source = atob(content.content)
			buttonsResult = /buttons = \[/.exec(source)

			if buttonsResult? and buttonsResult.length>1
				@insertModule(source, @module, buttonsResult[1])

			return

	# FileManager.ModuleCreator = ModuleCreator
	return FileManager
