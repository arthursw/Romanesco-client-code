

	# class FaceShape extends RShape
	# 	@Shape = P.Path.Rectangle
	# 	@label = 'Face generator'
	# 	# @iconURL = 'static/images/icons/inverted/spiral.png'
	# 	# @iconAlt = 'spiral'
	# 	@description = "Face generator, inspired by weird faces study by Matthias Dörfelt aka mokafolio."

	# 	parameters: ()->
	# 		parameters = super()

	# 		parameters['Parameters'] ?= {}
	# 		parameters['Parameters'].minRadius =
	# 			type: 'slider'
	# 			label: 'Minimum radius'
	# 			min: 0
	# 			max: 100
	# 			default: 0
	# 		parameters['Parameters'].nTurns =
	# 			type: 'slider'
	# 			label: 'Number of turns'
	# 			min: 1
	# 			max: 50
	# 			default: 10
	# 		parameters['Parameters'].nSides =
	# 			type: 'slider'
	# 			label: 'Sides'
	# 			min: 3
	# 			max: 100
	# 			default: 50

	# 		return parameters

	# 	createShape: ()->
	# 		@headShape = @addPath(new P.Path.Ellipse(@rectangle.expand(-20,-10)))

	# 		@headShape.flatten(50)
	# 		for segment in @headShape.segments
	# 			segment.point.x += Math.random()*20
	# 			segment.point.y += Math.random()*5
	# 			segment.handleIn += Math.random()*5
	# 			segment.handleOut += Math.random()*5

	# 		@headShape.smooth()

	# 		nozeShape = Math.random()

	# 		center = @rectangle.center
	# 		width = @rectangle.width
	# 		height = @rectangle.height

	# 		rangeRandMM = (min, max)->
	# 			return min + (max-min)*Math.random()

	# 		rangeRandC = (center, amplitude)->
	# 			return center + amplitude*(Math.random()-0.5)

	# 		# noze
	# 		if nozeShape < 0.333	# two nostrils
	# 			deltaX = 0.1*width + Math.random()*10
	# 			x = center.x - deltaX
	# 			y = center.y + rangeRandC(0, 5)
	# 			position = center.add(x, y)
	# 			size = new P.Size(Math.random()*5, Math.random()*5)
	# 			nozeLeft = @addPath(new P.Path.Ellipse(position, size))
	# 			position += 2*deltaX
	# 			size = new P.Size(Math.random()*5, Math.random()*5)
	# 			nozeRight = @addPath(new P.Path.Ellipse(position, size))
	# 		else if nozeShape < 0.666 	# noze toward left
	# 			noze = @addPath()
	# 			noze.add(center)
	# 			noze.add(center.add(Math.random()*15, Math.random()*5))
	# 			noze.add(center.add(0, rangeRandMM(5,10)))
	# 			noze.smooth()
	# 		else				 	# noze toward right
	# 			noze = @addPath()
	# 			noze.add(center)
	# 			noze.add(center.add(-Math.random()*15, Math.random()*5))
	# 			noze.add(center.add(0, rangeRandMM(15,20)))
	# 			noze.smooth()

	# 		# eyes
	# 		deltaX = rangeRandC(0, 0.1*width)
	# 		x = center.x - deltaX
	# 		y = @rectangle.top + width/3 + rangeRandC(0, 10)
	# 		position = new P.Point(x, y)
	# 		size = new P.Size(Math.max(Math.random()*30,deltaX), Math.random()*30)
	# 		eyeLeft = @addPath(new P.Path.Ellipse(position, size))
	# 		position.x += 2*deltaX

	# 		eyeRight = @addPath(new P.Path.Ellipse(position, size))

	# 		eyeRight.position.x += rangeRandC(0, 5)
	# 		eyeLeft.position.x += rangeRandC(0, 5)

	# 		for i in [1 .. eyeLeft.segments.length-1]
	# 			eyeLeft.segments[i].point.x += Math.random()*3
	# 			eyeLeft.segments[i].point.y += Math.random()*3
	# 			eyeRight.segments[i].point.x += Math.random()*3
	# 			eyeRight.segments[i].point.y += Math.random()*3
	# 		return


	# R.FaceShape = FaceShape
	# R.pathClasses.push(R.FaceShape)
