define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	# The spiral shape can have an intern radius, and a custom number of sides
	# A smooth spiral could be drawn with less points and with handles, that could be more efficient
	class TotemShape extends Shape
		@Shape = P.Path.Rectangle
		@category = 'Shape/Animated/Spiral'
		@label = 'Totem'
		@description = "The spiral shape can have an intern radius, and a custom number of sides."
		@iconURL = 'static/images/icons/inverted/spiral.png'

		@initializeParameters: ()->
			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Parameters'].nWidth =
				type: 'slider'
				label: 'Minimum radius'
				min: 0
				max: 100
				default: 20
			parameters['Parameters'].nHeight =
				type: 'slider'
				label: 'Number of turns'
				min: 1
				max: 150
				default: 60
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		# animted paths must be initialized
		initialize: ()->
			return

		motif: (Rectangle)->
			return @addPath(new P.Path.Rectangle(Rectangle))

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

			shapeWidth = rectangle.width / @data.nWidth
			shapeWidth = rectangle.height / @data.nHeight

			for x in [0..@data.nWidth]
				for y in [0..@data.nHeight]
					r = new P.Rectangle(rectangle.left + x * shapeWidth / rectangle.width, rectangle.top + y * shapeHeight / rectangle.height)
					m = @motif(r)
					m.fillColor = 'black'

			@shape.strokeCap = 'round'
			return

		# # called at each frame event
		# # this is the place where animated paths should be updated
		# onFrame: (event)=>
		# 	# very simple example of path animation
		# 	@shape.strokeColor.hue += 1
		# 	@shape.rotation += @rotationSpeed
		# 	return

	return SpiralShape
