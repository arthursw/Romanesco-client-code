define [ 'Items/Paths/Path' ], (Path) ->

	# An RShape is defined by a rectangle in which the drawing should be included
	# during the creation, the user draw the rectangle with the mouse
	class Shape extends Path
		@Shape = P.Path.Rectangle
		@label = 'Shape'
		@description = "Base shape class"
		@squareByDefault = true 				# whether the shape will be square by default (user must press the shift key to make it rectangle) or not
		@centerByDefault = false 				# whether the shape will be centered on the first point by default
												# (user must press the special key - command on a mac, control otherwise -
												# to use the first point as the first corner of the shape) or not

		# todo: check that control path always fit to rectangle: this is necessary for the getBounds method

		# overload {RPath#prepareHitTest} + fill control path
		prepareHitTest: (fullySelected=true, strokeWidth)->
			@controlPath.fillColor = 'red'
			return super(fullySelected, strokeWidth)

		# overload {RPath#finishHitTest} + remove control path fill
		finishHitTest: (fullySelected=true)->
			@controlPath.fillColor = null
			return super(fullySelected)

		# redefine {RPath#loadPath}
		# - load the shape rectangle from @data.rectangle
		# - initialize the control path
		# - draw
		# - check that the points in the database correspond to the new control path
		loadPath: (points)->
			if not @data.rectangle? then console.log 'Error loading shape ' + @pk + ': invalid rectangle.'
			@rectangle = if @data.rectangle? then new P.Rectangle(@data.rectangle) else new P.Rectangle()
			@initializeControlPath()
			@controlPath.rotation = @rotation
			@initialize()

			R.rasterizer.loadItem(@)

			# Check shape validity
			distanceMax = @constructor.secureDistance*@constructor.secureDistance
			for point, i in points
				@controlPath.segments[i].point == point
				if @controlPath.segments[i].point.getDistance(point, true)>distanceMax
					# @remove()
					@controlPath.strokeColor = 'red'
					P.view.center = @controlPath.bounds.center
					console.log "Error: invalid shape!"
					return

		# draw the shape
		# the drawing logic goes here
		# this is the main method that developer will redefine
		createShape: ()->
			@shape = @addPath(new @constructor.Shape(@rectangle))
			return

		process: ()->
			@initializeDrawing()
			@createShape()
			@shape.rotation = @rotation
			return

		# redefine {RPath#draw}
		# initialize the drawing and draw the shape
		draw: (simplified=false)->
			@drawn = false
			if not R.rasterizer.requestDraw(@, simplified) then return
			# if R.rasterizer.disableDrawing then return

			if not R.catchErrors
				@process()
			else
				try 							# catch errors to log them in console (if the user has code editor open)
					@process()
				catch error
					console.error error.stack
					console.error error
					throw error

			@drawn = true
			return

		# initialize the control path
		# create the rectangle from the two points and create the control path
		# @param pointA [Paper point] the top left or bottom right corner of the rectangle
		# @param pointB [Paper point] the top left or bottom right corner of the rectangle (opposite of point A)
		# @param shift [Boolean] whether shift is pressed
		# @param specialKey [Boolean] whether the special key is pressed (command on a mac, control otherwise)
		initializeControlPath: (pointA, pointB, shift, specialKey)->

			# create the rectangle from the two points
			if pointA and pointB
				square = if @constructor.squareByDefault then (not shift) else shift
				createFromCenter = if @constructor.centerByDefault then (not specialKey) else specialKey

				if createFromCenter
					delta = pointB.subtract(pointA)
					@rectangle = new P.Rectangle(pointA.subtract(delta), pointB)
					# @rectangle = new P.Rectangle(pointA.subtract(delta), new P.Size(delta.multiply(2)))
					if square
						center = @rectangle.center
						if @rectangle.width>@rectangle.height
							@rectangle.width = @rectangle.height
						else
							@rectangle.height = @rectangle.width
						@rectangle.center = center
				else
					if not square
						@rectangle = new P.Rectangle(pointA, pointB)
					else
						width = pointA.x-pointB.x
						height = pointA.y-pointB.y
						min = Math.min(Math.abs(width), Math.abs(height))
						@rectangle = new P.Rectangle(pointA, pointA.subtract(Utils.sign(width)*min, Utils.sign(height)*min))

			# create the control path
			@controlPath?.remove()
			@rotation ?= 0
			@addControlPath(new P.Path.Rectangle(@rectangle))
			@controlPath.fillColor = R.selectionBlue
			@controlPath.fillColor.alpha = 0.25
			return

		# overload {RPath#beginCreate} + initialize the control path and draw
		beginCreate: (point, event) ->
			super()
			@downPoint = point
			@initializeControlPath(@downPoint, point, event?.modifiers?.shift, R.specialKey(event))
			# @draw() can not draw with an empty rectangle
			return

		# redefine {RPath#updateCreate}:
		# initialize the control path and draw
		updateCreate: (point, event) ->
			# console.log " event.modifiers.command"
			# console.log event.modifiers.command
			# console.log R.specialKey(event)
			# console.log event?.modifiers?.shift
			@initializeControlPath(@downPoint, point, event?.modifiers?.shift, R.specialKey(event))
			@draw()
			return

		# overload {RPath#endCreate} + initialize the control path and draw
		endCreate: (point, event) ->
			@initializeControlPath(@downPoint, point, event?.modifiers?.shift, R.specialKey(event))
			@initialize()
			@draw()
			super()
			return

		setRectangle: (rectangle, update)->
			Utils.Rectangle.updatePathRectangle(@controlPath, rectangle)
			super(rectangle, update)
			return

		# overload {RPath#getData} and add rectangle to @data
		getData: ()->
			data = jQuery.extend({}, @data)
			data.rectangle = { x: @rectangle.x, y: @rectangle.y, width: @rectangle.width, height: @rectangle.height }
			return data

	return Shape
