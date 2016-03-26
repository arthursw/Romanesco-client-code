define [ 'Items/Paths/PrecisePaths/StepPath', 'Spacebrew'], (StepPath, spacebrew) ->

	class SpacePath extends StepPath
		@label = 'Space path'
		@description = "This path sends coordinates to spacebrew."
		@iconURL = 'static/images/icons/inverted/editCurve.png'

		@initializeParameters: ()->

			parameters = super()

			parameters['Spacebrew'] =
				pause:
					type: 'checkbox'
					label: 'Pause'
					default: false
					onChange: (value)-> item.data.pause = value for item in R.selectedItems; return
				scaleDrawing:
					type: 'slider'
					label: 'Scale'
					min: 0
					max: 500
					default: 100

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		getViewBounds: ()->
			rectangle = paper.view.bounds
			bounds =
				x: rectangle.x
				y: rectangle.y
				width: rectangle.width
				height: rectangle.height
			return bounds

		beginCreate: (point, event)->
			# if not @data.polygonMode then else
			super(point, event)
			if @data.pause then return
			spacebrew.send("command", "string", JSON.stringify(type: 'pen', direction: 'down'))
			spacebrew.send("command", "string", JSON.stringify(point: point, type: 'moveTo', bounds: @getViewBounds(), scale: @data.scaleDrawing))
			return

		updateCreate: (point, event)->
			# if not @data.polygonMode then else
			super(point, event)
			if @data.pause then return
			spacebrew.send("command", "string", JSON.stringify(point: point, type: 'goTo', bounds: @getViewBounds(), scale: @data.scaleDrawing))
			return

		createMove: (event)->
			super(event)
			return

		endCreate: (point, event)->
			# if @data.polygonMode then return 	# in polygon mode, finish is called by the path tool
			super(point, event)
			if @data.pause then return
			spacebrew.send("command", "string", JSON.stringify(type: 'pen', direction: 'up'))
			return

	return SpacePath
