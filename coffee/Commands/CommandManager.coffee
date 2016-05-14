define [ 'Commands/Command' ], (Command) ->

	class CommandManager
		@maxCommandNumber = 20

		constructor: ()->
			@history = []
			@itemToCommands = {}
			@currentCommand = -1
			@historyJ = $("#History ul.history")
			@add(new Command('Loaded Romanesco'), true)
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
			@add(new Command("Load Romanesco"), true)
			return

		# manage actions

		beginAction: (command, event)->
			if @actionCommand?
				clearTimeout(R.updateTimeout['addCurrentCommand-' + @actionCommand.id])
				@endAction()
			@actionCommand = command
			@actionCommand.begin(event)
			return

		updateAction: ()->
			@actionCommand?.update.apply(@actionCommand, arguments)
			return

		endAction: (event)=>
			@actionCommand?.end(event)
			@actionCommand = null
			return

		deferredAction: (ActionCommand, items, event, args...)->
			if not ActionCommand.prototype.isPrototypeOf(@actionCommand)
				@beginAction(new ActionCommand(items, args), event)
			@updateAction.apply(@, args)
			Utils.deferredExecution(@endAction, 'addCurrentCommand-' + @actionCommand.id )
			return

		# manage items

		mapItemsToCommand: (command)->
			if not command.items? then return
			for pk, item of command.items
				@itemToCommands[pk] ?= []
				@itemToCommands[pk].push(command)
			return

		setItemPk: (id, pk)->
			commands = @itemToCommands[id]
			if commands?
				for command in commands
					command.setItemPk(id, pk)
			@itemToCommands[pk] = @itemToCommands[id]
			delete @itemToCommands[id]
			return

		unloadItem: (item)->
			commands = @itemToCommands[item.getPk()]
			if commands?
				for command in commands
					command.unloadItem(item)
			# do not delete @itemToCommands[item.getPk()], we will need it to resurect the item
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
					command.resurrectItem(item)
			@itemToCommands[item.getPk()] = commands
			delete @itemToCommands[pk]
			return

	return CommandManager
