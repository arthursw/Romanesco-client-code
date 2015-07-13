define ['Items/Paths/PrecisePaths/SpeedPaths/SpeedPath'], (SpeedPath) ->

	# The thickness pass demonstrates a simple use of the speed path: it draws a stroke which is thick where the user draws quickly, and thin elsewhere
	# The stroke width can be changed with the speed handles at any time
	class ThicknessPath extends SpeedPath
		@label = 'Thickness path'
		@description = "The stroke width is function of the drawing speed: the faster the wider."
		@iconURL = 'static/images/icons/inverted/rollerBrush.png'
		@iconAlt = 'roller brush'

		# The thickness path adds two parameters in the options bar:
		# step: a number which defines the size of the steps along the control path (@data.step is already defined in precise path, this will bind it to the options bar)
		# trackWidth: a number to control the stroke width (factor of the speed)
		@initializeParameters: ()->
			parameters = super()

			# override the default parameters, we do not need a stroke width, a stroke color and a fill color
			parameters['Style'].strokeWidth.default = 0
			parameters['Style'].strokeColor.defaultCheck = false
			parameters['Style'].fillColor.defaultCheck = true

			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 30
				max: 300
				default: 30
				simplified: 30
				step: 1
			parameters['Parameters'].trackWidth =
				type: 'slider'
				label: 'Track width'
				min: 0.1
				max: 3
				default: 0.5
			parameters['Parameters'].useCanvas =
				type: 'checkbox'
				label: 'Use canvas'
				default: false
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		beginDraw: ()->
			@initializeDrawing(false)
			@path = @addPath()
			@path.add(@controlPath.firstSegment.point)
			@path.add(@controlPath.firstSegment.point)
			return

		updateDraw: (offset, step)->
			# get point, normal and speed at current position
			point = @controlPath.getPointAt(offset)
			normal = @controlPath.getNormalAt(offset).normalize()

			if not step
				if @path.segments.length<=1 then return
				@path.firstSegment.point = point
				return

			speed = @speedAt(offset)

			# create two points at each side of the control path (separated by a length function of the speed)
			delta = normal.multiply(speed*@data.trackWidth/2)
			top = point.add(delta)
			bottom = point.subtract(delta)

			# add the two points at the beginning and the end of the path
			@path.firstSegment.remove()
			@path.add(top)
			@path.insert(0, bottom)
			@path.insert(0, point)
			@path.smooth()

			return

		endDraw: ()->
			# add the last segment, close and smooth the path
			@path.add(@controlPath.lastSegment.point)
			@path.closed = true
			@path.smooth()
			@path.selected = false 		# @path would be selected because we added the last point of the control path which is selected
			return

	return ThicknessPath
