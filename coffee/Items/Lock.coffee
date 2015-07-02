define [ 'Items/Item' ], (Item) ->

	# Lock are locked area which can only be modified by their author
	# all RItems on the area are also locked, and can be unlocked if the user drags them outside the div

	# There are different Locks:
	# - Lock: a simple Lock which just locks the area and the items underneath, and displays a popover with a message when the user clicks on it
	# - Link: extends Lock but works as a link: the one who clicks on it is redirected to the website
	# - RWebsite:
	#    - extends Lock and provide the author a special website adresse
	#    - the owner of the site can choose a few options: "restrict area" and "hide toolbar"
	#    - a user going to a site with the "restricted area" option can not go outside the area
	#    - the tool bar will be hidden to users navigating to site with the "hide toolbar" option
	# - RVideogame:
	#    - a video game is an area which can interact with other RItems (very experimental)
	#    - video games are always loaded entirely (the whole area is loaded at once with its items)

	# an Lock can be set in background mode ({Lock#updateBackgroundMode}):
	# - this hide the jQuery div and display a equivalent rectangle on the paper project instead (named controlPath in the code)
	# - it is usefull to add and edit items on the area
	#

	class Lock extends Item
		@label = 'Lock'
		@object_type = 'lock'

		@initialize: (rectangle)->
			submit = (data)->
				switch data.object_type
					when 'lock'
						lock = new Lock(rectangle, data)
					when 'website'
						lock = new Website(rectangle, data)
					when 'video-game'
						lock = new VideoGame(rectangle, data)
					when 'link'
						lock = new Link(rectangle, data)
				lock.save(true)
				lock.update('rectangle') 	# update to add items which are under the lock
				lock.select()
				return
			R.RModal.initialize('Create a locked area', submit)

			radioButtons = [
				{ value: 'lock', checked: true, label: 'Create simple lock', submitShortcut: true, linked: [] }
				{ value: 'link', checked: false, label: 'Create link', linked: ['linkName', 'url', 'message'] }
				{ value: 'website', checked: false, label: 'Create  website (® x2)', linked: ['restrictArea', 'disableToolbar', 'siteName'] }
				# { value: 'video-game', checked: false, label: 'Create  video game (® x2)', linked: ['message'] }
			]

			radioGroupJ = R.RModal.addRadioGroup('object_type', radioButtons)
			R.RModal.addCheckbox('restrictArea', 'Restrict area', "Users visiting your website will not be able to go out of the site boundaries.")
			R.RModal.addCheckbox('disableToolbar', 'Disable toolbar', "Users will not have access to the toolbar on your site.")
			R.RModal.addTextInput('linkName', 'Site name', 'text', '', 'Site name')
			R.RModal.addTextInput('url', 'http://', 'url', 'url', 'URL')
			siteURLJ = $("""
				<div class="form-group siteName">
					<label for="modalSiteName">Site name</label>
					<div class="input-group">
						<span class="input-group-addon">romanesco.city/#</span>
						<input id="modalSiteName" type="text" class="name form-control" placeholder="Site name">
					</div>
				</div>
			""")
			siteUrlExtractor = (data, siteURLJ)->
				data.siteURL = siteURLJ.find("#modalSiteName").val()
				return true
			R.RModal.addCustomContent('siteName', siteURLJ, siteUrlExtractor)
			R.RModal.addTextInput('message', 'Enter the message you want others to see when they look at this link.', 'text', '', 'Message', true)

			radioGroupJ.click (event)->
				lockType = radioGroupJ.find('input[type=radio][name=object_type]:checked')[0].value
				for radioButton in radioButtons
					if radioButton.value == lockType
						for name, extractor of R.RModal.extractors
							if radioButton.linked.indexOf(name) >= 0
								extractor.div.show()
							else if name != 'object_type'
								extractor.div.hide()
				return
			radioGroupJ.click()
			R.RModal.show()
			radioGroupJ.find('input:first').focus()
			return

		@highlightStage: (color)->
			R.view.backgroundRectangle = new P.Path.Rectangle(P.view.bounds)
			R.view.backgroundRectangle.fillColor = color
			R.view.backgroundRectangle.sendToBack()
			return

		@unhighlightStage: ()->
			R.view.backgroundRectangle?.remove()
			R.view.backgroundRectangle = null
			return

		@highlightValidity: (item)->
			@validatePosition(item, null, true)
			return

		# - check if *bounds* is valid: does not intersect with a planet nor a lock
		# - if bounds is not defined, the bounds of the item will be used
		# - cancel all highlights
		# - if the item has been dragged over a lock or out of a lock: highlight (if *highlight*) or update the items accordingly
		# @param item [Item] the item to check
		# @param bounds [Paper P.Rectangle] (optional) the bounds to consider, item's bounds are used if *bounds* is null
		# @param highlight [boolean] (optional) whether to highlight or update the items
		@validatePosition: (item, bounds=null, highlight=false)->

			if item.getDrawingBounds?() > R.rasterizer.maxArea()
				if highlight
					R.alertManager.alert('The path is too big.', 'Warning')
				else
					return false

			bounds ?= item.getBounds()

			R.limitPathV?.strokeColor = 'green'
			R.limitPathH?.strokeColor = 'green'

			for lock in R.locks
				lock.unhighlight()

			@unhighlightStage()

			if R.view.grid.rectangleOverlapsTwoPlanets(bounds)
				if highlight
					R.limitPathV?.strokeColor = 'red'
					R.limitPathH?.strokeColor = 'red'
				else
					return false

			locks = Lock.getLocksWhichIntersect(bounds)

			for lock in locks
				if Lock.prototype.isPrototypeOf(item)
					if item != lock
						if highlight
							lock.highlight('red')
						else
							return false
				else
					if lock.getBounds().contains(bounds) and R.me == lock.owner
						if item.lock != lock
							if highlight
								lock.highlight('green')
							else
								lock.addItem(item)
					else
						if highlight
							lock.highlight('red')
						else
							return false

			if locks.length == 0
				if item.lock?
					if highlight
						@highlightStage('green')
					else
						Item.addItemToStage(item)

			# if item is a lock: check that it still contains its children
			if Lock.prototype.isPrototypeOf(item)
				if not item.containsChildren()
					if highlight
						item.highlight('red')
					else
						return false
			return true
		# # @param point [Paper point] the point to test
		# # @return [Lock] the intersecting lock or null
		# @intersectPoint: (point)->
		# 	for lock in R.locks
		# 		if lock.getBounds().contains(point)
		# 			return R.items[lock.pk]
		# 	return null

		# # @param rectangle [Paper P.Rectangle] the rectangle to test
		# # @return [Boolean] whether it intersects a lock
		# @intersectsRectangle: (rectangle)->
		# 	return @intersectRectangle(rectangle).length>0

		# @param rectangle [Paper P.Rectangle] the rectangle to test
		# @return [Array<Lock>] the locks
		@getLockWhichContains: (rectangle)->
			for lock in R.locks
				if lock.getBounds().contains(rectangle)
					return lock
			return null

		# @param rectangle [Paper P.Rectangle] the rectangle to test
		# @return [Array<Lock>] the intersecting locks
		@getLocksWhichIntersect: (rectangle)->
			locks = []
			for lock in R.locks
				if lock.getBounds().intersects(rectangle)
					locks.push(lock)
			return locks

		# @getSelectedLock: (warnIfMultipleLocksSelected)->
		# 	lock = null
		# 	for item in R.selectedItems
		# 		if Lock.prototype.isPrototypeOf(item)
		# 			if lock != null and warnIfMultipleLocksSelected
		# 				R.alertManager.alert "Two locks are selected, please choose a single lock.", "Warning"
		# 				return null
		# 			lock = item
		# 	return lock

		@initializeParameters: ()->
			parameters = super()

			strokeWidth = $.extend(true, {}, R.parameters.strokeWidth)
			strokeWidth.default = 1
			strokeColor = $.extend(true, {}, R.parameters.strokeColor)
			strokeColor.default = 'black'
			fillColor = $.extend(true, {}, R.parameters.fillColor)
			fillColor.default = 'white'
			fillColor.defaultCheck = true
			fillColor.defaultFunction = null

			parameters['Style'].strokeWidth = strokeWidth
			parameters['Style'].strokeColor = strokeColor
			parameters['Style'].fillColor = fillColor
			parameters['Options'] =
				addModule:
					type: 'button'
					label: 'Link module'
					default: ()->
						for item in R.selectedItems
							if Lock.prototype.isPrototypeOf(item)
								item.askForModule()
						return
					initializeController: (controller)->
						spanJ = $(controller.domElement).find('.property-name')
						firstItem = R.selectedItems[0]
						if firstItem?.data?.moduleName?
							spanJ.text('Change module (' + firstItem.data.moduleName + ')')
						return

			return parameters

		@parameters = @initializeParameters()

		constructor: (@rectangle, @data=null, @pk=null, @owner=null, @date, @modulePk) ->
			super(@data, @pk)

			R.locks.push(@)

			@group.name = 'lock group'

			@draw()
			R.view.lockLayer.addChild(@group)

			# create special list to contains children paths
			@sortedPaths = []
			@sortedDivs = []

			@itemListsJ = R.templatesJ.find(".layer").clone()
			pkString = '' + (@pk or @id)
			pkString = pkString.substring(pkString.length-3)
			title = "Lock ..." + pkString
			if @owner then title += " of " + @owner
			titleJ = @itemListsJ.find(".title")
			titleJ.text(title)
			titleJ.click (event)=>
				@itemListsJ.toggleClass('closed')
				if not event.shiftKey
					R.tools.select.deselectAll()()
				@select()
				return

			@itemListsJ.find('.rDiv-list').sortable( stop: Item.zIndexSortStop, delay: 250 )
			@itemListsJ.find('.rPath-list').sortable( stop: Item.zIndexSortStop, delay: 250 )

			@itemListsJ.mouseover (event)=>
				@highlight()
				return
			@itemListsJ.mouseout (event)=>
				@unhighlight()
				return

			R.sidebar.itemListsJ.prepend(@itemListsJ)
			@itemListsJ = R.sidebar.itemListsJ.find(".layer:first")

			# check if items are under this lock
			for pk, item in R.items
				if Lock.prototype.isPrototypeOf(item)
					continue
				if item.getBounds().intersects(@rectangle)
					@addItem(item)

			# check if the lock must be entirely loaded
			if @data?.loadEntireArea
				R.view.entireAreas.push(@)

			if @modulePk?
				Dajaxice.draw.getModuleSource(R.initializeModule, { pk: @modulePk, accepted: true })

			return

		initializeModule: ()->
			if not R.loader.checkError(result) then return
			module = JSON.parse(result.module)
			R.parentLock = @
			R.runModule(module)
			return

		draw: ()->
			if @drawing? then @drawing.remove()
			if @raster? then @raster.remove()
			@raster = null
			@drawing = new P.Path.Rectangle(@rectangle)
			@drawing.name = 'rlock background'
			@drawing.strokeWidth = if @data.strokeWidth>0 then @data.strokeWidth else 1
			@drawing.strokeColor = if @data.strokeColor? then @data.strokeColor else 'black'
			@drawing.fillColor = @data.fillColor or new P.Color(255,255,255,0.5)
			@drawing.controller = @
			@group.addChild(@drawing)
			return

		# @param name [String] the name of the value to change
		# @param value [Anything] the new value
		# @param updateGUI [Boolean] (optional, default is false) whether to update the GUI (parameters bar), true when called from SetParameterCommand
		setParameter: (name, value, updateGUI, update)->
			super(name, value, updateGUI, update)
			switch name
				when 'strokeWidth', 'strokeColor', 'fillColor'
					if not @raster?
						@drawing[name] = @data[name]
					else
						@draw()
			return

		save: (addCreateCommand=true) ->

			if Grid.rectangleOverlapsTwoPlanets(@rectangle)
				return

			if @rectangle.area == 0
				@remove()
				R.alertManager.alert "Error: your box is not valid.", "error"
				return

			data = @getData()

			siteData =
				restrictArea: data.restrictArea
				disableToolbar: data.disableToolbar
				loadEntireArea: data.loadEntireArea

			args =
				city: city: R.city
				box: Utils.CS.boxFromRectangle(@rectangle)
				object_type: @constructor.object_type
				data: JSON.stringify(data)
				siteData: JSON.stringify(siteData)
				name: data.name
			Dajaxice.draw.saveBox( @saveCallback, args)
			super
			return

		# check if the save was successful and set @pk if it is
		saveCallback: (result)=>
			R.loader.checkError(result)
			if not result.pk?  		# if @pk is null, the path was not saved, do not set pk nor rasterize
				@remove()
				return

			@owner = result.owner
			@setPK(result.pk)

			if @updateAfterSave?
				@update(@updateAfterSave)
			super
			return

		addUpdateFunctionAndArguments: (args, type)->
			for item in @children()
				item.addUpdateFunctionAndArguments(args, type)
			return

		update: (type) =>
			if not @pk?
				@updateAfterSave = type
				return
			delete @updateAfterSave

			# check if position is valid
			if Grid.rectangleOverlapsTwoPlanets(@rectangle)
				return

			# initialize data to be saved
			updateBoxArgs =
				box: Utils.CS.boxFromRectangle(@rectangle)
				pk: @pk
				object_type: @object_type
				name: @data.name
				data: @getStringifiedData()
				updateType: type 		# not used anymore
				modulePk: @modulePk
				# message: @data.message

			# Dajaxice.draw.updateBox( @updateCallback, args )
			args = []
			args.push( function: 'updateBox', arguments: updateBoxArgs )

			if type == 'position' or type == 'rectangle'
				itemsToUpdate = if type == 'position' then @children() else []

				# check if new items are inside @rectangle
				for pk, item of R.items
					if not Lock.prototype.isPrototypeOf(item)
						if item.lock != @ and @rectangle.contains(item.getBounds())
							@addItem(item)
							itemsToUpdate.push(item)

				for item in itemsToUpdate
					args.push( function: item.getUpdateFunction(), arguments: item.getUpdateArguments() )

			Dajaxice.draw.multipleCalls( @updateCallback, functionsAndArguments: args)
			return

		updateCallback: (results)->
			for result in results
				R.loader.checkError(result)
			return

		# called when user deletes the item by pressing delete key or from the gui
		# @delete() removes the item and delete it in the database
		# @remove() just removes visually
		delete: () ->
			@remove()
			if not @pk? then return
			if not @socketAction then Dajaxice.draw.deleteBox( R.loader.checkError, { 'pk': @pk } )
			super
			return

		setRectangle: (rectangle, update=true)->
			super(rectangle, update)
			Utils.Rectangle.updatePathRectangle(@drawing, rectangle)
			return

		moveTo: (position, update)->
			delta = position.subtract(@rectangle.center)
			for item in @children()
				item.rectangle.center.x += delta.x
				item.rectangle.center.y += delta.y
				if Item.Div.prototype.isPrototypeOf(item)
					item.updateTransform()
			super(position, update)
			return

		# check if lock contains its children
		containsChildren: ()->
			for item in @children()
				if not @rectangle.contains(item.getBounds())
					return false
			return true

		showChildren: ()->
			for item in @children()
				item.group?.visible = true
			return

		# can not select a lock which the user does not own
		select: (updateOptions=true) =>
			if not super(updateOptions) or @owner != R.me then return false
			for item in @children()
				item.deselect()
			return true

		remove: () ->
			for path in @children()
				@removeItem(path)

			@itemListsJ.remove()
			@itemListsJ = null
			Utils.Array.remove(R.locks, @)
			@drawing = null
			super
			return

		children: ()->
			return @sortedDivs.concat(@sortedPaths)

		addItem: (item)->
			Item.addItemTo(item, @)
			item.lock = @
			return

		removeItem: (item)->
			Item.addItemToStage(item)
			item.lock = null
			return

		highlight: (color)->
			super()
			if color
				@highlightRectangle.fillColor = color
				@highlightRectangle.strokeColor = color
				@highlightRectangle.dashArray = []
			return

		askForModule: ()->
			Dajaxice.draw.getModuleList(@createSelectModuleModal)
			return

		createSelectModuleModal: (result)->
			# R.codeEditor.createModuleEditorModal(result, @addModule)
			# R.RModal.modalJ.find("tr.module[data-pk='#{@modulePk}']").css('background-color': 'rgba(213, 18, 18, 0.54)')
			return

		addModule: ()->
			# @modulePk = $(this).attr("data-pk")
			# @data.moduleName = $(this).attr("data-name")
			# Dajaxice.draw.updateBox( R.loader.checkError, { pk: @pk, modulePk: @modulePk } )
			return

	# RWebsite:
	#  - extends Lock and provide the author a special website adresse
	#  - the owner of the site can choose a few options: "restrict area" and "hide toolbar"
	#  - a user going to a site with the "restricted area" option can not go outside the area
	#  - the tool bar will be hidden to users navigating to site with the "hide toolbar" option
	class Website extends Lock
		@label = 'Website'
		@object_type = 'website'

		# overload {Div#constructor}
		# the mouse interaction is modified to enable user navigation (the user can scroll the view by dragging on the website area)
		constructor: (@rectangle, @data=null, @pk=null, @owner=null, date=null) ->
			super(@rectangle, @data, @pk, @owner, date)
			return

		# todo: remove
		# can not enable interaction if the user not owner and is website
		enableInteraction: () ->
			return

	# RVideogame:
	# - a video game is an area which can interact with other RItems (very experimental)
	# - video games are always loaded entirely (the whole area is loaded at the same time with its items)
	# this a default videogame class which must be redefined in custom scripts
	class VideoGame extends Lock
		@label = 'Video game'
		@object_type = 'video-game'

		# overload {Div#constructor}
		# the mouse interaction is modified to enable user navigation (the user can scroll the view by dragging on the videogame area)
		constructor: (@rectangle, @data=null, @pk=null, @owner=null, date=null) ->
			super(@rectangle, @data, @pk, @owner, date)
			@currentCheckpoint = -1
			@checkpoints = []
			return

		# overload {Div#getData} + set data.loadEntireArea to true (we want videogames to load entirely)
		getData: ()->
			data = super()
			data.loadEntireArea = true
			return data

		# todo: remove
		# redefine {Lock#enableInteraction}
		enableInteraction: () ->
			return

		# initialize the video game gui (does nothing for now)
		initGUI: ()->
			console.log "Gui init"
			return

		# update game machanics:
		# called at each frame (currently by the tool event, but should move to main.coffee in the onFrame event)
		# @param tool [RTool] the car tool to get the car position
		updateGame: (tool)->
			for checkpoint in @checkpoints
				if checkpoint.contains(tool.car.position)
					if @currentCheckpoint == checkpoint.data.checkpointNumber-1
						@currentCheckpoint = checkpoint.data.checkpointNumber
						if @currentCheckpoint == 0
							@startTime = Date.now()
							R.alertManager.alert "Game started, go go go!", "success"
						else
							R.alertManager.alert "Checkpoint " + @currentCheckpoint + " passed!", "success"
					if @currentCheckpoint == @checkpoints.length-1
						@finishGame()
			return

		# ends the game: called when user passes the last checkpoint!
		finishGame: ()->
			time = (Date.now() - @startTime)/1000
			R.alertManager.alert "You won ! Your time is: " + time.toFixed(2) + " seconds.", "success"
			@currentCheckpoint = -1
			return

	# todo: make the link enabled even with the move tool?
	# Link: extends Lock but works as a link: the one who clicks on it is redirected to the website
	class Link extends Lock
		@label = 'Link'
		@modalTitle = "Insert a hyperlink"
		@modalTitleUpdate = "Modify your link"
		@object_type = 'link'

		@initializeParameters: ()->
			parameters = super()
			delete parameters['Lock']
			return parameters

		@parameters = @initializeParameters()

		constructor: (@rectangle, @data=null, @pk=null, @owner=null, date=null) ->
			super(@rectangle, @data, @pk, @owner, date)

			@linkJ?.click (event)=>
				if @linkJ.attr("href").indexOf("http://romanesc.co/#") == 0
					location = @linkJ.attr("href").replace("http://romanesc.co/#", "")
					pos = location.split(',')
					p = new P.Point()
					p.x = parseFloat(pos[0])
					p.y = parseFloat(pos[1])
					View.moveTo(p, 1000)
					event.preventDefault()
					return false
				return
			return

	Item.Lock = Lock
	Item.Link = Link
	Item.Website = Website
	Item.VideoGame = VideoGame
	return Lock
