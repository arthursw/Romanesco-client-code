define [ 'utils', 'bootstrap', 'tween', 'mousewheel', 'scrollbar' ], () ->

	###
	# Global functions #

	Here are all global functions (which do not belong to classes and are not event handlers neither initialization functions).

	###

	Utils.Event = {}
	# Convert a jQuery event to a project position
	# @return [Paper P.Point] the project position corresponding to the event pageX, pageY
	Utils.Event.jEventToPoint = (event)->
		return P.view.viewToProject(new P.Point(event.pageX-R.canvasJ.offset().left, event.pageY-R.canvasJ.offset().top))

	# ## Event to object conversion (to send event info through websockets)

	# # Convert an event (jQuery event or Paper.js event) to an object
	# # Only specific data is copied: modifiers (in paper.js event), position (pageX/Y or event.point), downPoint, delta, and target
	# # convert the class name to selector to be able to find the target on the other clients [to be modified]
	# #
	# # @param event [jQuery or Paper.js event] event to convert
	# Utils.Event.eventToObject = (event)->
	# 	eo =
	# 		modifiers: event.modifiers
	# 		point: if not event.pageX? then event.point else Utils.Event.jEventToPoint(event)
	# 		downPoint: event.downPoint?
	# 		delta: event.delta
	# 	if event.pageX? and event.pageY?
	# 		eo.modifiers = {}
	# 		eo.modifiers.control = event.ctrlKey
	# 		eo.modifiers.command = event.metaKey
	# 	if event.target?
	# 		# convert class name to selector to be able to find the target on the other clients (websocket com)
	# 		eo.target = "." + event.target.className.replace(" ", ".")
	# 	return eo

	# # Convert an object to an event (to receive event info through websockets)
	# #
	# # @param event [object event] event to convert
	# R.objectToEvent = (event)->
	# 	event.point = new P.Point(event.point)
	# 	event.downPoint = new P.Point(event.downPoint)
	# 	event.delta = new P.Point(event.delta)
	# 	return event

	# Convert a jQuery event to a Paper event
	#
	# @param event [jQuert event] event to convert
	# @param previousPosition [Paper P.Point] (optional) the previous position of the mouse
	# @param initialPosition [Paper P.Point] (optional) the initial position of the mouse
	# @param type [String] (optional) the type of event
	# @param count [Number] (optional) the number of times the mouse event was fired
	# @return Paper event
	Utils.Event.jEventToPaperEvent = (event, previousPosition=null, initialPosition=null, type=null, count=null)->
		currentPosition = Utils.Event.jEventToPoint(event)
		previousPosition ?= currentPosition
		initialPosition ?= currentPosition
		delta = currentPosition.subtract(previousPosition)
		paperEvent =
			modifiers:
				shift: event.shiftKey
				control: event.ctrlKey
				option: event.altKey
				command: event.metaKey
			point: currentPosition
			downPoint: initialPosition
			delta: delta
			middlePoint: previousPosition.add(delta.divide(2))
			type: type
			count: count
		return paperEvent

	# Returns snapped event
	#
	# @param event [Paper Event] event to snap
	# @param from [String] (optional) username of the one who emitted of the event
	# @return [Paper event] snapped event
	Utils.Event.snap = (event, from=R.me)->
		if from!=R.me then return event
		if R.selectedTool.disableSnap() then return event
		snap = R.parameters.General.snap.value
		# snap = snap-snap%R.parameters.General.snap.step
		if snap != 0
			snappedEvent = jQuery.extend({}, event)
			snappedEvent.modifiers = event.modifiers
			snappedEvent.point = Utils.Event.snap2D(event.point, snap)
			if event.lastPoint? then snappedEvent.lastPoint = Utils.Event.snap2D(event.lastPoint, snap)
			if event.downPoint? then snappedEvent.downPoint = Utils.Event.snap2D(event.downPoint, snap)
			if event.lastPoint? then snappedEvent.middlePoint = snappedEvent.point.add(snappedEvent.lastPoint).multiply(0.5)
			if event.type != 'mouseup' and event.lastPoint?
				snappedEvent.delta = snappedEvent.point.subtract(snappedEvent.lastPoint)
			else if event.downPoint?
				snappedEvent.delta = snappedEvent.point.subtract(snappedEvent.downPoint)
			return snappedEvent
		else
			return event


	# Test if the special key is pressed. Special key is command key on a mac, and control key on other systems.
	#
	# @param event [jQuery or Paper.js event] key event
	# @return [Boolean] *specialKey*
	R.specialKey = (event)->
		if event.pageX? and event.pageY?
			specialKey = if R.OSName == "MacOS" then event.metaKey else event.ctrlKey
		else
			specialKey = if R.OSName == "MacOS" then event.modifiers.command else event.modifiers.control
		return specialKey

	## Snap management
	# The snap is applied to all emitted events (on the downPoint, point, delta and lastPoint properties)
	# This is a poor and dirty implementation
	# not good at all since it does not help to align elements on a grid (the offset between the initial position and the closest grid point is not cancelled)

	Utils.Snap = {}
	# Returns quantized snap
	#
	# @return [Number] *snap*
	Utils.Snap.getSnap = ()->
		# snap = R.parameters.snap.snap
		# return snap-snap%R.parameters.snap.step
		return R.parameters.General.snap.value

	# Returns snapped value
	#
	# @param value [Number] value to snap
	# @param snap [Number] optional snap, default is getSnap()
	# @return [Number] snapped value
	Utils.Snap.snap1D = (value, snap)->
		snap ?= Utils.Event.getSnap()
		if snap != 0
			return Math.round(value/snap)*snap
		else
			return value

	# Returns snapped point
	#
	# @param point [P.Point] point to snap
	# @param snap [Number] optional snap, default is getSnap()
	# @return [Paper point] snapped point
	Utils.Snap.snap2D = (point, snap)->
		snap ?= Utils.Event.getSnap()
		if snap != 0
			return new P.Point(Utils.Event.snap1D(point.x, snap), Utils.Event.snap1D(point.y, snap))
		else
			return point

	# # Hide show RItems (RPath and RDivs)

	# # Hide every path except *me* and set fastModeOn to true
	# #
	# # @param me [RItem] the only item not to hide
	# R.hideOthers = (me)->
	# 	for name, item of R.paths
	# 		if item != me
	# 			item.group?.visible = false
	# 	R.fastModeOn = true
	# 	return

	# # Show every path and set fastModeOn to false (do nothing if not in fastMode. The fastMode is when items are hidden when user modifies an RItem)
	# R.showAll = ()->
	# 	if not R.fastModeOn then return
	# 	for name, item of R.paths
	# 		item.group?.visible = true
	# 	R.fastModeOn = false
	# 	return

	Utils.Animation = {}
	# register animation: push item to R.animatedItems
	Utils.Animation.registerAnimation = (item)->
		Utils.Array.pushIfAbsent(R.animatedItems, item)
		return

	# deregister animation: remove item from R.animatedItems
	Utils.Animation.deregisterAnimation = (item)->
		Utils.Array.remove(R.animatedItems, item)
		return

	# # Get the game under *point*
	# # @param point [P.Point] point to test
	# # @return [RVideoGame] the video game at *point*
	# R.gameAt = (point)->
	# 	for div in R.divs
	# 		if div.getBounds().contains(point) and div.constructor.name == 'RVideoGame'
	# 			return div
	# 	return null

	# R.updateLoadingBar = (percentage)->
	# 	updateLoadingText = ()->
	# 		$("#loadingBar").text((percentage*100).toFixed(2) + '%')
	# 		return
	# 	window.setTimeout(updateLoadingText, 10)
	# 	return

	# R.initLoadingBar = ()->
	# 	R.nLoadingRequest = 0
	# 	R.nLoadingStartRequest = 0
	# 	R.loadingBarTimeout = null
	# 	R.loadingBarJ = $("#loadingBar")
	# 	R.loadingBarProject = new Project("loadingBar")
	# 	R.loadingBarProject.activate()
	# 	size = 70
	# 	s = new P.Path.Star(new P.Point(size+30, size+30), 8, 0.8*size, size)
	# 	s.strokeWidth = 10
	# 	s.strokeColor = 'rgb(146, 215, 94)'

	# 	for i in [1 .. 10]
	# 		s = s.clone()
	# 		s.rotation = 45/2
	# 		s.scaling = 0.7
	# 		l = s.strokeColor.getLightness()
	# 		s.strokeColor.setLightness(l+(i+1)*0.01)

	# 	paper.projects[0].activate()
	# 	R.startLoadingBar()

	# 	return

	# R.setLoadingBar = (percentage)->
	# 	if percentage>=1 then return
	# 	loadingBarPath = R.loadingBarProject.activeLayer.children[0].clone()
	# 	loadingBarPath.strokeColor = 'rgb(47, 161, 214)'
	# 	reminder = loadingBarPath.split(loadingBarPath.length*percentage)
	# 	reminder.remove()
	# 	return

	# R.animatedLoadingBar = ()->
	# 	if not R.loadingBarJ? then return
	# 	R.loadingBarProject.activeLayer.rotation += 0.5
	# 	R.loadingBarProject.P.view.draw()
	# 	# divJ = R.loadingBarJ.find(".rotation")
	# 	# divJ.css( transform: 'rotate(' + (Date.now()/10) + 'deg)')
	# 	# context = R.loadingBarJ.getContext("2d")
	# 	# context.rotate(Date.now()/10)
	# 	return

	# R.startLoadingBar = (timeBeforeStart=200)->
	# 	if not R.loadingBarJ? then return
	# 	if R.loadingBarTimeout? then return
	# 	R.loadingBarTimeout = setTimeout(R.startLoadingBarHandler, timeBeforeStart)
	# 	R.nLoadingStartRequest++
	# 	return

	# R.startLoadingBarHandler = ()->
	# 	if not R.loadingBarJ? then return

	# 	R.nLoadingRequest++
	# 	if R.loadingState == 'started' then return

	# 	R.loadingBarJ.stop(true)
	# 	R.loadingBarJ.fadeIn( duration: 200, queue: false )
	# 	clearInterval(R.loadingInterval)
	# 	R.loadingInterval = setInterval(R.animatedLoadingBar, 1000/60)
	# 	R.loadingState = 'started'

	# 	return

	# R.stopLoadingBar = ()->
	# 	if not R.loadingBarJ? then return

	# 	R.nLoadingRequest--
	# 	if R.nLoadingRequest>0 then return

	# 	R.nLoadingStartRequest--
	# 	if R.nLoadingStartRequest==0 then clearTimeout(R.loadingBarTimeout)

	# 	R.loadingState = 'stop requested'

	# 	R.loadingBarJ.fadeOut( duration: 200, queue: false, complete: ()->
	# 		clearInterval(R.loadingInterval)
	# 		R.loadingInterval = null
	# 		R.loadingState = 'stopped'
	# 		return
	# 	)
	# 	return


	## RItems selection



	# R.drawView = ()->
	# 	time = Date.now()
	# 	P.view.draw()
	# 	console.log "Time to draw the view: " + ((Date.now()-time)/1000) + " sec."
	# 	return

	# this.benchmarkRectangleClone = ()->
	# 	start = Date.now()
	# 	r = new P.Rectangle(1,2,3,4)
	# 	p = new P.Point(5,6)
	# 	for i in [0 .. 1000000]
	# 		r2 = r.clone()
	# 		r2.center = p
	# 	end = Date.now()
	# 	console.log "rectangle clone time: " + (end-start)

	# 	d = p.subtract(r.center)

	# 	start = Date.now()
	# 	for i in [0 .. 1000000]
	# 		r.x += d.x
	# 		r.y += d.y
	# 	end = Date.now()

	# 	console.log "rectangle move time: " + (end-start)

	# 	return



	# this.rasterizePaths = ()->
	# 	for pk, path of R.paths
	# 		raster = path.drawing.rasterize()
	# 		position = P.Point.max(P.view.projectToView(raster.bounds.topLeft), new P.Point(0,0))
	# 		R.context.drawImage(raster.canvas, position.x, position.y)
	# 		raster.remove()
	# 		path.group.visible = false
	# 	return

	# this.deletePaths = ()->
	# 	for pk, path of R.paths
	# 		path.remove()
	# 	return

	# this.rasterizeProject = (path)->
	# 	if path.controlPath?
	# 		path.group.visible = false
	# 		P.view.draw()
	# 	R.backgroundCanvasJ.show()
	# 	R.backgroundContext.drawImage(R.canvas, 0, 0, R.canvas.width, R.canvas.height)
	# 	for pk, p of R.paths
	# 		if p != path
	# 			p.group.visible = false
	# 	path.group.visible = true
	# 	return

	# this.restoreProject = ()->
	# 	R.backgroundCanvasJ.hide()
	# 	R.backgroundContext.clearRect(0, 0, canvas.width, canvas.height)
	# 	for pk, p of R.paths
	# 		p.group.visible = true
	# 	return

	# R.rasterizeProject = (paths)->

	# 	for pk, p of R.path
	# 		if not p.drawing? then p.draw()
	# 		p.group.visible = true

	# 	# do we need update when path is not created
	# 	for path in paths
	# 		path.group.visible = false
	# 		P.view.update()

	# 	# R.backgroundCanvasJ.show()
	# 	# R.backgroundContext.drawImage(R.canvas, 0, 0, R.canvas.width, R.canvas.height)

	# 	R.putViewToRasters()

	# 	for pk, p of R.paths
	# 		if paths.indexOf(p)<0 then p.group.visible = false

	# 	for path in paths
	# 		path.group.visible = true

	# 	return

	# R.restoreProject = ()->
	# 	# R.backgroundCanvasJ.hide()
	# 	# R.backgroundContext.clearRect(0, 0, canvas.width, canvas.height)

	# 	# for pk, p of R.paths
	# 	# 	p.group.visible = true

	# 	# P.view.update()
	# 	# R.rasterizeToRasters()

	# 	if path.getDrawingBounds() < 2000*2000
	# 		R.putImageToRasters(path.drawing.rasterize())

	# 	return

	# R.rasterizeToRasters = ()->
	# 	for x, rasterColumn of R.rasters
	# 		for y, raster of rasterColumn
	# 			intersection = raster.bounds.intersect(P.view.bounds)
	# 			if intersection.area > 0
	# 				positionInRaster = intersection.topLeft.subtract(raster.bounds.topLeft) #.divide(raster.bounds.width, raster.bounds.height).multiply(1000, 1000)
	# 				intersectionInView = R.projectToViewRectangle(intersection)
	# 				imageData = R.context.getImageData(intersectionInView.x, intersectionInView.y, intersectionInView.width, intersectionInView.height)
	# 				raster.setImageData(imageData, positionInRaster.x, positionInRaster.y)

	# 	return


	# R.putViewToRasters = (r)->
	# 	R.putImageToRasters(R.context, P.view.bounds)
	# 	return

	# R.putRasterToRasters = (raster)->
	# 	bounds = R.projectToViewRectangle(raster.bounds)
	# 	raster.size = raster.size.multiply(P.view.zoom)
	# 	R.putImageToRasters(raster, bounds)
	# 	return

	# R.putRasterToRasters = (raster)->
	# 	raster.size = raster.size.multiply(P.view.zoom)
	# 	bounds = raster.bounds
	# 	for x, rasterColumn of R.rasters
	# 		for y, raster of rasterColumn
	# 			intersection = raster.bounds.intersect(bounds)
	# 			if intersection.area > 0
	# 				positionInRaster = intersection.topLeft.subtract(raster.bounds.topLeft).divide(raster.bounds.width, raster.bounds.height).multiply(1000, 1000)
	# 				intersectionInView = R.projectToViewRectangle(intersection)
	# 				imageData = container.getImageData(intersectionInView.x, intersectionInView.y, intersectionInView.width, intersectionInView.height)
	# 				raster.setImageData(imageData, positionInRaster.x, positionInRaster.y)

	# 	return

	# R.putImageToRasters = (container, bounds)->

	# 	for x, rasterColumn of R.rasters
	# 		for y, raster of rasterColumn
	# 			intersection = raster.bounds.intersect(bounds)
	# 			if intersection.area > 0
	# 				positionInRaster = intersection.topLeft.subtract(raster.bounds.topLeft).divide(raster.bounds.width, raster.bounds.height).multiply(1000, 1000)
	# 				intersectionInView = R.projectToViewRectangle(intersection)
	# 				imageData = container.getImageData(intersectionInView.x, intersectionInView.y, intersectionInView.width, intersectionInView.height)
	# 				raster.setImageData(imageData, positionInRaster.x, positionInRaster.y)

	# 	return

	# hide rasters and redraw all items
	# this.updateView = ()->

	# 	for x, rasterColumn of R.rasters
	# 		for y, raster of rasterColumn
	# 			raster.remove()
	# 			delete R.rasters[x][y]
	# 			if Utils.isEmpty(R.rasters[x]) then delete R.rasters[x]

	# 	for pk, item of R.paths
	# 		item.draw()

	# 	return

	# this.hidePaths = ()->
	# 	for pk, path of R.paths
	# 		path.group.visible = false
	# 	return

	# this.showPaths = ()->
	# 	for pk, path of R.paths
	# 		path.group.visible = true
	# 	return


	# # deprecated
	# # 1. remove rasters on which @ lies
	# # 2. redraw all items which lie on those rasters
	# # @param bounds [Paper rectangle] the area to update
	# # @param item [RItem] (optional) the item not to update (draw)
	# this.updateClientRasters = (bounds, ritem=null)->

	# 	console.log "updateClientRasters"

	# 	# find top, left, bottom and right positions of the area in the quantized space
	# 	scale = R.scale
	# 	t = Math.floor(bounds.top / scale) * scale
	# 	l = Math.floor(bounds.left / scale) * scale
	# 	b = Math.floor(bounds.bottom / scale) * scale
	# 	r = Math.floor(bounds.right / scale) * scale

	# 	# for all rasters on which @ relies
	# 	areasToLoad = []
	# 	for x in [l .. r] by scale
	# 		for y in [t .. b] by scale
	# 			raster = R.rasters[x]?[y]

	# 			if not raster then continue

	# 			console.log "remove raster: " + x + "," + y

	# 			raster.remove()
	# 			delete R.rasters[x][y]
	# 			if Utils.isEmpty(R.rasters[x]) then delete R.rasters[x]

	# 			rastebounds = new P.Rectangle(x, y, 1000, 1000)

	# 			for pk, item of R.items
	# 				console.log "item: " + item.name
	# 				console.log item.getBounds()
	# 				console.log rastebounds
	# 				console.log item.getBounds().intersects(rastebounds)
	# 				if item != ritem and item.getBounds().intersects(rastebounds)
	# 					item.draw()
	# 	return



	## Debug

	R.highlightAreasToUpdate = ()->
		for pk, rectangle of R.areasToUpdate
			rectanglePath = P.project.getItem( name: pk )
			rectanglePath.strokeColor = 'green'
		return

	# Log all RItems
	R.logItems = ()->
		console.log "Selected items:"
		for item, i in P.project.selectedItems
			if item.name?.indexOf("debug")==0 then continue
			console.log "------" + i + "------"
			console.log item.name
			console.log item
			console.log item.controller
			console.log item.controller?.pk
		console.log "All items:"
		for item, i in P.project.activeLayer.children
			if item.name?.indexOf("debug")==0 then continue
			console.log "------" + i + "------"
			console.log item.name
			console.log item
			console.log item.controller
			console.log item.controller?.pk
		return "--- THE END ---"

	# Check if there are items without rasters
	R.checkRasters = ()->
		for item in P.project.activeLayer.children
			if item.controller? and not item.controller.raster?
				console.log item.controller
				# item.controller.rasterize()
		return

	# select rasters
	R.selectRasters = ()->
		rasters = []
		for item in P.project.activeLayer.children
			if item.constructor.name == "Raster"
				item.selected = true
				rasters.push(item)
		console.log 'selected rasters:'
		return rasters

	R.printPathList = ()->
		names = []
		for pathClass in R.pathClasses
			names.push(pathClass.label)
		console.log names
		return

	R.fakeGeoJsonBox = (rectangle)->
		box = {}

		planet = R.pointToObj( R.projectToPlanet(rectangle.topLeft) )

		box.planetX = planet.x
		box.planetY = planet.y

		box.box = coordinates: [[
			R.pointToArray(R.projectToPosOnPlanet(rectangle.topLeft, planet))
			R.pointToArray(R.projectToPosOnPlanet(rectangle.topRight, planet))
			R.pointToArray(R.projectToPosOnPlanet(rectangle.bottomRight, planet))
			R.pointToArray(R.projectToPosOnPlanet(rectangle.bottomLeft, planet))
		]]
		return JSON.stringify(box)

	R.getControllerFromFomElement = ()->
		for folderName, folder of R.gui.__folders
			for controller in folder.__controllers
				if controller.domElement == $0 or $($0).find(controller.domElement).length>0
					return controller
		return

	R.logStack = ()->
		caller = arguments.callee.caller
		while caller?
			console.log caller.prototype
			caller = caller.caller
		return

	R.getCoffeeSources = ()->
		$.ajax( url: R.romanescoURL + "static/coffee/path.coffee" ).done (data)->

			lines = data.split(/\n/)
			expressions = CoffeeScript.nodes(data).expressions

			classMap = {}
			for pathClass in R.pathClasses
				classMap[pathClass.name] = pathClass

			for expression in expressions
				classMap[expression.variable.base.value]?.source = lines[expression.locationData.first_line .. expression.locationData.last_line].join("\n")

			return

		return


	R.startTime = Date.now()

	R.logElapsedTime = ()->
		time = (Date.now() - R.startTime) / 1000
		console.log "Time elapsed: " + time + " sec."
		return

	R.startTimer = ()->
		R.timerStartTime = Date.now()
		return

	R.stopTimer = (message)->
		time = (Date.now() - R.timerStartTime) / 1000
		console.log "" + message + ": " + time + " sec."
		return

	R.setDebugMode = (debugMode)->
		Dajaxice.draw.setDebugMode(R.loader.checkError, debug: debugMode)
		return

	R.roughSizeOfObject = (object, maxDepth=4) ->

		if Item.prototype.isPrototypeOf(object)
			object = object.clone(false)

		blackList = ['project', 'layer', 'view', 'parent', '_project', '_layer', '_view', '_parent']

		objectList = []
		stack = [ depth: 0, object: object ]
		bytes = 0

		depth = 0

		while stack.length
			s = stack.pop()
			value = s.object
			depth = s.depth

			if depth > maxDepth
				console.log s.name
				continue

			ignoreBlackList = Item.prototype.isPrototypeOf(value) or Style.prototype.isPrototypeOf(value)

			# if Item.prototype.isPrototypeOf(value)

			# 	if object.view? then object.view = null
			# 	if object.project? then object.project = null
			# 	if object.parent? then object.parent = null
			# 	if object.layer? then object.layer = null
			# 	if object._view? then object._view = null
			# 	if object._project? then object._project = null
			# 	if object._parent? then object._parent = null
			# 	if object._layer? then object._layer = null

			# 	if object.style?
			# 		if object.style.view? then object.style.view = null
			# 		if object.style.project? then object.style.project = null
			# 		if object.style._view? then object.style._view = null
			# 		if object.style._project? then object.style._project = null

			if typeof value == 'boolean'
				bytes += 4
			else if typeof value == 'string'
				bytes += value.length * 2
			else if typeof value == 'number'
				bytes += 8
			else if typeof value == 'object' and objectList.indexOf(value) == -1
				objectList.push value

				for name, property of value

					# if not ignoreBlackList or name not in blackList
					if name not in blackList
						stack.push( object: property, depth: s.depth + 1, name: name )

		console.log 'takes ' + bytes + ' bytes.'
		return bytes

