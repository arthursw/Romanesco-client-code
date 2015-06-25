define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	# The ellipse path does not even override any function, the RShape.createShape draws the shape defined in @constructor.Shape by default
	class EllipseShape extends Shape
		@Shape = paper.P.Path.Ellipse 			# the shape to draw
		@category = 'Shape'
		@label = 'Ellipse'
		@description = """Simple ellipse, circle by default (use shift key to draw an ellipse).
		Use special key (command on a mac, control otherwise) to avoid the shape to be centered on the first point."""
		@iconURL = 'static/images/icons/inverted/circle.png'
		@iconAlt = 'circle'
		@squareByDefault = true
		@centerByDefault = true

		@createTool(@)

	return EllipseShape