define [
	'utils', 'RTool'
], (utils, RTool) ->

	# PathTool: the mother class of all drawing tools
	# doctodo: Path are created with three steps:
	# - begin: initialize RPath: create the group, controlPath etc., and initialize the drawing
	# - update: update the drawing
	# - end: finish the drawing and finish RPath initialization
	# doctodo: explain polygon mode
	# begin, update, and end handlers are called by onMouseDown handler (then from == g.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == RItem initial data)
	# begin, update, and end handlers emit the events to websocket
	class PathTool extends RTool

		@rname = ''
		@description = ''
		@iconURL = ''
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'

		# Find or create a button for the tool in the sidebar (if the button is created, add it default or favorite tool list depending on the user settings stored in local storage, and whether the tool was just created in a newly created script)
		# set its name and icon if an icon url is provided, or create an icon with the letters of the name otherwise
		# the icon will be made with the first two letters of the name if the name is in one word, or the first letter of each words of the name otherwise
		# @param [RPath constructor] the RPath which will be created by this tool
		# @param [Boolean] whether the tool was just created (with the code editor) or not
		constructor: (@RPath, justCreated=false) ->
			@name = @RPath.rname
			@constructor.description = @RPath.rdescription
			@constructor.iconURL = @RPath.iconURL
			@constructor.category = @RPath.category

			# delete tool if it already exists (when user creates a tool)
			if justCreated and g.tools[@name]?
				g[@RPath.constructor.name] = @RPath
				g.tools[@name].remove()
				delete g.tools[@name]
				g.lastPathCreated = @RPath

			# check if a button already exists (when created fom a module)
			@btnJ = g.allToolsJ.find('li[data-name="'+@name+'"]')

			if @btnJ.length==0
				favorite = justCreated or g.favoriteTools?.indexOf(@name)>=0
				@btnJ = new Sidebar.Button(@name, @RPath.iconURL, favorite, @RPath.category)
			else
				@btnJ.off("click")

			# must remove the icon of precise path otherwise all children class will inherit the same icon
			if @name == 'Precise path' then @RPath.iconURL = null

			@cursor = @RPath.cursor
			super(@RPath.rname, false)

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

			g.rasterizer.drawItems()

			super

			g.tool.onMouseMove = @move
			return

		updateParameters: ()->
			g.controllerManager.setSelectedTool(@RPath)
			return

		# Deselect: remove the mouse move listener
		deselect: ()->
			super()
			@finish()
			g.tool.onMouseMove = null
			return

		# Begin path action:
		# - deselect all and create new Path in all case except in polygonMode (add path to g.currentPaths)
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		# @param [Object] RItem initial data (strokeWidth, strokeColor, etc.)
		# begin, update, and end handlers are called by onMouseDown handler (then from == g.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == RItem initial data)
		begin: (event, from=g.me, data=null) ->
			if event.event.which == 2 then return 			# if middle mouse button (wheel) pressed: return

			if 100 * view.zoom < 10
				g.romanesco_alert("You can not draw path at a zoom smaller than 10.", "Info")
				return

			# deselect all and create new Path in all case except in polygonMode
			if not (g.currentPaths[from]? and g.currentPaths[from].data?.polygonMode) 	# if not in polygon mode
				g.deselectAll()
				g.currentPaths[from] = new @RPath(Date.now(), data)
				# g.currentPaths[from].select(false, false)

			g.currentPaths[from].beginCreate(event.point, event, false)

			# emit event on websocket (if user is the author of the event)
			# if g.me? and from==g.me then g.chatSocket.emit( "begin", g.me, g.eventToObject(event), @name, g.currentPaths[from].data )

			if g.me? and from==g.me
				data = g.currentPaths[from].data
				data.id = g.currentPaths[from].id
				g.chatSocket.emit "bounce", tool: @name, function: "begin", arguments: [event, g.me, data]
			return

		# Update path action:
		# update path action and emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse drag event
		# @param [String] author (username) of the event
		update: (event, from=g.me) ->
			g.currentPaths[from].updateCreate(event.point, event, false)
			# g.currentPaths[from].group.visible = true
			# if g.me? and from==g.me then g.chatSocket.emit( "update", g.me, g.eventToObject(event), @name)
			if g.me? and from==g.me then g.chatSocket.emit "bounce", tool: @name, function: "update", arguments: [event, g.me]
			return

		# Update path action (usually from a mouse move event, necessary for the polygon mode):
		# @param [Paper event or REvent] (usually) mouse move event
		move: (event) ->
			if g.currentPaths[g.me]?.data?.polygonMode then g.currentPaths[g.me].createMove?(event)
			return

		createPath: (event, from)->
			path = g.currentPaths[from]
			if not path.group then return

			if g.me? and from==g.me 						# if user is the author of the event: select and save path and emit event on websocket

				# if path.rectangle.area == 0
				# 	path.remove()
				# 	delete g.currentPaths[from]
				# 	return

				# bounds = path.getBounds()
				# locks = g.RLock.getLocksWhichIntersect(bounds)
				# for lock in locks
				# 	if lock.rectangle.contains(bounds)
				# 		if lock.owner == g.me
				# 			lock.addItem(path)
				# 		else
				# 			g.romanesco_alert("The path intersects with a lock", "Warning")
				# 			path.remove()
				# 			delete g.currentPaths[from]
				# 			return
				# if path.getDrawingBounds().area > g.rasterizer.maxArea()
				# 	g.romanesco_alert("The path is too big", "Warning")
				# 	path.remove()
				# 	delete g.currentPaths[from]
				# 	return

				if g.me? and from==g.me then g.chatSocket.emit "bounce", tool: @name, function: "createPath", arguments: [event, g.me]

				path.save(true)
				path.select(false)
			else
				path.endCreate(event.point, event)
			delete g.currentPaths[from]
			return

		# End path action:
		# - end path action
		# - if not in polygon mode: select and save path and emit event on websocket (if user is the author of the event), (remove path from g.currentPaths)
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=g.me) ->
			path = g.currentPaths[from]

			path.endCreate(event.point, event, false)

			if not path.data?.polygonMode
				@createPath(event, from)

			return

		# Finish path action (necessary in polygon mode):
		# - check that we are in polygon mode (return otherwise)
		# - end path action
		# - select and save path and emit event on websocket (if user is the author of the event), (remove path from g.currentPaths)
		# @param [String] author (username) of the event
		finish: (from=g.me)->
			if not g.currentPaths[g.me]?.data?.polygonMode then return false
			g.currentPaths[from].finish()
			@createPath(event, from)
			return true

		keyUp: (event)->
			switch event.key
				when 'enter'
					@finish?()
				when 'escape'
					finishingPath = @finish?()
					if not finishingPath
						g.deselectAll()
			return

	return PathTool