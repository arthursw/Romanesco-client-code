define [
	'utils', 'RShape'
], (utils, RShape) ->

	# The ellipse path does not even override any function, the RShape.createShape draws the shape defined in @constructor.Shape by default
	class EllipseShape extends RShape
		@Shape = paper.Path.Ellipse 			# the shape to draw
		@category = 'Shape'
		@rname = 'Ellipse'
		@rdescription = """Simple ellipse, circle by default (use shift key to draw an ellipse).
		Use special key (command on a mac, control otherwise) to avoid the shape to be centered on the first point."""
		@iconURL = 'static/images/icons/inverted/circle.png'
		@iconAlt = 'circle'
		@squareByDefault = true
		@centerByDefault = true

	g.pathClasses.push(g.EllipseShape)

	return EllipseShape