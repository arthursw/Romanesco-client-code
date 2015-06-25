define [ 'Tools/Tool' ], (Tool) ->

	# Lock creation tool
	class LockTool extends Tool.Item

		@label = 'Lock'
		@description = ''
		@iconURL = 'lock.png'
		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 0, y:0
			name: 'default'
			icon: 'key'
		@drawItems = false

		constructor: () ->
			super(Lock)
			@textItem = null
			return

		# Update lock action:
		# - display lock cost (in romanescoins) in selection rectangle
		# @param [Paper event or REvent] (usually) mouse move event
		# @param [String] author (username) of the event
		update: (event, from=R.me) ->
			point = event.point

			cost = R.currentPaths[from].bounds.area/1000.0

			@textItem?.remove()
			@textItem = new PointText(point)
			@textItem.justification = 'right'
			@textItem.fillColor = 'black'
			@textItem.content = '' + cost + ' romanescoins'
			super(event, from)
			return

		# End lock action:
		# - remove lock cost and init Lock modal if it is valid (does not overlap two planets, and does not intersects with an Lock)
		# the Lock modal window will ask the user some information about the lock he wants to create, the Lock will be saved once the user submits and created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			@textItem?.remove()
			if super(event, from)
				Lock.initialize(R.currentPaths[from].bounds)
				delete R.currentPaths[from]
			return

	Tool.Lock = LockTool
	return LockTool
