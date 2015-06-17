define [
	'utils', 'ItemTool'
], (utils, ItemTool) ->

	# RMedia creation tool
	class MediaTool extends ItemTool

		@rname = 'Media'
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
			super(g.RMedia)
			return

		# End RMedia action:
		# - init RMedia modal if it is valid (does not overlap two planets, and does not intersects with an RLock)
		# the RMedia modal window will ask the user some information about the media he wants to create, the RMedia will be saved once the user submits and created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=g.me) ->
			if super(event, from)
				g.RMedia.initialize(g.currentPaths[from].bounds)
				delete g.currentPaths[from]
			return

	return MediaTool