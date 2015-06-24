define [
	'Tool' # and all tools
	'Path' # and all paths
	'Ajax'
	'Options'
	'Socket'
	'Command'
	'City'
	'Code'
	'Rasterizer'
	'Grid'
	'Sound'
	'Modal'
], () ->

	g = utils.g()
	R.rasterizerMode = window.rasterizerMode

	if R.rasterizerMode
		R.initializeRasterizerMode()

	# TODO: manage items and path in the same way (R.paths and R.items)? make an interface on top of path and div, and use events to update them
	# todo: add else case in switches
	# todo: bug when creating a small div (happened with text)
	# todo: snap div
	# todo: center modal vertically with an event system: http://codepen.io/dimbslmh/pen/mKfCc and http://stackoverflow.com/questions/18422223/bootstrap-3-modal-vertical-position-center

	# doctodo: look for "improve", "improvement", "deprecated", "to be updated" to see each time romanesco must be updated

	###
	# Romanesco documentation #

	Romanesco is an experiment about freedom, creativity and collaboration.

	tododoc
	tododoc: define RItems

	The source code is divided in files:
	 - [main.coffee](http://main.html) which is where the initialization
	 - [path.coffee](http://path.html)
	 - etc

	Notations:
	 - override means that the method extends functionnalities of the inherited method (super is called at some point)
	 - redefine means that it totally replace the method (super is never called)

	###


	## Init tools
	# - init jQuery elements related to the tools
	# - create all tools
	# - init tool typeahead (the algorithm to find the tools from a few letters in the search tool input)
	# - get custom tools from the database, and initialize them
	# - make the tools draggable between the 'favorite tools' and 'other tools' panels, and update R.typeaheadModuleEngine and R.favoriteTools accordingly
	initTools = () ->
		# $.getJSON 'https://api.github.com/users/RomanescoModules/repos', (json)->
		# 	for repo in json.repos
		# 		repo.
		# 	return

		# init jQuery elements related to the tools
		R.toolsJ = $(".tool-list")

		R.toolsJ.find("[data-name='Create']").click ()->
			submit = (data)->
				Dajaxice.draw.createCity(R.loadCityFromServer, name: data.name, public: data.public)
				return
			modal = R.RModal.createModal( title: 'Create city', submit: submit, postSubmit: 'load' )
			modal.addTextInput( label: "City name", name: 'name', required: true, submitShortcut: true, placeholder: 'Paris' )
			modal.addCheckbox( label: "Public", name: 'public', helpMessage: "Public cities will be accessible by anyone.", defaultValue: true )
			modal.show()
			return

		R.toolsJ.find("[data-name='Open']").click ()->
			modal = R.RModal.createModal( title: 'Open city', name: 'open-city' )
			modal.modalBodyJ.find('.modal-footer').hide()
			modal.addProgressBar()
			modal.show()
			Dajaxice.draw.loadCities(R.loadCities)
			return

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

		defaultFavoriteTools = [R.PrecisePath, R.ThicknessPath, R.Meander, R.GeometricLines, R.RectangleShape, R.EllipseShape, R.StarShape, R.SpiralShape]

		while R.favoriteTools.length < 8
			Utils.Array.pushIfAbsent(R.favoriteTools, defaultFavoriteTools.pop().label)

		# create all tools
		# R.tools = {}
		# new R.MoveTool()
		# new R.CarTool()
		# new R.SelectTool()
		# new R.CodeTool()
		# # new LinkTool(RLink)
		# new R.LockTool(Lock)
		# new R.TextTool(R.RText)
		# new R.MediaTool(R.RMedia)
		# new R.ScreenshotTool()
		# new R.GradientTool()

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

		R.tools['Move'].select() 		# select the move tool

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

	## Init position
	# initialize the view position according to the 'data-box' of the canvas (when loading a website or video game)
	# update R.entireArea and R.restrictedArea according to site settings
	# update sidebar according to site settings
	initPosition = ()->
		if R.rasterizerMode then return

		R.city =
			owner: R.canvasJ.attr("data-owner")
			city: R.canvasJ.attr("data-city")
			site: R.canvasJ.attr("data-site")

		# check if canvas has an attribute 'data-box'
		boxString = R.canvasJ.attr("data-box")

		if not boxString or boxString.length==0
			window.onhashchange()
			return

		# initialize the area rectangle *boxRectangle* from 'data-box' attr and move to the center of the box
		box = JSON.parse( boxString )

		planet = new P.Point(box.planetX, box.planetY)

		tl = R.posOnPlanetToProject(box.box.coordinates[0][0], planet)
		br = R.posOnPlanetToProject(box.box.coordinates[0][2], planet)

		boxRectangle = new P.Rectangle(tl, br)
		pos = boxRectangle.center

		View.moveTo(pos)

		# load the entire area if 'data-load-entire-area' is set to true, and set R.entireArea
		loadEntireArea = R.canvasJ.attr("data-load-entire-area")

		if loadEntireArea
			R.entireArea = boxRectangle
			R.load(boxRectangle)

		# boxData = if box.data? and box.data.length>0 then JSON.parse(box.data) else null
		# console.log boxData

		# init R.restrictedArea
		siteString = R.canvasJ.attr("data-site")
		site = JSON.parse( siteString )
		if site.restrictedArea
			R.restrictedArea = boxRectangle

		R.tools['Select'].select() 		# select 'Select' tool by default when loading a website
										# since a click on an RLock will activate the drag (temporarily select the 'Move' tool)
										# and the user must be able to select text

		# update sidebar according to site settings
		if site.disableToolbar
			# just hide the sidebar
			R.sidebarJ.hide()
		else
			# remove all panels except the chat
			R.sidebarJ.find("div.panel.panel-default:not(:last)").hide()

			# remove all controllers and folder except zoom in General.
			for folderName, folder of R.gui.__folders
				for controller in folder.__controllers
					if controller.name != 'Zoom'
						folder.remove(controller)
						folder.__controllers.remove(controller)
				if folder.__controllers.length==0
					R.gui.removeFolder(folderName)

			R.sidebarHandleJ.click()

		return



	# initialize Romanesco
	# all global variables and functions are stored in *g* which is a synonym of *window*
	# all jQuery elements names end with a capital J: elementNameJ
	init = ()->
		# R.romanescoURL = 'http://romanesc.co/'

		R.romanescoURL = 'http://localhost:8000/'
		R.stageJ = $("#stage")
		R.sidebarJ = $("#sidebar")
		R.canvasJ = R.stageJ.find("#canvas")
		R.canvas = R.canvasJ[0]
		R.canvas.width = window.innerWidth
		R.canvas.height = window.innerHeight
		R.context = R.canvas.getContext('2d')

		# R.selectionCanvasJ = R.stageJ.find("#selection-canvas")
		# R.selectionCanvas = R.selectionCanvasJ[0]
		# R.selectionCanvas.width = window.innerWidth
		# R.selectionCanvas.height = window.innerHeight

		# R.backgroundCanvasJ = R.stageJ.find("#background-canvas")
		# R.backgroundCanvas = R.backgroundCanvasJ[0]
		# R.backgroundCanvas.width = window.innerWidth
		# R.backgroundCanvas.height = window.innerHeight
		# R.backgroundCanvasJ.width(window.innerWidth)
		# R.backgroundCanvasJ.height(window.innerHeight)
		# R.backgroundContext = R.backgroundCanvas.getContext('2d')

		R.me = null 							# R.me is the username of the user (sent by the server in each ajax "load")
		R.selectionLayer = null					# paper layer containing all selected paper items
		R.updateTimeout = {} 					# map of id -> timeout id to clear the timeouts
		R.requestedCallbacks = {} 				# map of id -> request id to clear the requestAnimationFrame
		R.restrictedArea = null 				# area in which the user position will be constrained (in a website with restrictedArea == true)
		R.OSName = "Unknown OS" 				# user's operating system
		R.currentPaths = {} 					# map of username -> path id corresponding to the paths currently being created
		R.loadingBarTimeout = null 				# timeout id of the loading bar
		R.entireArea = null 					# entire area to be kept loaded, it is a paper P.Rectangle
		R.entireAreas = [] 						# array of RDivs which have data.loadEntireArea==true
		R.loadedAreas = [] 						# array of areas { pos: pos, planet: planet } which are loaded
												# (to test if areas have to be loaded or unloaded)
		R.paths = new Object() 					# a map of RPath.pk (or RPath.id) -> RPath. RPath are first added with their id, and then with their pk
												# (as soon as server saved it and responds)
		R.items = new Object() 					# map RItem.id or RItem.pk -> RItem, all loaded RItems. The key is RItem.id before RItem is saved
												# in the database, and RItem.pk after
		R.locks = [] 							# array of loaded RLocks
		R.divs = [] 							# array of loaded RDivs
		R.sortedPaths = []						# an array where paths are sorted by index (z-index)
		R.sortedDivs = []						# an array where divs are sorted by index (z-index)
		R.animatedItems = [] 					# an array of animated items to be updated each frame
		R.cars = {} 							# a map of username -> cars which will be updated each frame
		# R.fastMode = false 						# fastMode will hide all items except the one being edited (when user edits an item)
		# R.fastModeOn = false					# fastModeOn is true when the user is edditing an item
		R.alerts = null 						# An array of alerts ({ type: type, message: message }) containing all alerts info.
												# It is append to the alert box in showAlert().
		R.scale = 1000.0 						# the scale to go from project coordinates to planet coordinates
		R.previousPoint = null 					# the previous mouse event point
		R.draggingEditor = false 				# boolean, true when user is dragging the code editor
		# R.rasters = {}							# map to store rasters (tiles, rasterized version of the view)
		R.areasToUpdate = {} 					# map of areas to update { pk->rectangle }
												# (areas which are not rasterize on the server, that we must send if we can rasterize them)
		R.rastersToUpload = [] 					# an array of { data: dataURL, position: position } containing the rasters to upload on the server
		R.areasToRasterize = [] 				# an array of P.Rectangle to rasterize
		R.isUpdatingRasters = false 			# true if we are updating rasters (in loopUpdateRasters)
		R.viewUpdated = false 					# true if the view was updated ( rasters removed and items drawn in R.updateView() )
												# and we don't need to update anymore (until new Rasters are added in load_callback)
		R.currentDiv = null 					# the div currently being edited (dragged, moved or resized) used to also send jQuery mouse event to divs
		R.areasToUpdateRectangles = {} 			# debug map: area to update pk -> rectangle path
		R.catchErrors = false 					# the error will not be caught when drawing an RPath (let chrome catch them at the right time)
		R.previousMousePosition = null 			# the previous position of the mouse in the mousedown/move/up
		R.initialMousePosition = null 			# the initial position of the mouse in the mousedown/move/up
		R.previousViewPosition = null			# the previous view position
		R.backgroundRectangle = null 			# the rectangle to highlight the stage when dragging an RContent over it
		R.limitPathV = null 					# the vertical limit path (line between two planets)
		R.limitPathH = null 					# the horizontal limit path (line between two planets)
		R.selectedItems = [] 					# the selectedItems
		R.ignoreSockets = false 				# whether sockets messages are ignored
		R.mousePosition = new P.Point() 			# the mouse position in window coordinates (updated everytime the mouse moves)
												# used to get mouse position on a key event
		R.hiddenDivs = []

		# initialize sort

		R.itemListsJ = $("#RItems .layers")
		R.pathList = R.itemListsJ.find(".rPath-list")
		R.pathList.sortable( stop: Item.zIndexSortStop, delay: 250 )
		R.pathList.disableSelection()
		R.divList = R.itemListsJ.find(".rDiv-list")
		R.divList.sortable( stop: Item.zIndexSortStop, delay: 250 )
		R.divList.disableSelection()
		R.itemListsJ.find('.title').click (event)->
			$(this).parent().toggleClass('closed')
			return

		R.commandManager = new R.CommandManager()
		R.loader = new Loader()
		# R.globalMaskJ = $("#globalMask")
		# R.globalMaskJ.hide()

		# Display a R.alertManager.alert message when a dajaxice error happens (problem on the server)
		Dajaxice.setup( 'default_exception_callback': (error)->
			console.log 'Dajaxice error!'
			R.alertManager.alert "Connection error", "error"
			return
		)

		# init R.OSName (user's operating system)
		if navigator.appVersion.indexOf("Win")!=-1 then R.OSName = "Windows"
		if navigator.appVersion.indexOf("Mac")!=-1 then R.OSName = "MacOS"
		if navigator.appVersion.indexOf("X11")!=-1 then R.OSName = "UNIX"
		if navigator.appVersion.indexOf("Linux")!=-1 then R.OSName = "Linux"

		# init paper.js
		# paper.setup(R.selectionCanvas)
		# R.selectionProject = project

		paper.setup(R.canvas)
		R.project = project

		R.mainLayer = P.project.activeLayer
		R.mainLayer.name = 'main layer'
		R.debugLayer = new P.Layer()				# Paper layer to append debug items
		R.debugLayer.name = 'debug layer'
		R.carLayer = new P.Layer() 				# Paper layer to append all cars
		R.carLayer.name = 'car layer'
		R.lockLayer = new P.Layer()	 			# Paper layer to keep all locked items
		R.lockLayer.name = 'lock layer'
		R.selectionLayer = new P.Layer() 			# Paper layer to keep all selected items
		# R.selectionLayer = R.selectionProject.activeLayer
		R.selectionLayer.name = 'selection layer'
		R.areasToUpdateLayer = new P.Layer() 		# Paper layer to show areas to update
		R.areasToUpdateLayer.name = 'areasToUpdateLayer'
		R.areasToUpdateLayer.visible = false
		R.mainLayer.activate()
		paper.settings.hitTolerance = 5
		R.grid = new P.Group() 					# Paper P.Group to append all grid items
		R.grid.name = 'grid group'
		P.view.zoom = 1 # 0.01
		R.previousViewPosition = P.view.center




		# initialize sidebar handle
		R.sidebarHandleJ = R.sidebarJ.find(".sidebar-handle")
		R.sidebarHandleJ.click ()->
			R.toggleSidebar()
			return

		# R.sound = new R.RSound(['/static/sounds/space_ship_engine.mp3', '/static/sounds/space_ship_engine.ogg'])
		R.sound = new R.RSound(['/static/sounds/viper.ogg']) 			# load car sound

		# R.sound = new Howl(
		# 	urls: ['/static/sounds/viper.ogg']
		# 	onload: ()->
		# 		console.log("sound loaded")
		# 		XMLHttpRequest = R.DajaxiceXMLHttpRequest
		# 		return
		# 	volume: 0.25
		# 	buffer: true
		# 	sprite:
		# 		loop: [2000, 3000, true]
		# )

		# R.sound.plays = (spriteName)->
		# 	return R.sound.spriteName == spriteName # and R.sound.pos()>0

		# R.sound.playAt = (spriteName, time)->
		# 	if time < 0 or time > 1.0 then return
		# 	sprite = R.sound.sprite()[spriteName]
		# 	begin = sprite[0]
		# 	duration = sprite[1]
		# 	looped = sprite[2]
		# 	R.sound.stop()
		# 	R.sound.spriteName = spriteName
		# 	R.sound.play(spriteName)
		# 	R.sound.pos(time*duration/1000)
		# 	callback = ()->
		# 		R.sound.stop()
		# 		if looped then R.sound.play(spriteName)
		# 		return
		# 	clearTimeout(R.sound.rTimeout)
		# 	R.sound.rTimeout = setTimeout(callback, duration-time*duration)
		# 	return false

		# R.sidebarJ.find("#buyRomanescoins").click ()->
		# 	R.templatesJ.find('#romanescoinModal').modal('show')
		# 	paypalFormJ = R.templatesJ.find("#paypalForm")
		# 	paypalFormJ.find("input[name='submit']").click( ()->
		# 		data =
		# 			user: R.me
		# 			location: { x: P.view.center.x, y: P.view.center.y }
		# 		paypalFormJ.find("input[name='custom']").attr("value", JSON.stringify(data) )
		# 	)

		# load path source code

		# xmlhttp = new RXMLHttpRequest()
		# url = R.romanescoURL + "static/romanesco-client-code/coffee/Item/path.coffee"

		# xmlhttp.onreadystatechange = ()->
		# 	if xmlhttp.readyState == 4 and xmlhttp.status == 200
		# 		sources = xmlhttp.responseText

		# 		lines = sources.split(/\n/)
		# 		expressions = CoffeeScript.nodes(sources).expressions

		# 		classMap = {}
		# 		for pathClass in R.pathClasses
		# 			classMap[pathClass.name] = pathClass

		# 		classExpressions = expressions[0].args[1].body.expressions
		# 		for expression in classExpressions
		# 			className = expression.variable?.base?.value
		# 			if className? and classMap[className]? and expression.locationData?
		# 				start = expression.locationData.first_line
		# 				end = expression.locationData.last_line-1
		# 				# remove tab:
		# 				for i in [start .. end]
		# 					lines[i] = lines[i].substring(1)
		# 				source = lines[start .. end].join("\n")
		# 				# automatically create new PathTool
		# 				source += "\ntool = new R.PathTool(#{className}, true)"
		# 				pathClass = classMap[className]
		# 				pathClass.source = source
		# 				R.modules[pathClass.label]?.source = source
		# 	return

		# xmlhttp.open("GET", url, true)
		# xmlhttp.send()

		# not working, because of dajaxice
		# $.ajax( url: R.romanescoURL + "static/coffee/path.coffee", cache: false )
		# .done (data)->
		# 	console.log "done"
		# 	lines = data.split(/\n/)
		# 	expressions = CoffeeScript.nodes(data).expressions

		# 	classMap = {}
		# 	for pathClass in R.pathClasses
		# 		classMap[pathClass.name] = pathClass

		# 	for expression in expressions
		# 		source = lines[expression.locationData.first_line .. expression.locationData.last_line].join("\n")
		# 		classMap[expression.variable.base.value]?.source = source

		# 	return
		# .success (data)->
		# 	console.log "success"
		# 	return
		# .fail (data)->
		# 	console.log "fail"
		# 	return
		# .error (data)->
		# 	console.log "error"
		# 	return
		# .always (data)->
		# 	console.log "always"
		# 	return

		R.initializeRasterizers()
		# R.initializeGlobalParameters()

		if not R.rasterizerMode
			R.initParameters()
			R.initSocket()
			initTools()
			$(".mCustomScrollbar").mCustomScrollbar( keyboard: false )
		else
			R.initToolsRasterizer()

		initPosition()

		# initLoadingBar()
		Grid.updateGrid()

		window.setPageFullyLoaded?(true)
		return

	# Initialize Romanesco and handlers
	$(document).ready () ->

		R.alertManager = new AlertManager()

		init()

		if R.rasterizerMode then return

		## mouse and key listeners

		R.canvasJ.dblclick( (event) -> R.selectedTool.doubleClick?(event) )
		# cancel default delete key behaviour (not really working)
		R.canvasJ.keydown( (event) -> if event.key == 46 then event.preventDefault(); return false )

		R.tool = new P.Tool()

		focusIsOnCanvas = ()->
			return $(document.activeElement).is("body")
			# activeElementIsOnSidebar = $(document.activeElement).parents(".sidebar").length>0
			# activeElementIsTextarea = $(document.activeElement).is("textarea")
			# activeElementIsOnParameterBar = $(document.activeElement).parents(".dat-gui").length
			# return not activeElementIsOnSidebar and not activeElementIsTextarea and not activeElementIsOnParameterBar

		# Paper listeners
		R.tool.onMouseDown = (event) ->

			if R.wacomPenAPI?.isEraser
				R.tool.onKeyUp( key: 'delete' )
				return
			$(document.activeElement).blur() # prevent to keep focus on the chat when we interact with the canvas
			# event = Utils.Event.snap(event) 		# snapping mouseDown event causes some problems
			R.selectedTool.begin(event)
			return

		R.tool.onMouseDrag = (event) ->
			if R.wacomPenAPI?.isEraser then return
			if R.currentDiv? then return
			# event = Utils.Event.snap(event)
			R.selectedTool.update(event)
			return

		# R.tool.onMouseMove = (event) ->
		# 	if R.selectedTool.name == 'Select'
		# 		event.item?.controller?.highlight()
		# 	return

		R.tool.onMouseUp = (event) ->
			if R.wacomPenAPI?.isEraser then return
			if R.currentDiv? then return
			# event = Utils.Event.snap(event)
			R.selectedTool.end(event)
			return

		R.tool.onKeyDown = (event) ->

			# if the focus is on anything in the sidebar or is a textarea or in parameters bar: ignore the event
			if not focusIsOnCanvas() then return

			if event.key == 'delete' 									# prevent default delete behaviour (not working)
				event.preventDefault()
				return false

			# select 'Move' tool when user press space key (and reselect previous tool after)
			if event.key == 'space' and R.selectedTool.name != 'Move'
				R.tools['Move'].select()

			return

		R.tool.onKeyUp = (event) ->
			# if the focus is on anything in the sidebar or is a textarea or in parameters bar: ignore the event
			if not focusIsOnCanvas() then return

			R.selectedTool.keyUp(event)

			switch event.key
				when 'space'
					R.previousTool?.select()
				when 'v'
					R.tools['Select'].select()
				when 't'
					R.showToolBox()
				when 'r'
					# if R.specialKey(event) # Ctrl + R is already used to reload the page
					if event.modifiers.shift
						R.rasterizer.rasterizeImmediately()

			event.preventDefault()
			return

		# on frame event:
		# - update animatedItems
		# - update cars positions
		P.P.view.onFrame = (event)->
			TWEEN.update(event.time)

			R.rasterizer.updateLoadingBar?(event.time)

			R.selectedTool.onFrame?(event)

			for item in R.animatedItems
				item.onFrame(event)

			for username, car of R.cars
				direction = new P.Point(1,0)
				direction.angle = car.rotation-90
				car.position = car.position.add(direction.multiply(car.speed))
				if Date.now() - car.rLastUpdate > 1000
					R.cars[username].remove()
					delete R.cars[username]

			return

		# update grid and mCustomScrollbar when window is resized
		$(window).resize (event) ->
			# R.backgroundCanvas.width = window.innerWidth
			# R.backgroundCanvas.height = window.innerHeight
			# R.backgroundCanvasJ.width(window.innerWidth)
			# R.backgroundCanvasJ.height(window.innerHeight)
			Grid.updateGrid()
			$(".mCustomScrollbar").mCustomScrollbar("update")
			P.view.update()

			R.canvasJ.width(window.innerWidth)
			R.canvasJ.height(window.innerHeight)
			P.view.viewSize = new P.Size(window.innerWidth, window.innerHeight)

			# R.selectionCanvasJ.width(window.innerWidth)
			# R.selectionCanvasJ.height(window.innerHeight)
			# R.selectionProject.P.view.viewSize = new P.Size(window.innerWidth, window.innerHeight)
			return

		# mousedown event listener
		mousedown = (event) ->

			switch event.which						# switch on mouse button number (left, middle or right click)
				when 2
					R.tools['Move'].select()		# select move tool if middle mouse button
				when 3
					R.selectedTool.finish?() 	# finish current path (in polygon mode) if right click

			if R.selectedTool.name == 'Move' 		# update 'Move' tool if it is the one selected, and return
				# R.initialMousePosition = new P.Point(event.pageX, event.pageY)
				# R.previousMousePosition = R.initialMousePosition.clone()
				# R.selectedTool.begin()
				R.selectedTool.beginNative(event)
				return

			R.initialMousePosition = R.jEventToPoint(event)
			R.previousMousePosition = R.initialMousePosition.clone()

			return

		# mousemove event listener
		mousemove = (event) ->
			R.mousePosition.x = event.pageX
			R.mousePosition.y = event.pageY

			if R.selectedTool.name == 'Move' and R.selectedTool.dragging
				# mousePosition = new P.Point(event.pageX, event.pageY)
				# simpleEvent = delta: R.previousMousePosition.subtract(mousePosition)
				# R.previousMousePosition = mousePosition
				# console.log simpleEvent.delta.toString()
				# R.selectedTool.update(simpleEvent) 	# update 'Move' tool if it is the one selected
				R.selectedTool.updateNative(event)
				return

			R.RDiv.updateHiddenDivs(event)

			# update selected RDivs
			# if R.previousPoint?
			# 	event.delta = new P.Point(event.pageX-R.previousPoint.x, event.pageY-R.previousPoint.y)
			# 	R.previousPoint = new P.Point(event.pageX, event.pageY)

			# 	for item in R.selectedItems
			# 		item.updateSelect?(event)

			# update code editor width
			R.codeEditor?.onMouseMove(event)

			if R.currentDiv?
				paperEvent = Utils.Event.jEventToPaperEvent(event, R.previousMousePosition, R.initialMousePosition, 'mousemove')
				R.currentDiv.updateSelect?(paperEvent)
				R.previousMousePosition = paperEvent.point

			return

		# mouseup event listener
		mouseup = (event) ->

			if R.stageJ.hasClass("has-tool-box") and not $(event.target).parents('.tool-box').length>0
				R.hideToolBox()

			R.codeEditor?.onMouseUp(event)

			if R.selectedTool.name == 'Move'
				# R.selectedTool.end(R.previousMousePosition.equals(R.initialMousePosition))
				R.selectedTool.endNative(event)

				# deselect move tool and select previous tool if middle mouse button
				if event.which == 2 # middle mouse button
					R.previousTool?.select()
				return


			if R.currentDiv?
				paperEvent = Utils.Event.jEventToPaperEvent(event, R.previousMousePosition, R.initialMousePosition, 'mouseup')
				R.currentDiv.endSelect?(paperEvent)
				R.previousMousePosition = paperEvent.point

			# drag handles
			# R.mousemove(event)
			# selectedDiv.endSelect(event) for selectedDiv in R.selectedDivs

			# # update selected RDivs
			# if R.previousPoint?
			# 	event.delta = new P.Point(event.pageX-R.previousPoint.x, event.pageY-R.previousPoint.y)
			# 	R.previousPoint = null
			# 	for item in R.selectedItems
			# 		item.endSelect?(event)


			return
		# jQuery listeners
		# R.canvasJ.mousedown( mousedown )
		R.stageJ.mousedown( mousedown )
		$(window).mousemove( mousemove )
		$(window).mouseup( mouseup )
		R.stageJ.mousewheel (event)->
			View.moveBy(new P.Point(-event.deltaX, event.deltaY))
			return

		R.fileManager = new R.FileManager()

		return

	R.showCodeEditor = (source)->
		if not R.codeEditor?
			require ['editor'], (CodeEditor)->
				R.codeEditor = new CodeEditor()
				if source then R.codeEditor.setSource(source)
				R.codeEditor.open()
				return
		else
			if source then R.codeEditor.setSource(source)
			R.codeEditor.open()
		return

	return
