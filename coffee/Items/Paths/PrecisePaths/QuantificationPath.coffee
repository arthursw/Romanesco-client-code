
	# class QuantificationPath extends StepPath
	#   @label = 'Quantification path'
	#   @description = "Quantification path."

	#   parameters: ()->
	#     parameters = super()

	#     parameters['Parameters'] ?= {}
	#     parameters['Parameters'].quantification =
	#         type: 'slider'
	#         label: 'Quantification'
	#         min: 0
	#         max: 100
	#         default: 10

	#     return parameters

	#   constructor: (@date=null, @data=null, @pk=null, points=null) ->
	#     super(@date, @data, @pk, points)

	#   beginDraw: ()->

	#     @initializeDrawing(false)

	#     @path = @addPath()
	#     return

	#   updateDraw: (length)->

	#     point = @controlPath.getPointAt(length)
	#     quantification = @data.quantification
	#     point.x = Math.floor(point.x/quantification)*quantification
	#     point.y = Math.floor(point.y/quantification)*quantification
	#     @path.add(point)
	#     return

	#   endDraw: ()->
	#     return

	# @QuantificationPath = QuantificationPath
