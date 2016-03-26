scriptName = "spaghetti"

paper.project.clear()

bounds = paper.view.bounds
center = bounds.center

data = []
for i in [0 .. 100]
	data.push(Math.random())

point = center
radius = Math.random()*10
angle = Math.random()*360
for i in [0 .. 100]
	circle = new paper.Path.Circle(point, radius)
	angle += Math.random()*10
	newRadius = Math.random()*10
	delta = new paper.Point(length: radius+newRadius, angle: angle)
	point = point.add(delta) # paper.Point.random().multiply(bounds.width, bounds.height).add(bounds.topLeft)
	radius = newRadius
	circle.strokeColor = 'black'
	circle.strokeWidth = 1
#	console.log(delta)

	# path = new paper.Path()
	# for i in [0 .. 10]



		# path.add(point)
	# path.smooth()

#	path2 = new paper.Path()
#	path3 = new paper.Path()
	# for segment in path.segments
	# 	tangent = path.getTangentAt(segment.location.offset).normalize().multiply(500)
	# 	segment.handleIn = tangent
	# 	segment.handleOut = tangent.multiply(-1)
#		path2.add(segment)
#		path2.lastSegment.point = segment.point.add(new paper.Point(4,0))
#		path3.add(segment)
#		path2.lastSegment.point = segment.point.add(new paper.Point(0,4))

#	path.strokeColor = 'darkBlue'
#	path.strokeWidth = 3
#	path2.strokeColor = 'black'
#	path2.strokeWidth = 1
#	path3.strokeColor = 'black'
#	path3.strokeWidth = 1
