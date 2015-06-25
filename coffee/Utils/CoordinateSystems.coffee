define [], () ->

	CS = {}
	# Romansco relies on different coordinate systems:
	# - the paper view: corresponds to the canvas on the html document, top left corner of canvas is [0,0] and bottom left is [P.view.size.width, P.view.size.height]
	# - the paper project: the infinite space, 0,0 is the origin of the infinite space, from [-inf,-inf] to [inf,inf]
	# - the planet: the project positions are defined on a grid of cells of dimension [360*R.scale, 180*R.scale] (R.scale = 1000 by default)
	# 				the origin of the space [0,0] is in the middle of a cell (meaning the first top left limit will be at [-180*R.scale, -90*R.scale])
	# 				one cell correspond to a planet with two coordinates, objects in the database are stored and sorted in a planet (x,y) and then in a map
	# 				the map is defined within a rectangle {x: -180, y: -90, width: 360, height: 180} in GeoJson format

	# When loading/saving to the database: posOnPlanet <-> project

	# Get the planet on which *point* lies
	#
	# @param [P.Point] point to convert
	# @return [P.Point object] the planet on which *point* lies
	CS.projectToPlanet = (point)->
		planet = {}
		# if not point.x? and not point.y? then point = arrayToPoint(point)

		x = point.x / R.scale
		planet.x = Math.floor( ( x + 180 ) / 360 )

		y = point.y / R.scale
		planet.y = Math.floor( ( y + 90 ) / 180 )

		return planet

	# Get the position of *point* on *planet*
	#
	# @param point [P.Point] point to convert
	# @param planet [P.Point] planet to convert
	# @return [P.Point object] the position of *point* on the planet
	CS.projectToPosOnPlanet = (point, planet)->
		planet ?= CS.projectToPlanet(point)
		# if not point.x? and not point.y? then point = arrayToPoint(point)

		pos = {}
		pos.x = point.x/R.scale - 360*planet.x
		pos.y = point.y/R.scale - 180*planet.y

		return pos

	# Get an object { pos: pos, planet: planet } with the planet on which *point* lies and the position of *point* on this planet
	# This is the opposite of posOnPlanetToProject
	#
	# @param point [P.Point] point to convert
	# @return [{ pos: P.Point, planet: Planet }] the planet on which *point* lies and the position of *point* on the planet
	CS.projectToPlanetJson = (point)->
		planet = CS.projectToPlanet(point)
		pos = CS.projectToPosOnPlanet(point, planet)
		return { pos: pos, planet: planet }

	# Get the position in project coordinate system of *point* on *planet*
	# This is the opposite of projectToPlanetJson
	#
	# @param [P.Point] point to convert
	# @param [P.Point] planet to convert
	# @return [Paper point] the position of *point* on *planet*
	CS.posOnPlanetToProject = (point, planet)->
		if not point.x? and not point.y? then point = CS.arrayToPoint(point)
		x = planet.x*360+point.x
		y = planet.y*180+point.y
		x *= R.scale
		y *= R.scale
		return new P.Point(x,y)

	# @return [Paper point] point extracted from *array*
	CS.arrayToPoint = (array) ->
		return new P.Point(array)

	# @return [Array of Number] array extracted from *point*
	CS.pointToArray = (point) ->
		return [point.x, point.y]

	# @return [P.Point] object converted from paper point
	CS.pointToObj = (point) ->
		return { x: point.x, y: point.y }

	# @return [Paper point] the top left corner of the view [0,0] in project coordinates
	CS.getTopLeftCorner = ()->
		return P.view.viewToProject(new P.Point(0,0))

	# @return [Paper point] the point between *p1* and *p2*
	CS.midPoint = (p1, p2) ->
		return new P.Point( (p1.x+p2.x)*0.5, (p1.y+p2.y)*0.5 )

	# @return [P.Rectangle] *rectangle* in project coordinates
	CS.viewToProjectRectangle = (rectangle)->
		return new P.Rectangle(P.view.viewToProject(rectangle.topLeft), P.view.viewToProject(rectangle.bottomRight))

	# @return [P.Rectangle] *rectangle* in view coordinates
	CS.projectToViewRectangle = (rectangle)->
		return new P.Rectangle(P.view.projectToView(rectangle.topLeft), P.view.projectToView(rectangle.bottomRight))

	# @return [Paper point] topLeft point of the bottom right planet in project coordinates (this will be the origin of the limits)
	CS.getLimit = ()->
		planet = CS.projectToPlanet(CS.getTopLeftCorner())
		return CS.posOnPlanetToProject( new P.Point(-180,-90), new P.Point(planet.x+1, planet.y+1) )

	# get a GeoJson valid box in planet coordinates from *rectangle*
	# @param rectangle [Paper P.Rectangle] the rectangle to convert
	# @return [{ points:Array<Array<2 Numbers>>, planet: Object, tl: P.Point, br: P.Point }] the resulting object
	CS.boxFromRectangle = (rectangle)->
		# remove margin to ignore intersections of paths which are close to the edges

		planet = CS.pointToObj( CS.projectToPlanet(rectangle.topLeft) )

		tlOnPlanet = CS.projectToPosOnPlanet(rectangle.topLeft, planet)
		brOnPlanet = CS.projectToPosOnPlanet(rectangle.bottomRight, planet)

		points = []
		points.push(CS.pointToArray(tlOnPlanet))
		points.push(CS.pointToArray(CS.projectToPosOnPlanet(rectangle.topRight, planet)))
		points.push(CS.pointToArray(brOnPlanet))
		points.push(CS.pointToArray(CS.projectToPosOnPlanet(rectangle.bottomLeft, planet)))
		points.push(CS.pointToArray(tlOnPlanet))

		return { points:points, planet: CS.pointToObj(planet), tl: tlOnPlanet, br: brOnPlanet }

	# WARNING: not used, not tested
	# get a rectangle from a GeoJson valid box in planet coordinates
	# @param box [{ points:Array<Array<2 Numbers>>, planet: Object, tl: P.Point, br: P.Point }] the box to convert
	# @return [P.Rectangle] the resulting rectangle
	CS.rectangleFromBox = (box)->
		planet = new P.Point(box.planetX, box.planetY)

		tl = CS.posOnPlanetToProject(box.box.coordinates[0][0], planet)
		br = CS.posOnPlanetToProject(box.box.coordinates[0][2], planet)

		return new P.Rectangle(tl, br)

	CS.quantizeZoom = (zoom)->
		if zoom < 5
			zoom = 1
		else if zoom < 25
			zoom = 5
		else
			zoom = 25
		return zoom

	return CS