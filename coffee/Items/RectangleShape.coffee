define [
	'utils', 'RShape'
], (utils, RShape) ->

	# Simple rectangle shape
	class RectangleShape extends RShape
		@Shape = paper.Path.Rectangle
		@category = 'Shape'
		@rname = 'Rectangle'
		@rdescription = """Simple rectangle, square by default (use shift key to draw a rectangle) which can have rounded corners.
		Use special key (command on a mac, control otherwise) to center the shape on the first point."""
		@iconURL = 'static/images/icons/inverted/rectangle.png'
		@iconAlt = 'rectangle'

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

		createShape: ()->
			@shape = @addPath(new @constructor.Shape(@rectangle, @data.cornerRadius)) 			# @constructor.Shape is a Path.Rectangle
			return

	g.pathClasses.push(RectangleShape)

	return RectangleShape