define [ 'Commands/Command', 'Items/Item', 'Items/Lock', 'Items/Divs/Div', 'Items/Divs/Media', 'Items/Divs/Text' ], (Command, Item) ->

	# --- load --- #

	class Loader

		constructor: ()->
			@loadedAreas = []
			@debug = false
			return

		showLoadingBar: ()->
			$("#loadingBar").show()
			return

		hideLoadingBar: ()->
			$("#loadingBar").hide()
			return

		# @return [Boolean] true if the area was already loaded, false otherwise
		areaIsLoaded: (pos, planet, qZoom) ->
			for area in @loadedAreas
				if area.planet.x == planet.x && area.planet.y == planet.y
					if area.pos.x == pos.x && area.pos.y == pos.y
						if not qZoom? or area.zoom == qZoom
							return true
			return false

		# this.areaIsQuickLoaded = (area) ->
		# 	for a in @loadedAreas
		# 		if a.x == area.x && a.y == area.y
		# 			return true
		# 	return false
		unload: () ->
			@loadedAreas = []
			for own pk, item of R.items
				item.remove()
			R.items = {}
			R.rasterizer.clearRasters()
			@previousLoadPosition = null
			return

		loadRequired: ()->
			if not R.rasterizerMode and @previousLoadPosition?
				if @previousLoadPosition.position.subtract(P.view.center).length<50
					if Math.abs(1-@previousLoadPosition.zoom/P.view.zoom)<0.2
						return false
			return true

		getLoadingBounds: (area)->
			if not area?
				if P.view.bounds.width <= window.innerWidth and P.view.bounds.height <= window.innerHeight
					return P.view.bounds
				else
					halfSize = new P.Point(window.innerWidth*0.5, window.innerHeight*0.5)
					return new P.Rectangle(P.view.center.subtract(halfSize), P.view.center.add(halfSize))
			return area

		unloadAreas: (area, limit, qZoom)->

			itemsOutsideLimit = []

			# remove RItems which are not on within limit anymore AND in area which must be unloaded
			# (do not remove items on an area which is not unloaded, otherwise they wont be reloaded if user comes back on it)
			for own pk, item of R.items
				if not item.getBounds().intersects(limit)
					itemsOutsideLimit.push(item)

			i = @loadedAreas.length
			while i--
				area = @loadedAreas[i]
				pos = Utils.CS.posOnPlanetToProject(area.pos, area.planet)
				rectangle = new P.Rectangle(pos.x, pos.y, R.scale * area.zoom, R.scale * area.zoom)

				if not rectangle.intersects(limit) or area.zoom != qZoom

					if @debug then @updateDebugArea(area)

					# # remove raster corresponding to the area
					# x = area.x*1000 	# should be equal to pos.x
					# y = area.y*1000		# should be equal to pos.y

					# if R.rasters[x]?[y]?
					# 	R.rasters[x][y].remove()
					# 	delete R.rasters[x][y]
					# 	if Utils.isEmpty(R.rasters[x]) then delete R.rasters[x]

					# remove area from loaded areas
					@loadedAreas.splice(i,1)

					# remove items on this area
					# items to remove must not intersect with the limit, and can overlap two areas:
					j = itemsOutsideLimit.length
					while j--
						item = itemsOutsideLimit[j]
						if item.getBounds().intersects(rectangle)
							item.remove()
							itemsOutsideLimit.splice(j,1)
			return

		getAreasToLoad: (scale, qZoom, t, l, b, r)->
			areasToLoad = []
			for x in [l .. r] by scale
				for y in [t .. b] by scale
					planet = Utils.CS.projectToPlanet(new P.Point(x,y))
					pos = Utils.CS.projectToPosOnPlanet(new P.Point(x,y))

					# rasterizer always add all areas since it must check if it is up-to-date
					# (items which are loaded could need to be updated)
					if R.rasterizerMode

						area = { pos: pos, planet: planet }

						areasToLoad.push(area)

						if @debug then @createAreaDebugRectangle(x, y, scale)

						if not @areaIsLoaded(pos, planet)
							@loadedAreas.push(area)
					else
						if not @areaIsLoaded(pos, planet, qZoom)

							area = { pos: pos, planet: planet }

							areasToLoad.push(area)

							area.zoom = qZoom

							if @debug then @createAreaDebugRectangle(x, y, scale)

							@loadedAreas.push(area)
			return areasToLoad

		# load an area from the server
		# the project coordinate system is divided into square cells of size *R.scale*
		# an Area is an object { pos: P.Point, planet: P.Point } corresponding to a cell (pos is the top left corner of the cell, the server consider the cells to be 1 unit wide (1000 pixels))
		# a load does:
		# - build a list of Area overlapping *area* and not already loaded
		# - define a load limit rectangle equels to *area* expanded to 2 x R.scale
		# - remove RItems which are not within this limit anymore AND in an area which must be unloaded
		#   (do not remove items on an area which is not unloaded, otherwise they wont be reloaded if user comes back on it)
		# - remove loaded areas which where unloaded
		# - load areas
		# @param [P.Rectangle] (optional) the area to load, *area* equals the bounds of the view if not defined
		load: (area=null) ->

			if not @loadRequired() then return false

			console.log "load"
			if area? then console.log area.toString()

			# R.startLoadingBar()

			@previousLoadPosition = position: P.view.center, zoom: P.view.zoom

			bounds = @getLoadingBounds(area)

			# unload:
			# define unload limit rectangle
			unloadDist = Math.round(R.scale / P.view.zoom)

			limit = R.view.entireArea or bounds.expand(unloadDist)

			# remove rasters which are outside the limit
			R.rasterizer.unload(limit)

			qZoom = Utils.CS.quantizeZoom(1.0 / P.view.zoom)

			# remove areas which are outside the limit
			@unloadAreas(area, limit, qZoom)

			scale = R.scale * qZoom

			# find top, left, bottom and right positions of the area in the quantized space
			t = Utils.floorToMultiple(bounds.top, scale)
			l = Utils.floorToMultiple(bounds.left, scale)
			b = Utils.floorToMultiple(bounds.bottom, scale)
			r = Utils.floorToMultiple(bounds.right, scale)

			if @debug then @updateDebugPaths(limit, bounds, t, l, b, r)

			# add areas to load
			areasToLoad = @getAreasToLoad(scale, qZoom, t, l, b, r)

			if not R.rasterizerMode and areasToLoad.length<=0 	# return if there is nothing to load
				return false

			# load areas
			_.defer(@showLoadingBar)

			if not R.rasterizerMode
				rectangle = { left: l / 1000.0, top: t / 1000.0, right: r / 1000.0, bottom: b / 1000.0 }
				Dajaxice.draw.load(@loadCallback, { rectangle: rectangle, areasToLoad: areasToLoad, qZoom: qZoom, city: R.city })
			else
				itemsDates = R.createItemsDates(bounds)
				Dajaxice.draw.loadRasterizer(@loadCallback, { areasToLoad: areasToLoad, itemsDates: itemsDates, cityPk: R.city })

			return true

		dispatchLoadFinished: ()->
			console.log "dispatch command executed"
			commandEvent = document.createEvent('Event')
			commandEvent .initEvent('command executed', true, true)
			document.dispatchEvent(commandEvent)
			return

		# set R.me (the server sends the username at each load)
		setMe: (user)->
			if not R.me? and user?
				R.me = user
				if R.chatJ? and R.chatJ.find("#chatUserNameInput").length==0
					R.startChatting( R.me )
			return

		removeDeletedItems: (deletedItems)->
			if not deletedItems? then return
			for pk, deletedItemLastUpdate of deletedItems
				R.items[pk]?.remove()
			return

		parseNewItems: (items)->
			itemsToLoad = []

			for i in items
				item = JSON.parse(i)

				if not R.rasterizerMode and R.items[item._id.$oid]?
					continue
				else if R.rasterizerMode
					itemToReplace = R.items[item._id.$oid]
					if itemToReplace?
						console.log "itemToReplace: " + itemToReplace.pk
						itemToReplace.remove() 	# if item is loaded: remove it (it must be updated)

				if item.rType == 'Box'
					itemsToLoad.unshift(item)
				else
					itemsToLoad.push(item)

			return itemsToLoad

		createNewItems: (itemsToLoad)->
			for item in itemsToLoad

				pk = item._id.$oid
				date = item.date?.$date
				data = if item.data? and item.data.length>0 then JSON.parse(item.data) else null
				lock = if item.lock? then R.items[item.lock] else null

				switch item.rType
					when 'Box'
						box = item
						if box.box.coordinates[0].length<5
							console.log "Error: box has less than 5 points"

						lock = null
						switch box.object_type
							when 'lock'
								lock = new Item.Lock(Utils.CS.rectangleFromBox(box), data, box._id.$oid, box.owner, date, box.module?.$oid)
							when 'link'
								lock = new Item.Link(Utils.CS.rectangleFromBox(box), data, box._id.$oid, box.owner, date, box.module?.$oid)
							when 'website'
								lock = new Item.Website(Utils.CS.rectangleFromBox(box), data, box._id.$oid, box.owner, date, box.module?.$oid)
							when 'video-game'
								lock = new Item.VideoGame(Utils.CS.rectangleFromBox(box), data, box._id.$oid, box.owner, date, box.module?.$oid)

						lock.lastUpdateDate = box.lastUpdate.$date

					when 'Div'			# add RDivs (Text and Media)
						div = item
						if div.box.coordinates[0].length<5
							console.log "Error: box has less than 5 points"



						# rdiv = new R.g[div.object_type](Utils.CS.rectangleFromBox(box), data, div._id.$oid, date, div.lock)

						switch div.object_type
							when 'text'
								rdiv = new Item.Text(Utils.CS.rectangleFromBox(div), data, pk, date, lock)
							when 'media'
								rdiv = new Item.Media(Utils.CS.rectangleFromBox(div), data, pk, date, lock)

						rdiv.lastUpdateDate = div.lastUpdate.$date

					when 'P.Path' 		# add RPaths
						path = item
						planet = new P.Point(path.planetX, path.planetY)
						data?.planet = planet

						points = []

						# convert points from planet coordinates to project coordinates
						for point in path.points.coordinates
							points.push( Utils.CS.posOnPlanetToProject(point, planet) )

						# create the RPath with the corresponding RTool
						rpath = null
						if R.tools[path.object_type]?
							rpath = new R.tools[path.object_type].RPath(date, data, pk, points, lock)
							rpath.lastUpdateDate = path.lastUpdate.$date

							if rpath.constructor.name == "Checkpoint"
								console.log rpath
						else
							console.log "Unknown path type: " + path.object_type
					when 'AreaToUpdate'
						R.rasterizer.addAreaToUpdate(Utils.CS.rectangleFromBox(item))

						# areaToUpdate = new P.Path.Rectangle(Utils.CS.rectangleFromBox(item))
						# areaToUpdate.fillColor = 'rgba(255,50,50,0.25)'
						# areaToUpdate.strokeColor = 'rgba(255,50,50,0.5)'
						# areaToUpdate.strokeWidth = 3
						# areaToUpdate.getBounds = ()-> return areaToUpdate.bounds
						# R.view.areasToUpdateLayer.addChild(areaToUpdate)
						# R.view.mainLayer.activate()
					else
						continue
			return

		# load callback: add loaded RItems
		loadCallback: (results)=>
			console.log "load callback"
			console.log P.project.activeLayer.name

			if not @checkError(results) then return

			if results.hasOwnProperty('message') && results.message == 'no_paths'
				@dispatchLoadFinished()
				return

			@setMe(results.user)

			if results.rasters? then R.rasterizer.load(results.rasters, results.qZoom)

			# if R.rasterizerMode then R.removeItemsToUpdate(results.itemsToUpdate)

			@removeDeletedItems(results.deletedItems)

			itemsToLoad = @parseNewItems(results.items)

			@createNewItems(itemsToLoad)


			R.rasterizer.setQZoomToUpdate(results.qZoom)

			if not results.rasters? or results.rasters.length==0
				R.rasterizer.rasterizeAreasToUpdate()

			Item.Div.updateZIndex(R.sortedDivs)

			if not R.rasterizerMode

				# update areas to update (draw items which lie on those areas)
				# for pk, rectangle of R.areasToUpdate
				# 	if rectangle.intersects(P.view.bounds)
				# 		R.updateView()
				# 		break

				# loadFonts()
				# P.view.draw()
				# updateView()

				@hideLoadingBar()

				@dispatchLoadFinished()

			if typeof window.saveOnServer == "function"
				console.log "rasterizeAndSaveOnServer"
				R.rasterizeAndSaveOnServer()

			# R.stopLoadingBar()
			return

		# check for any error in an ajax callback and display the appropriate error message
		# @return [Boolean] true if there was no error, false otherwise
		checkError: (result)->
			# console.log result
			if not result? then return true
			if result.state == 'not_logged_in'
				R.alertManager.alert("You must be logged in to update drawings to the database.", "info")
				return false
			if result.state == 'error'
				if result.message == 'invalid_url'
					R.alertManager.alert("Your URL is invalid or does not point to an existing page.", "error")
				else
					R.alertManager.alert("Error: " + result.message, "error")
				return false
			else if result.state == 'system_error'
				console.log result.message
				return false
			return true

		### Debug methods ###

		updateDebugPaths: (limit, bounds, t, l, b, r)->
			@unloadRectangle?.remove()
			@unloadRectangle = new P.Path.Rectangle(limit)
			@unloadRectangle.name = '@debug load unload rectangle'
			@unloadRectangle.strokeWidth = 1
			@unloadRectangle.strokeColor = 'red'
			@unloadRectangle.dashArray = [10, 4]
			R.view.debugLayer.addChild(@unloadRectangle)

			@viewRectangle?.remove()
			@viewRectangle = new P.Path.Rectangle(bounds)
			@viewRectangle.name = '@debug load view rectangle'
			@viewRectangle.strokeWidth = 1
			@viewRectangle.strokeColor = 'blue'
			R.view.debugLayer.addChild(@viewRectangle)

			@limitRectangle?.remove()
			@limitRectangle = new P.Path.Rectangle(new P.Point(l, t), new P.Point(r, b))
			@limitRectangle.name = '@debug load limit rectangle'
			@limitRectangle.strokeWidth = 2
			@limitRectangle.strokeColor = 'blue'
			@limitRectangle.dashArray = [10, 4]
			R.view.debugLayer.addChild(@limitRectangle)
			return

		updateDebugArea: (area)->
			area.rectangle.strokeColor = 'red'
			@removeDebugRectangle(area.rectangle)
			return

		removeDebugRectangle: (rectangle)->
			removeRect = ()-> rectangle.remove()
			setTimeout(removeRect, 1500)
			return

		createAreaDebugRectangle: (x, y, scale)->
			areaRectangle = new P.Path.Rectangle(x, y, scale, scale)
			areaRectangle.name = '@debug load area rectangle'
			areaRectangle.strokeWidth = 1
			areaRectangle.strokeColor = 'green'
			R.view.debugLayer.addChild(areaRectangle)
			area.rectangle = areaRectangle
			return

		# this.benchmark_load = ()->
		# 	bounds = P.view.bounds
		# 	scale = R.scale
		# 	t = Utils.floorToMultiple(bounds.top, scale)
		# 	l = Utils.floorToMultiple(bounds.left, scale)
		# 	b = Utils.floorToMultiple(bounds.bottom, scale)
		# 	r = Utils.floorToMultiple(bounds.right, scale)

		# 	# add areas to load
		# 	areasToLoad = []

		# 	for x in [l .. r] by scale
		# 		for y in [t .. b] by scale
		# 			planet = projectToPlanet(new P.Point(x,y))
		# 			pos = projectToPosOnPlanet(new P.Point(x,y))

		# 			area = { pos: pos, planet: planet, x: x/1000, y: y/1000 }

		# 			areasToLoad.push(area)

		# 	console.log "areasToLoad: "
		# 	console.log areasToLoad

		# 	Dajaxice.draw.benchmark_load(R.loader.checkError, { areasToLoad: areasToLoad })
		# 	return

	return Loader
