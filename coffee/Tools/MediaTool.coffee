define [ 'Tools/Tool' ], (Tool) ->

	# Media creation tool
	class MediaTool extends Tool.Item

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
			super(R.Media)
			return

		# End Media action:
		# - init Media modal if it is valid (does not overlap two planets, and does not intersects with an Lock)
		# the Media modal window will ask the user some information about the media he wants to create, the Media will be saved once the user submits and created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			if super(event, from)
				R.Media.initialize(R.currentPaths[from].bounds)
				delete R.currentPaths[from]
			return

	Tool.Media = MediaTool
	return MediaTool
