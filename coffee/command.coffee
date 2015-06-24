define [ 'utils' ], () ->

	class Command

		constructor: (@name)->
			@liJ = $("<li>").text(@name)
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
			$(@).triggerHandler('do')
			return

		undo: ()->
			@superUndo()
			$(@).triggerHandler('undo')
			return

		click: ()=>
			R.commandManager.commandClicked(@)
			return

		toggle: ()->
			return if @done then @undo() else @do()

		delete: ()->
			@liJ.remove()
			return

		update: ()->
			return

		end: ()->
			@superDo()
			return

	R.Command = Command

	class Command.Items extends Command

		constructor: (name, items)->
			super(name)
			@items = mapItems(items)
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
				if not Lock.validatePosition(item) then return false
			return true

		unloadItem: (item)->
			@items[item.pk] = null
			return

		loadItem: (item)->
			@items[item.pk] = item
			return

		resurrectItem: (pk, item)->
			@items[pk] = item
			return

		delete: ()->
			for pk, item of @items
				_.remove(R.commandManager.itemToCommands[pk], @)
			super()
			return

	class Command.Item extends Command.Items

		constructor: (name, items)->
			items = if Utils.Array.isArray(items) then items else [items]
			@item = items[0]
			super(name, items)
			return

		unloadItem: (item)->
			@item = {pk: item.pk}
			super(item)
			return

		loadItem: (item)->
			@item = item
			super(item)
			return

		resurrectItem: (pk, item)->
			@item = item
			super(pk, item)
			return

	class Command.Deferred extends Command.Item

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

			@apply(@constructor.endMethod, [])

			R.commandManager.add(@)
			@updateItems()
			return

		commandChanged: ()->
			return

		updateItems: (type)->
			args = []
			for pk, item of @items
				item.addUpdateFunctionAndArguments(args, type)
			Dajaxice.draw.multipleCalls( @updateCallback, functionsAndArguments: args)
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

	class Command.SelectionRectangle extends Command.Deferred

		constructor: (items)->
			super(@Method + ' items', items)
			return

		begin: (event)->
			Tool.Select.selectionRectangle[@constructor.beginMethod](event)
			return

		update: (event)->
			Tool.Select.selectionRectangle[@constructor.updateMethod](event)
			super(event)
			return

		end: (event)->
			@args = Tool.Select.selectionRectangle[@constructor.endMethod](event)
			super(event)
			return

		do: ()->
			@apply(@constructor.method, @args)
			super()
			return

		undo: ()->
			@apply(@constructor.method, @negate(@args))
			super()
			return

		negate: (args)->
			args[0].multiply(-1)
			return args

		commandChanged: ()->
			delta = args[0]
			return delta.x != 0 and delta.y != 0

	class Command.Scale extends Command.SelectionRectangle

		@initialize('scale')

	class Command.Rotation extends Command.SelectionRectangle

		@initialize('rotate')

		negate: (args)->
			args[0] *= -1
			return args

		commandChanged: ()->
			return args[0] != 0

	class Command.Translate extends Command.SelectionRectangle

		@initialize('translate')

	class Command.BeforeAfter extends Command.Deferred

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
			@apply(@constructor.updateMethod, arguments)
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

	class Command.ModifyPoint extends Command

		@initialize('modifiyPoint', 'Modify point')

		getState: ()->
			segment = @item.selectionState.segment
			return [segment.point.clone(), segment.handleIn.clone(), segment.handleOut.clone()]


	class Command.ModifySpeed extends Command

		@disablePositionCheck = true

		@initialize('modifiySpeed', 'Modify speed')

		getState: ()->
			return [@item.speeds.slice()]

		commandChanged: ()->
			return true

	class Command.SetParameter extends Command

		@initialize('modifiyParameter')

		constructor: (item, controller)->
			controller.listen(@)
			@name = controller.name
			super('Change item parameter "' + @name + '"', item)
			return

		getState: ()->
			return [@name, @item.data[@name]]


		# constructor: (@item, args)->
		# 	@controller = args[0]
		# 	@previousValue = @item.data[@controller.name]
		# 	super('Change item parameter "' + @controller.name + '"')
		# 	return

		# do: ()->
		# 	@item.setParameter(@controller, @value, true)
		# 	super()
		# 	return

		# undo: ()->
		# 	@item.setParameter(@controller, @previousValue, true)
		# 	super()
		# 	return

		# update: (controller, value)->
		# 	@item.setParameter(controller, value)
		# 	return

		# end: (valid)->
		# 	@value = @item.data[@controller.name]
		# 	if @value == @previousValue then return false
		# 	if not valid then return
		# 	@item.update(@controller.name)
		# 	super()
		# 	return true

	# ---- # # ---- # # ---- # # ---- #
	# ---- # # ---- # # ---- # # ---- #
	# ---- # # ---- # # ---- # # ---- #
	# ---- # # ---- # # ---- # # ---- #

	class Command.AddPoint extends Command.Item

		constructor: (item, @location, name=null)->
			super(if not name? then 'Add point on item' else name, [item])
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

	class Command.DeletePoint extends Command.AddPoint

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

	class Command.ModifyPointType extends Command.Item

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
			@item.changeSegment(@segment, @previousPosition, @previousHandleIn, @previousHandleOut)
			super()
			return

	### --- Custom command for all kinds of command which modifiy the path --- ###

	class Command.ModifyControlPath extends Command.Item

		constructor: (item, @previousPointsAndPlanet, @newPointsAndPlanet)->
			super('Modify path', [item])
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

	class Command.MoveView extends Command
		constructor: (@previousPosition, @newPosition)->
			super("Move view")
			@superDo()
			# if not @previousPosition? or not @newPosition?
			# 	debugger
			return

		updateCommandItems: ()=>
			console.log "updateCommandItems"
			document.removeEventListener('command executed', @updateCommandItems)
			for command in R.commandManager.history
				if command.item?
					if not command.item.group? and R.items[command.item.pk or command.item.id]
						command.item = R.items[command.item.pk or command.item.id]
				if command.items?
					for item, i in command.items
						if not item.group? and R.items[item.pk or item.id]
							command.items[i] = R.items[item.pk or item.id]
			return

		do: ()->
			somethingToLoad = View.moveBy(@newPosition.subtract(@previousPosition), false)
			if somethingToLoad then document.addEventListener('command executed', @updateCommandItems)
			super()
			return somethingToLoad

		undo: ()->
			somethingToLoad = View.moveBy(@previousPosition.subtract(@newPosition), false)
			if somethingToLoad then document.addEventListener('command executed', @updateCommandItems)
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

	class Command.Select extends Command
		constructor: (items, name)->
			@items = @mapItems(items)
			super(name or "Select items")
			return

		selectItems: ()->
			for pk, item of @items
				item.select()
			R.controllerManager.updateParametersForSelectedItems()
			return

		deselectItems: ()->
			for pk, item of @items
				item.deselect()
			R.controllerManager.updateParametersForSelectedItems()
			return

		do: ()->
			@selectItems()
			super()
			return

		undo: ()->
			@deselectItems()
			super()
			return

	class Command.Deselect extends Command.Select

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

	class Command.CreateItem extends Command.Item

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

	class Command.DeleteItem extends Command.CreateItem
		constructor: (item)-> super(item, 'Delete item')

		do: ()->
			@deleteItem()
			@superDo()
			return

		undo: ()->
			@duplicateItem()
			@superUndo()
			return

	class Command.DuplicateItem extends Command.CreateItem
		constructor: (item)->
			@duplicateData = item.getDuplicateData()
			super(item, 'Duplicate item')

	class Command.ModifyText extends Command.Item

		constructor: (item, args)->
			super("Change text", item)
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

		end: (valid)->
			if @newText == @previousText then return false
			if not valid then return false
			@item.update('text')
			super()
			return true

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
	# 		return RMedia.prototype.isPrototypeOf(@item) 	# deferred if item is an RMedia

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
	# 		return RMedia.prototype.isPrototypeOf(@item) 	# deferred if item is an RMedia

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

	class CommandManager
		@maxCommandNumber = 20

		constructor: ()->
			@history = []
			@itemToCommands = {}
			@currentCommand = -1
			@historyJ = $("#History ul.history")
			return

		add: (command, execute=false)->
			if @currentCommand >= @constructor.maxCommandNumber - 1
				firstCommand = @history.shift()
				firstCommand.delete()
				@currentCommand--
			currentLiJ = @history[@currentCommand]?.liJ
			currentLiJ?.nextAll().remove()
			@historyJ.append(command.liJ)
			$("#History .mCustomScrollbar").mCustomScrollbar("scrollTo","bottom")
			@currentCommand++
			@history.splice(@currentCommand, @history.length-@currentCommand, command)

			@mapItemsToCommand(command)

			if execute then command.do()
			return

		toggleCurrentCommand: ()=>

			console.log "toggleCurrentCommand"
			$('#loadingMask').css('visibility': 'hidden')
			document.removeEventListener('command executed', @toggleCurrentCommand)

			if @currentCommand == @commandIndex then return

			deferred = @history[@currentCommand+@offset].toggle()
			@currentCommand += @direction

			if deferred
				$('#loadingMask').css('visibility': 'visible')
				document.addEventListener('command executed', @toggleCurrentCommand)
			else
				@toggleCurrentCommand()

			return

		commandClicked: (command)->
			@commandIndex = @getCommandIndex(command)

			if @currentCommand == @commandIndex then return

			if @currentCommand > @commandIndex
				@direction = -1
				@offset = 0
			else
				@direction = 1
				@offset = 1

			@toggleCurrentCommand()
			return

		getCommandIndex: (command)->
			for c, i in @history
				if c == command then return i
			return -1

		getCurrentCommand: ()->
			return @history[@currentCommand]


		clearHistory: ()->
			@historyJ.empty()
			@history = []
			@currentCommand = -1
			@add(new R.Command("Load Romanesco"), true)
			return

		# manage actions

		beginAction: (command, event)->
			if @currentCommand
				@endAction()
				clearTimeout(R.updateTimeout['addCurrentCommand-' + @currentCommand.id])
			@currentCommand = command
			@currentCommand.begin(event)
			return

		updateAction: (event)->
			@currentCommand.update(event)
			return

		endAction: (event)=>
			@currentCommand.end(event)
			@currentCommand = null
			return

		deferredAction: (ActionCommand, items, args...)->
			if not ActionCommand.prototype.isPrototypeOf(@currentCommand)
				@beginAction(new ActionCommand(items, args))
			@updateAction.apply(args)
			Utils.deferredExecution(@endAction, 'addCurrentCommand-' + @currentCommand.id )
			return

		# manage items

		mapItemsToCommand: (command)->
			for item in command.items
				@itemToCommands[item.getPk()] ?= []
				@itemToCommands[item.getPk()].push(command)
			return

		setItemPk: (id, pk)->
			@itemToCommands[pk] = @itemToCommands[id]
			delete @itemToCommands[id]
			return

		unloadItem: (item)->
			commands = @itemToCommands[item.getPk()]
			if commands?
				for command in commands
					command.unloadItem(item)
			return

		loadItem: (item)->
			commands = @itemToCommands[item.getPk()]
			if commands?
				for command in commands
					command.loadItem(item)
			return

		resurrectItem: (pk, item)->
			commands = @itemToCommands[pk]
			if commands?
				for command in commands
					command.resurrectItem(pk, item)
			return

	return CommandManager