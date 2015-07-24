define [ 'Items/Paths/PrecisePaths/StepPath' ], (StepPath) ->

	# The geometric lines path draws a line between all pair of points which are close enough
	# This means that hundreds of lines will be drawn at each update.
	# To improve drawing efficiency (and because we do not need any complexe editing functionnality for those lines),
	# we use a child canvas for the drawing.
	# We must convert the points in canvas coordinates, draw with the @context of the canvas
	# (and use the native html5 canvas drawing functions, unless we load an external library)
	class GeometricLines extends StepPath
		@label = 'Geometric lines'
		@description = "Draws a line between pair of points which are close enough."
		@iconURL = 'static/images/icons/inverted/links.png'

		@initializeParameters: ()->
			parameters = super()
			# override the default color function, since we get better results with a very transparent color
			parameters['Style'].strokeColor.defaultFunction = null
			parameters['Style'].strokeColor.default = "rgba(39, 158, 224, 0.21)"
			delete parameters['Style'].fillColor 	# remove the fill color, we do not need it

			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 5
				max: 100
				default: 11
				simplified: 20
				step: 1
			parameters['Parameters'].distance = 	# the maximum distance between two linked points
				type: 'slider'
				label: 'Distance'
				min: 5
				max: 250
				default: 150
				simplified: 100

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		beginDraw: ()->
			@initializeDrawing(true)
			@points = [] 							# will contain the points to check distances
			return

		updateDraw: (offset, step)->
			if not step then return

			point = @controlPath.getPointAt(offset)
			normal = @controlPath.getNormalAt(offset).normalize()

			point = @projectToRaster(point) 		#  convert the points from project to canvas coordinates
			@points.push(point)

			distMax = @data.distance*@data.distance

			# for all points: check if current point is close enough
			for pt in @points

				if point.getDistance(pt, true) < distMax 	# if points are close enough: draw a line between them
					@context.beginPath()
					@context.moveTo(point.x,point.y)
					@context.lineTo(pt.x,pt.y)
					@context.stroke()

			return

		endDraw: ()->
			return

	return GeometricLines
