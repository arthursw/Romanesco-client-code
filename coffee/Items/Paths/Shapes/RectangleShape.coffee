define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	# Simple rectangle shape
	class RectangleShape extends Shape
		@Shape = P.Path.Rectangle
		@category = 'Shape'
		@label = 'Rectangle'
		@description = """Simple rectangle, square by default (use shift key to draw a rectangle) which can have rounded corners.
		Use special key (command on a mac, control otherwise) to center the shape on the first point."""
		@iconURL = 'static/images/icons/inverted/rectangle.png'

		@initializeParameters: ()->
			parameters = super()
			parameters['Style'] ?= {}
			parameters['Style'].cornerRadius =
				type: 'slider'
				label: 'Corner radius'
				min: 0
				max: 100
				default: 0
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		createShape: ()->
			@shape = @addPath(new @constructor.Shape(@rectangle, @data.cornerRadius)) 			# @constructor.Shape is a P.Path.Rectangle
			return

	return RectangleShape
