define ['Items/Paths/PrecisePaths/SpeedPaths/SpeedPath'], (SpeedPath) ->

	# The shape path draw a rectangle or an ellipse along the control path
	class ShapePath extends SpeedPath
		@label = 'Shape path'
		@description = "Draws rectangles or ellipses along the path. The size of the shapes is function of the drawing speed."

		@initializeParameters: ()->
			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 5
				max: 100
				default: 20
				simplified: 20
				step: 1
			parameters['Parameters'].ellipse =
				type: 'checkbox'
				label: 'Ellipse'
				default: false
			parameters['Parameters'].minWidth =
				type: 'slider'
				label: 'Min width'
				min: 1
				max: 250
				default: 1
			parameters['Parameters'].maxWidth =
				type: 'slider'
				label: 'Max width'
				min: 1
				max: 250
				default: 200
			parameters['Parameters'].speedForLength =
				type: 'checkbox'
				label: 'Speed for length'
				default: false
			parameters['Parameters'].minSpeed =
				type: 'slider'
				label: 'Min speed'
				min: 1
				max: 250
				default: 1
			parameters['Parameters'].maxSpeed =
				type: 'slider'
				label: 'Max speed'
				min: 1
				max: 250
				default: 200

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		beginDraw: ()->
			@initializeDrawing(false)
			@lastOffset = 0
			return

		updateDraw: (offset, step)->
			if not step then return

			speed = @speedAt(offset)

			# if @data.speedForLength: the drawing is not updated at each step, but the step length is function of the speed
			if not @data.speedForLength
				@addShape(offset, @data.step, speed)
			else 	# @data.speedForLength

				# map 'speed' to the interval [@data.minSpeed, @data.maxSpeed]
				speed = @data.minSpeed + (speed / @constructor.maxSpeed) * (@data.maxSpeed - @data.minSpeed)

				# check when we must update the path (if the current position if greater than the last position we updated + speed)
				stepOffset = offset-@lastOffset
				if stepOffset>speed
					midOffset = (offset+@lastOffset)/2
					@addShape(midOffset, stepOffset, speed)
					@lastOffset = offset

			return

		endDraw: ()->
			return

		# add a shape at 'offset'
		addShape: (offset, height, speed)->
			point = @controlPath.getPointAt(offset)
			normal = @controlPath.getNormalAt(offset)

			width = @data.minWidth + (@data.maxWidth - @data.minWidth) * speed / @constructor.maxSpeed
			rectangle = new P.Rectangle(point.subtract(new P.Point(width/2, height/2)), new P.Size(width, height))
			if not @data.ellipse
				shape = @addPath(new P.Path.Rectangle(rectangle))
			else
				shape = @addPath(new P.Path.Ellipse(rectangle))
			shape.rotation = normal.angle
			return

	return ShapePath
