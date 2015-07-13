define [ 'Tools/Tool', 'Tools/ItemTool', 'Items/Divs/Text' ], (Tool, ItemTool, Text) ->

	# Text creation tool
	class TextTool extends ItemTool

		@label = 'Text'
		@description = ''
		@iconURL = 'text.png'
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'
		@order = 5

		constructor: () ->
			super(Text)
			return

		# End Text action:
		# - save Text if it is valid (does not overlap two planets, and does not intersects with an Lock)
		# the Text will be created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			if super(event, from)
				text = new Text(R.currentPaths[from].bounds)
				text.finish()
				if not text.group then return
				text.select()
				text.save(true)
				delete R.currentPaths[from]
			return

	R.Tools.Text = TextTool
	return TextTool
