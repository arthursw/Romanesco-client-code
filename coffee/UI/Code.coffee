define [ 'coffee', 'jqtree' ], (CoffeeScript) ->

	class FileManager

		constructor: ()->
			@fileBrowserJ = $('#Code').find('.files')
			@files = []
			@nDirsToLoad = 1
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/contents/', @loadTree)
			# $.get('https://api.github.com/repos/arthursw/romanesco-client-code/contents/', @loadFiles)
			# @state = '' + Math.random()
			# parameters =
			# 	client_id: '4140c547598d6588fd37'
			# 	redirect_uri: 'http://localhost:8000/github'
			# 	scope: 'public_repo'
			# 	state: @state
			# $.get( { url: 'https://github.com/login/oauth/authorize', data: parameters }, (result)-> console.log result; return)
			return

		request: (request, callback)->
			Dajaxice.draw.githubRequest(callback, {githubRequest: request})
			return

		createFile: ()->
			return

		updateFile: ()->
			return

		deleteFile: ()->
			return

		getParentNode: (file, node)->
			dirs = file.path.split('/')
			file.name = dirs.pop()

			for dirName, i in dirs
				node.children[dirName] ?= { children: {} }
				node = node.children[dirName]
			return node

		buildTree: (files)->
			tree = { children: {} }

			for file in files
				node = tree
				node = @getParentNode(file, node)
				node.children[file.name] ?= { children: {} }
				node.children[file.name].type = file.type
				node.children[file.name].path = file.path

			return tree

		buildJqTree: (tree, jqTree)->
			for name, node of tree.children
				jqTreeNode = { label: name, type: node.type, path: node.path, children: [] }
				node.jqTreeNode = jqTreeNode
				jqTree.children.push( jqTreeNode )
				@buildJqTree(node, jqTreeNode)
			return

		loadTree: (content)=>
			for file in content
				if file.name == 'coffee'
					@request(file.git_url + '?recursive=1', @readTree)
					break
			return

		readTree: (content)=>
			@tree = @buildTree(content.tree)

			jqTreeData = { children: [] }
			@buildJqTree(@tree, jqTreeData)

			@fileBrowserJ.tree(
				data: jqTreeData.children
				autoOpen: true
				dragAndDrop: true
				onCanMoveTo: (moved_node, target_node, position)-> return target_node.type == 'tree' or position != 'inside'
			)
			@fileBrowserJ.bind('tree.click', @loadAndOpenFile)
			@fileBrowserJ.bind('tree.move', @onFileMoved)
			return

		loadAndOpenFile: (event)=>
			if event.node.type == 'tree'
				@fileBrowserJ.tree('toggle', event.node)
				return
			@loadFile(event.node.path, @openFile)
			return

		openFile: (content)->
			R.showCodeEditor(atob(content.content))
			return

		onFileMoved: (event)=>
			console.log('moved_node', event.move_info.moved_node)
			console.log('target_node', event.move_info.target_node)
			console.log('position', event.move_info.position)
			console.log('previous_parent', event.move_info.previous_parent)
			return

		loadFile: (path, callback)->
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/contents/coffee/'+path, callback)
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
			for name, node of pathDirectory.children
				if node.type != 'tree'
					@loadFile(node.path, @createButton)
				else
					@createButtons(node)
			return

		loadButtons: ()->
			@createButtons(@tree.children['Items'].children['Paths'])
			return

		registerModule: (@module)->
			@loadFile(@tree.children['ModuleLoader'].path, @registerModuleInModuleLoader)
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
