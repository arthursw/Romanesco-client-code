define [ 'Tools/Tool', 'Items/Item', 'Items/Content', 'Items/Divs/Div', 'Commands/Command' ], (Tool, Item, Content, Div, Command) ->

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
					return new P.Point(rectangle[name], rectangle.center.y)
				when 'top', 'bottom'
					return new P.Point(rectangle.center.x, rectangle[name])
				else
					return rectangle[name]

		# Paper hitOptions for hitTest function to check which items (corresponding to those criterias) are under a point
		@hitOptions =
			segments: true
			stroke: true
			fill: true
			tolerance: 5

		@create: ()->
			for item in R.selectedItems
				if not Content.prototype.isPrototypeOf(item)
					return new SelectionRectangle()
			return new SelectionRotationRectangle()

		@getDelta: (center, point, rotation)->
			d = point.subtract(center)
			x = new P.Point(1,0)
			y = new P.Point(0,1)
			return new P.Point(x.rotate(rotation).dot(d), y.rotate(rotation).dot(d))

		@setRectangle: (items, previousRectangle, rectangle, rotation, update)->
			scale = new P.Point(rectangle.size.divide(previousRectangle.size))
			previousCenter = previousRectangle.center

			for item in items
				itemRectangle = item.rectangle.clone()
				# translate
				delta = @getDelta(previousCenter, itemRectangle.center, rotation)
				itemRectangle.center = rectangle.center.add(delta.multiply(scale).rotate(rotation))
				# scale
				itemRectangle = itemRectangle.scale(scale.x, scale.y)
				# set rectangle
				item.setRectangle(itemRectangle, update)
			return

		constructor: (@rectangle)->
			@items = if not @rectangle? then R.selectedItems else []
			@rectangle ?= @getBoundingRectangle(@items)
			@translation = new P.Point()
			@previousRectangle = @rectangle.clone()

			@transformState = null

			@group = new P.Group()
			@group.name = "selection rectangle group"
			@group.controller = @

			@path = new P.Path.Rectangle(@rectangle)
			@path.name = "selection rectangle path"
			@path.strokeColor = R.selectionBlue
			@path.strokeWidth = 1
			@path.selected = true
			@path.controller = @

			@addHandles(@rectangle)
			@update()
			@group.addChild(@path)

			R.view.selectionLayer.addChild(@group)

			@path.pivot = @rectangle.center

			return

		getBoundingRectangle: (items)->
			if items.length == 0 then return
			bounds = items[0].getBounds()
			for item in items
				bounds = bounds.unite(item.getBounds())
			return bounds.expand(5)

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
					@transformState = command: 'Translate', corner: @getClosestCorner(hitResult.point)
				when'segment'
					@transformState = command: 'Scale', index: hitResult.segment.index
				else
					@transformState = command: 'Translate'
			return

		hitTest: (event)->
			hitResult = @path.hitTest(event.point, @constructor.hitOptions)
			if not hitResult? then return false
			@beginAction(hitResult, event)
			return true

		beginAction: (hitResult, event)->
			@setTransformState(hitResult)
			R.commandManager.beginAction(new Command[@transformState.command](R.selectedItems), event)
			return

		update: ()->
			@items = R.selectedItems
			if @items.length == 0
				@remove()
				return
			@rectangle = @getBoundingRectangle(@items)
			@updatePath()
			Item.updatePositionAndSizeControllers(@rectangle.point, new paper.Point(@rectangle.size))
			Div.showDivs()
			return

		updatePath: ()->
			for index, name of @constructor.indexToName
				@path.segments[index].point = @constructor.pointFromName(@rectangle, name)
			@path.pivot = @rectangle.center
			@path.rotation = @rotation or 0
			return

		show: ()->
			@group.visible = true
			@path.visible = true
			return

		hide: ()->
			@group.visible = false
			@path.visible = false
			return

		setVisibility: (show)->
			if show then @show() else @hide()
			return

		remove: ()->
			@group.remove()
			@rectangle = null
			R.tools.select.selectionRectangle = null
			Div.showDivs()
			return

		# translate

		translate: (delta)->
			@translation = @translation.add(delta)
			@rectangle = @rectangle.translate(delta)
			@path.translate(delta)
			for item in @items
				item.translate(delta, false)
			return

		snapPosition: (event)->
			@dragOffset ?= @rectangle.center.subtract(event.downPoint)
			destination = Utils.Snap.snap2D(event.point.add(@dragOffset))
			@translate(destination.subtract(@rectangle.center))
			return

		snapEdgePosition: (event)->
			cornerName = @transformState.corner
			rectangle = @rectangle.clone()
			@dragOffset ?= rectangle[cornerName].subtract(event.downPoint)
			destination = Utils.Snap.snap2D(event.point.add(@dragOffset))
			rectangle.moveCorner(cornerName, destination)
			@translate(rectangle.center.subtract(@rectangle.center))
			return

		updatePositionController: ()->
			position = @rectangle.topLeft
			string = '' + position.x.toFixed(2) + ', ' + position.y.toFixed(2)
			R.controllerManager.folders["Position & size"]?.controllers.position?.setValue(string)
			return

		updateSizeController: ()->
			size = @rectangle.size
			string = '' + size.width.toFixed(2) + ', ' + size.height.toFixed(2)
			R.controllerManager.folders["Position & size"]?.controllers.size?.setValue(string)
			return

		beginTranslate: (event)->
			@translation = new P.Point()
			return

		updateTranslate: (event)->
			if Utils.Snap.getSnap() <= 1
				@translate(event.delta)
			else
				if @transformState.corner? 		# if snap and dragging an edge: snap the edge position
					@snapEdgePosition(event)
				else 							# if snap and dragging anything else: snap the new position
					@snapPosition(event)
			@updatePositionController()
			return

		endTranslate: ()->
			@dragOffset = null
			@updatePositionController()
			return delta: @translation

		# scale

		# getScale: (point, oppositeCorner, name)->
		# 	delta = point.subtract(oppositeCorner).divide(@rectangle.size).abs()
		# 	switch name
		# 		when 'top', 'bottom'
		# 			delta.x = 1.0
		# 		when 'left', 'right'
		# 			delta.y = 1.0
		# 	return delta
		# #
		# getScale: (event)->
		# 	delta = event.point.subtract(@rectangle.center)
		# 	x = new P.Point(1,0)
		# 	dx = x.dot(delta)
		# 	y = new P.Point(0,1)
		# 	dy = y.dot(delta)
		# 	return new P.Point(dx, dy)
		#
		# keepAspectRatio: (event, scale, name)->
		# 	# if shift is not pressed and a corner is selected: keep aspect ratio
		# 	if not event.modifiers.shift and name in @constructor.cornersNames
		# 		if scale.x > scale.y
		# 			scale.y = scale.x
		# 		else
		# 			scale.x = scale.y
		# 	return
		#
		# getScaleCenter: (event, oppositeCorner, name)->
		# 	if R.specialKey(event)
		# 		return oppositeCorner
		# 	else
		# 		return @rectangle.center

		# scale: (scale, center)->
		# 	@scaling = @scaling.add(scale)
		# 	@rectangle = @rectangle.scaleFromCenter(scale, center)
		# 	@scalePath(scale, center)
		# 	for item in @items
		# 		item.scale(scale, center)
		# 	return

		beginScale: (event)->
			@previousRectangle = @rectangle.clone()
			return

		snapPoint: (point)->
			return Utils.Snap.snap2D(point)

		keepAspectRatio: (event, rectangle, delta, name)->
			# if shift is not pressed and a corner is selected: keep aspect ratio (rectangle must have width and height greater than 0 to keep aspect ratio)
			if name in @constructor.cornersNames and rectangle.width > 0 and rectangle.height > 0 and ( @items.length > 1 or not event.modifiers.shift )
				if Math.abs(delta.x / rectangle.width) > Math.abs(delta.y / rectangle.height)
					delta.x = Utils.sign(delta.x) * Math.abs(rectangle.width * delta.y / rectangle.height)
				else
					delta.y = Utils.sign(delta.y) * Math.abs(rectangle.height * delta.x / rectangle.width)
			return

		moveSelectedSide: (name, rectangle, center, delta)->
			rectangle[name] = @constructor.valueFromName(center.add(delta), name)
			return

		moveOppositeSide: (name, rectangle, center, delta)->
			rectangle[@constructor.oppositeName[name]] = @constructor.valueFromName(center.subtract(delta), name)
			return

		adjustPosition: (center)->
			return

		adjustPosition: (rectangle, center)->
			# the center of the rectangle changes when moving only one side
			# the center must be repositionned with the previous center as pivot point (necessary when rotation > 0)
			rectangle.center = center.add(rectangle.center.subtract(center).rotate(@rotation))
			return

		cancelNegativeSize: (rectangle, center)->
			if rectangle.width < 0
				rectangle.width = Math.abs(rectangle.width)
				rectangle.center.x = center.x
			if rectangle.height < 0
				rectangle.height = Math.abs(rectangle.height)
				rectangle.center.y = center.y
			return

		#
		# setRectangle: (rectangle)->
		# 	scale = new P.Point(rectangle.size.divide(@rectangle.size))
		# 	rotation = @rotation or 0
		# 	previousCenter = @rectangle.center
		# 	@rectangle = rectangle
		# 	@updatePath()
		#
		# 	for item in @items
		# 		itemRectangle = item.rectangle.clone()
		# 		# translate
		# 		delta = @getDelta(previousCenter, itemRectangle.center, rotation)
		# 		itemRectangle.center = @rectangle.center.add(delta.multiply(scale).rotate(rotation))
		# 		# scale
		# 		itemRectangle = itemRectangle.scale(scale.x, scale.y)
		# 		# set rectangle
		# 		item.setRectangle(itemRectangle)
		# 	return

		updateScale: (event)->
			point = @snapPoint(event.point)
			name = @constructor.indexToName[@transformState.index]
			rectangle = @rectangle.clone()
			center = rectangle.center.clone()
			rotation = @rotation or 0

			delta = @constructor.getDelta(center, point, rotation)
			@keepAspectRatio(event, rectangle, delta, name)

			@moveSelectedSide(name, rectangle, center, delta)

			if not R.specialKey(event)
				@moveOppositeSide(name, rectangle, center, delta)
			else
				@adjustPosition(rectangle, center)

			@cancelNegativeSize(rectangle, center)

			@constructor.setRectangle(@items, @rectangle, rectangle, rotation, false)
			@rectangle = rectangle
			@updatePath()
			@updateSizeController()
			return
		#
		# updateScale: (event)->
		# 	name = @constructor.indexToName[@transformState.index]
		# 	oppositeCorner = @constructor.pointFromName(@rectangle, @constructor.oppositeName[name])
		# 	event.point = Utils.Snap.snap2D(event.point)
		# 	center = @rectangle.center.clone()
		# 	scale = @getScale(event.point, oppositeCorner, name)
		# 	@keepAspectRatio(event, scale, name)
		# 	center = @getScaleCenter(event, oppositeCorner, name)
		# 	if R.specialKey(event) and @rotation?
		# 		@rectangle.center = center.add(@rectangle.center.subtract(center).rotate(@rotation))
		# 	@scale(scale, center)
		#
		# 	# center = rectangle.center.clone()
		# 	# rectangle[name] = @constructor.valueFromName(center.add(dx, dy), name)
		#
		# 	# if not R.specialKey(event)
		# 	# 	rectangle[@constructor.oppositeName[name]] = @constructor.valueFromName(center.subtract(dx, dy), name)
		# 	# else
		# 	# 	# the center of the rectangle changes when moving only one side
		# 	# 	# the center must be repositionned with the previous center as pivot point (necessary when rotation > 0)
		# 	# 	rectangle.center = center.add(rectangle.center.subtract(center).rotate(rotation))
		#
		# 	# if rectangle.width < 0
		# 	# 	rectangle.width = Math.abs(rectangle.width)
		# 	# 	rectangle.center.x = center.x
		# 	# if rectangle.height < 0
		# 	# 	rectangle.height = Math.abs(rectangle.height)
		# 	# 	rectangle.center.y = center.y
		#
		# 	# @setRectangle(rectangle, false)
		#
		# 	return

		endScale: ()->
			@updateSizeController()
			return previous: @previousRectangle.clone(), new: @rectangle.clone(), rotation: @rotation

		# commands

		setPosition: (position)->
			delta = position.subtract(@rectangle.topLeft)
			R.commandManager.add(Command.Translate.create(R.selectedItems, delta: delta), true)
			return

		translateBy: (delta)->
			R.commandManager.add(Command.Translate.create(R.selectedItems, delta: delta), true)
			return

		setSize: (newSize)->
			state =
				previous: @rectangle
				new: new P.Rectangle(@rectangle.topLeft, new P.Size(newSize))
				rotation: @rotation or 0
			R.commandManager.add(Command.Scale.create(R.selectedItems, state), true)
			return

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

		@pointFromName: (rectangle, name)->
			if name == 'rotation-handle'
				return new P.Point(rectangle.center.x, rectangle.top-25)
			else
				return super(rectangle, name)

		constructor: ()->
			@rotation = 0
			@deltaRotation = 0
			super()
			return

		addHandles: (bounds)->
			super(bounds)
			@path.insert(3, new P.Point(bounds.center.x, bounds.top-25))
			@path.insert(3, new P.Point(bounds.center.x, bounds.top))
			return

		update: (rotation)->
			@items = R.selectedItems
			if rotation
				@rotation = rotation
			else if @items.length==1 and Content.prototype.isPrototypeOf(@items[0])
				@rotation = @items[0].rotation
			super()
			return

		setTransformState: (hitResult)->
			if hitResult?.type == 'segment'
				name = @constructor.indexToName[hitResult.segment.index]
				if name == 'rotation-handle'
					@transformState = command: 'Rotate'
					return
				if @items.length > 1 and name in @constructor.sidesNames
					@transformState = command: 'Translate'
					return
			super(hitResult)
			return

		# scale

		# scalePath: (scale, center)->
		# 	@path.rotate(-@rotation)
		# 	@path.scale(scale.x, scale.y, center)
		# 	@path.position = @rectangle.center
		# 	@path.pivot = @rectangle.center
		# 	@path.rotate(@rotation)
		# 	return

		# getScale: (point, oppositeCorner, name)->
		# 	delta = point.subtract(@rectangle.center)
		# 	delta = delta.rotate(-@rotation)
		# 	return super(@rectangle.center.add(delta), oppositeCorner, name)

		# getScale: (event)->
		# 	delta = event.point.subtract(@rectangle.center)
		# 	x = new P.Point(1,0)
		# 	x.angle += @rotation
		# 	dx = x.dot(delta)
		# 	y = new P.Point(0,1)
		# 	y.angle += @rotation
		# 	dy = y.dot(delta)
		# 	switch name
		# 		when 'top', 'bottom'
		# 			dx = 1.0
		# 		when 'left', 'right'
		# 			dy = 1.0
		# 	return new P.Point(dx, dy)

		# rotate

		rotate: (angle)->
			@deltaRotation += angle
			@rotation += angle
			@path.rotate(angle)
			for item in @items
				item.rotate(angle, @rectangle.center, false)
			return

		beginRotate: ()->
			@deltaRotation = 0
			return

		updateRotate: (event)->
			angle = event.point.subtract(@rectangle.center).angle + 90
			if event.modifiers.shift or R.specialKey(event) or Utils.Snap.getSnap() > 1
				angle = Utils.roundToMultiple(rotation, if event.modifiers.shift then 10 else 5)
			@rotate(angle-@rotation)
			return

		endRotate: ()->
			return delta: @deltaRotation, center: @rectangle.center

		# commands

		setRotation: (rotation, center)->
			delta =
				delta: rotation - @rotation
				center: center
			R.commandManager.add(Command.Rotate.create(R.selectedItems, delta), true)
			return

		rotateBy: (rotation, center)->
			delta =
				delta: rotation
				center: center
			R.commandManager.add(Command.Rotate.create(R.selectedItems, delta), true)
			return


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

			R.tools.select.select()

			return

		remove: ()->
			@removing = true
			super()
			@buttonJ.remove()
			R.tools.Screenshot.selectionRectangle = null
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

	R.SelectionRectangle = SelectionRectangle
	return SelectionRectangle
