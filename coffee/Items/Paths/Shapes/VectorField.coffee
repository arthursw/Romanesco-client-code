define ['Utils/Utils', 'Items/Paths/Shapes/Shape'], (Utils, Shape) ->


	class VectorField extends Shape
		@Shape = P.Path.Rectangle
		@label = 'Vector field'
		@description = "Creates a vector field."
		@squareByDefault = false

		@initializeParameters: ()->
			parameters = super()

			parameters['Style'].strokeWidth.default = 1
			parameters['Style'].strokeColor.default = 'black'
			parameters['Style'].strokeColor.defaultFunction = null

			parameters['Parameters'] ?= {}
			# parameters['Parameters'].effectType =
			# 	default: 'horizontalLines'
			# 	values: ['horizontalLines', 'verticalLines']
			# 	label: 'Effect type'
			parameters['Parameters'].nLines =
				type: 'slider'
				label: 'nLines'
				min: 10
				max: 100
				default: 50
			parameters['Parameters'].nLineSteps =
				type: 'slider'
				label: 'nLineSteps'
				min: 10
				max: 100
				default: 50
			parameters['Parameters'].strength =
				type: 'slider'
				label: 'strength'
				min: 0
				max: 1000
				default: 300
			parameters['Parameters'].nForces =
				type: 'slider'
				label: 'nForces'
				min: 1
				max: 10
				default: 3
			parameters['Parameters'].quadratic =
				type: 'checkbox'
				label: 'quadratic'
				default: true
			parameters['Parameters'].forceMean =
				type: 'slider'
				label: 'forceMean'
				min: -100
				max: 100
				default: 0
			parameters['Parameters'].forceSigma =
				type: 'slider'
				label: 'forceSigma'
				min: 0
				max: 100
				default: 30
			parameters['Parameters'].closestForce =
				type: 'checkbox'
				label: 'closestForce'
				default: false
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		# animted paths must be initialized
		initialize: ()->
			return

		initializeField: ()->
			@forces = []
			for i in [1 .. @data.nForces]
				circle = @addPath(new P.Path.Circle(@rectangle.topLeft.add(@rectangle.size.multiply(P.Point.random())), 10))
				circle.fillColor = 'white'
				circle.onMouseDrag = (event)=>
					event.target.position = event.target.position.add(event.delta)
					@resetField()
					@updateField()
					return
				@forces.push(circle)

			@lines = []
			x = @rectangle.left
			y = @rectangle.top
			yStep = @rectangle.height / @data.nLines
			xStep = @rectangle.width / @data.nLineSteps
			for i in [1 .. @data.nLines]
				line = @addPath(new P.Path())
				for j in [1 .. @data.nLineSteps]
					line.add(x, y)
					x += xStep
				y += yStep
				x = @rectangle.left
				@lines.push(line)
			return

		resetField: ()->
			x = @rectangle.left
			y = @rectangle.top
			yStep = @rectangle.height / @data.nLines
			xStep = @rectangle.width / @data.nLineSteps
			for line in @lines
				for segment in line.segments
					segment.point.x = x
					segment.point.y = y
					x += xStep
				y += yStep
				x = @rectangle.left
			return

		updateField: ()->
			for line in @lines
				for segment in line.segments
					if @data.closestForce
						closestForceDistance = 1000000000
						closestForce = null
						for force in @forces
							forceDistance = force.position.getDistance(segment.point, true)
							if forceDistance < closestForceDistance
								closestForceDistance = forceDistance
								closestForce = force
						direction = segment.point.subtract(closestForce.position).normalize()
						if not @data.quadratic then closestForceDistance = Math.sqrt(closestForceDistance)
						strength = @data.strength * Utils.gaussian(@data.forceMean, @data.forceSigma, closestForceDistance)
						# segment.point = segment.point.add( direction.multiply( strength ) )
					else
						for force in @forces
							direction = segment.point.subtract(force.position)
							strength = @data.strength * Utils.gaussian(@data.forceMean, @data.forceSigma, direction.length)
							direction = direction.normalize()
							segment.point.y += direction.y * strength
							# segment.point = segment.point.add( direction.multiply( strength ) )
			return

		createShape: ()->
			# super()
			@shape = new P.Group()

			@initializeField()
			@updateField()

			# changed = false
			#
			# for key, value of @parameters
			#   if @data[key] != value
			#     changed = true
			#     break

			return

	return VectorField
