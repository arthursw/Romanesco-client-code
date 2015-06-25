define [ ], () ->

	class SelectionRectangle

		@indexToName =
			0: 'bottomLeft'
			1: 'left'
			2: 'topLeft'
			3: 'top'
			4: 'topRight'
			5: 'right'
			6: 'bottomRight'
			7: 'bottom'

		@oppositeName =
			'top': 'bottom'
			'bottom': 'top'
			'left': 'right'
			'right': 'left'
			'topLeft': 'bottomRight'
			'topRight':  'bottomLeft'
			'bottomRight':  'topLeft'
			'bottomLeft':  'topRight'

		@cornersNames = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft']
		@sidesNames = ['left', 'right', 'top', 'bottom']

		@valueFromName: (point, name)->
			switch name
				when 'left', 'right'
					return point.x
				when 'top', 'bottom'
					return point.y
				else
					return point

		@pointFromName: (rectangle, name)->
			switch name
				when 'left', 'right'
					return new Point(rectangle[name], rectangle.center.y)
				when 'top', 'bottom'
					return new Point(rectangle.center.x, rectangle[name])
				else
					return rectangle[name]

		# Paper hitOptions for hitTest function to check which items (corresponding to those criterias) are under a point
		@hitOptions =
			segments: true
			stroke: true
			fill: true
			selected: true
			tolerance: 5

		constructor: (@items)->
			@rectangle = @getBoundingRectangle(@items)
			@transformState = null

			@group = new P.Group()
			@group.name = "selection rectangle group"

			@path = new P.Path.Rectangle(@rectangle)
			@path.name = "selection rectangle path"
			@path.strokeColor = R.selectionBlue
			@path.strokeWidth = 1
			@path.selected = true
			@path.controller = @

			@group.addChild(@path)

			@addHandles(@rectangle)
			@path.pivot = @rectangle.center
			return

		getBoundingRectangle: (items)->
			bounds = items[0].getBounds()
			for item in items
				bounds = bounds.unite(item.getBounds())
			return bounds

		addHandles: (bounds)->
			@path.insert(1, new P.Point(bounds.left, bounds.center.y))
			@path.insert(3, new P.Point(bounds.center.x, bounds.top))
			@path.insert(5, new P.Point(bounds.right, bounds.center.y))
			@path.insert(7, new P.Point(bounds.center.x, bounds.bottom))
			return

		getClosestCorner: (point)->
			minDistance = Infinity
			closestCorner = ''
			for cornerName in @constructor.cornersNames
				distance = @rectangle[cornerName].getDistance(point, true)
				if distance < minDistance
					closestCorner = cornerName
					minDistance = distance
			return closestCorner

		setTransformState: (hitResult)->
			switch hitResult.type
				when 'stroke'
					@transformState = command: 'Move', corner: @getClosestCorner(hitResult.point)
				when'segment'
					@transformState = command: 'Resize', index: hitResult.segment.index
				else
					@transformState = command: 'Move'
			return

		hitTest: (event)->
			hitResult = @path.hitTest(event.point, @constructor.hitOptions)
			if not hitResult? then return
			@setTransformState(hitResult)
			return @transformState

		# translate

		translate: (delta)->
			@translation = @translation.add(delta)
			@path.translate(delta)
			for item in @items
				item.translate(delta)
			return

		snapPosition: (event)->
			@dragOffset ?= @rectangle.center.subtract(event.downPoint)
			destination = Utils.Event.snap2D(event.point.add(@dragOffset))
			@translate(destination.subtract(@rectangle.center))
			return

		snapEdgePosition: (event)->
			cornerName = @transformState.corner
			rectangle = @rectangle.clone()
			@dragOffset ?= rectangle[cornerName].subtract(event.downPoint)
			destination = Utils.Event.snap2D(event.point.add(@dragOffset))
			rectangle.moveCorner(cornerName, destination)
			@translate(rectangle.center.subtract(@rectangle.center))
			return

		beginTranslate: (event)->
			@translation = new Point()
			return

		updateTranslate: (event)->
			if Utils.Event.getSnap() <= 1
				@translate(event.delta)
			else
				if @selectionState.corner? 		# if snap and dragging an edge: snap the edge position
					@snapEdgePosition(event)
				else 							# if snap and dragging anything else: snap the new position
					@snapPosition(event)
			return

		endTranslate: ()->
			@dragOffset = null
			return @translation

		# scale

		getScale: (event)->
			return event.point.subtract(@rectangle.center)

		keepAspectRatio: (event, scale)->
			# if shift is not pressed and a corner is selected: keep aspect ratio (rectangle must have width and height greater than 0 to keep aspect ratio)
			if not event.modifiers.shift and name in @constructor.cornersNames and @rectangle.width > 0 and @rectangle.height > 0
				if Math.abs(scale.x / @rectangle.width) > Math.abs(scale.y / @rectangle.height)
					scale.x = Utils.sign(scale.x) * Math.abs(@rectangle.width * scale.y / @rectangle.height)
				else
					scale.y = Utils.sign(scale.y) * Math.abs(@rectangle.height * scale.x / @rectangle.width)
			return

		getScaleCenter: ()->
			if R.specialKey(event)
				name = @constructor.indexToName[@selectionState.index]
				return @constructor.pointFromName(@rectangle, @constructor.oppositeName[name])
			else
				return @rectangle.center

		normalizeScale: (scale)->
			scale.x = Math.abs(2 * scale.x / rectangle.width)
			scale.y = Math.abs(2 * scale.y / rectangle.height)
			return

		scale: (scale, center)->
			@scaling = @scaling.add(scale)
			@rectangle.scaleFromCenter(scale, center)
			@path.scale(scale.x, scale.y, center)
			for item in @items
				item.scale(scale, center)
			return

		beginScale: (event)->
			@scaling = new Point(1,1)
			return

		updateScale: (event)->

			event.point = Utils.Event.snap2D(event.point)
			scale = @getScale(event)
			@keepAspectRatio(event, scale)
			@normalizeScale(scale)
			center = @getScaleCenter(event)
			@scale(scale, center)

			# center = rectangle.center.clone()
			# rectangle[name] = @constructor.valueFromName(center.add(dx, dy), name)

			# if not R.specialKey(event)
			# 	rectangle[@constructor.oppositeName[name]] = @constructor.valueFromName(center.subtract(dx, dy), name)
			# else
			# 	# the center of the rectangle changes when moving only one side
			# 	# the center must be repositionned with the previous center as pivot point (necessary when rotation > 0)
			# 	rectangle.center = center.add(rectangle.center.subtract(center).rotate(rotation))

			# if rectangle.width < 0
			# 	rectangle.width = Math.abs(rectangle.width)
			# 	rectangle.center.x = center.x
			# if rectangle.height < 0
			# 	rectangle.height = Math.abs(rectangle.height)
			# 	rectangle.center.y = center.y

			# @setRectangle(rectangle, false)

			return

		endScale: ()->
			return [@scaling, @rectangle.center]

	class SelectionRotationRectangle extends SelectionRectangle

		@indexToName =
			0: 'bottomLeft'
			1: 'left'
			2: 'topLeft'
			3: 'top'
			4: 'rotation-handle'
			5: 'top'
			6: 'topRight'
			7: 'right'
			8: 'bottomRight'
			9: 'bottom'

		constructor: (rectangle)->
			super(rectangle)
			@rotation = 0
			return

		addHandles: (bounds)->
			super(bounds)
			@path.insert(3, new P.Point(bounds.center.x, bounds.top-25))
			@path.insert(3, new P.Point(bounds.center.x, bounds.top))
			return

		setTransformState: (hitResult)->
			if hitResult?.type == 'segment'
				if @constructor.indexToName[hitResult.segment.index] == 'rotation-handle'
					@selectionState = type: 'rotation'
					return
			super(hitResult)
			return

		# scale

		getScale: (event)->
			delta = super(event)
			x = new P.Point(1,0)
			x.angle += @rotation
			dx = x.dot(delta)
			y = new P.Point(0,1)
			y.angle += @rotation
			dy = y.dot(delta)
			return new Point(dx, dy)

		# rotate

		rotate: (angle)->
			@rotation += angle
			@path.rotate(angle)
			for item in @items
				item.rotate(angle, rectangle.center)
			return

		beginRotate: ()->
			@rotation = 0
			return

		updateRotate: (event)->
			angle = event.point.subtract(@rectangle.center).angle + 90
			if event.modifiers.shift or R.specialKey(event) or Utils.Event.getSnap() > 1
				angle = Utils.roundToMultiple(rotation, if event.modifiers.shift then 10 else 5)
			@rotate(angle-@rotation)
			return

		endRotate: ()->
			return [@rotation, @rectangle.center]



	class ScreenshotRectangle extends SelectionRectangle

		constructor: (@rectangle, extractImage) ->
			super()

			@drawing = new P.Path.Rectangle(@rectangle)
			@drawing.name = 'selection rectangle background'
			@drawing.strokeWidth = 1
			@drawing.strokeColor = R.selectionBlue
			@drawing.controller = @

			@group.addChild(@drawing)

			separatorJ = R.stageJ.find(".text-separator")
			@buttonJ = R.templatesJ.find(".screenshot-btn").clone().insertAfter(separatorJ)

			@buttonJ.find('.extract-btn').click (event)->
				redraw = $(this).attr('data-click') == 'redraw-snapshot'
				extractImage(redraw)
				return

			@updateTransform()

			@select()

			Tool.select.select()

			return

		remove: ()->
			@removing = true
			super()
			@buttonJ.remove()
			R.tools['Screenshot'].selectionRectangle = null
			return

		deselect: ()->
			if not super() then return false
			if not @removing then @remove()
			return true

		setRectangle: (rectangle, update=true)->
			super(rectangle, update)
			Utils.Rectangle.updatePathRectangle(@drawing, rectangle)
			@updateTransform()
			return

		moveTo: (position, update)->
			super(position, update)
			@updateTransform()
			return

		updateTransform: ()->
			viewPos = P.view.projectToView(@rectangle.center)
			transfrom = 'translate(' + viewPos.x + 'px,' + viewPos.y + 'px)'
			transfrom += 'translate(-50%, -50%)'
			@buttonJ.css( 'position': 'absolute', 'transform': transfrom, 'top': 0, 'left': 0, 'transform-origin': '50% 50%', 'z-index': 999 )
			return

		update: ()->
			return

	return SelectionRectangle