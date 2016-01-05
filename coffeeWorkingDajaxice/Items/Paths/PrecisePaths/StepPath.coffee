define [ 'Items/Paths/PrecisePaths/PrecisePath' ], (PrecisePath) ->

	class StepPath extends PrecisePath
		@label = 'Step path'

		@initializeParameters: ()->

			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 30
				max: 300
				default: 30
				simplified: 30
				step: 1
			return parameters

		@parameters = @initializeParameters()

		checkUpdateDrawing: (segment, redrawing=true)->
			step = @data.step
			controlPathOffset = segment.location.offset

			while @drawingOffset+step<controlPathOffset
				@drawingOffset += step
				@updateDraw(@drawingOffset, true, redrawing)

			if @drawingOffset+step>controlPathOffset 	# we can not make a step between drawingOffset and the controlPathOffset
				@updateDraw(controlPathOffset, false, redrawing)

			return

	return StepPath
