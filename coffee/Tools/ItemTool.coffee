define [ 'Tools/Tool' ], (Tool) ->

	# ItemTool: mother class of all Div creation tools (this will create a new div on top of the canvas, with custom content, and often resizable)
	# User will create a selection rectangle
	# once the mouse is released, the box will be validated by Div.end() (check that the Div does not overlap two planets, and does not intersects with an Lock)
	# children classes will use Div.end() to check if it is valid and:
	# - initialize a modal to ask the user more info about the Div
	# - or directly save the Div
	# the Div will be created on server response
	# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
	# begin, update, and end handlers emit the events to websocket
	class ItemTool extends Tool

		constructor: (@Item) ->
			super(true)
			# test: @isDiv = true
			return

		updateParameters: ()->
			R.controllerManager.setSelectedTool(@Item)
			return

		select: (deselectItems=true, updateParameters=true)->
			R.rasterizer.drawItems()
			super
			return

		# Begin div action:
		# - create new selection rectangle
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
		begin: (event, from=R.me) ->
			point = event.point

			R.tools.select.deselectAll()

			R.currentPaths[from] = new P.Path.Rectangle(point, point)
			R.currentPaths[from].name = 'div tool rectangle'
			R.currentPaths[from].dashArray = [4, 10]
			R.currentPaths[from].strokeColor = 'black'
			R.view.selectionLayer.addChild(R.currentPaths[from])

			# if R.me? and from==R.me then R.socket.emit( "begin", R.me, R.eventToObject(event), @name, R.currentPaths[from].data )
			if R.me? and from==R.me then R.socket.emit "bounce", tool: @name, function: "begin", arguments: [event, R.me, R.currentPaths[from].data]
			return

		# Update div action:
		# - update selection rectangle
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		update: (event, from=R.me) ->
			point = event.point

			R.currentPaths[from].segments[2].point = point
			R.currentPaths[from].segments[1].point.x = point.x
			R.currentPaths[from].segments[3].point.y = point.y
			R.currentPaths[from].fillColor = null

			bounds = R.currentPaths[from].bounds
			locks = @constructor.Item.Lock.getLocksWhichIntersect(bounds)
			for lock in locks
				if lock.owner != R.me or (@name != 'Lock' and not lock.rectangle.contains(bounds))
					R.currentPaths[from].fillColor = 'red'

			if R.view.grid.rectangleOverlapsTwoPlanets(bounds)
				R.currentPaths[from].fillColor = 'red'

			# if R.me? and from==R.me then R.socket.emit( "update", R.me, point, @name )
			if R.me? and from==R.me then R.socket.emit "bounce", tool: @name, function: "update", arguments: [event, R.me]
			return

		# End div action:
		# - remove selection rectangle
		# - check if div if valid (does not overlap two planets, and does not intersects with an Lock), return false otherwise
		# - resize div to 10x10 if area if lower than 100
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			if from != R.me 					# if event come from websocket (another user in the room is creating the Div): just remove the selection rectangle
				R.currentPaths[from].remove()
				delete R.currentPaths[from]
				return false

			point = event.point

			R.currentPaths[from].remove()

			bounds = R.currentPaths[from].bounds
			locks = @constructor.Item.Lock.getLocksWhichIntersect(bounds)
			for lock in locks
				if lock.owner != R.me or (@name != 'Lock' and not lock.rectangle.contains(bounds))
					R.alertManager.alert 'Your item intersects with a locked area.', 'error'
					return false

			# check if div if valid (does not overlap two planets, and does not intersects with an Lock), return false otherwise
			if R.view.grid.rectangleOverlapsTwoPlanets(bounds)
				R.alertManager.alert 'Your item overlaps with two planets.', 'error'
				return false

			if R.currentPaths[from].bounds.area < 100 			# resize div to 10x10 if area if lower than 100
				R.currentPaths[from].width = 10
				R.currentPaths[from].height = 10

			# if R.me? and from==R.me then R.socket.emit( "end", R.me, point, @name )
			if R.me? and from==R.me then R.socket.emit "bounce", tool: @name, function: "end", arguments: [event, R.me]

			return true

	R.Tools.Item = ItemTool
	return ItemTool
