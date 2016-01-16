define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	# The spiral shape can have an intern radius, and a custom number of sides
	# A smooth spiral could be drawn with less points and with handles, that could be more efficient
	class SpiralShape extends Shape
		@Shape = P.Path.Ellipse
		@category = 'Shape/Animated/Spiral'
		@label = 'Spiral'
		@description = "The spiral shape can have an intern radius, and a custom number of sides."
		@iconURL = 'static/images/icons/inverted/spiral.png'

		@initializeParameters: ()->
			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Parameters'].minRadius =
				type: 'slider'
				label: 'Minimum radius'
				min: 0
				max: 100
				default: 0
			parameters['Parameters'].nTurns =
				type: 'slider'
				label: 'Number of turns'
				min: 1
				max: 50
				default: 10
			parameters['Parameters'].nSides =
				type: 'slider'
				label: 'Sides'
				min: 3
				max: 100
				default: 50
			parameters['Parameters'].animate =
				type: 'checkbox'
				label: 'Animate'
				default: false
			parameters['Parameters'].rotationSpeed =
				type: 'slider'
				label: 'Rotation speed'
				min: -10
				max: 10
				default: 1

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		# animted paths must be initialized
		initialize: ()->
			@setAnimated(@data.animate)
			return

		createShape: ()->
			@shape = @addPath()

			# drawing a spiral (as a set of straight lines) is like drawing a circle, but changing the radius of the circle at each step
			# to draw a circle, we would do somehting like this: for each point: addPoint( radius*Math.cos(angle), radius*Math.sin(angle) )
			# the same things applies for a spiral, except that radius decreases at each step
			# ellipses are similar except the radius is different on the x axis and on the y axis

			rectangle = @rectangle
			hw = rectangle.width/2
			hh = rectangle.height/2
			c = rectangle.center
			angle = 0

			angleStep = 360.0/@data.nSides
			spiralWidth = hw-hw*@data.minRadius/100.0
			spiralHeight = hh-hh*@data.minRadius/100.0
			radiusStepX = (spiralWidth / @data.nTurns) / @data.nSides 		# the amount by which decreasing the x radius at each step
			radiusStepY = (spiralHeight / @data.nTurns) / @data.nSides 		# the amount by which decreasing the y radius at each step
			for i in [0..@data.nTurns-1]
				for step in [0..@data.nSides-1]
					@shape.add(new P.Point(c.x+hw*Math.cos(angle), c.y+hh*Math.sin(angle)))
					angle += (2.0*Math.PI*angleStep/360.0)
					hw -= radiusStepX
					hh -= radiusStepY
			@shape.add(new P.Point(c.x+hw*Math.cos(angle), c.y+hh*Math.sin(angle)))
			@shape.pivot = @rectangle.center

			@shape.strokeCap = 'round'
			return

		# called at each frame event
		# this is the place where animated paths should be updated
		onFrame: (event)=>
			# very simple example of path animation
			@shape.strokeColor.hue += 1
			@shape.rotation += @rotationSpeed
			return

	return SpiralShape
