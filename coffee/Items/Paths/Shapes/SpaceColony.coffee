define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	class SpaceColony extends Shape
		@Shape = P.Path.Rectangle
		@label = 'Space colony'
		@description = "Space colony animation."
		@squareByDefault = false

		@initializeParameters: ()->
			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Style'].animate =
				type: 'checkbox'
				label: 'Animate'
				default: true
			parameters['Parameters'].delay =
				type: 'slider'
				label: 'Delay'
				min: 0
				max: 300
				default: 0
			parameters['Parameters'].nodeRadius =
				type: 'slider'
				label: 'Node radius'
				min: 1
				max: 100
				default: 4
			parameters['Parameters'].pointSelectionDist =
				type: 'slider'
				label: 'Selection dist'
				min: 1
				max: 300
				default: 35
			parameters['Parameters'].pointDeletionDist =
				type: 'slider'
				label: 'Deletion dist'
				min: 1
				max: 300
				default: 4
			parameters['Parameters'].nPoints =
				type: 'slider'
				label: 'Num. points'
				min: 100
				max: 1000
				default: 1000
			parameters['Parameters'].branching =
				type: 'slider'
				label: 'Branching'
				min: 0
				max: 100
				default: 50
			parameters['Parameters'].scaleTree =
				type: 'slider'
				label: 'Scale'
				min: 0
				max: 500
				default: 100
			parameters['Parameters'].pauseTree =
				type: 'checkbox'
				label: 'Pause'
				default: false
				onChange: ()-> item.data.pauseTree = !item.data.pauseTree for item in R.selectedItems; return

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		# animted paths must be initialized
		initialize: ()->
			@setAnimated(@data.animate)
			return

		createShape: ()->
			# @rectangle = paper.view.bounds
			super()

			@pointGroup?.remove()
			@nodeGroup?.remove()

			@pointGroup = new paper.Group()
			@nodeGroup = new paper.Group()

			@points = []
			@nodes = []

			@nFrame = 0
			@animating = true

			for i in [0 .. @data.nPoints]
				@points.push( point: new paper.Point.random().multiply(new paper.Point(@rectangle.size)).add(@rectangle.topLeft), closestNode: null)
			@points.push( point: @rectangle.center, closestNode: null)

			root =
				point: @rectangle.center
				age: 0
				alive: true
				growCount: 0
				growDirection: new paper.Point(0,0)
			root.parent = root
			@nodes.push( root )
			@aliveNodes = [root]

			@drawTree()

			@setAnimated(@data.animate)
			return

		drawTree: ()=>
			@pointGroup.removeChildren()
			@nodeGroup.removeChildren()

			for point in @points
				circle = new paper.Path.Circle(point.point, 2)
				circle.strokeWidth = 1
				circle.strokeColor = 'black'
				@pointGroup.addChild(circle)

			for node in @nodes
				path = new paper.Path()
				path.add(node.point)
				path.add(node.parent.point)
				path.strokeWidth = node.age
				path.strokeColor = if node.alive then 'purple' else 'black'
				path.strokeCap = 'round'
				@nodeGroup.addChild(path)
				node.age = 1 # 0.125

			return

		onFrame: (event)=>
			if (not @animating) or @data.pauseTree then return

			@nFrame++
			if @nFrame < @data.delay
				return
			else
				@nFrame = 0

			# for all points:
			#  - delete if too close to a node
			#  - update average direction of the closest node (and grow count)
			for point, i in @points
				point.closestNode = null
				point.closestNodeDistance = 0

				for node in @aliveNodes
					direction = point.point.subtract(node.point)
					distance = direction.length
					if distance < @data.pointDeletionDist
						@points[i] = null
					else if distance < @data.pointSelectionDist
						if not point.closestNode?
							point.closestNode = node
							point.closestNodeDistance = distance
						else if point.closestNodeDistance > distance
							point.closestNode = node
							point.closestNodeDistance = distance

				if point.closestNode?
					direction = point.point.subtract(point.closestNode.point)
					direction = direction.normalize()
					point.closestNode.growDirection = point.closestNode.growDirection.add(direction)
					point.closestNode.growCount++

			# remove null points
			@points = @points.filter (p)-> return p?

			# for all nodes: grow if growCount > 0
			nodeAdded = false
			newNodes = []
			newAliveNodes = []
			for node in @aliveNodes
				if node.growCount > 0

					averageDirection = node.growDirection.divide(node.growCount)
					averageDirection = averageDirection.normalize()

					newNode =
						parent: node
						point: node.point.add(averageDirection.multiply(@data.nodeRadius))
						growDirection: averageDirection
						growCount: 0
						age: 0
						alive: true

					newNodes.push(newNode)
					newAliveNodes.push(newNode)

					node.growCount = 0
					node.growDirection = new paper.Point(0, 0)
					nodeAdded = true
					newAliveNodes.push(node)
				else
					node.alive = false

			@aliveNodes = newAliveNodes
			@nodes = @nodes.concat(newNodes)

			if not nodeAdded
				@animating = false
				console.log "ANIMATION FINISHED"
			@drawTree()
			return

		# called at each frame event
		# this is the place where animated paths should be updated
		# problem: the points affect all nodes, not only the cloest one, resulting in lots of branching.
		onFrame2: (event)=>
			if not @animating then return

			@nFrame++
			if @nFrame < @data.delay
				return
			else
				@nFrame = 0

			nNodeAdded = 0
			pointsToRemove = []

			# find
			for node in @nodes
				if not node.alive then continue

				# find close points
				closestPoints = []

				for point, i in @points
					distance = point.point.subtract(node.point).length
					if distance < @data.pointSelectionDist
						closestPoints.push(point)
						if distance < @data.pointDeletionDist
							pointsToRemove.push(i)

				if closestPoints.length > 0

					# create node in direction of points
					averageDirection = new paper.Point(0, 0)
					for closestPoint in closestPoints
						averageDirection = averageDirection.add(closestPoint.subtract(node.point))
					averageDirection = averageDirection.divide(closestPoints.length)
					averageDirection = averageDirection.normalize()

					@nodes.push( point: node.point.add(averageDirection.multiply(2*@data.nodeRadius)), parent: node, age: 0, alive: true )
					nNodeAdded++
				else
					node.alive = false

			if nNodeAdded == 0
				@animating = false
				console.log("ANIMATION FINISHED")
				return

			# remove points to remove
			pointsToRemove = pointsToRemove.sort((a, b)-> return a-b ).filter (item, pos, array)->
				return !pos or item != array[pos-1]

			newPoints = []
			pointToRemoveIndex = 0
			for point, i in @points
				if i != pointsToRemove[pointToRemoveIndex]
					newPoints.push(point)
				else
					pointToRemoveIndex++
			@points = newPoints

			@pointGroup.removeChildren()
			@nodeGroup.removeChildren()

			for point in @points
				circle = new paper.Path.Circle(point.point, 2)
				circle.strokeWidth = 1
				circle.strokeColor = 'black'
				@pointGroup.addChild(circle)

			for node in @nodes
				path = new paper.Path()
				path.add(node.point)
				path.add(node.parent.point)
				path.strokeWidth = node.age
				path.strokeColor = 'black'
				path.strokeCap = 'round'
				@nodeGroup.addChild(path)
				node.age += 0.125

			return

		followNode: (node, branches)->
			branches[branches.length-1].push(node.point)
			if not node.children? then return
			for child, i in node.children
				if i==0
					@followNode(child, branches)
				else
					branches.push([node.point])
					@followNode(child, branches)
			return

		sendToSpacebrew: (spacebrew)=>
			json = {}
			leaves = []

			# reset children in case it was set (don't add them twice!)
			for node in @nodes
				node.children = null

			for node in @nodes
				if node.parent?
					if node.parent == node then continue # ignore root (root.parent = root)
					node.parent.children ?= []
					node.parent.children.push(node)

			branches = [[]]
			@followNode(@nodes[0], branches)
			data =
				paths: branches
				scale: @data.scaleTree
				bounds:
					x: @rectangle.x
					y: @rectangle.y
					width: @rectangle.width
					height: @rectangle.height
			json = JSON.stringify(data)
			console.log json
			spacebrew.send("commands", "string", json)
			return

	return SpaceColony
