define [ 'Tool' ], (Tool) ->

	# RMedia creation tool
	class Tool.Media extends Tool.Item

		@label = 'Media'
		@description = ''
		@iconURL = 'image.png'
		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 0, y:0
			name: 'default'
			icon: 'image'

		constructor: () ->
			super(R.RMedia)
			return

		# End RMedia action:
		# - init RMedia modal if it is valid (does not overlap two planets, and does not intersects with an RLock)
		# the RMedia modal window will ask the user some information about the media he wants to create, the RMedia will be saved once the user submits and created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			if super(event, from)
				R.RMedia.initialize(R.currentPaths[from].bounds)
				delete R.currentPaths[from]
			return

	new Tool.Media()
	return Tool.Media