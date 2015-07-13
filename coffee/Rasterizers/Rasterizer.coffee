define [ 'Items/Lock' ], (Lock) ->

	#  values: ['one raster per shape', 'paper.js only', 'tiled canvas', 'hide inactives', 'single canvas']

	class Rasterizer
		@TYPE = 'default'
		@MAX_AREA = 1.5
		@UNION_RATIO = 1.5

		# Get the image in *rectangle* of the view in a data url
		# @param rectangle [Paper P.Rectangle] a rectangle in view or project coordinates representing the area to extract
		# @param convertToView [Boolean] (optional) a boolean indicating whether to intersect *rectangle* with the view bounds and convert to view coordinates
		# @return [String] the data url of the view image defined by area
		@areaToImageDataUrl: (rectangle, convertToView=true)->
			if rectangle.height <=0 or rectangle.width <=0
				console.log 'Warning: trying to extract empty area!!!'
				return null

			if convertToView
				rectangle = rectangle.intersect(P.view.bounds)
				viewRectangle = Utils.CS.projectToViewRectangle(rectangle)
			else
				viewRectangle = rectangle

			if viewRectangle.size.equals(P.view.size) and viewRectangle.x == 0 and viewRectangle.y == 0
				return R.canvas.toDataURL("image/png")

			canvasTemp = document.createElement('canvas')
			canvasTemp.width = viewRectangle.width
			canvasTemp.height = viewRectangle.height
			contextTemp = canvasTemp.getContext('2d')
			contextTemp.putImageData(R.context.getImageData(viewRectangle.x, viewRectangle.y, viewRectangle.width, viewRectangle.height), 0, 0)

			dataURL = canvasTemp.toDataURL("image/png")
			return dataURL

		constructor: ()->
			R.rasterizerManager.rasterizers[@constructor.TYPE] = @
			@rasterizeItems = true
			return

		quantizeBounds: (bounds=P.view.bounds, scale=R.scale)->
			quantizedBounds =
				t: Utils.floorToMultiple(bounds.top, scale)
				l: Utils.floorToMultiple(bounds.left, scale)
				b: Utils.floorToMultiple(bounds.bottom, scale)
				r: Utils.floorToMultiple(bounds.right, scale)
			return quantizedBounds

		rasterize: (items, excludeItems)->
			return

		unload: (limit)->
			return

		load: (rasters, qZoom)->
			return

		move: ()->
			return

		loadItem: (item)->
			item.draw?()
			if @rasterizeItems
				item.rasterize?()
			return

		requestDraw: ()->
			return true

		selectItem: (item)->
			return

		deselectItem: (item)->
			item.rasterize?()
			return

		rasterizeRectangle: (rectangle)->
			return

		addAreaToUpdate: (area)->
			return

		setQZoomToUpdate: (qZoom)->
			return

		rasterizeAreasToUpdate: ()->
			return

		maxArea: ()->
			return P.view.bounds.area * @constructor.MAX_AREA

		rasterizeView: ()->
			return

		clearRasters: ()->
			return

		drawItems: ()->
			return

		rasterizeAllItems: ()->

			for pk, item of R.items
				item.rasterize?()

			return

		hideOthers: (itemsToExclude)->
			return

		showItems: ()->
			return

		hideRasters: ()->
			return

		showRasters: ()->
			return

		extractImage: (rectangle, redraw)->
			return Rasterizer.areaToImageDataUrl(rectangle)

	class TileRasterizer extends Rasterizer

		@TYPE = 'abstract tile'
		@loadingBarJ = null

		@addChildren: (parent, sortedItems)->
			if not parent.children? then return
			for item in parent.children
				if item.controller? and P.Group.prototype.isPrototypeOf(item)
					sortedItems.push(item.controller)
					if Lock.prototype.isPrototypeOf(item.controller)
						@addChildren(item, sortedItems)
			return

		@getSortedItems: ()->
			sortedItems = []
			@addChildren(R.view.mainLayer, sortedItems)
			@addChildren(R.view.lockLayer, sortedItems)
			# @addChildrenToParent(R.view.selectionLayer, sortedItems) # the selection layer is never rasterized (should it be?)
			return sortedItems

		constructor: ()->
			super()
			@itemsToExclude = []
			@areaToRasterize = null 	# areas to rasterize on the client (when user modifies an item)
			@areasToUpdate = [] 		# areas to update stored in server (areas not yet rasterized by the server rasterizer)

			@rasters = {}

			@rasterizeItems = true
			@rasterizationDisabled = false
			@autoRasterization = 'deferred'
			@rasterizationDelay = 800

			@renderInView = false

			@itemsAreDrawn = false
			@itemsAreVisible = false

			@move()
			return

		loadItem: (item)->
			if item.data?.animate or R.selectedTool.constructor.drawItems	# only draw if animated thanks to rasterization
				item.draw?()
			else
				@itemsAreDrawn = false
			if @rasterizeItems
				item.rasterize?()
			return

		startLoading: ()->
			@startLoadingTime = P.view._time
			TileRasterizer.loadingBarJ.css( width: 0 )
			TileRasterizer.loadingBarJ.show()

			Utils.deferredExecution(@rasterizeCallback, 'rasterize', @rasterizationDelay)
			return

		stopLoading: (cancelTimeout=true)->
			@startLoadingTime = null
			TileRasterizer.loadingBarJ.hide()

			if cancelTimeout
				clearTimeout(R.updateTimeout['rasterize'])
			return

		rasterizeImmediately: ()=>
			@stopLoading()
			@rasterizeCallback()
			return

		updateLoadingBar: (time)->
			if not @startLoadingTime? then return
			duration = 1000 * ( time - @startLoadingTime ) / @rasterizationDelay
			totalWidth = 241
			TileRasterizer.loadingBarJ.css( width: duration * totalWidth )
			if duration>=1
				@stopLoading(false)
			return

		drawItemsAndHideRasters: ()->
			@drawItems(true)
			@hideRasters()
			return

		selectItem: (item)->
			@drawItems()
			@rasterize(item, true)

			switch @autoRasterization
				when 'disabled'
					@drawItemsAndHideRasters()
					item.group.visible = true
				when 'deferred'
					@drawItemsAndHideRasters()
					item.group.visible = true
					@stopLoading()
				when 'immediate'
					Utils.callNextFrame(@rasterizeCallback, 'rasterize')
			return

		deselectItem: (item)->
			if @rasterizeItems
				item.rasterize?()

			@rasterize(item)

			switch @autoRasterization
				when 'deferred'
					@startLoading()
				when 'immediate'
					Utils.callNextFrame(@rasterizeCallback, 'rasterize')

			return

		rasterLoaded: (raster)->
			raster.context.clearRect(0, 0, R.scale, R.scale)
			raster.context.drawImage(raster.image, 0, 0)
			raster.ready = true
			raster.loaded = true
			@checkRasterizeAreasToUpdate()
			return

		checkRasterizeAreasToUpdate: (pathsCreated=false)->
			if pathsCreated or Utils.isEmpty(R.loader.pathsToCreate)
				allRastersAreReady = true
				for x, rasterColumn of @rasters
					for y, raster of rasterColumn
						allRastersAreReady &= raster.ready
				if allRastersAreReady
					@rasterizeAreasToUpdate()
			return

		createRaster: (x, y, zoom, raster)->
			raster.zoom = zoom
			raster.ready = true
			raster.loaded = false
			@rasters[x] ?= {}
			@rasters[x][y] = raster
			return

		getRasterBounds: (x, y)->
			size = @rasters[x][y].zoom * R.scale
			return new P.Rectangle(x, y, size, size)

		removeRaster: (raster, x, y)->
			delete @rasters[x][y]
			if Utils.isEmpty(@rasters[x]) then delete @rasters[x]
			return

		unload: (limit)->
			qZoom = Utils.CS.quantizeZoom(1.0 / P.view.zoom)

			for x, rasterColumn of @rasters
				x = Number(x)
				for y, raster of rasterColumn
					y = Number(y)
					rectangle = @getRasterBounds(x, y)
					if not limit.intersects(rectangle) or @rasters[x][y].zoom != qZoom
						@removeRaster(raster, x, y)

			return

		loadImageForRaster: (raster, url)->
			return

		load: (rasters, qZoom)->
			@move()

			for r in rasters
				x = r.position.x * R.scale
				y = r.position.y * R.scale
				raster = @rasters[x]?[y]
				if raster and not raster.loaded
					raster.ready = false
					url = R.romanescoURL + r.url + '?' + Math.random()
					@loadImageForRaster(raster, url)

			return

		createRasters: (rectangle)->
			qZoom = Utils.CS.quantizeZoom(1.0 / P.view.zoom)
			scale = R.scale * qZoom
			qBounds = @quantizeBounds(rectangle, scale)
			for x in [qBounds.l .. qBounds.r] by scale
				for y in [qBounds.t .. qBounds.b] by scale
					@createRaster(x, y, qZoom)
			return

		move: ()->
			@createRasters(P.view.bounds)
			return

		splitAreaToRasterize: ()->
			maxSize = P.view.size.multiply(2)

			areaToRasterizeInteger = Utils.Rectangle.expandRectangleToInteger(@areaToRasterize)
			area = Utils.Rectangle.expandRectangleToInteger(new P.Rectangle(@areaToRasterize.topLeft, P.Size.min(maxSize, @areaToRasterize.size)))
			areas = [area.clone()]

			while area.right < @areaToRasterize.right or area.bottom < @areaToRasterize.bottom
				if area.right < @areaToRasterize.right
					area.x += maxSize.width
				else
					area.x = areaToRasterizeInteger.left
					area.y += maxSize.height

				areas.push(area.intersect(areaToRasterizeInteger))

			return areas

		rasterizeCanvasInRaster: (x, y, canvas, rectangle, qZoom, clearRasters=false, sourceRectangle=null)->
			if not @rasters[x]?[y]? then return
			rasterRectangle = @getRasterBounds(x, y)
			intersection = rectangle.intersect(rasterRectangle)

			destinationRectangle = new P.Rectangle(intersection.topLeft.subtract(rasterRectangle.topLeft).divide(qZoom), intersection.size.divide(qZoom))

			context = @rasters[x][y].context

			# context.fillRect(destinationRectangle.x-1, destinationRectangle.y-1, destinationRectangle.width+2, destinationRectangle.height+2)

			if clearRasters then context.clearRect(destinationRectangle.x, destinationRectangle.y, destinationRectangle.width, destinationRectangle.height)
			# if clearRasters
			# 	context.globalCompositeOperation = 'copy' # this clear completely and then draw the new image (not what we want)
			# else
			# 	context.globalCompositeOperation = 'source-over'
			if canvas?
				if sourceRectangle?
					sourceRectangle = new P.Rectangle(intersection.topLeft.subtract(sourceRectangle.topLeft), intersection.size)
				else
					sourceRectangle = new P.Rectangle(intersection.topLeft.subtract(rectangle.topLeft).divide(qZoom), intersection.size.divide(qZoom))
				context.drawImage(canvas, sourceRectangle.x, sourceRectangle.y, sourceRectangle.width, sourceRectangle.height,
					destinationRectangle.x, destinationRectangle.y, destinationRectangle.width, destinationRectangle.height)
			return

		rasterizeCanvas: (canvas, rectangle, clearRasters=false, sourceRectangle=null)->
			console.log "rasterize: " + rectangle.width + ", " + rectangle.height
			qZoom = Utils.CS.quantizeZoom(1.0 / P.view.zoom)
			scale = R.scale * qZoom
			qBounds = @quantizeBounds(rectangle, scale)
			for x in [qBounds.l .. qBounds.r] by scale
				for y in [qBounds.t .. qBounds.b] by scale
					@rasterizeCanvasInRaster(x, y, canvas, rectangle, qZoom, clearRasters, sourceRectangle)
			return

		clearAreaInRasters: (rectangle)->
			@rasterizeCanvas(null, rectangle, true)
			return

		rasterizeArea: (area)->
			P.view.viewSize = area.size.multiply(P.view.zoom)
			P.view.center = area.center
			P.view.update()

			@rasterizeCanvas(R.canvas, area, true)
			return

		rasterizeAreas: (areas)->
			viewZoom = P.view.zoom
			viewSize = P.view.viewSize
			viewPosition = P.view.center

			P.view.zoom = 1.0 / Utils.CS.quantizeZoom(1.0 / P.view.zoom)

			for area in areas
				@rasterizeArea(area)

			P.view.zoom = viewZoom
			P.view.viewSize = viewSize
			P.view.center = viewPosition
			return

		prepareView: ()->
			# show all items
			for pk, item of R.items
				item.group.visible = true

			# hide excluded items
			for item in @itemsToExclude
				item.group?.visible = false 	# group is null when item has been deleted

			R.grid.visible = false
			R.view.selectionLayer.visible = false
			R.view.carLayer.visible = false
			@viewOnFrame = P.view.onFrame
			P.view.onFrame = null

			@rasterLayer?.visible = false
			return

		restoreView: ()->
			@rasterLayer?.visible = true

			P.view.onFrame = @viewOnFrame
			R.view.carLayer.visible = true
			R.view.selectionLayer.visible = true
			R.grid.visible = true
			return

		rasterizeCallback: (step)=>

			if not @areaToRasterize then return

			console.log "rasterize"

			Utils.logElapsedTime()

			R.startTimer()

			if @autoRasterization == 'deferred' or @autoRasterization == 'disabled'
				@showRasters()

			areas = @splitAreaToRasterize()

			if @renderInView
				@prepareView()
				@rasterizeAreas(areas)
				@restoreView()
			else
				sortedItems = @constructor.getSortedItems()
				for area in areas
					# p = new P.Path.Rectangle(area)
					# p.strokeColor = 'red'
					# p.strokeWidth = 1
					# R.view.debugLayer.addChild(p)
					@clearAreaInRasters(area)
					for item in sortedItems
						if item.raster?.bounds.intersects(area) and item not in @itemsToExclude
							@rasterizeCanvas(item.raster.canvas, item.raster.bounds.intersect(area), false, item.raster.bounds)

			# hide all items except selected ones and the ones being created
			for pk, item of R.items
				if item == R.currentPaths[R.me] or item.selectionRectangle? then continue
				item.group?.visible = false

			# show excluded items and their children
			for item in @itemsToExclude
				item.group?.visible = true
				item.showChildren?()

			@itemsToExclude = []
			@areaToRasterize = null
			@itemsAreVisible = false

			@stopLoading()

			R.stopTimer('Time to rasterize path: ')
			Utils.logElapsedTime()
			return

		rasterize: (items, excludeItems)->

			if @rasterizationDisabled then return

			console.log "ask rasterize" + (if excludeItems then " excluding items." else "")
			Utils.logElapsedTime()

			if not Utils.Array.isArray(items) then items = [items]
			if not excludeItems then @itemsToExclude = []

			for item in items
				@areaToRasterize ?= item.getDrawingBounds()
				@areaToRasterize = @areaToRasterize.unite(item.getDrawingBounds())
				if excludeItems
					Utils.Array.pushIfAbsent(@itemsToExclude, item)

			return

		rasterizeRectangle: (rectangle)->
			@drawItems()

			if not @areaToRasterize?
				@areaToRasterize = rectangle
			else
				@areaToRasterize = @areaToRasterize.unite(rectangle)

			Utils.callNextFrame(@rasterizeCallback, 'rasterize')
			return

		addAreaToUpdate: (area)->
			@areasToUpdate.push(area)
			return

		setQZoomToUpdate: (qZoom)->
			@areasToUpdateQZoom = qZoom
			return

		rasterizeAreasToUpdate: ()->

			if @areasToUpdate.length==0 then return

			@drawItems(true)

			previousItemsToExclude = @itemsToExclude
			previousAreaToRasterize = @areaToRasterize
			previousZoom = P.view.zoom
			P.view.zoom = 1.0 / @areasToUpdateQZoom

			@itemsToExclude = []
			for area in @areasToUpdate
				# @createRasters(area)
				@areaToRasterize = area
				@rasterizeCallback()

			@areasToUpdate = []

			@itemsToExclude = previousItemsToExclude
			@areaToRasterize = previousAreaToRasterize
			P.view.zoom = previousZoom

			return

		clearRasters: ()->
			for x, rasterColumn of @rasters
				for y, raster of rasterColumn
					raster.context.clearRect(0, 0, R.scale, R.scale)
			return

		drawItems: (showItems=false)->
			if showItems then @showItems()

			if @itemsAreDrawn then return

			for pk, item of R.items
				if not item.drawing? then item.draw?()
				if @rasterizeItems
					item.rasterize?()

			@itemsAreDrawn = true

			return

		showItems: ()->
			if @itemsAreVisible then return

			for pk, item of R.items
				item.group.visible = true

			@itemsAreVisible = true
			return

		disableRasterization: ()->
			@rasterizationDisabled = true
			@clearRasters()
			@drawItems(true)
			return

		enableRasterization: ()->
			@rasterizationDisabled = false
			@rasterizeView()
			return

		rasterizeView: ()->
			@rasterizeRectangle(P.view.bounds)
			return

		hideRasters: ()->
			return

		showRasters: ()->
			return

		hideOthers: (itemToExclude)->
			console.log itemToExclude.pk
			for pk, item of R.items
				if item != itemToExclude
					item.group.visible = false
			return

		extractImage: (rectangle, redraw)->
			if redraw

				rasterizeItems = @rasterizeItems
				@rasterizeItems = false
				disableDrawing = @disableDrawing
				@disableDrawing = false
				@drawItemsAndHideRasters()

				dataURL = Rasterizer.areaToImageDataUrl(rectangle)

				if rasterizeItems
					@rasterizeItems = true
					for pk, item of R.items
						item.rasterize?()

				if disableDrawing then @disableDrawing = true

				@showRasters()
				@rasterizeImmediately()

				return dataURL
			else
				return Rasterizer.areaToImageDataUrl(rectangle)

	class PaperTileRasterizer extends TileRasterizer

		@TYPE = 'paper tile'

		constructor:()->
			@rasterLayer = new P.Layer()
			@rasterLayer.name = 'raster layer'
			@rasterLayer.moveBelow(R.view.mainLayer) 	# this will activate the top layer (selection layer or areasToUpdateLayer)
			R.view.mainLayer.activate()
			super()
			return

		onRasterLoad: ()=>
			raster.context = raster.canvas.getContext('2d')
			@rasterLoaded(raster)
			return

		createRaster: (x, y, zoom)->
			if @rasters[x]?[y]? then return

			raster = new P.Raster()
			raster.name = 'raster: ' + x + ', ' + y
			console.log raster.name
			raster.position.x = x + 0.5 * R.scale * zoom
			raster.position.y = y + 0.5 * R.scale * zoom
			raster.width = R.scale
			raster.height = R.scale
			raster.scale(zoom)
			raster.context = raster.canvas.getContext('2d')
			@rasterLayer.addChild(raster)
			raster.onLoad = @onRasterLoad
			super(x, y, zoom, raster)
			return

		removeRaster: (raster, x, y)->
			raster.remove()
			super(raster, x, y)
			return

		loadImageForRaster: (raster, url)->
			raster.source = url
			return

		hideRasters: ()->
			for x, rasterColumn of @rasters
				for y, raster of rasterColumn
					raster.visible = false
			return

		showRasters: ()->
			for x, rasterColumn of @rasters
				for y, raster of rasterColumn
					raster.visible = true
			return

	class InstantPaperTileRasterizer extends PaperTileRasterizer

		@TYPE = 'light'

		constructor:()->
			super()
			@disableDrawing = true
			@updateDrawingAfterDelay = true
			@itemsToDraw = {}
			return

		drawItemsAndHideRasters: ()->
			return

		requestDraw: (item, simplified, redrawing)->
			if @disableDrawing
				if @updateDrawingAfterDelay
					time = Date.now()
					delay = 500
					if not @itemsToDraw[item.pk]? or time-@itemsToDraw[item.pk] < delay
						@itemsToDraw[item.pk] = time
						Utils.deferredExecution(item.draw, 'item.draw:'+item.pk, delay, [simplified, redrawing], item)
					else
						delete @itemsToDraw[item.pk]
						return true
			return not @disableDrawing

		selectItem: (item)->
			if not @rasterizeItems
				item.removeDrawing()
			super(item)
			return

		deselectItem: (item)->
			super(item)

			if not @rasterizeItems
				item.replaceDrawing()
			return

		rasterizeCallback: (step)->

			@disableDrawing = false

			for pk, item of R.items
				if item.drawn? and not item.drawn and item.getDrawingBounds().intersects(@areaToRasterize)
					item.draw?()
					if @rasterizeItems then item.rasterize?()

			@disableDrawing = true

			super(step)

			return

		rasterizeAreasToUpdate: ()->
			@disableDrawing = false
			super()
			@disableDrawing = true
			return

	class CanvasTileRasterizer extends TileRasterizer

		@TYPE = 'canvas tile'

		constructor: ()->
			super()
			return

		createRaster: (x, y, zoom)->
			raster = @rasters[x]?[y]
			if raster?
				# if raster.zoom != zoom
				# 	scale = raster.zoom / zoom
				# 	raster.zoom = zoom
				# 	raster.context.clearRect(0, 0, R.scale, R.scale)
				# 	raster.context.drawImage(raster.image, 0, 0, raster.image.width * scale, raster.image.height * scale)
				# 	console.log "image scaled by: " + scale
				return

			raster = {}
			raster.canvasJ = $('<canvas hidpi="off" width="' + R.scale + '" height="' + R.scale + '">')
			raster.canvas = raster.canvasJ[0]
			# raster.position = new P.Point(x, y)
			raster.context = raster.canvas.getContext('2d')
			raster.image = new Image()

			raster.image.onload = ()=>
				@rasterLoaded(raster)
				return

			$("#rasters").append(raster.canvasJ)
			super(x, y, zoom, raster)
			return

		removeRaster: (raster, x, y)->
			raster.canvasJ.remove()
			super(raster, x, y)
			return

		loadImageForRaster: (raster, url)->
			raster.image.src = url
			return

		move: ()->
			super()

			for x, rasterColumn of @rasters
				x = Number(x)
				for y, raster of rasterColumn
					y = Number(y)

					viewPos = P.view.projectToView(new P.Point(x, y))

					if P.view.zoom == 1
						raster.canvasJ.css( 'left': viewPos.x, 'top': viewPos.y, 'transform': 'none' )
					else
						scale = P.view.zoom * raster.zoom
						css = 'translate(' + viewPos.x + 'px,' + viewPos.y + 'px)'
						css += ' scale(' + scale + ')'
						raster.canvasJ.css( 'transform': css, 'top': 0, 'left': 0, 'transform-origin': '0 0' )
			return

		hideRasters: ()->
			for x, rasterColumn of @rasters
				for y, raster of rasterColumn
					raster.canvasJ.hide()
			return

		showRasters: ()->
			for x, rasterColumn of @rasters
				for y, raster of rasterColumn
					raster.canvasJ.show()
			return

	Rasterizer.Tile = TileRasterizer
	Rasterizer.CanvasTile = CanvasTileRasterizer
	Rasterizer.InstantPaperTile = InstantPaperTileRasterizer
	Rasterizer.PaperTile = PaperTileRasterizer

	return Rasterizer
