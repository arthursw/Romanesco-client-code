define ['utils'], ()->
	## Manage limits between planets

	Grid = {}
	# Test if *rectangle* overlaps two planets
	#
	# @param rectangle [P.Rectangle] rectangle to test
	# @return [Boolean] true if overlaps
	Grid.rectangleOverlapsTwoPlanets = (rectangle)->
		limit = R.getLimit()
		if ( rectangle.left < limit.x && rectangle.right > limit.x ) || ( rectangle.top < limit.y && rectangle.bottom > limit.y )
			return true
		return false

	# Test if *path* overlaps two planets
	#
	# @param path [Paper path] path to test
	# @return [Boolean] true if overlaps
	# R.pathOverlapsTwoPlanets = (path)->
	# 	limitPaths = R.getLimitPaths()
	# 	limitPathV = limitPaths.vertical
	# 	limitPathH = limitPaths.horizontal

	# 	if limitPathV?
	# 		intersections = path.getIntersections(limitPathV)
	# 		limitPathV.remove()
	# 		if intersections.length>0
	# 			return true

	# 	if limitPathH?
	# 		intersections = path.getIntersections(limitPathH)
	# 		limitPathH.remove()
	# 		if intersections.length>0
	# 			return true

	# 	return false

	Grid.updateLimitPaths = ()->
		limit = R.getLimit()

		R.limitPathV = null
		R.limitPathH = null

		if limit.x >= P.view.bounds.left and limit.x <= P.view.bounds.right
			R.limitPathV = new P.Path()
			R.limitPathV.name = 'limitPathV'
			R.limitPathV.strokeColor = 'green'
			R.limitPathV.strokeWidth = 5
			R.limitPathV.add(limit.x,P.view.bounds.top)
			R.limitPathV.add(limit.x,P.view.bounds.bottom)
			R.grid.addChild(R.limitPathV)

		if limit.y >= P.view.bounds.top and limit.y <= P.view.bounds.bottom
			R.limitPathH = new P.Path()
			R.limitPathH.name = 'limitPathH'
			R.limitPathH.strokeColor = 'green'
			R.limitPathH.strokeWidth = 5
			R.limitPathH.add(P.view.bounds.left, limit.y)
			R.limitPathH.add(P.view.bounds.right, limit.y)
			R.grid.addChild(R.limitPathH)

		return

	# Draw planet limits, and draw the grid if *R.displayGrid*
	# The grid size is equal to the snap, except when snap < 15, then it is set to 25
	# one line every 4 lines is thick and darker
	Grid.updateGrid = ()->

		# draw planet limits (thick green lines)
		R.grid.removeChildren()

		Grid.updateLimitPaths()

		if P.view.bounds.width > window.innerWidth or P.view.bounds.height > window.innerHeight
			halfSize = new P.Point(window.innerWidth*0.5, window.innerHeight*0.5)
			bounds = new P.Rectangle(P.view.center.subtract(halfSize), P.view.center.add(halfSize))
			boundsCompoundPath = new CompoundPath( children: [ new P.Path.Rectangle(P.view.bounds), new P.Path.Rectangle(bounds) ] )
			boundsCompoundPath.strokeScaling = false
			boundsCompoundPath.fillColor = 'rgba(0,0,0,0.1)'
			R.grid.addChild(boundsCompoundPath)

		if not R.displayGrid
			return

		# draw grid
		snap = Utils.Event.getSnap()
		bounds = Utils.Rectangle.expandRectangleToMultiple(P.view.bounds, snap)

		left = bounds.left
		top = bounds.top

		while left<bounds.right or top<bounds.bottom

			px = new P.Path()
			px.name = "grid px"
			py = new P.Path()
			px.name = "grid py"

			px.strokeColor = "#666666"
			if ( left / snap ) % 4 == 0
				px.strokeColor = "#000000"
				px.strokeWidth = 2

			py.strokeColor = "#666666"
			if ( top / snap ) % 4 == 0
				py.strokeColor = "#000000"
				py.strokeWidth = 2

			px.add(new P.Point(left, P.view.bounds.top))
			px.add(new P.Point(left, P.view.bounds.bottom))

			py.add(new P.Point(P.view.bounds.left, top))
			py.add(new P.Point(P.view.bounds.right, top))

			R.grid.addChild(px)
			R.grid.addChild(py)

			left += snap
			top += snap

		# t = Math.floor(P.view.bounds.top / R.scale)
		# l = Math.floor(P.view.bounds.left / R.scale)
		# b = Math.floor(P.view.bounds.bottom / R.scale)
		# r = Math.floor(P.view.bounds.right / R.scale)

		# pos = getTopLeftCorner()

		# planet = projectToPlanet( pos )
		# posOnPlanet = projectToPosOnPlanet( pos )

		# debug = false

		# snap = Utils.Event.getSnap()
		# if snap < 15 then snap = 15
		# if debug then snap = 250

		# # draw lines
		# n = 1
		# i = l
		# j = t
		# while i<r+1 or j<b+1

		# 	px = new P.Path()
		# 	px.name = "grid px"
		# 	py = new P.Path()
		# 	px.name = "grid py"

		# 	ijOnPlanet = projectToPosOnPlanet(new P.Point(i*R.scale,j*R.scale))

		# 	if ijOnPlanet.x == -180
		# 		px.strokeColor = "#00FF00"
		# 		px.strokeWidth = 5
		# 	else if n<4 # i-Math.floor(i)>0.0
		# 		px.strokeColor = "#666666"
		# 	else
		# 		px.strokeColor = "#000000"
		# 		px.strokeWidth = 2

		# 	if ijOnPlanet.y == -90
		# 		py.strokeColor = "#00FF00"
		# 		py.strokeWidth = 5
		# 	else if n<4 # j-Math.floor(j)>0.0
		# 		py.strokeColor = "#666666"
		# 	else
		# 		py.strokeColor = "#000000"
		# 		py.strokeWidth = 2

		# 	px.add(new P.Point(i*R.scale, P.view.bounds.top))
		# 	px.add(new P.Point(i*R.scale, P.view.bounds.bottom))

		# 	py.add(new P.Point(P.view.bounds.left, j*R.scale))
		# 	py.add(new P.Point(P.view.bounds.right, j*R.scale))

		# 	R.grid.addChild(px)
		# 	R.grid.addChild(py)

		# 	i += snap/R.scale
		# 	j += snap/R.scale

		# 	if n==4 then n=0
		# 	n++

		# if not debug then return

		# # draw position text if debug
		# i = l
		# while i<r+1
		# 	j = t
		# 	while j<b+1
		# 		x = i*R.scale
		# 		y = j*R.scale

		# 		planetText = new PointText(new P.Point(x-10,y-40))
		# 		planetText.justification = 'right'
		# 		planetText.fillColor = 'black'
		# 		p = projectToPlanet(new P.Point(i*R.scale,j*R.scale))
		# 		planetText.content = 'px: ' + Math.floor(p.x) + ', py: ' + Math.floor(p.y)
		# 		R.grid.addChild(planetText)
		# 		posText = new PointText(new P.Point(x-10,y-20))
		# 		posText.justification = 'right'
		# 		posText.fillColor = 'black'
		# 		p = projectToPosOnPlanet(new P.Point(i*R.scale,j*R.scale))
		# 		posText.content = 'x: ' + p.x.toFixed(2) + ', y: ' + p.y.toFixed(2)
		# 		R.grid.addChild(posText)


		# 		j += snap/R.scale

		# 	i += snap/R.scale
		return

	return Grid