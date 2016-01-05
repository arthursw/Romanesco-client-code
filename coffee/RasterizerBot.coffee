define [], () ->

	class RasterizerBot

		constructor: ()->
			@areasToRasterize = []
			return

		initialize: ()->


			# R.updateRoom = R.fakeFunction
			# Utils.deferredExecution = R.fakeFunction
			# R.alertManager.alert = R.fakeFunction
			# R.rasterizer =
			# 	load: R.fakeFunction
			# 	unload: R.fakeFunction
			# 	move: R.fakeFunction
			# 	rasterizeAreasToUpdate: R.fakeFunction
			# 	addAreaToUpdate: R.fakeFunction
			# 	setQZoomToUpdate: R.fakeFunction
			# 	clearRasters: R.fakeFunction
			# jQuery.fn.mCustomScrollbar = R.fakeFunction
			#
			# R.selectedToolNeedsDrawings = ()->
			# 	return true
			#
			# R.CommandManager = R.fakeFunction
			# R.Rasterizer = R.fakeFunction
			# R.initializeGlobalParameters = R.fakeFunction
			# R.initParameters = R.fakeFunction
			# R.initCodeEditor = R.fakeFunction
			# R.initSocket = R.fakeFunction
			# R.initPosition = R.fakeFunction
			# R.view.grid.update = R.fakeFunction
			# R.RSound = R.fakeFunction
			# R.chatSocket = emit: R.fakeFunction
			# R.defaultColors = []
			# R.gui = __folders: {}
			# R.animatedItems = []
			# R.areaToRasterize = null				# the area to rasterize

			# rasterizer


			# R.removeItemsToUpdate = (itemsToUpdate)->
			# 	for pk in itemsToUpdate
			# 		R.items[pk].remove()
			# 	return
			return

		# called once the loader has finish loading
		# rasterize and save the areaToRasterize on the server
		rasterizeAndSaveOnServer: ()->
			console.log "rasterizeAndSaveOnServer"
			P.view.viewSize = P.Size.min(new P.Size(1000,1000), @areaToRasterize.size)
			P.view.center = @areaToRasterize.topLeft.add(P.view.size.multiply(0.5))
			@loopRasterize()
			return

		# methods called by the rasterizer

		loopRasterize: ()->
			rectangle = @areaToRasterize

			width = Math.min(1000, rectangle.right - P.view.bounds.left)
			height = Math.min(1000, rectangle.bottom - P.view.bounds.top)

			newSize = new P.Size(width, height)

			if not P.view.viewSize.equals(newSize)
				topLeft = P.view.bounds.topLeft
				P.view.viewSize = newSize
				P.view.center = topLeft.add(newSize.multiply(0.5))

			imagePosition = P.view.bounds.topLeft.clone()

			# text = new P.PointText(P.view.bounds.center)
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

		loadArea: (args)->
			console.log "load_area"

			if @areaToRasterize?
				console.log "error: load_area while loading !!"
				return

			areaObject = JSON.parse(args)

			if areaObject.city != R.city
				R.loader.unload()
				R.city = areaObject.city

			area = Utils.Rectangle.expandRectangleToInteger(Utils.CS.rectangleFromBox(areaObject))
			@areaToRasterize = area
			# P.view.viewSize = P.Size.min(area.size, new P.Size(1000, 1000))

			# move the view
			delta = area.center.subtract(P.view.center)
			P.view.scrollBy(delta)
			for div in R.divs
				div.updateTransform()

			console.log "call load"

			R.loader.load(area)

			return

		# rasterizer tests

		getAreasToUpdate: ()=>
			if @areasToRasterize.length==0 and @imageSaved
#				Dajaxice.draw.getAreasToUpdate(@getAreasToUpdateCallback)
				$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'getAreasToUpdate', args: {} } ).done(@getAreasToUpdateCallback)
			return

		loadNextArea: ()->
			if @areasToRasterize.length>0
				area = @areasToRasterize.shift()
				@areaToRasterizePk = area._id.$oid
				@imageSaved = false
				@loadArea(JSON.stringify(area))
			return

		getAreasToUpdateCallback: (areas)=>
			@areasToRasterize = areas
			@loadNextArea()
			return

		testSaveOnServer: (imageDataURL, x, y, finished)=>
			if not imageDataURL
				console.log "no image data url"
			@rasterizedAreasJ.append($('<img src="' + imageDataURL + '" data-position="' + x + ', ' + y + '" finished="' + finished + '">')
			.css( border: '1px solid black'))
			console.log 'position: ' + x + ', ' + y
			console.log 'finished: ' + finished
			if finished
#				Dajaxice.draw.deleteAreaToUpdate(@deleteAreaToUpdateCallback, { pk: @areaToRasterizePk } )
				$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteAreaToUpdate', args: { pk: @areaToRasterizePk }  } ).done(@deleteAreaToUpdateCallback)
			else
				@loopRasterize()
			return

		deleteAreaToUpdateCallback: (result)=>
			R.loader.checkError(result)
			@imageSaved = true
			@loadNextArea()
			return

		testRasterizer: ()->
			@rasterizedAreasJ = $('<div class="rasterized-areas">')
			@rasterizedAreasJ.css( position: 'absolute', top: 1000, left: 0 )
			$('body').css( overflow: 'auto' ).prepend(@rasterizedAreasJ)
			window.saveOnServer = @testSaveOnServer
			@areasToRasterize = []
			@imageSaved = true
			setInterval(@getAreasToUpdate, 1000)
			return

	window.loopRasterize = ()->
		return R.rasterizerBot.loopRasterize()

	window.loadArea = ()->
		return R.rasterizerBot.loadArea()

	return RasterizerBot
