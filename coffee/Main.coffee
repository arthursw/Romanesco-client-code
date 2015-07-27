define [
	'Utils/Utils'
	'Utils/Global'
	'Utils/FontManager'
	'Loader'
	'Socket'
	'City'
	'Rasterizers/RasterizerManager'
	'UI/Sidebar'
	'UI/Code'
	'UI/Modal'
	'UI/AlertManager'
	'UI/Controllers/ControllerManager'
	'Commands/CommandManager'
	'View/View'
	'Tools/ToolManager'
], (Utils, Global, FontManager, Loader, Socket, City, RasterizerManager, Sidebar, FileManager, Modal, AlertManager, ControllerManager, CommandManager, View, ToolManager) ->

	console.log 'Arthur-test FORK!'
	# R.rasterizerMode = window.rasterizerMode

	# if R.rasterizerMode
	# 	R.initializeRasterizerMode()

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


	# initialize Romanesco
	# all global variables and functions are stored in *g* which is a synonym of *window*
	# all jQuery elements names end with a capital J: elementNameJ
	# init = ()->
		# R.romanescoURL = 'http://romanesc.co/'




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

		# R.fastMode = false 						# fastMode will hide all items except the one being edited (when user edits an item)
		# R.fastModeOn = false					# fastModeOn is true when the user is edditing an item


		# R.draggingEditor = false 				# boolean, true when user is dragging the code editor
		# R.rasters = {}							# map to store rasters (tiles, rasterized version of the view)
		# R.areasToUpdate = {} 					# map of areas to update { pk->rectangle }
												# (areas which are not rasterize on the server, that we must send if we can rasterize them)
		# R.rastersToUpload = [] 					# an array of { data: dataURL, position: position } containing the rasters to upload on the server
		# R.areasToRasterize = [] 				# an array of P.Rectangle to rasterize
		# R.isUpdatingRasters = false 			# true if we are updating rasters (in loopUpdateRasters)
		# R.viewUpdated = false 					# true if the view was updated ( rasters removed and items drawn in R.updateView() )
												# and we don't need to update anymore (until new P.Rasters are added in load_callback)




												# used to get mouse position on a key event



		# R.globalMaskJ = $("#globalMask")
		# R.globalMaskJ.hide()



		# init paper.js
		# paper.setup(R.selectionCanvas)
		# R.selectionProject = project






		# R.sound = new R.RSound(['/static/sounds/space_ship_engine.mp3', '/static/sounds/space_ship_engine.ogg'])


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

		# R.initializeGlobalParameters()

		# if not R.rasterizerMode


		# else
		# 	R.initToolsRasterizer()

		# return

	# Initialize Romanesco and handlers
	$(document).ready () ->


		# parameters
		R.catchErrors = false 					# the error will not be caught when drawing an RPath (let chrome catch them at the right time)
		R.ignoreSockets = false 				# whether sockets messages are ignored

		R.currentPaths = {} 					# map of username -> path id corresponding to the paths currently being created

		# R.loadingBarTimeout = null 				# timeout id of the loading bar

		R.paths = new Object() 					# a map of RPath.pk (or RPath.id) -> RPath. RPath are first added with their id, and then with their pk
												# (as soon as server saved it and responds)
		R.items = new Object() 					# map Item.id or Item.pk -> Item, all loaded RItems. The key is Item.id before Item is saved
												# in the database, and Item.pk after
		R.locks = [] 							# array of loaded Locks
		R.divs = [] 							# array of loaded RDivs
		R.sortedPaths = []						# an array where paths are sorted by index (z-index)
		R.sortedDivs = []						# an array where divs are sorted by index (z-index)

		R.animatedItems = [] 					# an array of animated items to be updated each frame


		R.cars = {} 							# a map of username -> cars which will be updated each frame

		R.currentDiv = null 					# the div currently being edited (dragged, moved or resized) used to also send jQuery mouse event to divs

		# R.areasToUpdateRectangles = {} 			# debug map: area to update pk -> rectangle path


		R.selectedItems = [] 					# the selectedItems

		R.socket = new Socket()
		R.sidebar = new Sidebar()
		R.view = new View()
		R.loader = new Loader()
		R.alertManager = new AlertManager()
		R.controllerManager = new ControllerManager()
		R.controllerManager.createGlobalControllers()
		R.rasterizerManager = new RasterizerManager()
		R.rasterizerManager.initializeRasterizers()
		R.commandManager = new CommandManager()
		R.toolManager = new ToolManager()
		R.fileManager = new FileManager()
		R.fontManager = new FontManager()
		R.view.initializePosition()
		R.sidebar.initialize()

		window.setPageFullyLoaded?(true)

		# init()

		# if R.rasterizerMode then return

		return

	R.showCodeEditor = (fileNode)->
		if not R.codeEditor?
			require ['UI/Editor'], (CodeEditor)->
				R.codeEditor = new CodeEditor()
				if fileNode then R.codeEditor.setFile(fileNode)
				R.codeEditor.open()
				return
		else
			if fileNode then R.codeEditor.setFile(fileNode)
			R.codeEditor.open()
		return

	return