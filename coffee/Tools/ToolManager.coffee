define [
	'Tools/Tool'
	'Tools/MoveTool'
	'Tools/SelectTool'
	'Tools/PathTool'
	'Tools/ItemTool'
	'Tools/LockTool'
	'Tools/MediaTool'
	'Tools/TextTool'
	'Tools/ScreenshotTool'
	'Tools/GradientTool'
], (Tool) ->

	class ToolManager

		constructor: ()->

			# init jQuery elements related to the tools
			R.toolsJ = $(".tool-list")

			R.favoriteToolsJ = $("#FavoriteTools .tool-list")
			R.allToolsContainerJ = $("#AllTools")
			R.allToolsJ = R.allToolsContainerJ.find(".all-tool-list")

			# init R.favoriteTools to see where to put the tools (in the 'favorite tools' panel or in 'other tools')
			R.favoriteTools = []
			if localStorage?
				try
					R.favoriteTools = JSON.parse(localStorage.favorites)
				catch error
					console.log error

			Tool.car = new Tool.Car()
			Tool.gradient = new Tool.Gradient()
			Tool.lock = new Tool.Lock()
			Tool.media = new Tool.Media()
			Tool.move = new Tool.Move()
			Tool.screenshot = new Tool.Screenshot()
			Tool.select = new Tool.Select()
			Tool.text = new Tool.Text()

			defaultFavoriteTools = [] # [R.PrecisePath, R.ThicknessPath, R.Meander, R.GeometricLines, R.RectangleShape, R.EllipseShape, R.StarShape, R.SpiralShape]

			while R.favoriteTools.length < 8 and defaultFavoriteTools.length > 0
				Utils.Array.pushIfAbsent(R.favoriteTools, defaultFavoriteTools.pop().label)

			# R.modules = {}
			# path tools
			# for pathClass in R.pathClasses
			# 	pathTool = new R.PathTool(pathClass)
				# R.modules[pathTool.name] = { name: pathTool.name, iconURL: pathTool.RPath.iconURL, source: pathTool.RPath.source, description: pathTool.RPath.description, owner: 'Romanesco', thumbnailURL: pathTool.RPath.thumbnailURL, accepted: true, coreModule: true, category: pathTool.RPath.category }

			# R.initializeModules()

			# # init tool typeahead
			# initToolTypeahead = ()->
			# 	toolValues = []
			# 	toolValues.push( value: $(tool).attr("data-name") ) for tool in R.allToolsJ.children()
			# 	R.typeaheadModuleEngine = new Bloodhound({
			# 		name: 'Tools',
			# 		local: toolValues,
			# 		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
			# 		queryTokenizer: Bloodhound.tokenizers.whitespace
			# 	})
			# 	promise = R.typeaheadModuleEngine.initialize()

			# 	R.searchToolInputJ = R.allToolsContainerJ.find("input.search-tool")
			# 	R.searchToolInputJ.keyup (event)->
			# 		query = R.searchToolInputJ.val()
			# 		if query == ""
			# 			R.allToolsJ.children().show()
			# 			return
			# 		R.allToolsJ.children().hide()
			# 		R.typeaheadModuleEngine.get( query, (suggestions)->
			# 			for suggestion in suggestions
			# 				console.log(suggestion)
			# 				R.allToolsJ.children("[data-name='" + suggestion.value + "']").show()
			# 		)
			# 		return
			# 	return

			# # get custom tools from the database, and initialize them
			# # ajaxPost '/getTools', {}, (result)->
			# Dajaxice.draw.getTools (result)->
			# 	scripts = JSON.parse(result.tools)

			# 	for script in scripts
			# 		R.runScript(script)

			# 	initToolTypeahead()
			# 	return

			# make the tools draggable between the 'favorite tools' and 'other tools' panels, and update R.typeaheadModuleEngine and R.favoriteTools accordingly


			# sortStart = (event, ui)->
			# 	$( "#sortable1, #sortable2" ).addClass("drag-over")
			# 	return

			# sortStop = (event, ui)->
			# 	$( "#sortable1, #sortable2" ).removeClass("drag-over")
			# 	if not localStorage? then return
			# 	names = []
			# 	for li in R.favoriteToolsJ.children()
			# 		names.push($(li).attr("data-name"))
			# 	localStorage.favorites = JSON.stringify(names)

			# 	toolValues = []
			# 	toolValues.push( value: $(tool).attr("data-name") ) for tool in R.allToolsJ.children()
			# 	R.typeaheadModuleEngine.clear()
			# 	R.typeaheadModuleEngine.add(toolValues)

			# 	return

			# sortableArgs =
			# 	connectWith: ".connectedSortable"
			# 	appendTo: R.sidebarJ
			# 	helper: "clone"
			# 	cancel: '.category'
			# 	start: sortStart
			# 	stop: sortStop
			# 	delay: 250
			# $( "#sortable1, #sortable2" ).sortable( sortableArgs ).disableSelection()

			Tool.move.select() 		# select the move tool

			# ---  init Wacom tablet API --- #

			R.wacomPlugin = document.getElementById('wacomPlugin')
			if R.wacomPlugin?
				R.wacomPenAPI = wacomPlugin.penAPI
				R.wacomTouchAPI = wacomPlugin.touchAPI
				R.wacomPointerType = { 0: 'Mouse', 1: 'Pen', 2: 'Puck', 3: 'Eraser' }
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


	# todo: replace update by drag


	# CodeTool is just used as a button to open the code editor, the remaining code is in editor.coffee
	# class CodeTool extends RTool

	# 	constructor: ()->
	# 		super("Script")
	# 		return

	# 	# show code editor on select
	# 	select: (deselectItems=true, updateParameters=true)->
	# 		super
	# 		R.showEditor()
	# 		return

	# R.CodeTool = CodeTool

	## Init tools
	# - init jQuery elements related to the tools
	# - create all tools
	# - init tool typeahead (the algorithm to find the tools from a few letters in the search tool input)
	# - get custom tools from the database, and initialize them
	# - make the tools draggable between the 'favorite tools' and 'other tools' panels, and update R.typeaheadModuleEngine and R.favoriteTools accordingly

	return ToolManager