# ---
# generated by js2coffee 2.0.4
	# one complicated solution to handle the loading:
	# this.showMask = (show)->
		# if show
		# 	R.globalMaskJ.show()
		# else
		# 	R.globalMaskJ.hide()
		# return
	# this.loop = (work, max, batchSize, callback, init=0, step=1, callbackArgs) ->
	# 	length = init

	# 	doWork = () ->
	# 		limit = Math.min(length+batchSize*step, max)
	# 		while length < limit
	# 			if not work(length) then return
	# 			length += step
	# 		if length < max
	# 			setTimeout(doWork, 0)
	# 		else
	# 			callback(callbackArgs)
	# 		return

	# 	doWork()
	# 	return

	# 	draw: (simplified=false, loading=false)->
	#		R.showMask(true)
	# 		if @isDrawing
	# 			@stopDrawing = true
	# 			_this = @
	# 			setTimeout( ( ()-> _this.draw(simplified, loading) ), 0)

	# 		@isDrawing = true

	# 		if @controlPath.segments.length < 2 then return

	# 		if simplified then @simplifiedModeOn()

	# 		step = @data.step
	# 		controlPathLength = @controlPath.length
	# 		nf = controlPathLength/step
	# 		nIteration  = Math.floor(nf)
	# 		reminder = nf-nIteration
	# 		length = reminder*step/2

	# 		@drawBegin()

	# 		drawUpdateJob = (length)=>
	# 			try
	# 				if @stopDrawing
	# 					@isDrawing = false
	# 					@stopDrawing = false
	# 					return false 		# @controlPath is null if the path was removed before totally drawn, then return false (stop the loop execution)
	# 				@drawUpdate(length)
	# 				P.view.draw()
	# 			catch error
	# 				console.error error
	# 				throw error
	# 			# R.setLoadingBar(length/controlPathLength)
	# 			return true

	# 		R.loop(drawUpdateJob, controlPathLength, 10, @finishDraw, length, step, simplified)

	# 		# while length<controlPathLength
	# 		# 	@drawUpdate(length)
	# 		# 	length += step

	# 		return

	# 	finishDraw: (simplified)=>
	# 		@drawEnd()

	# 		if simplified
	# 			@simplifiedModeOff()
	# 		else
	# 			@rasterize()
	#		R.showMask(false)
	# 		return

	# Paper.js onFrame event also wotks with requestAnimationFrame so it is better to use the paper default function
	# deprecated animate function for Tween.js
	# this.animate = (time)->
	# 	requestAnimationFrame( animate )
	# 	TWEEN.update(time)
	# 	return

	doAreasOverlap = (areas)->
		for area in areas
			for a in areas
				if a.intersects(area)
					console.log "OVERLAAAAAAAAAPP"
		return

	return

# sort items by z-index
#
# getIndices = (item)->
# 	indices = []
# 	while not P.Layer.prototype.isPrototypeOf( item )
# 		indices.unshift(item.index)
# 		item = item.parent()
# 	return indices

# sort = (a, b)->
# 	ai = getIndices(a)
# 	bi = getIndices(b)

# 	i = 0
# 	while ai[i] == bi[i]
# 		i++

# 	if ai[i] > bi[i] or not bi[i]
# 		return 1
# 	else ai[i] < bi[i] or not ai[i]
# 		return -1
# 	return 0

# sortedItems = []
# items = []
# for pk, item of R.items
# 	items.push(item)

# sort(items, sort)

# # for pk, item of R.items
# # 	index = item.index
# # 	parent = item.parent
# # 	i = 1
# # 	while not P.Layer.prototype.isPrototypeOf( parent )
# # 		index += Math.pow(10,-i) * parent.index
# # 		parent = parent.parent
# # 		i++
