
	# class Brush extends StepPath
	# 	@label = 'new P.Path'
	# 	@description = "New tool description."

	# 	parameters: ()->
	# 		parameters = super()
	# 		###
	# 		parameters['Parameters'] ?= {}
	# 		parameters['Parameters'].width =
	# 			type: 'slider'
	# 			label: 'Width'
	# 			min: 2
	# 			max: 100
	# 			default: 10
	# 		###
	# 		return parameters

	# 	beginDraw: ()->
	# 		@initializeDrawing(true)

	# 		width = @data.strokeWidth

	# 		canvas = document.createElement("canvas")
	# 		context = canvas.getContext('2d')
	# 		gradient = context.createRadialGradient(width/2, width/2, 0, width/2, width/2, width/2)
	# 		gradient.addColorStop(0, '#8ED6FF')
	# 		gradient.addColorStop(1, '#004CB3')
	# 		context.fillStyle = gradient
	# 		context.fill()
	# 		@gradientData = context.getImageData(0, 0, width, width)
	# 		return

	# 	updateDraw: (length)->
	# 		point = @controlPath.getPointAt(length)
	# 		point = @projectToRaster(point)
	# 		width = @data.strokeWidth
	# 		@context.putImageData(@gradientData, point.x-width/2, point.y-width/2)
	# 		return

	# 	endDraw: ()->
	# 		return
