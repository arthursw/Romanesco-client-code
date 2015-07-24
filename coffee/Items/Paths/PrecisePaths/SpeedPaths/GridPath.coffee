define ['Items/Paths/PrecisePaths/SpeedPaths/SpeedPath'], (SpeedPath) ->

	# The grid path is similar to the thickness path, but draws a grid along the path
	class GridPath extends SpeedPath
		@label = 'Grid path'
		@description = "Draws a grid along the path, the thickness of the grid being function of the speed of the drawing."

		@initializeParameters: ()->
			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Parameters'].step =
				type: 'slider'
				label: 'Step'
				min: 5
				max: 100
				default: 5
				simplified: 20
				step: 1
			parameters['Parameters'].minWidth =
				type: 'slider'
				label: 'Min width'
				min: 1
				max: 100
				default: 5
			parameters['Parameters'].maxWidth =
				type: 'slider'
				label: 'Max width'
				min: 1
				max: 250
				default: 200
			parameters['Parameters'].minSpeed =
				type: 'slider'
				label: 'Min speed'
				min: 1
				max: 250
				default: 1
			parameters['Parameters'].maxSpeed =
				type: 'slider'
				label: 'Max speed'
				min: 1
				max: 250
				default: 200
			parameters['Parameters'].nLines =
				type: 'slider'
				label: 'N lines'
				min: 1
				max: 5
				default: 2
				simplified: 2
				step: 1
			parameters['Parameters'].symmetric =
				type: 'dropdown'
				label: 'Symmetry'
				values: ['symmetric', 'top', 'bottom']
				default: 'top'
			parameters['Parameters'].speedForWidth =
				type: 'checkbox'
				label: 'Speed for width'
				default: true
			parameters['Parameters'].speedForLength =
				type: 'checkbox'
				label: 'Speed for length'
				default: false
			parameters['Parameters'].orthoLines =
				type: 'checkbox'
				label: 'Orthogonal lines'
				default: true
			parameters['Parameters'].lengthLines =
				type: 'checkbox'
				label: 'Length lines'
				default: true

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		beginDraw: ()->
			@initializeDrawing(false)

			if @data.lengthLines
				# create the required number of paths, and add them to the 'lines' array
				@lines = []
				nLines = @data.nLines
				if @data.symmetric == 'symmetric' then nLines *= 2
				for i in [1 .. nLines]
					@lines.push( @addPath() )

			@lastOffset = 0

			return

		updateDraw: (offset, step)->
			if not step then return

			speed = @speedAt(offset)

			# add a point at 'offset'
			addPoint = (offset, speed)=>
				point = @controlPath.getPointAt(offset)
				normal = @controlPath.getNormalAt(offset).normalize()

				# set the width of the step
				if @data.speedForWidth
					# map the speed to [@data.minWidth, @data.maxWidth]
					width = @data.minWidth + (@data.maxWidth - @data.minWidth) * speed / @constructor.maxSpeed
				else
					width = @data.minWidth

				# add the tangent lines (parallel or following the path)
				if @data.lengthLines
					divisor = if @data.nLines>1 then @data.nLines-1 else 1
					if @data.symmetric == 'symmetric'
						for line, i in @lines by 2
							@lines[i+0].add(point.add(normal.multiply(i*width*0.5/divisor)))
							@lines[i+1].add(point.add(normal.multiply(-i*width*0.5/divisor)))
					else
						if @data.symmetric == 'top'
							line.add(point.add(normal.multiply(i*width/divisor))) for line, i in @lines
						else if @data.symmetric == 'bottom'
							line.add(point.add(normal.multiply(-i*width/divisor))) for line, i in @lines

				# add the orthogonal lines
				if @data.orthoLines
					path = @addPath()
					delta = normal.multiply(width)
					switch @data.symmetric
						when 'symmetric'
							path.add(point.add(delta))
							path.add(point.subtract(delta))
						when 'top'
							path.add(point.add(delta))
							path.add(point)
						when 'bottom'
							path.add(point.subtract(delta))
							path.add(point)
				return

			# if @data.speedForLength: the drawing is not updated at each step, but the step length is function of the speed
			if not @data.speedForLength
				addPoint(offset, speed)
			else 	# @data.speedForLength

				# map 'speed' to the interval [@data.minSpeed, @data.maxSpeed]
				speed = @data.minSpeed + (speed / @constructor.maxSpeed) * (@data.maxSpeed - @data.minSpeed)

				# check when we must update the path (if the current position if greater than the last position we updated + speed)
				stepOffset = offset-@lastOffset

				if stepOffset>speed
					midOffset = (offset+@lastOffset)/2
					addPoint(midOffset, speed)
					@lastOffset = offset

			return

		endDraw: ()->
			return

	return GridPath
