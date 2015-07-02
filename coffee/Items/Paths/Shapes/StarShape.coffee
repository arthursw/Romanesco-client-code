define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	# The star shape can be animated
	class StarShape extends Shape
		@Shape = P.Path.Star
		@category = 'Shape/Animated'
		@label = 'Star'
		@description = "Draws a star which can be animated (the color changes and it rotates)."
		@iconURL = 'static/images/icons/inverted/star.png'

		@initializeParameters: ()->
			parameters = super()
			parameters['Style'] ?= {}
			parameters['Style'].nPoints =
				type: 'slider'
				label: 'N points'
				min: 1
				max: 100
				default: 5
				step: 1
			parameters['Style'].internalRadius =
				type: 'slider'
				label: 'Internal radius'
				min: -200
				max: 100
				default: 38
			parameters['Style'].rsmooth =
				type: 'checkbox'
				label: 'Smooth'
				default: false
			parameters['Style'].animate =
				type: 'checkbox'
				label: 'Animate'
				default: false
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		# animted paths must be initialized
		initialize: ()->
			@setAnimated(@data.animate)
			return

		createShape: ()->
			rectangle = @rectangle
			# make sure that the shape does not exceed the area defined by @rectangle
			if @data.internalRadius>-100
				externalRadius = rectangle.width/2
				internalRadius = externalRadius*@data.internalRadius/100
			else
				internalRadius = rectangle.width/2
				externalRadius = internalRadius*100/@data.internalRadius
			# draw the star
			@shape = @addPath(new @constructor.Shape(rectangle.center, @data.nPoints, externalRadius, internalRadius))
			# optionally smooth it
			if @data.rsmooth then @shape.smooth()
			return

		# called at each frame event
		# this is the place where animated paths should be updated
		onFrame: (event)=>
			# very simple example of path animation
			@shape.strokeColor.hue += 1
			@shape.rotation += 1
			return

	return StarShape
