define [
	'utils', 'jquery'
], (utils) ->

	g = utils.g()

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
			@fileBrowserJ.bind('tree.select', @loadFile)
			@fileBrowserJ.bind('tree.move', @onFileMoved)
			return

		loadFile: (event)=>
			if event.node.type == 'tree' then return
			@request('https://api.github.com/repos/arthursw/romanesco-client-code/contents/coffee/'+event.node.path, @openFile)
			return

		openFile: (content)->
			g.showCodeEditor(atob(content.content))
			return

		onFileMoved: (event)=>
			console.log('moved_node', event.move_info.moved_node)
			console.log('target_node', event.move_info.target_node)
			console.log('position', event.move_info.position)
			console.log('previous_parent', event.move_info.previous_parent)
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

	g.FileManager = FileManager


	return