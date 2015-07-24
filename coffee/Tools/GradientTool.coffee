define [ 'Tools/Tool' ], (Tool) ->

	class GradientTool extends Tool

		@label = 'Gradient'
		@description = ''
		@favorite = false
		@category = ''
		@cursor =
			position:
				x: 0, y:0
			name: 'default'

		@handleSize = 5

		constructor: ()->
			super(false)
			@handles = []
			@radial = false
			return

		getDefaultGradient: (color)->
			if R.selectedItems.length==1
				bounds = R.selectedItems[0].getBounds()
			else
				bounds = P.view.bounds.scale(0.25)
			color = if color? then new P.Color(color) else Utils.Array.random(R.defaultColor)
			firstColor = color.clone()
			firstColor.alpha = 0.2
			secondColor = color.clone()
			secondColor.alpha = 0.8
			gradient =
				origin: bounds.topLeft
				destination: bounds.bottomRight
				gradient:
					stops: [ { color: 'red', rampPoint: 0 } , { color: 'blue', rampPoint: 1 } ]
					radial: false
			return gradient

		initialize: (updateGradient=true, updateParameters=true)->
			value = @controller.getValue()

			if not value?.gradient?
				value = @getDefaultGradient(value)

			@group?.remove()
			@handles = []

			@radial = value.gradient?.radial

			@group = new P.Group()

			origin = new P.Point(value.origin)
			destination = new P.Point(value.destination)
			delta = destination.subtract(origin)

			for stop in value.gradient.stops
				color = new P.Color(if stop.color? then stop.color else stop[0])
				location = parseFloat(if stop.rampPoint? then stop.rampPoint else stop[1])
				position = origin.add(delta.multiply(location))

				handle = @createHandle(position, location, color, true)
				if location == 0 then @startHandle = handle
				if location == 1 then @endHandle = handle

			@startHandle ?= @createHandle(origin, 0, 'red')
			@endHandle ?= @createHandle(destination, 1, 'blue')

			@line = new P.Path()
			@line.add(@startHandle.position)
			@line.add(@endHandle.position)

			@group.addChild(@line)
			@line.sendToBack()
			@line.strokeColor = R.selectionBlue
			@line.strokeWidth = 1

			R.view.selectionLayer.addChild(@group)

			@selectHandle(@startHandle)
			if updateGradient
				@updateGradient(updateParameters)
			return

		select: (deselectItems=true, updateParameters=true)->
			if R.selectedTool == @ then return

			R.previousTool = R.selectedTool
			R.selectedTool?.deselect()
			R.selectedTool = @

			@initialize(true, updateParameters)
			return

		remove: ()->
			@group?.remove()
			@handles = []
			@startHandle = null
			@endHandle = null
			@line = null
			@controller = null
			return

		deselect: ()->
			@remove()
			return

		selectHandle: (handle)->
			@selectedHandle?.selected = false
			handle.selected = true
			@selectedHandle = handle
			@controller.setColor(handle.fillColor.toCSS())
			return

		colorChange: (color)->
			@selectedHandle.fillColor = color
			@updateGradient()
			return

		setRadial: (value)->
			@select()
			@radial = value
			@updateGradient()
			return

		updateGradient: (updateParameters=true)->
			if not @startHandle? or not @endHandle? then return
			stops = []
			for handle in @handles
				stops.push([handle.fillColor, handle.location])

			gradient =
				origin: @startHandle.position
				destination: @endHandle.position
				gradient:
					stops: stops
					radial: @radial

			console.log JSON.stringify(gradient)

			if updateParameters
				@controller.onChange(gradient)

			# @controller.setGradient(gradient)

			# for item in R.selectedItems
			# 	# do not update if the value was never set (not even to null), update if it was set (even to null, for colors)
			# 	if typeof item.data?[@controller.name] isnt 'undefined'
			# 		item.setParameterCommand(@controller.name, gradient, @controller)
			return

		createHandle: (position, location, color, initialization=false)->
			handle = new P.Path.Circle(position, @constructor.handleSize)
			handle.name = 'handle'

			@group.addChild(handle)

			handle.strokeColor = R.selectionBlue
			handle.strokeWidth = 1
			handle.fillColor = color

			handle.location = location
			@handles.push(handle)

			if not initialization
				@selectHandle(handle)
				@updateGradient()

			return handle

		addHandle: (event, hitResult)->
			offset = hitResult.location.offset
			point = @line.getPointAt(offset)
			@createHandle(point, offset / @line.length, @controller.colorInputJ.val())
			return

		removeHandle: (handle)->
			if handle == @startHandle or handle == @endHandle then return
			Utils.Array.remove(@handles, handle)
			handle.remove()
			@updateGradient()
			return

		doubleClick: (event) ->
			point = P.view.viewToProject(new P.Point(event.pageX, event.pageY))
			hitResult = @group.hitTest(point)
			if hitResult
				if hitResult.item == @line
					@addHandle(event, hitResult)
				else if hitResult.item.name == 'handle'
					@removeHandle(hitResult.item)
			return

		begin: (event)->
			hitResult = @group.hitTest(event.point)
			if hitResult
				if hitResult.item.name == 'handle'
					@selectHandle(hitResult.item)
					@dragging = true
			return

		update: (event)->
			if @dragging
				if @selectedHandle == @startHandle or @selectedHandle == @endHandle
					@selectedHandle.position.x += event.delta.x
					@selectedHandle.position.y += event.delta.y
					@line.firstSegment.point = @startHandle.position
					@line.lastSegment.point = @endHandle.position
					lineLength = @line.length
					for handle in @handles
						handle.position = @line.getPointAt(handle.location*lineLength)
				else
					@selectedHandle.position = @line.getNearestPoint(event.point)
					@selectedHandle.location = @line.getOffsetOf(@selectedHandle.position) / @line.length

				@updateGradient()
			return

		end: (event)->
			@dragging = false
			return

	R.Tools.Gradient = GradientTool
	return GradientTool
