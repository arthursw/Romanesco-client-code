define [ 'Tool' ], (Tool) ->

	# RText creation tool
	class Tool.Text extends Tool.Item

		@label = 'Text'
		@description = ''
		@iconURL = 'text.png'
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'

		constructor: () ->
			super(Text)
			return

		# End RText action:
		# - save RText if it is valid (does not overlap two planets, and does not intersects with an RLock)
		# the RText will be created on server response
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			if super(event, from)
				text = new R.RText(R.currentPaths[from].bounds)
				text.finish()
				if not text.group then return
				text.select()
				text.save(true)
				delete R.currentPaths[from]
			return

	new Tool.Text()
	return Tool.Text