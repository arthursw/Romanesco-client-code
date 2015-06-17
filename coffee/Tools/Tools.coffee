define [
	'utils', 'zeroClipboard', 'Item/item', 'Item/lock', 'Item/div', 'Item/path', 'jquery', 'paper', 'bootstrap'
], (utils, ZeroClipboard) ->

	g = utils.g()

	# todo: replace update by drag

	# An RTool can be selected from the sidebar, or with special shortcuts.
	# once selected, a tool will usually react to user events (mouse and keyboard events)

	# Here are all types of tools:
	# - MoveTool to scroll the view in the project space
	# - SelectTool to select RItems
	# - TextTool to add RText (editable text box)
	# - MediaTool to add RMedia (can be an image, video, shadertoy, or anything embeddable)
	# - LockTool to add RLock (a locked area)
	# - CodeTool to open code editor and create a script
	# - ScreenshotTool to take a screenshot
	# - CarTool to have a car and travel in the world with arrow key (and play video games)
	# - PathTool the mother class of all drawing tools

	# The mother class of all RTools
	class RTool

		@rname = @name
		@description = null
		@iconURL = null
		@favorite = true
		@category = null
		@cursor =
			position:
				x: 0, y:0
			name: 'default'


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
			g.tools[@constructor.rname] = @
			if createButton then @createButton()
			return

		createButton: ()->
			@btn = new Sidebar.Button(@constructor.rname, @constructor.iconURL, @constructor.favorite, @constructor.category)

			# find or create the corresponding button in the sidebar
			# @btnJ ?= g.toolsJ.find('li[data-name="'+@name+'"]')

			@btn.btnJ.click( () => @select() )

			# initialize the popover (help tooltip)
			popoverOptions =
				placement: 'right'
				container: 'body'
				trigger: 'hover'
				delay:
					show: 500
					hide: 100

			if not @constructor.description?
				popoverOptions.content = @constructor.rname
			else
				popoverOptions.title = @constructor.rname
				popoverOptions.content = @constructor.description

			@btnJ.popover( popoverOptions )
			return

		# Select the tool:
		# - deselect selected tool
		# - deselect all RItems (if deselectItems)
		# - update cursor
		# - update parameters
		# @param [RTool constructor] the constructor used to update gui parameters (@constructor.parameters)
		# @param [RItem] selected item to update gui parameters
		# @param [Boolean] deselected selected items (false when selecting MoveTool or SelectTool)
		select: (deselectItems=true, updateParameters=true)->
			if g.selectedTool == @ then return

			g.previousTool = g.selectedTool
			g.selectedTool?.deselect()
			g.selectedTool = @

			@updateCursor()

			if deselectItems
				g.deselectAll()

			if updateParameters
				@updateParameters()
			return

		updateParameters: ()->
			g.controllerManager.setSelectedTool(@constructor)
			return

		updateCursor: ()->
			if @constructor.cursor.icon?
				g.stageJ.css('cursor', 'url(static/images/cursors/'+@constructor.cursor.icon+'.png) '+@cursor.position.x+' '+@constructor.cursor.position.y+','+@constructor.cursor.name)
			else
				g.stageJ.css('cursor', @constructor.cursor.name)
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

	g.RTool = RTool

	# CodeTool is just used as a button to open the code editor, the remaining code is in editor.coffee
	class CodeTool extends RTool

		constructor: ()->
			super("Script")
			return

		# show code editor on select
		select: (deselectItems=true, updateParameters=true)->
			super
			g.showEditor()
			return

	g.CodeTool = CodeTool

	## Init tools
	# - init jQuery elements related to the tools
	# - create all tools
	# - init tool typeahead (the algorithm to find the tools from a few letters in the search tool input)
	# - get custom tools from the database, and initialize them
	# - make the tools draggable between the 'favorite tools' and 'other tools' panels, and update g.typeaheadModuleEngine and g.favoriteTools accordingly
	g.initTools = () ->
		# $.getJSON 'https://api.github.com/users/RomanescoModules/repos', (json)->
		# 	for repo in json.repos
		# 		repo.
		# 	return

		# init jQuery elements related to the tools
		g.toolsJ = $(".tool-list")

		g.favoriteToolsJ = $("#FavoriteTools .tool-list")
		g.allToolsContainerJ = $("#AllTools")
		g.allToolsJ = g.allToolsContainerJ.find(".all-tool-list")

		# init g.favoriteTools to see where to put the tools (in the 'favorite tools' panel or in 'other tools')
		g.favoriteTools = []
		if localStorage?
			try
				g.favoriteTools = JSON.parse(localStorage.favorites)
			catch error
				console.log error

		defaultFavoriteTools = [g.PrecisePath, g.ThicknessPath, g.Meander, g.GeometricLines, g.RectangleShape, g.EllipseShape, g.StarShape, g.SpiralShape]

		while g.favoriteTools.length < 8
			g.pushIfAbsent(g.favoriteTools, defaultFavoriteTools.pop().rname)

		# create all tools
		g.tools = {}
		new g.MoveTool()
		new g.CarTool()
		new g.SelectTool()
		new g.CodeTool()
		# new LinkTool(RLink)
		new g.LockTool(g.RLock)
		new g.TextTool(g.RText)
		new g.MediaTool(g.RMedia)
		new g.ScreenshotTool()
		new g.GradientTool()

		# g.modules = {}
		# path tools
		for pathClass in g.pathClasses
			pathTool = new g.PathTool(pathClass)
			# g.modules[pathTool.name] = { name: pathTool.name, iconURL: pathTool.RPath.iconURL, source: pathTool.RPath.source, description: pathTool.RPath.description, owner: 'Romanesco', thumbnailURL: pathTool.RPath.thumbnailURL, accepted: true, coreModule: true, category: pathTool.RPath.category }

		# g.initializeModules()

		# # init tool typeahead
		# initToolTypeahead = ()->
		# 	toolValues = []
		# 	toolValues.push( value: $(tool).attr("data-name") ) for tool in g.allToolsJ.children()
		# 	g.typeaheadModuleEngine = new Bloodhound({
		# 		name: 'Tools',
		# 		local: toolValues,
		# 		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
		# 		queryTokenizer: Bloodhound.tokenizers.whitespace
		# 	})
		# 	promise = g.typeaheadModuleEngine.initialize()

		# 	g.searchToolInputJ = g.allToolsContainerJ.find("input.search-tool")
		# 	g.searchToolInputJ.keyup (event)->
		# 		query = g.searchToolInputJ.val()
		# 		if query == ""
		# 			g.allToolsJ.children().show()
		# 			return
		# 		g.allToolsJ.children().hide()
		# 		g.typeaheadModuleEngine.get( query, (suggestions)->
		# 			for suggestion in suggestions
		# 				console.log(suggestion)
		# 				g.allToolsJ.children("[data-name='" + suggestion.value + "']").show()
		# 		)
		# 		return
		# 	return

		# # get custom tools from the database, and initialize them
		# # ajaxPost '/getTools', {}, (result)->
		# Dajaxice.draw.getTools (result)->
		# 	scripts = JSON.parse(result.tools)

		# 	for script in scripts
		# 		g.runScript(script)

		# 	initToolTypeahead()
		# 	return

		# make the tools draggable between the 'favorite tools' and 'other tools' panels, and update g.typeaheadModuleEngine and g.favoriteTools accordingly


		# sortStart = (event, ui)->
		# 	$( "#sortable1, #sortable2" ).addClass("drag-over")
		# 	return

		# sortStop = (event, ui)->
		# 	$( "#sortable1, #sortable2" ).removeClass("drag-over")
		# 	if not localStorage? then return
		# 	names = []
		# 	for li in g.favoriteToolsJ.children()
		# 		names.push($(li).attr("data-name"))
		# 	localStorage.favorites = JSON.stringify(names)

		# 	toolValues = []
		# 	toolValues.push( value: $(tool).attr("data-name") ) for tool in g.allToolsJ.children()
		# 	g.typeaheadModuleEngine.clear()
		# 	g.typeaheadModuleEngine.add(toolValues)

		# 	return

		# sortableArgs =
		# 	connectWith: ".connectedSortable"
		# 	appendTo: g.sidebarJ
		# 	helper: "clone"
		# 	cancel: '.category'
		# 	start: sortStart
		# 	stop: sortStop
		# 	delay: 250
		# $( "#sortable1, #sortable2" ).sortable( sortableArgs ).disableSelection()

		g.tools['Move'].select() 		# select the move tool

		# ---  init Wacom tablet API --- #

		g.wacomPlugin = document.getElementById('wacomPlugin')
		if g.wacomPlugin?
			g.wacomPenAPI = wacomPlugin.penAPI
			g.wacomTouchAPI = wacomPlugin.touchAPI
			g.wacomPointerType = { 0: 'Mouse', 1: 'Pen', 2: 'Puck', 3: 'Eraser' }
		# # Wacom API documentation:

		# # penAPI properties:

		# penAPI.isWacom
		# penAPI.isEraser
		# penAPI.pressure
		# penAPI.posX
		# penAPI.posY
		# penAPI.sysX
		# penAPI.sysY
		# penAPI.tabX
		# penAPI.tabY
		# penAPI.rotationDeg
		# penAPI.rotationRad
		# penAPI.tiltX
		# penAPI.tiltY
		# penAPI.tangentialPressure
		# penAPI.version
		# penAPI.pointerType
		# penAPI.tabletModel

		# # add touchAPI event listeners (> IE 11)

		# touchAPI.addEventListener("TouchDataEvent", touchDataEventHandler)
		# touchAPI.addEventListener("TouchDeviceAttachEvent", touchDeviceAttachHandler)
		# touchAPI.addEventListener("TouchDeviceDetachEvent", touchDeviceDetachHandler)

		# # Open / close touch device connection

		# touchAPI.Close(touchDeviceID)
		# error = touchAPI.Open(touchDeviceID, passThrough) # passThrough == true: observe and pass touch data to system
		# if error != 0 then console.log "unable to establish connection to wacom plugin"

		# # touch device capacities:

		# deviceCapacities = touchAPI.TouchDeviceCapabilities(touchDeviceID)
		# deviceCapacities.Version
		# deviceCapacities.DeviceID
		# deviceCapacities.MaxFingers
		# deviceCapacities.ReportedSizeX
		# deviceCapacities.ReportedSizeY
		# deviceCapacities.PhysicalSizeX
		# deviceCapacities.PhysicalSizeY
		# deviceCapacities.LogicalOriginX
		# deviceCapacities.LogicalOriginY
		# deviceCapacities.LogicalWidth
		# deviceCapacities.LogicalHeight

		# # touch state helper map:
		# touchStates = [ 0: 'None', 1: 'Down', 2: 'Hold', 3: 'Up']
		# touchStates[touchState]

		# # Get touch data for as many fingers as supported
		# touchRawFingerData = touchAPI.TouchRawFingerData(touchDeviceID)

		# if touchRawFingerData.Status == -1 	# Bad data
		# 	return

		# touchRawFingerData.NumFingers

		# for finger in touchRawFingerData.FingerList
		# 	finger.FingerID
		# 	finger.PosX
		# 	finger.PosY
		# 	finger.Width
		# 	finger.Height
		# 	finger.Orientation
		# 	finger.Confidence
		# 	finger.Sensitivity
		# 	touchStates[finger.TouchState]

		return
	return