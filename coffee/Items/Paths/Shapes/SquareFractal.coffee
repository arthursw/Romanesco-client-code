define [ 'Items/Paths/Shapes/Shape', 'Spacebrew' ], (Shape, spacebrew) ->

	class SquareFractal extends Shape
		@Shape = P.Path.Rectangle
		@label = 'Square fractal'
		@description = "Square fractal."
		@squareByDefault = true

		@initializeParameters: ()->
			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Parameters'].depth =
				type: 'slider'
				label: 'Depth'
				min: 1
				max: 8
				default: 5
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		createShape: ()->
			# @rectangle = paper.view.bounds
			super()
			@drawSquare(@rectangle, @data.depth)
			return

		drawSquare: (rectangle, n)->
			square = @addPath(paper.Path.Rectangle(rectangle))
			n--
			if n == 0 then return
			size = rectangle.size.divide(2.05)
			halfSize = size.multiply(0.5)
			@drawSquare(new paper.Rectangle(rectangle.topLeft.subtract(halfSize), size), n)
			@drawSquare(new paper.Rectangle(rectangle.topRight.subtract(halfSize), size), n)
			@drawSquare(new paper.Rectangle(rectangle.bottomLeft.subtract(halfSize), size), n)
			@drawSquare(new paper.Rectangle(rectangle.bottomRight.subtract(halfSize), size), n)
			return

	return SquareFractal
