define [ 'Tools/Tool', 'UI/Button' ], (Tool, Button) ->

	# PathTool: the mother class of all drawing tools
	# doctodo: P.Path are created with three steps:
	# - begin: initialize RPath: create the group, controlPath etc., and initialize the drawing
	# - update: update the drawing
	# - end: finish the drawing and finish RPath initialization
	# doctodo: explain polygon mode
	# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
	# begin, update, and end handlers emit the events to websocket
	class PathTool extends Tool

		@label = ''
		@description = ''
		@iconURL = ''
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'
		@drawItems = true

		# Find or create a button for the tool in the sidebar (if the button is created, add it default or favorite tool list depending on the user settings stored in local storage, and whether the tool was just created in a newly created script)
		# set its name and icon if an icon url is provided, or create an icon with the letters of the name otherwise
		# the icon will be made with the first two letters of the name if the name is in one word, or the first letter of each words of the name otherwise
		# @param [RPath constructor] the RPath which will be created by this tool
		# @param [Boolean] whether the tool was just created (with the code editor) or not
		constructor: (@RPath, justCreated=false) ->
			@name = @RPath.label
			@constructor.description = @RPath.rdescription
			@constructor.iconURL = @RPath.iconURL
			@constructor.category = @RPath.category

			# delete tool if it already exists (when user creates a tool)
			if justCreated and R.tools[@name]?
				g[@RPath.constructor.name] = @RPath
				R.tools[@name].remove()
				delete R.tools[@name]
				R.lastPathCreated = @RPath

			# check if a button already exists (when created fom a module)
			@btnJ = R.allToolsJ.find('li[data-name="'+@name+'"]')

			if @btnJ.length==0
				favorite = justCreated or R.favoriteTools?.indexOf(@name)>=0
				@btnJ = new Button(@name, @RPath.iconURL, favorite, @RPath.category)
			else
				@btnJ.off("click")

			# must remove the icon of precise path otherwise all children class will inherit the same icon
			if @name == 'Precise path' then @RPath.iconURL = null

			@cursor = @RPath.cursor
			super(@RPath.label, false)

			if justCreated
				@select()

			return

		# Remove tool button, useful when user create a tool which already existed (overwrite the tool)
		remove: () ->
			@btnJ.remove()
			return

		# Select: add the mouse move listener on the tool (userful when creating a path in polygon mode)
		# todo: move this to main, have a global onMouseMove handler like other handlers
		select: (deselectItems=true, updateParameters=true)->

			R.rasterizer.drawItems()

			super

			R.tool.onMouseMove = @move
			return

		updateParameters: ()->
			R.controllerManager.setSelectedTool(@RPath)
			return

		# Deselect: remove the mouse move listener
		deselect: ()->
			super()
			@finish()
			R.tool.onMouseMove = null
			return

		# Begin path action:
		# - deselect all and create new P.Path in all case except in polygonMode (add path to R.currentPaths)
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		# @param [Object] Item initial data (strokeWidth, strokeColor, etc.)
		# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
		begin: (event, from=R.me, data=null) ->
			if event.event.which == 2 then return 			# if middle mouse button (wheel) pressed: return

			if 100 * P.view.zoom < 10
				R.alertManager.alert("You can not draw path at a zoom smaller than 10.", "Info")
				return

			# deselect all and create new P.Path in all case except in polygonMode
			if not (R.currentPaths[from]? and R.currentPaths[from].data?.polygonMode) 	# if not in polygon mode
				Tool.Select.deselectAll()
				R.currentPaths[from] = new @RPath(Date.now(), data)
				# R.currentPaths[from].select(false, false)

			R.currentPaths[from].beginCreate(event.point, event, false)

			# emit event on websocket (if user is the author of the event)
			# if R.me? and from==R.me then R.chatSocket.emit( "begin", R.me, R.eventToObject(event), @name, R.currentPaths[from].data )

			if R.me? and from==R.me
				data = R.currentPaths[from].data
				data.id = R.currentPaths[from].id
				R.chatSocket.emit "bounce", tool: @name, function: "begin", arguments: [event, R.me, data]
			return

		# Update path action:
		# update path action and emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse drag event
		# @param [String] author (username) of the event
		update: (event, from=R.me) ->
			R.currentPaths[from].updateCreate(event.point, event, false)
			# R.currentPaths[from].group.visible = true
			# if R.me? and from==R.me then R.chatSocket.emit( "update", R.me, R.eventToObject(event), @name)
			if R.me? and from==R.me then R.chatSocket.emit "bounce", tool: @name, function: "update", arguments: [event, R.me]
			return

		# Update path action (usually from a mouse move event, necessary for the polygon mode):
		# @param [Paper event or REvent] (usually) mouse move event
		move: (event) ->
			if R.currentPaths[R.me]?.data?.polygonMode then R.currentPaths[R.me].createMove?(event)
			return

		createPath: (event, from)->
			path = R.currentPaths[from]
			if not path.group then return

			if R.me? and from==R.me 						# if user is the author of the event: select and save path and emit event on websocket

				# if path.rectangle.area == 0
				# 	path.remove()
				# 	delete R.currentPaths[from]
				# 	return

				# bounds = path.getBounds()
				# locks = Lock.getLocksWhichIntersect(bounds)
				# for lock in locks
				# 	if lock.rectangle.contains(bounds)
				# 		if lock.owner == R.me
				# 			lock.addItem(path)
				# 		else
				# 			R.alertManager.alert("The path intersects with a lock", "Warning")
				# 			path.remove()
				# 			delete R.currentPaths[from]
				# 			return
				# if path.getDrawingBounds().area > R.rasterizer.maxArea()
				# 	R.alertManager.alert("The path is too big", "Warning")
				# 	path.remove()
				# 	delete R.currentPaths[from]
				# 	return

				if R.me? and from==R.me then R.chatSocket.emit "bounce", tool: @name, function: "createPath", arguments: [event, R.me]

				path.save(true)
				path.select(false)
			else
				path.endCreate(event.point, event)
			delete R.currentPaths[from]
			return

		# End path action:
		# - end path action
		# - if not in polygon mode: select and save path and emit event on websocket (if user is the author of the event), (remove path from R.currentPaths)
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			path = R.currentPaths[from]

			path.endCreate(event.point, event, false)

			if not path.data?.polygonMode
				@createPath(event, from)

			return

		# Finish path action (necessary in polygon mode):
		# - check that we are in polygon mode (return otherwise)
		# - end path action
		# - select and save path and emit event on websocket (if user is the author of the event), (remove path from R.currentPaths)
		# @param [String] author (username) of the event
		finish: (from=R.me)->
			if not R.currentPaths[R.me]?.data?.polygonMode then return false
			R.currentPaths[from].finish()
			@createPath(event, from)
			return true

		keyUp: (event)->
			switch event.key
				when 'enter'
					@finish?()
				when 'escape'
					finishingPath = @finish?()
					if not finishingPath
						Tool.Select.deselectAll()
			return

	Tool.Path = PathTool
	return PathTool
