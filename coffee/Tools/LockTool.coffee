define [
	'utils', 'ItemTool'
], (utils, ItemTool) ->

	# RLock creation tool
	class LockTool extends ItemTool

		@rname = 'Lock'
		@description = ''
		@iconURL = 'lock.png'
		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 0, y:0
			name: 'default'
			icon: 'key'

		constructor: () ->
			super(g.RLock)
			@textItem = null
			return

		# Update lock action:
		# - display lock cost (in romanescoins) in selection rectangle
		# @param [Paper event or REvent] (usually) mouse move event
		# @param [String] author (username) of the event
		update: (event, from=g.me) ->
			point = event.point

			cost = g.currentPaths[from].bounds.area/1000.0

			@textItem?.remove()
			@textItem = new PointText(point)
			@textItem.justification = 'right'
			@textItem.fillColor = 'black'
			@textItem.content = '' + cost + ' romanescoins'
			super(event, from)
			return

		# End lock action:
		# - remove lock cost and init RLock modal if it is valid (does not overlap two planets, and does not intersects with an RLock)
		# the RLock modal window will ask the user some information about the lock he wants to create, the RLock will be saved once the user submits and created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=g.me) ->
			@textItem?.remove()
			if super(event, from)
				g.RLock.initialize(g.currentPaths[from].bounds)
				delete g.currentPaths[from]
			return

	return LockTool