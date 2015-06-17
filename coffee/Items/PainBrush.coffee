define [
	'utils', 'PrecisePath'
], (utils, PrecisePath) ->

	class PaintBrush extends PrecisePath
		@rname = 'Paint brush'
		@rdescription = "Paints a thick stroke with customable blur effects."
		@iconURL = 'static/images/icons/inverted/brush.png'
		@iconAlt = 'brush'

		@initializeParameters: ()->
			parameters = super()
			delete parameters['Style'].fillColor 	# remove the fill color, we do not need it

			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 1
				max: 100
				default: 11
				simplified: 20
				step: 1
			parameters['Parameters'].size =
				type: 'slider'
				label: 'Size'
				min: 1
				max: 100
				default: 10
			parameters['Parameters'].blur =
				type: 'slider'
				label: 'Blur'
				min: 0
				max: 100
				default: 20

			return parameters

		@parameters = @initializeParameters()

		getDrawingBounds: ()->
			return @getBounds().expand(@data.size)

		beginDraw: ()->
			@initializeDrawing(true)
			point = @controlPath.firstSegment.point
			point = @projectToRaster(point)
			@context.moveTo(point.x, point.y)
			return

		updateDraw: (offset, step)->
			if not step then return

			point = @controlPath.getPointAt(offset)
			normal = @controlPath.getNormalAt(offset).normalize()

			point = @projectToRaster(point) 		#  convert the points from project to canvas coordinates

			innerRadius = @data.size * (1 - @data.blur / 100)
			outerRadius = @data.size

			radialGradient = @context.createRadialGradient(point.x, point.y, innerRadius, point.x, point.y, outerRadius)

			midColor = new Color(@data.strokeColor)
			midColor.alpha = 0.5
			endColor = new Color(@data.strokeColor)
			endColor.alpha = 0
			radialGradient.addColorStop(0, @data.strokeColor)
			radialGradient.addColorStop(0.5, midColor.toCSS())
			radialGradient.addColorStop(1, endColor.toCSS())

			@context.fillStyle = radialGradient
			@context.fillRect(point.x-outerRadius, point.y-outerRadius, 2*outerRadius, 2*outerRadius)

			return

		endDraw: ()->
			return

	g.pathClasses.push(g.PaintBrush)

	return PaintBrush