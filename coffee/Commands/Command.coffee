define ['Utils/Utils', 'UI/Controllers/ControllerManager'], (Utils, ControllerManager) ->

	class Command

		constructor: (name)->
			@liJ = $("<li>").text(name)
			@liJ.click(@click)
			@id = Math.random()
			return

		# item: ()->
		# 	return R.items[@item.pk]

		superDo: ()->
			@done = true
			@liJ.addClass('done')
			return

		superUndo: ()->
			@done = false
			@liJ.removeClass('done')
			return

		do: ()->
			@superDo()
			# $(@).triggerHandler('do')
			return

		undo: ()->
			@superUndo()
			# $(@).triggerHandler('undo')
			return

		click: ()=>
			R.commandManager.commandClicked(@)
			return

		toggle: ()->
			return if @done then @undo() else @do()

		delete: ()->
			# $(@).triggerHandler('delete', [@])
			@liJ.remove()
			return

		begin: ()->
			return

		update: ()->
			return

		end: ()->
			@superDo()
			return

	class ItemsCommand extends Command

		constructor: (name, items)->
			super(name)
			@items = @mapItems(items)
			return

		mapItems: (items)->
			map = {}
			for item in items
				map[item.getPk()] = item
			return map

		apply: (method, args)->
			for pk, item of @items
				item[method].apply(item, args)
			return

		call: (method, args...)->
			@apply(method, args)
			return

		update: ()->
			return

		end: ()->
			if @positionIsValid()
				super()
			else
				@undo()
			return

		positionIsValid: ()->
			if @constructor.disablePositionCheck then return true
			for pk, item of @items
				if not item.validatePosition() then return false
			return true

		unloadItem: (item)->
			delete @items[item.pk]
			return

		loadItem: (item)->
			@items[item.pk] = item
			return

		setItemPk: (id, pk)->
			@items[pk] = @items[id]
			delete @items[id]
			return

		resurrectItem: (item)->
			@items[item.getPk()] = item
			return

		delete: ()->
			for pk, item of @items
				Utils.Array.remove(R.commandManager.itemToCommands[pk], @)
			super()
			return

	class ItemCommand extends ItemsCommand

		constructor: (name, items)->
			items = if Utils.Array.isArray(items) then items else [items]
			@item = items[0]
			super(name, items)
			return

		unloadItem: (item)->
			@item = null
			super(item)
			return

		loadItem: (item)->
			@item = item
			super(item)
			return

		resurrectItem: (item)->
			@item = item
			super(item)
			return

	class DeferredCommand extends ItemCommand

		@initialize: (method)->
			@method = method
			@Method = Utils.capitalizeFirstLetter(method)
			@beginMethod = 'begin' + @Method
			@updateMethod = 'update' + @Method
			@endMethod = 'end' + @Method
			return

		constructor: (name, items)->
			super(name, items)
			return

		update: ()->
			return

		end: ()->
			super()
			if not @commandChanged() then return
			R.commandManager.add(@)
			@updateItems()
			return

		commandChanged: ()->
			return

		updateItems: (type=@updateType)->
			args = []
			for pk, item of @items
				item.addUpdateFunctionAndArguments(args, type)

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'multipleCalls', args: {functionsAndArguments: args} } ).done(@updateCallback)
			# Dajaxice.draw.multipleCalls( @updateCallback, functionsAndArguments: args)
			return

		updateCallback: (results)->
			for result in results
				R.loader.checkError(result)
			return

	# class DuplicateCommand extends Command
	# 	constructor: (@item)->
	# 		super("Duplicate item")
	# 		return

	# 	do: ()->
	# 		@copy = @item.duplicate()
	# 		super()
	# 		return

	# 	undo: ()->
	# 		@copy.delete()
	# 		super()
	# 		return

	class SelectionRectangleCommand extends DeferredCommand

		@create: (items, state)->
			command = new @(items)
			command.state = state
			return command

		constructor: (items)->
			super(@constructor.Method + ' items', items)
			@updateType = @constructor.method
			return

		begin: (event)->
			R.tools.select.selectionRectangle[@constructor.beginMethod](event)
			return

		update: (event)->
			R.tools.select.selectionRectangle[@constructor.updateMethod](event)
			super(event)
			return

		updateSelectionRectangle: (rotation)->
			R.tools.select.updateSelectionRectangle(rotation)
			return

		end: (event)->
			@state = R.tools.select.selectionRectangle[@constructor.endMethod](event)
			super(event)
			return

		do: ()->
			@apply(@constructor.method, @newState())
			@updateSelectionRectangle()
			super()
			return

		undo: ()->
			@apply(@constructor.method, @previousState())
			@updateSelectionRectangle()
			super()
			return

	class ScaleCommand extends SelectionRectangleCommand

		@initialize('scale')
		@method = 'setRectangle'

		getItemArray: ()->
			if @itemsArray? then return @itemsArray
			@itemsArray = []
			for pk, item of @items
				@itemsArray.push(item)
			return @itemsArray

		do: ()->
			R.SelectionRectangle.setRectangle(@getItemArray(), @state.previous, @state.new, @state.rotation, false)
			@updateSelectionRectangle(@state.rotation)
			@superDo()
			return

		undo: ()->
			R.SelectionRectangle.setRectangle(@getItemArray(), @state.new, @state.previous, @state.rotation, false)
			@updateSelectionRectangle(@state.rotation)
			@superUndo()
			return

		commandChanged: ()->
			return not @state.new.equals(@state.previous)

	class RotateCommand extends SelectionRectangleCommand

		@initialize('rotate')

		newState: ()->
			return [@state.delta, @state.center]

		previousState: ()->
			return [-@state.delta, @state.center]

		commandChanged: ()->
			return @state.delta != 0

	class TranslateCommand extends SelectionRectangleCommand

		@initialize('translate')

		newState: ()->
			return [@state.delta]

		previousState: ()->
			return [@state.delta.multiply(-1)]

		commandChanged: ()->
			return !@state.delta.isZero()
	###
		class BeforeAfterCommand extends DeferredCommand

			@initialize: (method, @name)->
				super(method)
				return

			constructor: (name, item)->
				super(name or @constructor.name, item)
				@beforeArgs = @getState()
				return

			getState: ()->
				return

			update: ()->
				@apply(@constructor.updateMethod, arguments.push(true))
				return

			commandChanged: ()->
				for beforeArg, i in @beforeArgs
					if beforeArg != @afterArgs[i] then return false
				return true

			do: ()->
				@apply(@constructor.method, @afterArgs)
				super()
				return

			undo: ()->
				@afterArgs = @getState()
				@apply(@constructor.method, @beforeArgs)
				super()
				return
	###
	class ModifyPointCommand extends DeferredCommand

		constructor: (item)->
			super('Modify point', item)
			@index = @item.selectedSegment.index
			@previousPoint = @getPoint()
			@updateType = 'points'
			return

		update: (event)->
			@item.updateModifyPoint(event)
			return

		end: (event)->
			@item.endModifyPoint(event)
			@newPoint = @getPoint()
			super(event)
			return

		do: ()->
			@item.modifyPoint.apply(@item, @newPoint)
			super()
			return

		undo: ()->
			@item.modifyPoint.apply(@item, @previousPoint)
			super()
			return

		getPoint: ()->
			segment = @item.controlPath.segments[@index]
			return [segment.index, segment.point.clone(), segment.handleIn.clone(), segment.handleOut.clone(), true]

		commandChanged: ()->
			for i in [1 .. 3]
				if not @previousPoint[i].equals(@newPoint[i])
					return true
			return false

	class ModifySpeedCommand extends DeferredCommand

		constructor: (item)->
			super('Modify speed', item)
			@previousSpeeds = @item.speeds.slice()
			@updateType = 'speed'
			return

		update: (event)->
			@item.updateModifySpeed(event)
			return

		end: (event)->
			@item.endModifySpeed(event)
			super(event)
			return

		do: ()->
			@item.modifySpeed(@newSpeeds, true)
			@updateItems('speed')
			super()
			return

		undo: ()->
			@newSpeeds ?= @item.speeds.slice()
			@item.modifySpeed(@previousSpeeds, true)
			@updateItems('speed')
			super()
			return

		commandChanged: ()->
			return true

	class SetParameterCommand extends DeferredCommand

		constructor: (items, args)->
			@name = args[0]
			@previousValue = args[1]
			super('Change item parameter "' + @name + '"', items)
			@updateType = 'parameters'
			# @previousValue is used for the controller, @previousValues for each item
			@previousValues = {} 			# each item can initially have a different value
											# but in the end they will all have the same value @newValue
			for pk, item of @items
				@previousValues[pk] = item.data[@name]
			return

		do: ()->
			for pk, item of @items
				item.setParameter(@name, @newValue)
			R.controllerManager.updateController(@name, @newValue)
			@updateItems(@name)
			super()
			return

		undo: ()->
			for pk, item of @items
				item.setParameter(@name, @previousValues[pk])
			R.controllerManager.updateController(@name, @previousValue)
			@updateItems(@name)
			super()
			return

		update: (name, value)->
			@newValue = value
			for pk, item of @items
				item.setParameter(name, value)
			return

		commandChanged: ()->
			return true

	# ---- # # ---- # # ---- # # ---- #
	# ---- # # ---- # # ---- # # ---- #
	# ---- # # ---- # # ---- # # ---- #
	# ---- # # ---- # # ---- # # ---- #

	class AddPointCommand extends ItemCommand

		constructor: (item, @location, name='Add point on item')->
			super(name, [item])
			return

		addPoint: (update=true)->
			@segment = @item.addPointAt(@location, update)
			return

		deletePoint: ()->
			@location = @item.deletePoint(@segment)
			return

		do: ()->
			@addPoint()
			super()
			return

		undo: ()->
			@deletePoint()
			super()
			return

	class DeletePointCommand extends AddPointCommand

		constructor: (item, @segment)-> super(item, @segment, 'Delete point on item')

		do: ()->
			@previousPosition = new P.Point(@segment.point)
			@previousHandleIn = new P.Point(@segment.handleIn)
			@previousHandleOut = new P.Point(@segment.handleOut)
			@deletePoint()
			@superDo()
			return

		undo: ()->
			@addPoint(false)
			@item.modifyPoint(@segment, @previousPosition, @previousHandleIn, @previousHandleOut)
			@superUndo()
			return

	class ModifyPointTypeCommand extends ItemCommand

		constructor: (item, @segment, @rtype)->
			@previousRType = @segment.rtype
			@previousPosition = new P.Point(@segment.point)
			@previousHandleIn = new P.Point(@segment.handleIn)
			@previousHandleOut = new P.Point(@segment.handleOut)
			super('Change point type on item', [item])
			return

		do: ()->
			@item.modifyPointType(@segment, @rtype)
			super()
			return

		undo: ()->
			@item.modifyPointType(@segment, @previousRType, true, false)
			@item.modifyPoint(@segment, @previousPosition, @previousHandleIn, @previousHandleOut)
			super()
			return

	### --- Custom command for all kinds of command which modifiy the path --- ###

	class ModifyControlPathCommand extends ItemCommand

		constructor: (item, @previousPointsAndPlanet, @newPointsAndPlanet)->
			super('Modify path', item)
			@superDo()
			return

		do: ()->
			@item.modifyControlPath(@newPointsAndPlanet)
			super()
			return

		undo: ()->
			@item.modifyControlPath(@previousPointsAndPlanet)
			super()
			return

	class MoveViewCommand extends Command
		constructor: (@previousPosition, @newPosition)->
			super("Move view")
			@superDo()
			# if not @previousPosition? or not @newPosition?
			# 	debugger
			return

		# updateCommandItems: ()=>
		# 	console.log "updateCommandItems"
		# 	document.removeEventListener('command executed', @updateCommandItems)
		# 	for command in R.commandManager.history
		# 		if command.item?
		# 			if not command.item.group? and R.items[command.item.pk or command.item.id]
		# 				command.item = R.items[command.item.pk or command.item.id]
		# 		if command.items?
		# 			for item, i in command.items
		# 				if not item.group? and R.items[item.pk or item.id]
		# 					command.items[i] = R.items[item.pk or item.id]
		# 	return

		do: ()->
			somethingToLoad = R.view.moveBy(@newPosition.subtract(@previousPosition), false)
			# if somethingToLoad then document.addEventListener('command executed', @updateCommandItems)
			super()
			return somethingToLoad

		undo: ()->
			somethingToLoad = R.view.moveBy(@previousPosition.subtract(@newPosition), false)
			# if somethingToLoad then document.addEventListener('command executed', @updateCommandItems)
			super()
			return somethingToLoad

	# class MoveCommand extends Command
	# 	constructor: (@item, @newPosition=null)->
	# 		super("Move item", @newPosition?)
	# 		@previousPosition = @item.rectangle.center
	# 		return

	# 	do: ()->
	# 		@item.moveTo(@newPosition, true)
	# 		super()
	# 		return

	# 	undo: ()->
	# 		@item.moveTo(@previousPosition, true)
	# 		super()
	# 		return

	# 	end: ()->
	# 		@newPosition = @item.rectangle.center
	# 		return

	# @MoveCommand = MoveCommand

	class SelectCommand extends ItemsCommand

		constructor: (items, name)->
			super(name or "Select items", items)
			return

		selectItems: ()->
			for pk, item of @items
				item.select()
			return

		deselectItems: ()->
			for pk, item of @items
				item.deselect()
			return

		do: ()->
			@selectItems()
			super()
			return

		undo: ()->
			@deselectItems()
			super()
			return

	class DeselectCommand extends SelectCommand

		constructor: (items)->
			super(items or R.selectedItems.slice(), 'Deselect items')
			return

		do: ()->
			@deselectItems()
			@superDo()
			return

		undo: ()->
			@selectItems()
			@superUndo()
			return

	# class SelectCommand extends Command
	# 	constructor: (@items, @updateParameters, name)->
	# 		super(name or "Select item")
	# 		@previouslySelectedItems = R.previouslySelectedItems.slice()
	# 		return

	# 	deselectSelect: (itemsToDeselect=[], itemsToSelect=[], dontRasterizeItems=false)->
	# 		for item in itemsToDeselect
	# 			item.deselect(false)

	# 		for item in itemsToSelect
	# 			item.select(false)

	# 		R.rasterizer.rasterize(itemsToSelect, dontRasterizeItems)

	# 		items = itemsToSelect.map( (item)-> return { tool: item.constructor, item: item } )
	# 		R.updateParameters(items, true)
	# 		R.selectedItems = itemsToSelect.slice()
	# 		return

	# 	selectItems: ()->
	# 		R.previouslySelectedItems = @previouslySelectedItems
	# 		@deselectSelect(@previouslySelectedItems, @items, true)
	# 		return

	# 	deselectItems: ()->
	# 		R.previouslySelectedItems = R.selectedItems.slice()
	# 		@deselectSelect(@items, @previouslySelectedItems)
	# 		return

	# 	do: ()->
	# 		@selectedItems()
	# 		super()
	# 		return

	# 	undo: ()->
	# 		@deselectItems()
	# 		super()
	# 		return

	# @SelectCommand = SelectCommand

	# class DeselectCommand extends SelectCommand

	# 	constructor: (items, updateParameters)->
	# 		super(items, updateParameters, 'Deselect items')
	# 		return

	# 	do: ()->
	# 		@deselectSelect(@items)
	# 		@superDo()
	# 		return

	# 	undo: ()->
	# 		@selectedItems()
	# 		@superUndo()
	# 		return

	# @DeselectCommand = DeselectCommand

	class CreateItemCommand extends ItemCommand

		constructor: (item, name='Create item')->
			@itemConstructor = item.constructor
			super(name, item)
			@superDo()
			return

		# setDuplicatedItemToCommands: ()->
		# 	for command in R.commandManager.history
		# 		if command == @ then continue
		# 		if command.item? and command.item == @itemPk then command.item = @item
		# 		if command.items?
		# 			for item, i in command.items
		# 				if item == @itemPk then command.items[i] = @item
		# 	return

		# removeDeleteItemFromCommands: ()->
		# 	for command in R.commandManager.history
		# 		if command == @ then continue
		# 		if command.item? and command.item == @item then command.item = @item.pk or @item.id
		# 		if command.items?
		# 			for item, i in command.items
		# 				if item == @item then command.items[i] = @item.pk or @item.id
		# 	@itemPk = @item.pk or @item.id
		# 	return

		duplicateItem: ()->
			@item = @itemConstructor.create(@duplicateData)
			R.commandManager.resurrectItem(@duplicateData.pk, @item)
			# @setDuplicatedItemToCommands()
			@item.select()
			return

		deleteItem: ()->
			# @removeDeleteItemFromCommands()

			@duplicateData = @item.getDuplicateData()
			@item.delete()

			@item = null
			return

		do: ()->
			@duplicateItem()
			super()
			return

		undo: ()->
			@deleteItem()
			super()
			return

	class DeleteItemCommand extends CreateItemCommand
		constructor: (item)-> super(item, 'Delete item')

		do: ()->
			@deleteItem()
			@superDo()
			return

		undo: ()->
			@duplicateItem()
			@superUndo()
			return

	class DuplicateItemCommand extends CreateItemCommand
		constructor: (item)->
			@duplicateData = item.getDuplicateData()
			super(item, 'Duplicate item')

	class ModifyTextCommand extends DeferredCommand

		constructor: (items, args)->
			super("Change text", items)
			@newText = args[0]
			@previousText = @item.data.message
			return

		do: ()->
			@item.data.message = @newText
			@item.contentJ.val(@newText)
			super()
			return

		undo: ()->
			@item.data.message = @previousText
			@item.contentJ.val(@previousText)
			super()
			return

		update: (@newText)->
			@item.setText(@newText, false)
			return

		commandChanged: ()->
			return @newText != @previousText

	# class CreatePathCommand extends CreateItemCommand
	# 	constructor: (item, name=null)->
	# 		name ?= "Create path" 	# if name is not define: it is a create path command
	# 		super(item, name)
	# 		return

	# 	duplicateItem: ()->
	# 		@item = @itemConstructor.duplicate(@data, @controlPathSegments)
	# 		super()
	# 		return

	# 	deleteItem: ()->
	# 		clone = @item.controlPath.clone()
	# 		@controlPathSegments = clone.segments
	# 		clone.remove()
	# 		super()
	# 		return

	# @CreatePathCommand = CreatePathCommand

	# class DeletePathCommand extends CreatePathCommand
	# 	constructor: (item)-> super(item, 'Delete path', true)

	# 	do: ()->
	# 		@deleteItem()
	# 		@superDo()
	# 		return

	# 	undo: ()->
	# 		@duplicateItem()
	# 		@superUndo()
	# 		return

	# @DeletePathCommand = DeletePathCommand

	# class CreateDivCommand extends CreateItemCommand
	# 	constructor: (item, name=null)->
	# 		name ?= "Create div" 	# if name is not define: it is a create path command
	# 		super(item, name)
	# 		return

	# 	duplicateItem: ()->
	# 		@item = @itemConstructor.duplicate(@rectangle, @data)
	# 		super()
	# 		return

	# 	deleteItem: ()->
	# 		@rectangle = @item.rectangle
	# 		@data = @item.getData()
	# 		super()
	# 		return

	# 	do: ()->
	# 		super()
	# 		return Media.prototype.isPrototypeOf(@item) 	# deferred if item is an Media

	# @CreateDivCommand = CreateDivCommand

	# class DeleteDivCommand extends CreateDivCommand
	# 	constructor: (item, name=null)->
	# 		super(item, name or 'Delete div', true)
	# 		return

	# 	do: ()->
	# 		@deleteItem()
	# 		@superDo()
	# 		return

	# 	undo: ()->
	# 		@duplicateItem()
	# 		@superUndo()
	# 		return Media.prototype.isPrototypeOf(@item) 	# deferred if item is an Media

	# @DeleteDivCommand = DeleteDivCommand

	# class CreateLockCommand extends CreateDivCommand
	# 	constructor: (item, name)->
	# 		super(item, name or 'Create lock')

	# @CreateLockCommand = CreateLockCommand

	# class DeleteLockCommand extends DeleteDivCommand
	# 	constructor: (item)->
	# 		super(item, 'Delete lock')
	# 		return

	# @DeleteLockCommand = DeleteLockCommand

	# class RotationCommand extends Command

	# 	constructor: (@item)->
	# 		@previousRotation = @item.rotation
	# 		super('Rotate item', false)
	# 		return

	# 	do: ()->
	# 		@item.select()
	# 		@item.setRotation(@rotation)
	# 		super()
	# 		return

	# 	undo: ()->
	# 		@item.select()
	# 		@item.setRotation(@previousRotation)
	# 		super()
	# 		return

	# 	end: ()->
	# 		@rotation = @item.rotation
	# 		@item.update('rotation')
	# 		return

	# @RotationCommand = RotationCommand

	# class ResizeCommand extends Command

	# 	constructor: (@item)->
	# 		@previousRectangle = @item.rectangle
	# 		super('Resize item', false)
	# 		return

	# 	do: ()->
	# 		@item.select()
	# 		@item.setRectangle(@rectangle)
	# 		super()
	# 		return

	# 	undo: ()->
	# 		@item.select()
	# 		@item.setRectangle(@previousRectangle)
	# 		super()
	# 		return

	# 	end: ()->
	# 		@rectangle = @item.rectangle
	# 		@item.update('rectangle')
	# 		return

	# @ResizeCommand = ResizeCommand

	R.Command = Command
	Command.Scale = ScaleCommand
	Command.Rotate = RotateCommand
	Command.Translate = TranslateCommand

	Command.ModifyPoint = ModifyPointCommand
	Command.ModifySpeed = ModifySpeedCommand

	Command.AddPoint = AddPointCommand
	Command.DeletePoint = DeletePointCommand
	Command.ModifyPointType = ModifyPointTypeCommand
	Command.ModifyControlPath = ModifyControlPathCommand

	Command.SetParameter = SetParameterCommand
	Command.ModifyText = ModifyTextCommand

	Command.CreateItem = CreateItemCommand
	Command.DeleteItem = DeleteItemCommand
	Command.DuplicateItem = DuplicateItemCommand

	Command.Select = SelectCommand
	Command.Deselect = DeselectCommand

	Command.MoveView = MoveViewCommand

	return Command
