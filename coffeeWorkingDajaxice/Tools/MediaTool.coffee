define [ 'Tools/Tool', 'Tools/ItemTool', 'Items/Divs/Media' ], (Tool, ItemTool, Media) ->

	# Media creation tool
	class MediaTool extends ItemTool

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
		@order = 6

		constructor: () ->
			super(Media)
			return

		# End Media action:
		# - init Media modal if it is valid (does not overlap two planets, and does not intersects with an Lock)
		# the Media modal window will ask the user some information about the media he wants to create, the Media will be saved once the user submits and created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			if super(event, from)
				Media.initialize(R.currentPaths[from].bounds)
				delete R.currentPaths[from]
			return

	R.Tools.Media = MediaTool
	return MediaTool
