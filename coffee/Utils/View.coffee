define ['utils'], ()->
	View = {}

	## Move/scroll the romanesco view

	# Move the romanesco view to *pos*
	# @param pos [P.Point] destination
	# @param delay [Number] time of the animation to go to destination in millisecond
	View.moveTo = (pos, delay, addCommand=true) ->
		if not delay?
			somethingToLoad = View.moveBy(pos.subtract(P.view.center), addCommand)
		else
			# console.log pos
			# console.log delay
			initialPosition = P.view.center
			tween = new TWEEN.Tween( initialPosition ).to( pos, delay ).easing( TWEEN.Easing.Exponential.InOut ).onUpdate( ()->
				View.moveTo(this, addCommand)
				# console.log this.x + ', ' + this.y
				return
			).start()
		return somethingToLoad

	# Move the romanesco view from *delta*
	# if user is in a restricted area (a website or videogame with restrictedArea), the move will be constrained in this area
	# This method does:
	# - scroll the paper view
	# - update RDivs' positions
	# - update grid
	# - update R.entireArea (the area which must be kept loaded, in a video game or website)
	# - load entire area if we have a new entire area
	# - update websocket room
	# - update hash in 0.5 seconds
	# - set location in the general options
	# @param delta [P.Point]
	View.moveBy = (delta, addCommand=true) ->

		# if user is in a restricted area (a website or videogame with restrictedArea), the move will be constrained in this area
		if R.restrictedArea?

			# check if the restricted area contains P.view.center (if not, move to center)
			if not R.restrictedArea.contains(P.view.center)
				# delta = R.restrictedArea.center.subtract(P.view.size.multiply(0.5)).subtract(P.view.bounds.topLeft)
				delta = R.restrictedArea.center.subtract(P.view.center)
			else
				# test if new pos is still in restricted area
				newView = P.view.bounds.clone()
				newView.center.x += delta.x
				newView.center.y += delta.y

				# if it does not contain the view, change delta so that it contains it
				if not R.restrictedArea.contains(newView)

					restrictedAreaShrinked = R.restrictedArea.expand(P.view.size.multiply(-1)) # restricted area shrinked by P.view.size

					if restrictedAreaShrinked.width<0
						restrictedAreaShrinked.left = restrictedAreaShrinked.right = R.restrictedArea.center.x
					if restrictedAreaShrinked.height<0
						restrictedAreaShrinked.top = restrictedAreaShrinked.bottom = R.restrictedArea.center.y

					newView.center.x = Utils.clamp(restrictedAreaShrinked.left, newView.center.x, restrictedAreaShrinked.right)
					newView.center.y = Utils.clamp(restrictedAreaShrinked.top, newView.center.y, restrictedAreaShrinked.bottom)
					delta = newView.center.subtract(P.view.center)

		R.previousViewPosition ?= P.view.center

		# scroll the paper views
		P.project.P.view.scrollBy(new P.Point(delta.x, delta.y))
		# R.selectionProject.P.view.scrollBy(new P.Point(delta.x, delta.y))

		for div in R.divs 										# update RDivs' positions
			div.updateTransform()

		R.rasterizer.move()
		Grid.updateGrid() 											# update grid

		# update R.entireArea (the area which must be kept loaded, in a video game or website)
		# if the loaded entire areas contain the center of the view, it is the current entire area
		# R.entireArea [P.Rectangle]
		# R.entireAreas [array of RDiv] the array is updated when we load the RDivs (in ajax.coffee)
		# get the new entire area
		newEntireArea = null
		for area in R.entireAreas
			if area.getBounds().contains(P.project.P.view.center)
				newEntireArea = area
				break

		# update R.entireArea
		if not R.entireArea? and newEntireArea?
			R.entireArea = newEntireArea.getBounds()
		else if R.entireArea? and not newEntireArea?
			R.entireArea = null

		somethingToLoad = if newEntireArea? then R.load(R.entireArea) else R.load()

		R.updateRoom() 											# update websocket room

		Utils.deferredExecution(View.updateHash, 'updateHash', 500) 					# update hash in 500 milliseconds

		if addCommand
			addMoveCommand = ()->
				R.commandManager.add(new R.MoveViewCommand(R.previousViewPosition, P.view.center))
				R.previousViewPosition = null
				return
			Utils.deferredExecution(addMoveCommand, 'add move command')

		# R.willUpdateAreasToUpdate = true
		# Utils.deferredExecution(R.updateAreasToUpdate, 'updateAreasToUpdate', 500) 					# update areas to update in 500 milliseconds

		# for pk, rectangle of R.areasToUpdate
		# 	if rectangle.intersects(P.view.bounds)
		# 		R.updateView()
		# 		break

		# update location in sidebar
		R.controllerManager.folders['General'].controllers['location'].setValue('' + P.view.center.x.toFixed(2) + ',' + P.view.center.y.toFixed(2))

		return somethingToLoad

	## Hash

	# Update hash (the string after '#' in the url bar) according to the location of the (center of the) view
	# set *R.ignoreHashChange* flag to ignore this change in *window.onhashchange* callback
	View.updateHash = ()->
		R.ignoreHashChange = true
		prefix = ''
		if R.city.owner? and R.city.name? and R.city.owner != 'RomanescoOrg' and R.city.name != 'Romanesco'
			prefix = R.city.owner + '/' + R.city.name + '/'
		location.hash = prefix + P.view.center.x.toFixed(2) + ',' + P.view.center.y.toFixed(2)
		return

	# Update hash (the string after '#' in the url bar) according to the location of the (center of the) view
	# set *R.ignoreHashChange* flag to ignore this change in *window.onhashchange* callback
	window.onhashchange = (event) ->
		if R.ignoreHashChange
			R.ignoreHashChange = false
			return

		p = new P.Point()

		fields = location.hash.substr(1).split('/')

		if fields.length>=3
			owner = fields[0]
			name = fields[1]
			if R.city.name != name or R.city.owner != owner
				R.loadCity(name, owner)

		pos = _.last(fields).split(',')
		p.x = parseFloat(pos[0])
		p.y = parseFloat(pos[1])

		if not _.isFinite(p.x) then p.x = 0
		if not _.isFinite(p.y) then p.y = 0
		View.moveTo(p)
		return

	return View