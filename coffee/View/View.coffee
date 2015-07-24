define [ 'View/Grid', 'Commands/Command', 'Items/Divs/Div', 'mousewheel', 'tween' ], (Grid, Command, Div)->

	class View

		constructor: ()->

			R.stageJ = $("#stage")

			R.canvasJ = R.stageJ.find("#canvas")
			R.canvas = R.canvasJ[0]
			R.canvas.width = window.innerWidth
			R.canvas.height = window.innerHeight
			R.context = R.canvas.getContext('2d')

			paper.setup(R.canvas)
			R.project = P.project

			@mainLayer = P.project.activeLayer
			@mainLayer.name = 'main layer'
			@debugLayer = new P.Layer()				# Paper layer to append debug items
			@debugLayer.name = 'debug layer'
			@carLayer = new P.Layer() 				# Paper layer to append all cars
			@carLayer.name = 'car layer'
			@lockLayer = new P.Layer()	 			# Paper layer to keep all locked items
			@lockLayer.name = 'lock layer'
			@selectionLayer = new P.Layer() 			# Paper layer to keep all selected items
			# R.view.selectionLayer = R.selectionProject.activeLayer
			@selectionLayer.name = 'selection layer'
			@areasToUpdateLayer = new P.Layer() 		# Paper layer to show areas to update
			@areasToUpdateLayer.name = 'areasToUpdateLayer'

			@backgroundRectangle = null 			# the rectangle to highlight the stage when dragging an RContent over it

			@areasToUpdateLayer.visible = false
			@mainLayer.activate()
			paper.settings.hitTolerance = 5

			R.scale = 1000.0
			P.view.zoom = 1 # 0.01
			@previousPosition = P.view.center

			@restrictedArea = null 				# area in which the user position will be constrained (in a website with restrictedArea == true)
			@entireArea = null 					# entire area to be kept loaded, it is a paper P.Rectangle
			@entireAreas = [] 						# array of RDivs which have data.loadEntireArea==true

			@grid = new Grid()


			R.canvasJ.dblclick( (event) -> R.selectedTool?.doubleClick?(event) )
			# cancel default delete key behaviour (not really working)
			R.canvasJ.keydown( (event) -> if event.key == 46 then event.preventDefault(); return false )


			@tool = new P.Tool()
			@tool.onMouseDown = @onMouseDown
			@tool.onMouseDrag = @onMouseDrag
			@tool.onMouseUp = @onMouseUp
			@tool.onKeyDown = @onKeyDown
			@tool.onKeyUp = @onKeyUp
			P.view.onFrame = @onFrame

			R.stageJ.mousewheel( @mousewheel )
			R.stageJ.mousedown( @mousedown )
			$(window).mousemove( @mousemove )
			$(window).mouseup( @mouseup )
			$(window).resize(@onWindowResize)

			window.onhashchange = @onHashChange

			@mousePosition = new P.Point() 			# the mouse position in window coordinates (updated everytime the mouse moves)
			@previousMousePosition = null 			# the previous position of the mouse in the mousedown/move/up
			@initialMousePosition = null 			# the initial position of the mouse in the mousedown/move/up


			return

		## Move/scroll the romanesco view

		# Move the romanesco view to *pos*
		# @param pos [P.Point] destination
		# @param delay [Number] time of the animation to go to destination in millisecond
		moveTo: (pos, delay, addCommand=true) ->
			pos ?= new P.Point()
			if not delay?
				somethingToLoad = @moveBy(pos.subtract(P.view.center), addCommand)
			else
				# console.log pos
				# console.log delay
				initialPosition = P.view.center
				tween = new TWEEN.Tween( initialPosition )
				.to( pos, delay )
				.easing( TWEEN.Easing.Exponential.InOut )
				.onUpdate( ()-> @moveTo(this, addCommand) )
				.start()
			return somethingToLoad

		# Move the romanesco view from *delta*
		# if user is in a restricted area (a website or videogame with restrictedArea), the move will be constrained in this area
		# This method does:
		# - scroll the paper view
		# - update RDivs' positions
		# - update grid
		# - update @entireArea (the area which must be kept loaded, in a video game or website)
		# - load entire area if we have a new entire area
		# - update websocket room
		# - update hash in 0.5 seconds
		# - set location in the general options
		# @param delta [P.Point]
		moveBy: (delta, addCommand=true) ->

			# if user is in a restricted area (a website or videogame with restrictedArea), the move will be constrained in this area
			if @restrictedArea?

				# check if the restricted area contains P.view.center (if not, move to center)
				if not @restrictedArea.contains(P.view.center)
					# delta = @restrictedArea.center.subtract(P.view.size.multiply(0.5)).subtract(P.view.bounds.topLeft)
					delta = @restrictedArea.center.subtract(P.view.center)
				else
					# test if new pos is still in restricted area
					newView = P.view.bounds.clone()
					newView.center.x += delta.x
					newView.center.y += delta.y

					# if it does not contain the view, change delta so that it contains it
					if not @restrictedArea.contains(newView)

						restrictedAreaShrinked = @restrictedArea.expand(P.view.size.multiply(-1)) # restricted area shrinked by P.view.size

						if restrictedAreaShrinked.width<0
							restrictedAreaShrinked.left = restrictedAreaShrinked.right = @restrictedArea.center.x
						if restrictedAreaShrinked.height<0
							restrictedAreaShrinked.top = restrictedAreaShrinked.bottom = @restrictedArea.center.y

						newView.center.x = Utils.clamp(restrictedAreaShrinked.left, newView.center.x, restrictedAreaShrinked.right)
						newView.center.y = Utils.clamp(restrictedAreaShrinked.top, newView.center.y, restrictedAreaShrinked.bottom)
						delta = newView.center.subtract(P.view.center)

			@previousPosition ?= P.view.center

			# scroll the paper views
			P.view.scrollBy(new P.Point(delta.x, delta.y))
			# R.selectionProject.P.view.scrollBy(new P.Point(delta.x, delta.y))

			for div in R.divs 										# update RDivs' positions
				div.updateTransform()

			R.rasterizer.move()
			@grid.update() 											# update grid

			# update @entireArea (the area which must be kept loaded, in a video game or website)
			# if the loaded entire areas contain the center of the view, it is the current entire area
			# @entireArea [P.Rectangle]
			# @entireAreas [array of Div] the array is updated when we load the RDivs (in ajax.coffee)
			# get the new entire area
			newEntireArea = null
			for area in @entireAreas
				if area.getBounds().contains(P.view.center)
					newEntireArea = area
					break

			# update @entireArea
			if not @entireArea? and newEntireArea?
				@entireArea = newEntireArea.getBounds()
			else if @entireArea? and not newEntireArea?
				@entireArea = null

			somethingToLoad = if newEntireArea? then R.loader.load(@entireArea) else R.loader.load()

			R.socket.updateRoom() 											# update websocket room

			Utils.deferredExecution(@updateHash, 'updateHash', 500) 					# update hash in 500 milliseconds

			if addCommand
				Utils.deferredExecution(@addMoveCommand, 'add move command')

			# R.willUpdateAreasToUpdate = true
			# Utils.deferredExecution(R.updateAreasToUpdate, 'updateAreasToUpdate', 500) 					# update areas to update in 500 milliseconds

			# for pk, rectangle of R.areasToUpdate
			# 	if rectangle.intersects(P.view.bounds)
			# 		R.updateView()
			# 		break

			# update location in sidebar
			R.controllerManager.folders['General'].controllers['location'].setValue('' + P.view.center.x.toFixed(2) + ',' + P.view.center.y.toFixed(2))

			return somethingToLoad


		addMoveCommand: ()=>
			R.commandManager.add(new Command.MoveView(@previousPosition, P.view.center))
			@previousPosition = null
			return

		## Hash

		# Update hash (the string after '#' in the url bar) according to the location of the (center of the) view
		# set *@ignoreHashChange* flag to ignore this change in *window.onhashchange* callback
		updateHash: ()=>
			@ignoreHashChange = true
			hashParameters = {}
			if R.repository.commit?
				hashParameters['repository-owner'] = R.repository.owner
				hashParameters['repository-commit'] = R.repository.commit
			if R.city.owner? and R.city.name? and R.city.owner != 'RomanescoOrg' and R.city.name != 'Romanesco'
				hashParameters['city-owner'] = R.city.owner
				hashParameters['city-name'] = R.city.name
			hashParameters['location'] = P.view.center.x.toFixed(2) + ',' + P.view.center.y.toFixed(2)
			location.hash = Utils.URL.setParameters(hashParameters)
			return

		# Update hash (the string after '#' in the url bar) according to the location of the (center of the) view
		# set *@ignoreHashChange* flag to ignore this change in *window.onhashchange* callback
		onHashChange: (event)=>
			if @ignoreHashChange
				@ignoreHashChange = false
				return

			parameters = Utils.URL.getParameters(document.location.hash)

			if R.repository.commit? and ( R.repository.owner != parameters['repository-owner'] or R.repository.commit != parameters['repository-commit'] )
				location.reload()
				return

			if parameters['location']?
				pos = parameters['location'].split(',')
				p = new P.Point(pos[0], pos[1])
				if not _.isFinite(p.x) then p.x = 0
				if not _.isFinite(p.y) then p.y = 0

			if R.city.name != parameters['city-name'] or R.city.owner != parameters['city-owner']
				R.city.loadCity(parameters['city-name'], parameters['city-owner'], p)
				return

			@moveTo(p)
			return

		## Init position
		# initialize the view position according to the 'data-box' of the canvas (when loading a website or video game)
		# update @entireArea and @restrictedArea according to site settings
		# update sidebar according to site settings
		initializePosition: ()->
			if R.rasterizerMode then return

			R.githubLogin = R.canvasJ.attr("data-github-login")

			R.city =
				owner: if R.canvasJ.attr("data-owner") != '' then R.canvasJ.attr("data-owner") else undefined
				city: if R.canvasJ.attr("data-city") != '' then R.canvasJ.attr("data-city") else undefined
				site: if R.canvasJ.attr("data-site") != '' then R.canvasJ.attr("data-site") else undefined

			# check if canvas has an attribute 'data-box'
			boxString = R.canvasJ.attr("data-box")

			if not boxString or boxString.length==0
				window.onhashchange()
				return

			# initialize the area rectangle *boxRectangle* from 'data-box' attr and move to the center of the box
			box = JSON.parse( boxString )

			planet = new P.Point(box.planetX, box.planetY)

			tl = Utils.CS.posOnPlanetToProject(box.box.coordinates[0][0], planet)
			br = Utils.CS.posOnPlanetToProject(box.box.coordinates[0][2], planet)

			boxRectangle = new P.Rectangle(tl, br)
			pos = boxRectangle.center

			@moveTo(pos)

			# load the entire area if 'data-load-entire-area' is set to true, and set @entireArea
			loadEntireArea = R.canvasJ.attr("data-load-entire-area")

			if loadEntireArea
				@entireArea = boxRectangle
				R.loader.load(boxRectangle)

			# boxData = if box.data? and box.data.length>0 then JSON.parse(box.data) else null
			# console.log boxData

			# init @restrictedArea
			siteString = R.canvasJ.attr("data-site")
			site = JSON.parse( siteString )
			if site.restrictedArea
				@restrictedArea = boxRectangle

			R.tools.select.select() 		# select 'Select' tool by default when loading a website
											# since a click on an Lock will activate the drag (temporarily select the 'Move' tool)
											# and the user must be able to select text

			# update sidebar according to site settings
			if site.disableToolbar
				# just hide the sidebar
				R.sidebar.hide()
			else
				# remove all panels except the chat
				R.sidebar.sidebarJ.find("div.panel.panel-default:not(:last)").hide()

				# remove all controllers and folder except zoom in General.
				for folderName, folder of R.gui.__folders
					for controller in folder.__controllers
						if controller.name != 'Zoom'
							folder.remove(controller)
							folder.__controllers.remove(controller)
					if folder.__controllers.length==0
						R.gui.removeFolder(folderName)

				R.sidebar.handleJ.click()

			return


		## mouse and key listeners


		focusIsOnCanvas: ()->
			return $(document.activeElement).is("body")
			# activeElementIsOnSidebar = $(document.activeElement).parents(".sidebar").length>0
			# activeElementIsTextarea = $(document.activeElement).is("textarea")
			# activeElementIsOnParameterBar = $(document.activeElement).parents(".dat-gui").length
			# return not activeElementIsOnSidebar and not activeElementIsTextarea and not activeElementIsOnParameterBar


		# Paper listeners
		onMouseDown: (event) =>

			if R.wacomPenAPI?.isEraser
				@tool.onKeyUp( key: 'delete' )
				return
			$(document.activeElement).blur() # prevent to keep focus on the chat when we interact with the canvas
			# event = Utils.Snap.snap(event) 		# snapping mouseDown event causes some problems
			R.selectedTool?.begin(event)
			return

		onMouseDrag: (event) =>
			if R.wacomPenAPI?.isEraser then return
			if R.currentDiv? then return
			# event = Utils.Snap.snap(event)
			R.selectedTool?.update(event)
			return

		# @tool.onMouseMove = (event) ->
		# 	if R.selectedTool.name == 'Select'
		# 		event.item?.controller?.highlight()
		# 	return

		onMouseUp: (event) =>
			if R.wacomPenAPI?.isEraser then return
			if R.currentDiv? then return
			# event = Utils.Snap.snap(event)
			R.selectedTool?.end(event)
			return

		onKeyDown: (event) =>

			# if the focus is on anything in the sidebar or is a textarea or in parameters bar: ignore the event
			if not @focusIsOnCanvas() then return

			if event.key == 'delete' 									# prevent default delete behaviour (not working)
				event.preventDefault()
				return false

			# select 'Move' tool when user press space key (and reselect previous tool after)
			if event.key == 'space' and R.selectedTool?.name != 'Move'
				R.tools.move.select()

			return

		onKeyUp: (event) =>
			# if the focus is on anything in the sidebar or is a textarea or in parameters bar: ignore the event
			if not @focusIsOnCanvas() then return

			R.selectedTool?.keyUp(event)

			switch event.key
				when 'space'
					R.previousTool?.select()
				when 'v'
					R.tools.select.select()
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
		onFrame: (event)=>
			TWEEN.update(event.time)

			R.rasterizer.updateLoadingBar?(event.time)

			R.selectedTool?.onFrame?(event)

			for item in R.animatedItems
				item.onFrame(event)

			return

		onWindowResize: (event)=>
			# update grid and mCustomScrollbar when window is resized
			# R.backgroundCanvas.width = window.innerWidth
			# R.backgroundCanvas.height = window.innerHeight
			# R.backgroundCanvasJ.width(window.innerWidth)
			# R.backgroundCanvasJ.height(window.innerHeight)
			@grid.update()
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
		mousedown: (event) =>

			switch event.which						# switch on mouse button number (left, middle or right click)
				when 2
					R.tools.move.select()		# select move tool if middle mouse button
				when 3
					R.selectedTool?.finish?() 	# finish current path (in polygon mode) if right click

			if R.selectedTool?.name == 'Move' 		# update 'Move' tool if it is the one selected, and return
				# @initialMousePosition = new P.Point(event.pageX, event.pageY)
				# @previousMousePosition = @initialMousePosition.clone()
				# R.selectedTool.begin()
				R.selectedTool?.beginNative(event)
				return

			@initialMousePosition = Utils.Event.jEventToPoint(event)
			@previousMousePosition = @initialMousePosition.clone()

			return

		# mousemove event listener
		mousemove: (event) =>
			@mousePosition.x = event.pageX
			@mousePosition.y = event.pageY

			if R.selectedTool?.name == 'Move' and R.selectedTool.dragging
				# mousePosition = new P.Point(event.pageX, event.pageY)
				# simpleEvent = delta: @previousMousePosition.subtract(mousePosition)
				# @previousMousePosition = mousePosition
				# console.log simpleEvent.delta.toString()
				# R.selectedTool.update(simpleEvent) 	# update 'Move' tool if it is the one selected
				R.selectedTool.updateNative(event)
				return

			Div.updateHiddenDivs(event)

			# update selected RDivs
			# if R.previousPoint?
			# 	event.delta = new P.Point(event.pageX-R.previousPoint.x, event.pageY-R.previousPoint.y)
			# 	R.previousPoint = new P.Point(event.pageX, event.pageY)

			# 	for item in R.selectedItems
			# 		item.updateSelect?(event)

			# update code editor width
			R.codeEditor?.onMouseMove(event)

			if R.currentDiv?
				paperEvent = Utils.Event.jEventToPaperEvent(event, @previousMousePosition, @initialMousePosition, 'mousemove')
				R.currentDiv.updateSelect?(paperEvent)
				@previousMousePosition = paperEvent.point

			return

		# mouseup event listener
		mouseup: (event) =>

			if R.stageJ.hasClass("has-tool-box") and not $(event.target).parents('.tool-box').length>0
				R.hideToolBox()

			R.codeEditor?.onMouseUp(event)

			if R.selectedTool?.name == 'Move'
				# R.selectedTool.end(@previousMousePosition.equals(@initialMousePosition))
				R.selectedTool.endNative(event)

				# deselect move tool and select previous tool if middle mouse button
				if event.which == 2 # middle mouse button
					R.previousTool?.select()
				return


			if R.currentDiv?
				paperEvent = Utils.Event.jEventToPaperEvent(event, @previousMousePosition, @initialMousePosition, 'mouseup')
				R.currentDiv.endSelect?(paperEvent)
				@previousMousePosition = paperEvent.point

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

		mousewheel: (event)=>
			@moveBy(new P.Point(-event.deltaX, event.deltaY))
			return

		# hash format: [repo-owner=repo-owner-name&commit-hash=commit-hash][&city-owner=city-owner&city-name=city-name][&location=location-x,location-y]
		# default values: repo=arthursw:main&city-owner=RomanescoOrg&city-name=Romanesco&location=0.0,0.0
		# examples: repo-owner=arthursw:247c64eae291e6551646f8785fd19d92333969de&city-owner=John&city-name=Paris&location=100.0,-9850.0


	return View
