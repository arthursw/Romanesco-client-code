define [
	'utils', 'ItemTool'
], (utils, ItemTool) ->

	# RText creation tool
	class TextTool extends ItemTool

		@rname = 'Text'
		@description = ''
		@iconURL = 'text.png'
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'

		constructor: () ->
			super(g.RText)
			return

		# End RText action:
		# - save RText if it is valid (does not overlap two planets, and does not intersects with an RLock)
		# the RText will be created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=g.me) ->
			if super(event, from)
				text = new g.RText(g.currentPaths[from].bounds)
				text.finish()
				if not text.group then return
				text.select()
				text.save(true)
				delete g.currentPaths[from]
			return

	return TextTool