define ['Items/Paths/PrecisePaths/SpeedPaths/SpeedPath'], (SpeedPath) ->

	class DynamicBrush extends SpeedPath
		@label = 'Dynamic brush'
		@description = "The stroke width is function of the drawing speed: the faster the wider."
		@polygonMode = false

		# "http://thenounproject.com/term/spray-bottle/7835/"
		# "http://thenounproject.com/term/spray-bottle/93690/"
		# "http://thenounproject.com/term/spray-paint/3533/"
		# "http://thenounproject.com/term/spray-paint/18249/"
		# "http://thenounproject.com/term/spray-paint/18249/"
		# "http://thenounproject.com/term/spray-paint/17918/"

		@initializeParameters: ()->
			parameters = super()
			delete parameters['Style'].fillColor 	# remove the fill color, we do not need it
			parameters['Edit curve'].showSpeed.default = false

			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 1
				max: 100
				default: 5
				simplified: 20
				step: 1
			parameters['Parameters'].trackWidth =
				type: 'slider'
				label: 'Track width'
				min: 0.0
				max: 10.0
				default: 0.5
			parameters['Parameters'].mass =
				type: 'slider'
				label: 'Mass'
				min: 1
				max: 200
				default: 40
			parameters['Parameters'].drag =
				type: 'slider'
				label: 'Drag'
				min: 0
				max: 0.4
				default: 0.1
			parameters['Parameters'].maxSpeed =
				type: 'slider'
				label: 'Max speed'
				min: 0
				max: 100
				default: 35
			parameters['Parameters'].roundEnd =
				type: 'checkbox'
				label: 'Round end'
				default: false
			parameters['Parameters'].inverseThickness =
				type: 'checkbox'
				label: 'Inverse thickness'
				default: false
			parameters['Parameters'].fixedAngle =
				type: 'checkbox'
				label: 'Fixed angle'
				default: false
			parameters['Parameters'].simplify =
				type: 'checkbox'
				label: 'Simplify'
				default: true
			parameters['Parameters'].angle =
				type: 'slider'
				label: 'Angle'
				min: 0
				max: 360
				default: 0

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		getDrawingBounds: ()->
			width = if @data.inverseThickness then Utils.Array.max(@speeds) else Utils.Array.min(@speeds)
			width = if @data.inverseThickness then width else (@data.maxSpeed-width)
			width *= @data.trackWidth
			return @getBounds().expand(2*width)

		beginDraw: (redrawing=false)->
			@initializeDrawing(true)

			@point = @controlPath.firstSegment.point

			@currentPosition = @point
			@previousPosition = @currentPosition
			@previousMidPosition = @currentPosition
			@previousMidDelta = new P.Point()
			@previousDelta = new P.Point()

			@context.fillStyle = 'black' 	# @data.fillColor
			@context.strokeStyle = @data.fillColor

			# @path = @addPath()
			# @path.add(@point)
			# @path.strokeWidth = 0
			# @path.strokeColor = null
			# @path.fillColor = @data.strokeColor
			# @path.closed = true

			if not redrawing
				@velocity = new P.Point()
				@velocities = []
				@controlPathReplacement = @controlPath.clone()

				@setAnimated(true)
			return

		drawSegment: (currentPosition, width, delta=null)->
			# if not @continueDrawing then return

			width = if @data.inverseThickness then width else (@data.maxSpeed-width)

			width *= @data.trackWidth

			if width < 0.1
				width = 0.1

			if @data.fixedAngle
				delta = new P.Point(1,0)
				delta.angle = @data.angle
			else
				delta = delta.normalize()

			delta = delta.multiply(width)

			midPosition = currentPosition.add(@previousPosition).divide(2)
			midDelta = delta.add(@previousDelta).divide(2)

			# a = @projectToRaster(@previousPosition.add(@previousDelta))
			# b = @projectToRaster(@previousPosition.subtract(@previousDelta))
			# c = @projectToRaster(currentPosition.subtract(delta))
			# d = @projectToRaster(currentPosition.add(delta))

			# @context.fillStyle = @data.strokeColor

			# @context.beginPath()
			# @context.moveTo(a.x, a.y)
			# @context.lineTo(b.x, b.y)
			# @context.stroke()
			# @context.lineTo(c.x, c.y)
			# @context.lineTo(d.x, d.y)
			# @context.fill()

			previousMidTop = @projectToRaster(@previousMidPosition.add(@previousMidDelta))
			previousMidBottom = @projectToRaster(@previousMidPosition.subtract(@previousMidDelta))

			previousTop = @projectToRaster(@previousPosition.add(@previousDelta))
			previousBottom = @projectToRaster(@previousPosition.subtract(@previousDelta))

			midTop = @projectToRaster(midPosition.add(midDelta))
			midBottom = @projectToRaster(midPosition.subtract(midDelta))

			@context.beginPath()
			@context.moveTo(previousMidTop.x, previousMidTop.y)
			@context.lineTo(previousMidBottom.x, previousMidBottom.y)
			@context.quadraticCurveTo(previousBottom.x, previousBottom.y, midBottom.x, midBottom.y)
			@context.lineTo(midTop.x, midTop.y)
			@context.quadraticCurveTo(previousTop.x, previousTop.y, previousMidTop.x, previousMidTop.y,)
			@context.fill()
			@context.stroke()

			@previousDelta = delta
			@previousMidPosition = midPosition
			@previousMidDelta = midDelta
			return

		updateForce: ()->
			# calculate force and acceleration
			force = @point.subtract(@currentPosition)
			if force.length<0.1
				return false

			acceleration = force.divide(@data.mass)

			# calculate new velocity
			@velocity = @velocity.add(acceleration)
			if @velocity.length<0.1
				return false

			# apply drag
			@velocity = @velocity.multiply(1.0-@data.drag)

			# update position
			@previousPosition = @currentPosition
			@currentPosition = @currentPosition.add(@velocity)

			return true

		drawStep: ()->
			if @finishedDrawing then return

			continueDrawing = @updateForce()
			if not continueDrawing then return

			v = @velocity.length

			@controlPathReplacement.add(@currentPosition)
			@velocities.push(v)

			@drawSegment(@currentPosition, v, new P.Point(-@velocity.y, @velocity.x))

			###
			width = if @data.inverseThickness then v else (10-v)
			width *= @data.trackWidth

			if not @data.fixedAngle
				delta = new P.Point(-@velocity.y, @velocity.x)
			else
				delta = new P.Point(1,0)
				delta.angle = @data.angle
			delta = delta.normalize().multiply(width)

			a = @projectToRaster(@previousPosition.add(@previousDelta))
			b = @projectToRaster(@previousPosition.subtract(@previousDelta))
			c = @projectToRaster(@currentPosition.subtract(delta))
			d = @projectToRaster(@currentPosition.add(delta))

			# @path.add(c)
			# @path.insert(0, d)
			###

			return

		onFrame: ()=>
			for i in [0 .. 2]
				@drawStep()
			return

		updateDraw: (offset, step, redrawing)->
			@point = @controlPath.getPointAt(offset)

			if redrawing
				v = @speedAt(offset)

				@drawSegment(@point, v, @controlPath.getNormalAt(offset))

				@previousPosition = @point
				###
				width = if @data.inverseThickness then v else (10-v)
				width *= @data.trackWidth

				if not @data.fixedAngle
					delta = @controlPath.getNormalAt(offset).normalize()
				else
					delta = new P.Point(1,0)
					delta.angle = @data.angle

				delta = delta.multiply(width)
				top = @point.add(delta)
				bottom = @point.subtract(delta)

				@path.add(top)
				@path.insert(0, bottom)
				###
			return

		endDraw: (redrawing=false)->
			if not redrawing
				@setAnimated(false)

				@finishedDrawing = true
				# @path.closed = true

				# compute @speeds from @velocities
				length = @controlPathReplacement.length
				offset = 0
				@speeds = []

				while offset<length
					location = @controlPathReplacement.getLocationAt(offset)
					i = location.segment.index
					f = location.parameter
					if i<@velocities.length-1
						@speeds.push(Utils.linearInterpolation(@velocities[i], @velocities[i+1], f))
					else
						@speeds.push(@velocities[i])
					offset += @constructor.speedStep

				@velocities = []
				if @data.simplify then @controlPathReplacement.simplify()
				@controlPathReplacement.insert(0, @controlPathReplacement.firstSegment.point)
				@controlPathReplacement.insert(0, @controlPathReplacement.firstSegment.point)
				@controlPath.segments = @controlPathReplacement.segments
				@controlPathReplacement.remove()

			# else
				# if @data.roundEnd
				# 	@path.smooth()
				# @path.selected = false 		# @path would be selected because we added the last point of the control path which is selected

			return

		remove: ()->
			clearInterval(@timerId)
			super()
			return

	return DynamicBrush
