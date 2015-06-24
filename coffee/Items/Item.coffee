define [ 'Command'], (Command) ->

	class Item

		# @indexToName =
		# 	0: 'bottomLeft'
		# 	1: 'left'
		# 	2: 'topLeft'
		# 	3: 'top'
		# 	4: 'topRight'
		# 	5: 'right'
		# 	6: 'bottomRight'
		# 	7: 'bottom'

		# @oppositeName =
		# 	'top': 'bottom'
		# 	'bottom': 'top'
		# 	'left': 'right'
		# 	'right': 'left'
		# 	'topLeft': 'bottomRight'
		# 	'topRight':  'bottomLeft'
		# 	'bottomRight':  'topLeft'
		# 	'bottomLeft':  'topRight'

		# @cornersNames = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft']
		# @sidesNames = ['left', 'right', 'top', 'bottom']

		# @valueFromName: (point, name)->
		# 	switch name
		# 		when 'left', 'right'
		# 			return point.x
		# 		when 'top', 'bottom'
		# 			return point.y
		# 		else
		# 			return point

		# Paper hitOptions for hitTest function to check which items (corresponding to those criterias) are under a point
		@hitOptions =
			segments: true
			stroke: true
			fill: true
			selected: true
			tolerance: 5

		@zIndexSortStop: (event, ui)->
			previouslySelectedItems = R.selectedItems
			Tool.Select.deselectAll()
			rItem = R.items[ui.item.attr("data-pk")]
			nextItemJ = ui.item.next()
			if nextItemJ.length>0
				rItem.insertAbove(R.items[nextItemJ.attr("data-pk")], null, true)
			else
				previousItemJ = ui.item.prev()
				if previousItemJ.length>0
					rItem.insertBelow(R.items[previousItemJ.attr("data-pk")], null, true)
			for item in previouslySelectedItems
				item.select()
			return

		@addItemToStage: (item)->
			Item.addItemTo(item)
			return

		@addItemTo: (item, lock=null)->
			wasSelected = item.isSelected()
			if wasSelected then item.deselect()
			group = if lock then lock.group else R.mainLayer
			group.addChild(item.group)
			item.lock = lock
			Utils.Array.remove(item.sortedItems, item)
			parent = lock or R
			if R.RDiv.prototype.isPrototypeOf(item)
				item.sortedItems = parent.sortedDivs
				parent.itemListsJ.find(".rDiv-list").append(item.liJ)
			else if R.RPath.prototype.isPrototypeOf(item)
				item.sortedItems = parent.sortedPaths
				parent.itemListsJ.find(".rPath-list").append(item.liJ)
			else
				console.error "Error: the item is neither an RDiv nor an RPath"
			item.updateZIndex()
			if wasSelected then item.select()
			return

		# @onPositionFinishChange: (value)->
		# 	# -------------------------------------------------------------------- #
		# 	# !!! Problem: moveToCommand will move depending on the given item !!! #
		# 	# -------------------------------------------------------------------- #

		# 	value = value.split(':')

		# 	if value.length>1
		# 		switch value[0]
		# 			when 'x'
		# 				x = parseFloat(value[1])
		# 				if not R.isNumber(x)
		# 					R.alertManager.alert 'Position invalid.', 'Warning'
		# 					return
		# 				for item in R.selectedItems
		# 					y = item.rectangle.center.y
		# 					item.moveToCommand(new P.Point(x, y))
		# 			when 'y'
		# 				y = parseFloat(value[1])
		# 				if not R.isNumber(y)
		# 					R.alertManager.alert 'Position invalid.', 'Warning'
		# 					return
		# 				for item in R.selectedItems
		# 					x = item.rectangle.center.x
		# 					item.moveToCommand(new P.Point(x, y))
		# 			else
		# 				R.alertManager.alert 'Position invalid.', 'Warning'
		# 		return

		# 	value = value.split(',')

		# 	x = parseFloat(value[0])
		# 	y = parseFloat(value[1])

		# 	if not ( R.isNumber(x) and R.isNumber(y) )
		# 		R.alertManager.alert 'Position invalid.', 'Warning'
		# 		return

		# 	point = new P.Point(x, y)

		# 	for item in R.selectedItems
		# 		item.moveToCommand(point)

		# 	return

		# @onSizeFinishChange: (value)->
		# 	value = value.split(',')

		# 	if value.length==1
		# 		value = value.split(':')
		# 		switch value[0]
		# 			when 'width'
		# 				width = parseFloat(value[1])
		# 				if not R.isNumber(width)
		# 					R.alertManager.alert 'P.Size invalid.', 'Warning'
		# 					return
		# 				for item in R.selectedItems
		# 					height = item.rectangle.size.height
		# 					item.resizeCommand(new P.Rectangle(item.rectangle.point, new P.Size(width, height)))
		# 	return

		@initializeParameters: ()->

			parameters =
				'Items':
					align: R.parameters.align
					distribute: R.parameters.distribute
					delete: R.parameters.delete
				'Style':
					strokeWidth: R.parameters.strokeWidth
					strokeColor: R.parameters.strokeColor
					fillColor: R.parameters.fillColor
				'Pos. & size':
					position:
						default: ''
						label: 'Position'
						onChange: ()-> return
						onFinishChange: @onPositionFinishChange
					size:
						default: ''
						label: 'P.Size'
						onChange: ()-> return
						onFinishChange: @onSizeFinishChange

			return parameters

		@parameters = @initializeParameters()

		@create: (duplicateData)->
			copy = new @(duplicateData)
			if not @socketAction
				copy.save(false)
				R.chatSocket.emit "bounce", itemClass: @name, function: "create", arguments: [duplicateData]
			return copy

		constructor: (@data, @pk)->

			# if the RPath is being loaded: directly set pk and load path
			if @pk?
				@setPK(@pk, true)
				R.commandManager.loadItem(@)
			else
				@id = if @data?.id? then @data.id else Math.random() 	# temporary id used until the server sends back the primary key (@pk)
				R.items[@id] = @

			# creation of a new object by the user: set @data to R.gui values
			if @data?
				@secureData()
			else
				@data = new Object()
				R.controllerManager.updateItemData(@)

			@rectangle ?= null

			@selectionState = null
			@selectionRectangle = null

			@group = new P.Group()
			@group.name = "group"
			@group.controller = @


			return

		secureData: ()->
			for name, parameter of @constructor.parameters
				if parameter.secure?
					@data[name] = parameter.secure(@data, parameter)
				else
					value = @data[name]
					if value? and parameter.min? and parameter.max?
						if value < parameter.min or value > parameter.max
							@data[name] = Utils.clamp(parameter.min, value, parameter.max)
			return

		setParameterCommand: (controller, value)->
			@deferredAction(R.SetParameterCommand, controller, value)
			# if @data[name] == value then return
			# @setCurrentCommand(new SetParameterCommand(@, name))
			# @setParameter(name, value)
			# Utils.deferredExecution(@addCurrentCommand, 'addCurrentCommand-' + (@id or @pk) )
			return

		# @param name [String] the name of the value to change
		# @param value [Anything] the new value
		setParameter: (name, value, update)->
			@data[name] = value
			@changed = name
			if not @socketAction
				if update
					@update(name)
				R.chatSocket.emit "bounce", itemPk: @pk, function: "setParameter", arguments: [name, value, false, false]
			return

		# # set path items (control path, drawing, etc.) to the right state before performing hitTest
		# # store the current state of items, and change their state (the original states will be restored in @finishHitTest())
		# # @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)
		# # @param strokeWidth [Number] (optional) contorl path width will be set to *strokeWidth* if it is provided
		# prepareHitTest: ()->
		# 	@selectionRectangle?.strokeColor = R.selectionBlue
		# 	return

		# # restore path items orginial states (same as before @prepareHitTest())
		# # @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)
		# finishHitTest: ()->
		# 	@selectionRectangle?.strokeColor = null
		# 	return

		# # perform hit test to check if the point hits the selection rectangle
		# # @param point [P.Point] the point to test
		# # @param hitOptions [Object] the [paper hit test options](http://paperjs.org/reference/item/#hittest-point)
		# performHitTest: (point, hitOptions)->
		# 	return @selectionRectangle.hitTest(point)

		# # when hit through websocket, must be (fully)Selected to hitTest
		# # perform hit test on control path and selection rectangle with a stroke width of 1
		# # to manipulate points on the control path or selection rectangle
		# # since @hitTest() will be overridden by children RPath, it is necessary to @prepareHitTest() and @finishHitTest()
		# # @param point [P.Point] the point to test
		# # @param hitOptions [Object] the [paper hit test options](http://paperjs.org/reference/item/#hittest-point)
		# # @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)
		# # @return [Paper HitResult] the paper hit result
		# hitTest: (point, hitOptions, fullySelected=true)->
		# 	@prepareHitTest(fullySelected, 1)
		# 	hitResult = @performHitTest(point, hitOptions)
		# 	@finishHitTest(fullySelected)
		# 	return hitResult

		# intialize the selection:
		# determine which action to perform depending on the the *hitResult* (move by default, edit point if segment from contorl path, etc.)
		# set @selectionState which will be used during the selection process (select begin, update, end)
		# @param event [Paper event] the mouse event
		# @param hitResult [Paper HitResult] [paper hit result](http://paperjs.org/reference/hitresult/) form the hit test
		# initializeSelection: (event, hitResult) ->
		# 	if hitResult.item == @selectionRectangle
		# 		@selectionState = move: true
		# 		if hitResult?.type == 'stroke'
		# 			selectionBounds = @rectangle.clone().expand(10)
		# 			# for sideName in @constructor.sidesNames
		# 			# 	if Math.abs( selectionBounds[sideName] - @constructor.valueFromName(hitResult.point, sideName) ) < @constructor.hitOptions.tolerance
		# 			# 		@selectionState.move = sideName
		# 			minDistance = Infinity
		# 			for cornerName in @constructor.cornersNames
		# 				distance = selectionBounds[cornerName].getDistance(hitResult.point, true)
		# 				if distance < minDistance
		# 					@selectionState.move = cornerName
		# 					minDistance = distance
		# 		else if hitResult?.type == 'segment'
		# 			@selectionState = resize: { index: hitResult.segment.index }
		# 	return

		# # begin select action:
		# # - initialize selection (reset selection state)
		# # - select
		# # - hit test and initialize selection
		# # @param event [Paper event] the mouse event
		# beginSelect: (event) ->

		# 	@selectionState = move: true
		# 	if not @isSelected()
		# 		R.commandManager.add(updateActionR.SelectCommand([@]), true)
		# 	else
		# 		hitResult = @performHitTest(event.point, @constructor.hitOptions)
		# 		if hitResult? then @initializeSelection(event, hitResult)

		# 	if @selectionState.move?
		# 		@beginAction(new R.MoveCommand(@))
		# 	else if @selectionState.resize?
		# 		@beginAction(new R.ResizeCommand(@))

		# 	return

		# # depending on the selected item, updateSelect will:
		# # - rotate the group,
		# # - scale the group,
		# # - or move the group.
		# # @param event [Paper event] the mouse event
		# updateSelect: (event)->
		# 	@updateAction(event)
		# 	return

		# # end the selection action:
		# # - nullify selectionState
		# # - redraw in normal mode (not fast mode)
		# # - update select command
		# endSelect: (event)->
		# 	@endAction()
		# 	return

		# beginAction: (command)->
		# 	if @currentCommand
		# 		@endAction()
		# 		clearTimeout(R.updateTimeout['addCurrentCommand-' + (@id or @pk)])
		# 	@currentCommand = command
		# 	return

		# updateAction: ()->
		# 	@currentCommand.update.apply(@currentCommand, arguments)
		# 	return

		# endAction: ()=>

		# 	positionIsValid = if @currentCommand.constructor.needValidPosition then Lock.validatePosition(@) else true

		# 	commandChanged = @currentCommand.end(positionIsValid)
		# 	if positionIsValid
		# 		if commandChanged then R.commandManager.add(@currentCommand)
		# 	else
		# 		@currentCommand.undo()

		# 	@currentCommand = null
		# 	return

		# deferredAction: (ActionCommand, args...)->
		# 	if not ActionCommand.prototype.isPrototypeOf(@currentCommand)
		# 		@beginAction(new ActionCommand(@, args))
		# 	@updateAction.apply(@, args)
		# 	Utils.deferredExecution(@endAction, 'addCurrentCommand-' + (@id or @pk) )
		# 	return

		# doAction: (ActionCommand, args)->
		# 	@beginAction(new ActionCommand(@))
		# 	@updateAction.apply(@, args)
		# 	@endAction()
		# 	return

		# # create the selection rectangle (path used to rotate and scale the RPath)
		# # @param bounds [Paper P.Rectangle] the bounds of the selection rectangle
		# createSelectionRectangle: (bounds)->
		# 	@selectionRectangle.insert(1, new P.Point(bounds.left, bounds.center.y))
		# 	@selectionRectangle.insert(3, new P.Point(bounds.center.x, bounds.top))
		# 	@selectionRectangle.insert(5, new P.Point(bounds.right, bounds.center.y))
		# 	@selectionRectangle.insert(7, new P.Point(bounds.center.x, bounds.bottom))
		# 	return

		# # add or update the selection rectangle (path used to rotate and scale the RPath)
		# # redefined by RShape# the selection rectangle is slightly different for a shape since it is never reset (rotation and scale are stored in database)
		# updateSelectionRectangle: ()->
		# 	bounds = @rectangle.clone().expand(10)

		# 	# create the selection rectangle: rectangle path + handle at the top used for rotations
		# 	@selectionRectangle?.remove()
		# 	@selectionRectangle = new P.Path.Rectangle(bounds)
		# 	@group.addChild(@selectionRectangle)
		# 	@selectionRectangle.name = "selection rectangle"
		# 	@selectionRectangle.pivot = bounds.center

		# 	@createSelectionRectangle(bounds)

		# 	@selectionRectangle.selected = true
		# 	@selectionRectangle.controller = @

		# 	return

		setRectangle: (rectangle, update=true)->
			if not P.Rectangle.prototype.isPrototypeOf(rectangle) then rectangle = new P.Rectangle(rectangle)
			@rectangle = rectangle
			# if @selectionRectangle then @updateSelectionRectangle()
			if not @socketAction
				if update then @update('rectangle')
				R.chatSocket.emit "bounce", itemPk: @pk, function: "setRectangle", arguments: [@rectangle, false]
			return

		# updateSetRectangle: (event)->

		# 	event.point = Utils.Event.snap2D(event.point)

		# 	rotation = @rotation or 0
		# 	rectangle = @rectangle.clone()
		# 	delta = event.point.subtract(@rectangle.center)
		# 	x = new P.Point(1,0)
		# 	x.angle += rotation
		# 	dx = x.dot(delta)
		# 	y = new P.Point(0,1)
		# 	y.angle += rotation
		# 	dy = y.dot(delta)

		# 	index = @selectionState.resize.index
		# 	name = @constructor.indexToName[index]

		# 	# if shift is not pressed and a corner is selected: keep aspect ratio (rectangle must have width and height greater than 0 to keep aspect ratio)
		# 	if not event.modifiers.shift and name in @constructor.cornersNames and rectangle.width > 0 and rectangle.height > 0
		# 		if Math.abs(dx / rectangle.width) > Math.abs(dy / rectangle.height)
		# 			dx = Utils.sign(dx) * Math.abs(rectangle.width * dy / rectangle.height)
		# 		else
		# 			dy = Utils.sign(dy) * Math.abs(rectangle.height * dx / rectangle.width)

		# 	center = rectangle.center.clone()
		# 	rectangle[name] = @constructor.valueFromName(center.add(dx, dy), name)

		# 	if not R.specialKey(event)
		# 		rectangle[@constructor.oppositeName[name]] = @constructor.valueFromName(center.subtract(dx, dy), name)
		# 	else
		# 		# the center of the rectangle changes when moving only one side
		# 		# the center must be repositionned with the previous center as pivot point (necessary when rotation > 0)
		# 		rectangle.center = center.add(rectangle.center.subtract(center).rotate(rotation))

		# 	if rectangle.width < 0
		# 		rectangle.width = Math.abs(rectangle.width)
		# 		rectangle.center.x = center.x
		# 	if rectangle.height < 0
		# 		rectangle.height = Math.abs(rectangle.height)
		# 		rectangle.center.y = center.y

		# 	@setRectangle(rectangle, false)
		# 	Lock.highlightValidity(@)
		# 	return

		# endSetRectangle: (update)->
		# 	if update then @update('rectangle')
		# 	return

		moveTo: (position, update)->
			if not P.Point.prototype.isPrototypeOf(position) then position = new P.Point(position)
			delta = position.subtract(@rectangle.center)
			@rectangle.center = position
			@group.translate(delta)

			if not @socketAction
				if update then @update('position')
				R.chatSocket.emit "bounce", itemPk: @pk, function: "moveTo", arguments: [position, false]
			return

		moveBy: (delta, update)->
			@moveTo(@rectangle.center.add(delta), update)
			return

		# updateMove: (event)->
		# 	if Utils.Event.getSnap() > 1
		# 		if @selectionState.move != true
		# 			cornerName = @selectionState.move
		# 			rectangle = @rectangle.clone()
		# 			@dragOffset ?= rectangle[cornerName].subtract(event.downPoint)
		# 			destination = Utils.Event.snap2D(event.point.add(@dragOffset))
		# 			rectangle.moveCorner(cornerName, destination)
		# 			@moveTo(rectangle.center)
		# 		else
		# 			@dragOffset ?= @rectangle.center.subtract(event.downPoint)
		# 			destination = Utils.Event.snap2D(event.point.add(@dragOffset))
		# 			@moveTo(destination)
		# 	else
		# 		@moveBy(event.delta)
		# 	Lock.highlightValidity(@)
		# 	return

		# endMove: (update)->
		# 	@dragOffset = null
		# 	if update then @update('position')
		# 	return

		# moveToCommand: (position)->
		# 	R.commandManager.add(new R.MoveCommand(@, position), true)
		# 	return

		# resizeCommand: (rectangle)->
		# 	R.commandManager.add(new R.ResizeCommand(@, rectangle), true)
		# 	return

		# moveByCommand: (delta)->
		# 	@moveToCommand(@rectangle.center.add(delta), true)
		# 	return

		# @return [Object] @data along with @rectangle and @rotation
		getData: ()->
			data = jQuery.extend({}, @data)
			data.rectangle = @rectangle.toJSON()
			data.rotation = @rotation
			return data

		# @return [String] the stringified data
		getStringifiedData: ()->
			return JSON.stringify(@getData())

		getBounds: ()->
			return @rectangle

		getDrawingBounds: ()->
			return @rectangle.expand(@data.strokeWidth)

		# highlight this RItem by drawing a blue rectangle around it
		highlight: ()->
			if @highlightRectangle?
				Utils.Rectangle.updatePathRectangle(@highlightRectangle, @getBounds())
				return
			@highlightRectangle = new P.Path.Rectangle(@getBounds())
			@highlightRectangle.strokeColor = R.selectionBlue
			@highlightRectangle.strokeScaling = false
			@highlightRectangle.dashArray = [4, 10]
			R.selectionLayer.addChild(@highlightRectangle)
			return

		# common to all RItems
		# hide highlight rectangle
		unhighlight: ()->
			if not @highlightRectangle? then return
			@highlightRectangle.remove()
			@highlightRectangle = null
			return

		getPk: ()->
			return @pk or @id

		setPK: (@pk, loading=false)->
			if @id? then R.commandManager.setItemPk(@id, @pk)
			R.items[@pk] = @
			delete R.items[@id]
			if not loading and not @socketAction then R.chatSocket.emit "bounce", itemPk: @id, function: "setPK", arguments: [@pk]
			return

		# @return true if RItem is selected
		isSelected: ()->
			return @selectionRectangle?

		# select the RItem: (only if it has no selection rectangle i.e. not already selected)
		# - update the selection rectangle,
		# - (optionally) update controller in the gui accordingly
		# @return whether the ritem was selected or not
		select: ()->
			if @selectionRectangle? then return false


			@lock?.deselect()

			# create or update the selection rectangle
			@selectionState = move: true

			R.s = @

			@updateSelectionRectangle(true)
			R.selectedItems.push(@)
			R.controllerManager.updateParametersForSelectedItems()

			R.rasterizer.selectItem(@)

			@zindex = @group.index
			R.selectionLayer.addChild(@group)

			return true

		deselect: ()->
			if not @selectionRectangle? then return false

			@selectionRectangle?.remove()
			@selectionRectangle = null
			Utils.Array.remove(R.selectedItems, @)
			R.controllerManager.updateParametersForSelectedItems()

			if @group? 	# @group is null when item is removed (called from @remove())

				R.rasterizer.deselectItem(@)

				if not @lock
					@group = R.mainLayer.insertChild(@zindex, @group)
				else
					@group = @lock.group.insertChild(@zindex, @group)

			R.RDiv.showDivs()

			return true

		remove: ()->
			R.commandManager.unloadItem(@)
			if not @group then return

			@group.remove()
			@group = null
			@deselect()
			@highlightRectangle?.remove()
			if @pk?
				delete R.items[@pk]
			else
				delete R.items[@id]

			# @pk = null 	# pk is required to delete the path!!
			# @id = null
			return

		finish: ()->
			if @rectangle.area == 0
				@remove()
				return false
			return true

		save: (addCreateCommand)->
			if addCreateCommand then R.commandManager.add(new R.CreateItemCommand(@))
			return

		saveCallback: ()->
			return

		addUpdateFunctionAndArguments: (args, type)->
			args.push( function: @getUpdateFunction(type), arguments: @getUpdateArguments(type) )
			return

		delete: ()->
			if not @socketAction then R.chatSocket.emit "bounce", itemPk: @pk, function: "delete", arguments: []
			@pk = null
			return

		deleteCommand: ()->
			R.commandManager.add(new R.DeleteItemCommand(@), true)
			return

		getDuplicateData: ()->
			return data: @getData(), rectangle: @rectangle, pk: @getPk()

		duplicateCommand: ()->
			R.commandManager.add(new R.DuplicateItemCommand(@), true)
			return

		removeDrawing: ()->
			if not @drawing?.parent? then return
			@drawingRelativePosition = @drawing.position.subtract(@rectangle.center)
			@drawing.remove()
			return

		replaceDrawing: ()->
			if not @drawing? or not @drawingRelativePosition? then return
			@raster?.remove()
			@group.addChild(@drawing)
			@drawing.position = @rectangle.center.add(@drawingRelativePosition)
			@drawingRelativePosition = null
			return

		rasterize: ()->
			if @raster? or not @drawing? then return
			if not R.rasterizer.rasterizeItems then return
			@raster = @drawing.rasterize()
			@group.addChild(@raster)
			@raster.sendToBack() 	# the raster (of a lock) must be send behind other items
			@removeDrawing()
			return

	return RItem