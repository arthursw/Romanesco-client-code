define [
	'utils', 'RTool'
], (utils, RTool) ->

	# MoveTool to scroll the view in the project space
	class MoveTool extends RTool

		@rname = 'Media'
		@description = ''
		@iconURL = 'move.png'
		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 32, y: 32
			name: 'default'
			icon: 'move'

		constructor: () ->
			super(true)
			@prevPoint = { x: 0, y: 0 } 	# the previous point the mouse was at
			@dragging = false 				# a boolean to see if user is dragging mouse
			return

		# Select tool and disable RDiv interactions (to be able to scroll even when user clicks on them, for exmaple disable textarea default behaviour)
		select: (deselectItems=false, updateParameters=true)->
			super(deselectItems, updateParameters)
			g.stageJ.addClass("moveTool")
			for div in g.divs
				div.disableInteraction()
			return

		# Reactivate RDiv interactions
		deselect: ()->
			super()
			g.stageJ.removeClass("moveTool")
			for div in g.divs
				div.enableInteraction()
			return

		begin: (event) ->
			# @dragging = true
			return

		update: (event) ->
			# if @dragging
			# 	g.RMoveBy(event.delta)
			return

		end: (moved) ->
			# if moved
			# 	g.commandManager.add(new MoveViewCommand())
			# @dragging = false
			return

		# begin with jQuery event
		# note: we could use g.eventToObject to convert the Native event into Paper.ToolEvent, however onMouseDown/Drag/Up also fire begin/update/end
		beginNative: (event) ->
			@dragging = true
			@initialPosition = { x: event.pageX, y: event.pageY }
			@prevPoint = { x: event.pageX, y: event.pageY }
			return

		# update with jQuery event
		updateNative: (event) ->
			if @dragging
				g.RMoveBy({ x: (@prevPoint.x-event.pageX)/view.zoom, y: (@prevPoint.y-event.pageY)/view.zoom })
				@prevPoint = { x: event.pageX, y: event.pageY }
			return

		# end with jQuery event
		endNative: (event) ->
			# if @initialPosition? and ( @initialPosition.x != event.pageX or @initialPosition.y != event.pageY )
			# 	g.commandManager.add(new MoveViewCommand())
			@dragging = false
			return

	return MoveTool