define [
	'utils', 'RTool'
], (utils, RTool) ->

	# Enables to select RItems
	class SelectTool extends RTool

		@rname = 'Select'
		@description = ''
		@iconURL = 'cursor.png'
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'
			icon: 'cursor'

		# Paper hitOptions for hitTest function to check which items (corresponding to those criterias) are under a point
		@hitOptions =
			stroke: true
			fill: true
			handles: true
			segments: true
			curves: true
			selected: true
			tolerance: 5

		constructor: () ->
			super(true)
			@selectedItem = null 		# should be deprecated
			return

		select: (deselectItems=false, updateParameters=true)->
			# g.rasterizer.drawItems() 		# must not draw all items here since user can just wish to use an RMedia
			super(false, updateParameters)
			return

		updateParameters: ()->
			g.controllerManager.updateParametersForSelectedItems()
			return

		# Create selection rectangle path (remove if existed)
		# @param [Paper event] event containing down and current positions to draw the rectangle
		createSelectionRectangle: (event)->
			rectangle = new Rectangle(event.downPoint, event.point)

			if g.currentPaths[g.me]?
				g.updatePathRectangle(g.currentPaths[g.me], rectangle)
			else
				# g.currentPaths[g.me] = new Group()
				rectanglePath = new Path.Rectangle(rectangle)
				rectanglePath.name = 'select tool selection rectangle'
				rectanglePath.strokeColor = g.selectionBlue
				rectanglePath.strokeScaling = false
				rectanglePath.dashArray = [10, 4]
				# g.currentPaths[g.me].addChild(rectanglePath)

				g.selectionLayer.addChild(rectanglePath)
				g.currentPaths[g.me] = rectanglePath

			itemsToHighlight = []

			# Add all items which have bounds intersecting with the selection rectangle (1st version)
			for name, item of g.items
				item.unhighlight()
				bounds = item.getBounds()
				if bounds.intersects(rectangle)
					item.highlight()
					console.log item.highlightRectangle.index
					# rectanglePath = new Path.Rectangle(bounds)
					# rectanglePath.name = 'select tool selection rectangle highlight'
					# rectanglePath.strokeColor = 'red'
					# rectanglePath.dashArray = [10, 4]
					# g.currentPaths[g.me].addChild(rectanglePath)
				# if the user just clicked (not dragged a selection rectangle): just select the first item
				if rectangle.area == 0
					break
			return

		# Begin selection:
		# - perform hit test to see if there is any item under the mouse
		# - if user hits a path (not in selection group): begin select action (deselect other items by default (= remove selection group), or add to selection if shift pressed)
		# - otherwise: deselect other items (= remove selection group) and create selection rectangle
		# must be reshaped (right not impossible to add a group of RItems to the current selection group)
		begin: (event) ->
			if event.event.which == 2 then return 		# if the wheel button was clicked: return

			console.log 'begin select'
			g.logElapsedTime()

			# project = if g.selectionLayer.children.length == 0 then g.project else g.selectionProject

			# perform hit test to see if there is any item under the mouse
			path.prepareHitTest() for name, path of g.paths
			hitResult = g.project.hitTest(event.point, @constructor.hitOptions)
			path.finishHitTest() for name, path of g.paths

			if hitResult and hitResult.item.controller? 		# if user hits a path: select it
				@selectedItem = hitResult.item.controller

				if not event.modifiers.shift 	# if shift is not pressed: deselect previous items
					if g.selectedItems.length>0
						if g.selectedItems.indexOf(hitResult.item?.controller)<0
							g.commandManager.add(new g.DeselectCommand(), true)
					# else
					# 	if g.selectedDivs.length>0 then g.deselectAll()
				else
					g.tools['Screenshot'].checkRemoveScreenshotRectangle(hitResult.item.controller)

				hitResult.item.controller.beginSelect?(event)
			else 												# otherwise: remove selection group and create selection rectangle
				g.deselectAll()
				@createSelectionRectangle(event)

			g.logElapsedTime()

			return

		# Update selection:
		# - update selected RItems if there is no selection rectangle
		# - update selection rectangle if there is one
		update: (event) ->
			if not g.currentPaths[g.me] and @selectedItem? 			# update selected RItems if there is no selection rectangle
				@selectedItem.updateSelect(event)
				# selectedItems = g.selectedItems
				# if selectedItems.length == 1
				# 	selectedItems[0].updateSelect(event)
				# else
				# 	for item in selectedItems
				# 		item.updateMoveBy?(event)
			else 									# update selection rectangle if there is one
				@createSelectionRectangle(event)
			return

		# End selection:
		# - end selection action on selected RItems if there is no selection rectangle
		# - create selection group is there is a selection rectangle
		#   update parameters from selected RItems and remove selection rectangle
		end: (event) ->
			if not g.currentPaths[g.me] 		# end selection action on selected RItems if there is no selection rectangle
				# selectedItems = g.selectedItems
				# if selectedItems.length == 1
				@selectedItem.endSelect(event)
				@selectedItem = null
			else 								# create selection group is there is a selection rectangle

				rectangle = new Rectangle(event.downPoint, event.point)

				itemsToSelect = []
				locksToSelect = []

				# Add all items which have bounds intersecting with the selection rectangle (1st version)
				for name, item of g.items
					if item.getBounds().intersects(rectangle)
						if g.RLock.prototype.isPrototypeOf(item)
							locksToSelect.push(item)
						else
							itemsToSelect.push(item)

				if itemsToSelect.length == 0
					itemsToSelect = locksToSelect

				if itemsToSelect.length > 0

					# check if items all have the same parent
					itemsAreSiblings = true
					parent = itemsToSelect.first().group.parent
					for item in itemsToSelect
						if item.group.parent != parent
							itemsAreSiblings = false
							break

					# if items have different parents, remove children from itemsToSelect and add locks
					if not itemsAreSiblings
						# remove all lock children from itemsToSelect
						for lock in locksToSelect
							for child in lock.children()
								itemsToSelect.remove(child)

						# add locks to itemsToSelect
						itemsToSelect = itemsToSelect.concat(locksToSelect)

					# if the user just clicked (not dragged a selection rectangle): just select the first item
					if rectangle.area == 0 then itemsToSelect = [itemsToSelect.first()]

					g.commandManager.add(new g.SelectCommand(itemsToSelect), true)

					i = itemsToSelect.length-1
					while i>=0
						item = itemsToSelect[i]
						if not item.isSelected()
							itemsToSelect.remove(item)
						i--

				# Add all items which intersect with the selection rectangle (2nd version)

				# for item in project.activeLayer.children
				# 	bounds = item.bounds
				# 	if item.controller? and (rectangle.contains(bounds) or ( rectangle.intersects(bounds) and item.controller.controlPath?.getIntersections(g.currentPaths[g.me]).length>0 ))
				# 	# if item.controller? and rectangle.intersects(bounds)
				# 		g.pushIfAbsent(itemsToSelect, item.controller)

				# for item in itemsToSelect
				# 	item.select(false)

				# # update parameters
				# itemsToSelect = itemsToSelect.map( (item)-> return { tool: item.constructor, item: item } )
				# g.updateParameters(itemsToSelect)

				# for div in g.divs
				# 	if div.getBounds().intersects(rectangle)
				# 		div.select()

				# remove selection rectangle
				g.currentPaths[g.me].remove()
				delete g.currentPaths[g.me]
				for name, item of g.items
					item.unhighlight()

			console.log 'end select'
			g.logElapsedTime()
			return

		# Double click handler: send event to selected RItems
		doubleClick: (event) ->
			for item in g.selectedItems
				item.doubleClick?(event)
			return

		# Disable snap while drawnig a selection rectangle
		disableSnap: ()->
			return g.currentPaths[g.me]?

		keyUp: (event)->
			# - move selected RItem by delta if an arrow key was pressed (delta is function of special keys press)
			# - finish current path (if in polygon mode) if 'enter' or 'escape' was pressed
			# - select previous tool on space key up
			# - select 'Select' tool if key == 'v'
			# - delete selected item on 'delete' or 'backspace'
			if event.key in ['left', 'right', 'up', 'down']
				delta = if event.modifiers.shift then 50 else if event.modifiers.option then 5 else 1
			switch event.key
				when 'right'
					item.moveBy(new Point(delta,0), true) for item in g.selectedItems
				when 'left'
					item.moveBy(new Point(-delta,0), true) for item in g.selectedItems
				when 'up'
					item.moveBy(new Point(0,-delta), true) for item in g.selectedItems
				when 'down'
					item.moveBy(new Point(0,delta), true) for item in g.selectedItems
				when 'escape'
					g.deselectAll()
				when 'delete', 'backspace'
					selectedItems = g.selectedItems.slice()
					for item in selectedItems
						if item.selectionState?.segment?
							item.deletePointCommand()
						else
							item.deleteCommand()

			return

	return SelectTool