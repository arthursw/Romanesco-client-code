define ['Items/Paths/PrecisePaths/SpeedPaths/SpeedPath'], (SpeedPath) ->

	class PaintGun extends SpeedPath
		@label = 'Paint gun'
		@description = "The stroke width is function of the drawing speed: the faster the wider."
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
				default: 11
				simplified: 20
				step: 1
			parameters['Parameters'].trackWidth =
				type: 'slider'
				label: 'Track width'
				min: 0.1
				max: 3
				default: 0.25
			parameters['Parameters'].roundEnd =
				type: 'checkbox'
				label: 'Round end'
				default: false
			parameters['Parameters'].inverseThickness =
				type: 'checkbox'
				label: 'Inverse thickness'
				default: false

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		getDrawingBounds: ()->
			width = 0
			if not @data.inverseThickness
				width = Utils.Array.max(@speeds) * @data.trackWidth / 2
			else
				width = Math.max(@maxSpeed-Utils.Array.min(@speeds), 0) * @data.trackWidth / 2

			return @getBounds().expand(width)

		beginDraw: ()->
			@initializeDrawing(true)
			point = @controlPath.firstSegment.point
			point = @projectToRaster(point) 		#  convert the points from project to canvas coordinates
			@context.moveTo(point.x, point.y)

			@previousTop = point
			@previousBottom = point
			@previousMidTop = point
			@previousMidBottom = point

			@maxSpeed = if @speeds.length>0 then Utils.Array.max(@speeds) / 1.5 else @constructor.maxSpeed / 6

			return

		drawStep: (offset, step, end=false)->

			point = @controlPath.getPointAt(offset)
			normal = @controlPath.getNormalAt(offset).normalize()

			speed = @speedAt(offset)

			point = @projectToRaster(point) 		#  convert the points from project to canvas coordinates

			# create two points at each side of the control path (separated by a length function of the speed)
			if not @data.inverseThickness
				delta = normal.multiply(speed * @data.trackWidth / 2)
			else
				delta = normal.multiply(Math.max(@maxSpeed-speed, 0) * @data.trackWidth / 2)

			top = point.add(delta)
			bottom = point.subtract(delta)

			if not end
				midTop = @previousTop.add(top).multiply(0.5)
				midBottom = @previousBottom.add(bottom).multiply(0.5)
			else
				midTop = top
				midBottom = bottom

			@context.fillStyle = @data.strokeColor

			@context.beginPath()

			@context.moveTo(@previousMidTop.x, @previousMidTop.y)

			@context.lineTo(@previousMidBottom.x, @previousMidBottom.y)
			@context.quadraticCurveTo(@previousBottom.x, @previousBottom.y, midBottom.x, midBottom.y)
			@context.lineTo(midTop.x, midTop.y)
			@context.quadraticCurveTo(@previousTop.x, @previousTop.y, @previousMidTop.x, @previousMidTop.y,)

			@context.fill()
			@context.stroke()

			if step
				@previousTop = top
				@previousBottom = bottom
				@previousMidTop = midTop
				@previousMidBottom = midBottom

			return

		updateDraw: (offset, step)->
			@drawStep(offset, step)
			return

		endDraw: ()->
			@drawStep(@controlPath.length, false, true)

			if @data.roundEnd
				point = @controlPath.lastSegment.point
				point = @projectToRaster(point)
				@context.beginPath()
				@context.fillStyle = @data.strokeColor
				@context.arc(point.x, point.y, _.last(@speeds) * @data.trackWidth / 2, 0, 2 * Math.PI)
				@context.fill()
			return

	return PaintGun
