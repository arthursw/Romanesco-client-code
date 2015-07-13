define [ 'Items/Paths/PrecisePaths/StepPath' ], (StepPath) ->


	# Meander makes use of both the tangent and the normal of the control path to draw a spiral at each step
	# Many different versions can be derived from this one (some inspiration can be found here:
	# http://www.dreamstime.com/photos-images/meander-wave-ancient-greek-ornament.html )
	class Meander extends StepPath
		@label = 'Meander'
		@description = """As Karl Kerenyi pointed out, "the meander is the figure of a labyrinth in linear form".
		A meander or meandros (Greek: Μαίανδρος) is a decorative border constructed from a continuous line, shaped into a repeated motif.
		Such a design is also called the Greek fret or Greek key design, although these are modern designations.
		(source: http://en.wikipedia.org/wiki/Meander_(art))"""
		@iconURL = "static/images/icons/inverted/squareSpiral.png"

		# The thickness path adds 3 parameters in the options bar:
		# step: a number which defines the size of the steps along the control path
		# 		(@data.step is already defined in precise path, this will bind it to the options bar)
		# thickness: the thickness of the spirals
		# rsmooth: whether the path is smoothed or not (not that @data.smooth is already used
		# 			to define if one can edit the control path handles or if they are automatically set)

		@initializeParameters: ()->
			parameters = super()
			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 10
				max: 100
				default: 20
				simplified: 20
				step: 1
			parameters['Parameters'].thickness =
				type: 'slider'
				label: 'Thickness'
				min: 1
				max: 30
				default: 5
				step: 1
			parameters['Parameters'].rsmooth =
				type: 'checkbox'
				label: 'Smooth'
				default: false

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		beginDraw: ()->
			@initializeDrawing(false)
			@line = @addPath()
			@spiral = @addPath()
			return

		updateDraw: (offset, step)->
			if not step then return

			point = @controlPath.getPointAt(offset)
			normal = @controlPath.getNormalAt(offset).normalize()
			tangent = normal.rotate(90)

			@line.add(point)

			@spiral.add(point.add(normal.multiply(@data.thickness)))

	# line spiral
	#	|	|
	#	0   0---------------1
	#	|					|
	#	|	9-----------8	|
	#	|	|			|	|
	#	|	|	4---5	|	|
	#	|	|	|	|	|	|
	#	|	|	|	6---7	|
	#	|	|	|			|
	#	|	|	3-----------2
	#	|	|
	#	0   0---------------1
	#	|					|
	#	|	9-----------8	|
	#	|	|			|	|
	#	|	|	4---5	|	|
	#	|	|	|	|	|	|
	#	|	|	|	6---7	|
	#	|	|	|			|
	#	|	|	3-----------2
	#	|	|
	#	0   0---------------1
	#	|					|

			p1 = point.add(normal.multiply(@data.step))
			@spiral.add(p1)

			p2 = p1.add(tangent.multiply(@data.step-@data.thickness))
			@spiral.add(p2)

			p3 = p2.add(normal.multiply( -(@data.step-2*@data.thickness) ))
			@spiral.add(p3)

			p4 = p3.add(tangent.multiply( -(@data.step-3*@data.thickness) ))
			@spiral.add(p4)

			p5 = p4.add(normal.multiply( @data.thickness ))
			@spiral.add(p5)

			p6 = p5.add(tangent.multiply( @data.step-4*@data.thickness ))
			@spiral.add(p6)

			p7 = p6.add(normal.multiply( @data.step-4*@data.thickness ))
			@spiral.add(p7)

			p8 = p7.add(tangent.multiply( -(@data.step-3*@data.thickness) ))
			@spiral.add(p8)

			p9 = p8.add(normal.multiply( -(@data.step-2*@data.thickness) ))
			@spiral.add(p9)

			return

		endDraw: ()->
			if @data.rsmooth
				@spiral.smooth()
				@line.smooth()
			return

	return Meander
