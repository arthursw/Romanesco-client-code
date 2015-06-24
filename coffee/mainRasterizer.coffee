define ['utils'], (utils) ->

	if not window.rasterizerMode then return

	R.initializeRasterizerMode = ()->

		R.initToolsRasterizer = ()->
			R.tools = {}
			R.modules = {}
			for pathClass in R.pathClasses
				R.tools[pathClass.label] = RPath: pathClass
				R.modules[pathClass.label] = { name: pathClass.label, iconURL: pathClass.iconURL, source: pathClass.source, description: pathClass.description, owner: 'Romanesco', thumbnailURL: pathClass.thumbnailURL, accepted: true, coreModule: true, category: pathClass.category }
			R.initializeModules()
			return

		R.fakeFunction = ()->
			return

		R.updateRoom = R.fakeFunction
		Utils.deferredExecution = R.fakeFunction
		R.alertManager.alert = R.fakeFunction
		R.rasterizer =
			load: R.fakeFunction
			unload: R.fakeFunction
			move: R.fakeFunction
			rasterizeAreasToUpdate: R.fakeFunction
			addAreaToUpdate: R.fakeFunction
			setQZoomToUpdate: R.fakeFunction
			clearRasters: R.fakeFunction
		jQuery.fn.mCustomScrollbar = R.fakeFunction

		R.selectedToolNeedsDrawings = ()->
			return true

		R.CommandManager = R.fakeFunction
		R.Rasterizer = R.fakeFunction
		R.initializeGlobalParameters = R.fakeFunction
		R.initParameters = R.fakeFunction
		R.initCodeEditor = R.fakeFunction
		R.initSocket = R.fakeFunction
		R.initPosition = R.fakeFunction
		Grid.updateGrid = R.fakeFunction
		R.RSound = R.fakeFunction
		R.chatSocket = emit: R.fakeFunction
		R.defaultColors = []
		R.gui = __folders: {}
		R.animatedItems = []
		R.areaToRasterize = null				# the area to rasterize

		# rasterizer

		R.createItemsDates = (bounds)->
			itemsDates = {}
			for pk, item of R.items
				# if bounds.contains(item.getBounds())
				type = ''
				if Lock.prototype.isPrototypeOf(item)
					type = 'Box'
				else if R.RDiv.prototype.isPrototypeOf(item)
					type = 'Div'
				else if R.RPath.prototype.isPrototypeOf(item)
					type = 'P.Path'
				itemsDates[pk] = item.lastUpdateDate
				# itemsDates.push( pk: pk, lastUpdate: item.lastUpdateDate, type: type )
			return itemsDates

		# R.removeItemsToUpdate = (itemsToUpdate)->
		# 	for pk in itemsToUpdate
		# 		R.items[pk].remove()
		# 	return


		window.loopRasterize = ()->

			rectangle = R.areaToRasterize

			width = Math.min(1000, rectangle.right - P.view.bounds.left)
			height = Math.min(1000, rectangle.bottom - P.view.bounds.top)

			newSize = new P.Size(width, height)

			if not P.view.viewSize.equals(newSize)
				topLeft = P.view.bounds.topLeft
				P.view.viewSize = newSize
				P.view.center = topLeft.add(newSize.multiply(0.5))

			imagePosition = P.view.bounds.topLeft.clone()

			# text = new PointText(P.view.bounds.center)
			# text.justification = 'center'
			# text.fillColor = 'black'
			# text.content = 'Pos: ' + P.view.bounds.center.toString()

			# P.view.update()
			dataURL = R.canvas.toDataURL()

			finished = P.view.bounds.bottom >= rectangle.bottom and P.view.bounds.right >= rectangle.right

			if not finished
				if P.view.bounds.right < rectangle.right
					P.view.center = P.view.center.add(1000, 0)
				else
					P.view.center = new P.Point(rectangle.left+P.view.viewSize.width*0.5, P.view.bounds.bottom+P.view.viewSize.height*0.5)
			else
				R.areaToRasterize = null
			window.saveOnServer(dataURL, imagePosition.x, imagePosition.y, finished, R.city)
			return

		R.loopRasterize = window.loopRasterize

		R.rasterizeAndSaveOnServer = ()->
			console.log "area rasterized"

			P.view.viewSize = P.Size.min(new P.Size(1000,1000), R.areaToRasterize.size)
			P.view.center = R.areaToRasterize.topLeft.add(P.view.size.multiply(0.5))
			R.loopRasterize()

			return

		window.loadArea = (args)->
			console.log "load_area"

			if R.areaToRasterize?
				console.log "error: load_area while loading !!"
				return

			areaObject = JSON.parse(args)

			if areaObject.city != R.city
				R.unload()
				R.city = areaObject.city

			area = Utils.Rectangle.expandRectangleToInteger(R.rectangleFromBox(areaObject))
			R.areaToRasterize = area
			# P.view.viewSize = P.Size.min(area.size, new P.Size(1000, 1000))

			# move the view
			delta = area.center.subtract(P.view.center)
			P.project.P.view.scrollBy(delta)
			for div in R.divs
				div.updateTransform()

			console.log "call load"

			R.load(area)

			return

		R.loadArea = window.loadArea

		# rasterizer tests

		R.getAreasToUpdate = ()->
			if R.areasToRasterize.length==0 and R.imageSaved
				Dajaxice.draw.getAreasToUpdate(R.getAreasToUpdateCallback)
			return

		R.loadNextArea = ()->
			if R.areasToRasterize.length>0
				area = R.areasToRasterize.shift()
				R.areaToRasterizePk = area._id.$oid
				R.imageSaved = false
				R.loadArea(JSON.stringify(area))
			return

		R.getAreasToUpdateCallback = (areas)->
			R.areasToRasterize = areas
			R.loadNextArea()
			return

		R.testSaveOnServer = (imageDataURL, x, y, finished)->
			if not imageDataURL
				console.log "no image data url"
			R.rasterizedAreasJ.append($('<img src="' + imageDataURL + '" data-position="' + x + ', ' + y + '" finished="' + finished + '">')
			.css( border: '1px solid black'))
			console.log 'position: ' + x + ', ' + y
			console.log 'finished: ' + finished
			if finished
				Dajaxice.draw.deleteAreaToUpdate(R.deleteAreaToUpdateCallback, { pk: R.areaToRasterizePk } )
			else
				R.loopRasterize()
			return

		R.deleteAreaToUpdateCallback = (result)->
			R.loader.checkError(result)
			R.imageSaved = true
			R.loadNextArea()
			return

		R.testRasterizer = ()->
			R.rasterizedAreasJ = $('<div class="rasterized-areas">')
			R.rasterizedAreasJ.css( position: 'absolute', top: 1000, left: 0 )
			$('body').css( overflow: 'auto' ).prepend(R.rasterizedAreasJ)
			window.saveOnServer = R.testSaveOnServer
			R.areasToRasterize = []
			R.imageSaved = true
			setInterval(R.getAreasToUpdate, 1000)
			return

	return
