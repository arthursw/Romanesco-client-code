define [
	'utils', 'RTool'
], (utils, RTool) ->

	# ItemTool: mother class of all RDiv creation tools (this will create a new div on top of the canvas, with custom content, and often resizable)
	# User will create a selection rectangle
	# once the mouse is released, the box will be validated by RDiv.end() (check that the RDiv does not overlap two planets, and does not intersects with an RLock)
	# children classes will use RDiv.end() to check if it is valid and:
	# - initialize a modal to ask the user more info about the RDiv
	# - or directly save the RDiv
	# the RDiv will be created on server response
	# begin, update, and end handlers are called by onMouseDown handler (then from == g.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == RItem initial data)
	# begin, update, and end handlers emit the events to websocket
	class ItemTool extends RTool

		constructor: (@RItem) ->
			super(true)
			# test: @isDiv = true
			return

		select: (deselectItems=true, updateParameters=true)->
			g.rasterizer.drawItems()
			super
			return

		# Begin div action:
		# - create new selection rectangle
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		# begin, update, and end handlers are called by onMouseDown handler (then from == g.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == RItem initial data)
		begin: (event, from=g.me) ->
			point = event.point

			g.deselectAll()

			g.currentPaths[from] = new Path.Rectangle(point, point)
			g.currentPaths[from].name = 'div tool rectangle'
			g.currentPaths[from].dashArray = [4, 10]
			g.currentPaths[from].strokeColor = 'black'
			g.selectionLayer.addChild(g.currentPaths[from])

			# if g.me? and from==g.me then g.chatSocket.emit( "begin", g.me, g.eventToObject(event), @name, g.currentPaths[from].data )
			if g.me? and from==g.me then g.chatSocket.emit "bounce", tool: @name, function: "begin", arguments: [event, g.me, g.currentPaths[from].data]
			return

		# Update div action:
		# - update selection rectangle
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		update: (event, from=g.me) ->
			point = event.point

			g.currentPaths[from].segments[2].point = point
			g.currentPaths[from].segments[1].point.x = point.x
			g.currentPaths[from].segments[3].point.y = point.y
			g.currentPaths[from].fillColor = null

			bounds = g.currentPaths[from].bounds
			locks = g.RLock.getLocksWhichIntersect(bounds)
			for lock in locks
				if lock.owner != g.me or (@name != 'Lock' and not lock.rectangle.contains(bounds))
					g.currentPaths[from].fillColor = 'red'

			if g.rectangleOverlapsTwoPlanets(bounds)
				g.currentPaths[from].fillColor = 'red'

			# if g.me? and from==g.me then g.chatSocket.emit( "update", g.me, point, @name )
			if g.me? and from==g.me then g.chatSocket.emit "bounce", tool: @name, function: "update", arguments: [event, g.me]
			return

		# End div action:
		# - remove selection rectangle
		# - check if div if valid (does not overlap two planets, and does not intersects with an RLock), return false otherwise
		# - resize div to 10x10 if area if lower than 100
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		end: (event, from=g.me) ->
			if from != g.me 					# if event come from websocket (another user in the room is creating the RDiv): just remove the selection rectangle
				g.currentPaths[from].remove()
				delete g.currentPaths[from]
				return false

			point = event.point

			g.currentPaths[from].remove()

			bounds = g.currentPaths[from].bounds
			locks = g.RLock.getLocksWhichIntersect(bounds)
			for lock in locks
				if lock.owner != g.me or (@name != 'Lock' and not lock.rectangle.contains(bounds))
					g.romanesco_alert 'Your item intersects with a locked area.', 'error'
					return false

			# check if div if valid (does not overlap two planets, and does not intersects with an RLock), return false otherwise
			if g.rectangleOverlapsTwoPlanets(bounds)
				g.romanesco_alert 'Your item overlaps with two planets.', 'error'
				return false

			if g.currentPaths[from].bounds.area < 100 			# resize div to 10x10 if area if lower than 100
				g.currentPaths[from].width = 10
				g.currentPaths[from].height = 10

			# if g.me? and from==g.me then g.chatSocket.emit( "end", g.me, point, @name )
			if g.me? and from==g.me then g.chatSocket.emit "bounce", tool: @name, function: "end", arguments: [event, g.me]

			return true

	return ItemTool