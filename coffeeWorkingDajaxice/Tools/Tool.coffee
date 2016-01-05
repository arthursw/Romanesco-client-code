define [ 'UI/Button' ], (Button) ->

	# An RTool can be selected from the sidebar, or with special shortcuts.
	# once selected, a tool will usually react to user events (mouse and keyboard events)

	# Here are all types of tools:
	# - MoveTool to scroll the view in the project space
	# - SelectTool to select RItems
	# - TextTool to add Text (editable text box)
	# - MediaTool to add Media (can be an image, video, shadertoy, or anything embeddable)
	# - LockTool to add Lock (a locked area)
	# - CodeTool to open code editor and create a script
	# - ScreenshotTool to take a screenshot
	# - CarTool to have a car and travel in the world with arrow key (and play video games)
	# - PathTool the mother class of all drawing tools

	# The mother class of all RTools
	class Tool

		@label = @name
		@description = null
		@iconURL = null
		@favorite = true
		@category = null
		@cursor =
			position:
				x: 0, y:0
			name: 'default'
		@drawItems = false


		# parameters must return an object listing all parameters specific to the tool
		# those parameters will be accessible to the users from the options bar
		###
		parameters =
			'First folder':
				firstParameter:
					type: 'slider' 									# type is only required when adding a color (then it must be 'color') or a string input (then it must be 'string')
																	# if type is 'string' and there is no onChange nor onFinishChange callback:
																	# the default onChange callback will be called on onFinishChange since we often want to update only when the change is finished
																	# to override this behaviour, define both onChange and onFinishChange methods
					label: 'Name of the parameter'					# label of the controller (name displayed in the gui)
					default: 0 										# default value
					step: 5 										# values will be incremented/decremented by step
					min: 0 											# minimum value
					max: 100 										# maximum value
					simplified: 0 									# value during the simplified mode (useful to quickly draw an RPath, for example when modifying a curve)
					defaultFunction: () -> 							# called to get a default value
					onChange: (value)->  							# called when controller changes
					onFinishChange: (value)-> 						# called when controller finishes change
					setValue: (value)-> 							# called on set value of controller
					defaultCheck: true 								# checked/activated by default or not
					initializeController: (controller)->			# called just after controller is added to dat.gui, enables to customize the gui and add functionalities
				secondParameter:
					type: 'slider'
					label: 'Second parameter'
					value: 1
					min: 0
					max: 10
			'Second folder':
				thirdParameter:
					type: 'slider'
					label: 'Third parameter'
					value: 1
					min: 0
					max: 10
		###
		# to be overloaded by children classes, must return the parameters to display when the tool is selected
		@initializeParameters: ()->
			return {}

		@parameters = @initializeParameters()

		# RTool constructor:
		# - add a click handler to select the tool and extract the cursor name from the attribute 'data-cursor'
		# - initialize the popover (help tooltip)
		constructor: (createButton) ->
			if createButton then @createButton()
			@name = @constructor.label
			return

		createButton: ()->

			@btn = new Button(
				name: @constructor.label
				iconURL: @constructor.iconURL
				favorite: @constructor.favorite
				category: @constructor.category
				description: @constructor.description
				popover: true
				order: @constructor.order
			)

			@btn.btnJ.click( @select )

			return

		# Select the tool:
		# - deselect selected tool
		# - deselect all RItems (if deselectItems)
		# - update cursor
		# - update parameters
		# @param [RTool constructor] the constructor used to update gui parameters (@constructor.parameters)
		# @param [Item] selected item to update gui parameters
		# @param [Boolean] deselected selected items (false when selecting MoveTool or SelectTool)
		select: (deselectItems=true, updateParameters=true)=>
			if R.selectedTool == @ then return

			R.previousTool = R.selectedTool
			R.selectedTool?.deselect()
			R.selectedTool = @

			@updateCursor()

			if deselectItems
				R.tools.select.deselectAll()

			if updateParameters
				@updateParameters()
			return

		updateParameters: ()->
			R.controllerManager.setSelectedTool(@constructor)
			return

		updateCursor: ()->
			if @constructor.cursor.icon?
				R.stageJ.css('cursor', 'url(' + location.origin + '/static/images/cursors/'+@constructor.cursor.icon+'.png) '+@constructor.cursor.position.x+' '+@constructor.cursor.position.y+','+@constructor.cursor.name)
			else
				R.stageJ.css('cursor', @constructor.cursor.name)
			return

		# Deselect current tool
		deselect: ()->
			return

		# Begin tool action (usually called on mouse down event)
		begin: (event) ->
			return

		# Update tool action (usually called on mouse drag event)
		update: (event) ->
			return

		# Move tool action (usually called on mouse move event)
		move: (event) ->
			return

		# End tool action (usually called on mouse up event)
		end: (event) ->
			return

		keyUp: (event)->
			return

		# @return [Boolean] whether snap should be disabled when this tool is  selected or not
		disableSnap: ()->
			return false

	R.Tools = {}
	R.tools = {}
	return Tool
