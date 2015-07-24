define [ 'Items/Paths/PrecisePaths/StepPath', 'Commands/Command' ], (StepPath, Command) ->

	# SpeedPath extends R.PrecisePath to add speed functionnalities:
	#  - the speed at which the user has drawn the path is stored and has influence on the drawing,
	#  - the speed values are displayed as normals of the path, and can be edited thanks to handles,
	#  - when the user drags a handle, it will also influence surrounding speed values depending on how far from the normal the user drags the handle (with a gaussian attenuation)
	#  - the speed path and handles are added to a speed group, which is added to the main group
	#  - the speed group can be shown or hidden through the folder 'Edit curve' in the gui
	class SpeedPath extends StepPath
		@label = 'Speed path'
		@description = "This path offers speed."
		@iconURL = null
		@iconAlt = null

		@maxSpeed = 200
		@speedStep = 20
		@secureStep = 25

		@initializeParameters: ()->

			parameters = super()

			parameters['Edit curve'].showSpeed =
				type: 'checkbox'
				label: 'Show speed'
				default: false

			if R.wacomPenAPI?
				parameters['Edit curve'].usePenPressure =
					type: 'checkbox'
					label: 'Pen pressure'
					default: true

			return parameters

		@parameters = @initializeParameters()

		# overloads {PrecisePath#initializeDrawing}
		initializeDrawing: (createCanvas=false)->
			@speedOffset = 0
			super(createCanvas)
			return

		# overloads {PrecisePath#loadPath}
		loadPath: (points)->
			@data ?= {}
			@speeds = @data.speeds or []
			super(points)
			return

		# overloads {PrecisePath#checkUpdateDrawing} to update speed while drawing
		checkUpdateDrawing: (segment, redrawing=false)->
			if redrawing
				super(segment, redrawing)
				return

			step = @data.step
			controlPathOffset = segment.location.offset
			previousControlPathOffset = if segment.previous? then segment.previous.location.offset else 0

			previousSpeed = if @speeds.length>0 then @speeds.pop() else 0

			currentSpeed = null
			if not @data.usePenPressure or R.wacomPointerType[R.wacomPenAPI.pointerType] == 'Mouse'
				currentSpeed = controlPathOffset - previousControlPathOffset
			else
				currentSpeed = R.wacomPenAPI.pressure * @constructor.maxSpeed

			while @speedOffset + @constructor.speedStep < controlPathOffset
				@speedOffset += @constructor.speedStep
				f = (@speedOffset-previousControlPathOffset)/currentSpeed
				speed = Utils.linearInterpolation(previousSpeed, currentSpeed, f)
				@speeds.push(Math.min(speed, @constructor.maxSpeed))

			@speeds.push(Math.min(currentSpeed, @constructor.maxSpeed))

			super(segment, redrawing)

			return

		# todo: better handle lock area
		# overload {PrecisePath#beginCreate} and add speed initialization
		beginCreate: (point, event)->
			@speeds = if @data.polygonMode then [@constructor.maxSpeed/3] else []
			super(point, event)
			return

		# overload {PrecisePath#endCreate} and add speed initialization
		endCreate: (point, event)->
			# if not @data.polygonMode and not loading then @speeds = []
			super(point, event)
			return

		# deprecated
		# compute the speed (deduced from the space between each point of the control path)
		# the speed values are sampeled on regular intervals along the control path (same machanism as the drawing points)
		# the distance between each sample is defined in @constructor.speedStep
		# an average speed must be computed at each sample
		computeSpeed: ()->

			# 1. create an array *distances* containing speed values at regular intervals over the control path + speed values at the control path points
			# the speed values computed between the control path points are interpolated from the two closest points
			# the speed values of the points are equal to the length of the segment (distance between current and previous point)
			# this array will be converted to real speed values in a second step, i.e. all values in the regular intervals will be summed up/integrated

			# initialize variables
			step = @constructor.speedStep

			distances = []
			controlPathLength = @controlPath.length
			currentOffset = step
			segment = @controlPath.firstSegment
			distance = segment.point.getDistance(segment.next.point)
			distances.push({speed: distance, offset: 0})
			previousDistance = 0

			pointOffset = 0
			previousPointOffset = 0

			# we have a line with oddly distributed points:  |------|-------|--||-|-----------|--------|  ('|' represents the points, the speed at those point corresponds to the distance of the previous segment)
			# we want to add values on regular intervals:    I---I--|I---I--|I-||I|--I---I---I|--I---I-| ('I' have been added every three units, the corresponding speeds are interpolated)
			# (the last interval is shorter than the others)
			# in a second step, we will integrate the values on those regular intervals

			for segment, i in @controlPath.segments 		# loop over control path points
				if i==0 then continue

				point = segment.point
				previousDistance = distance
				distance = point.getDistance(segment.previous.point)
				previousPointOffset = pointOffset
				pointOffset += distance

				# while we can add more sample on this segment, add them (values are interpolation)
				while pointOffset > currentOffset
					f = (currentOffset-previousPointOffset)/distance
					interpolation = Utils.linearInterpolation(previousDistance, distance, f)
					distances.push({speed: interpolation, offset: currentOffset})
					currentOffset += step

				distances.push({speed: distance, offset: pointOffset})

			distances.push({speed: distance, offset: currentOffset}) 		# push last point

			# 2. intergate the values of the regular intervals to obtain final speed values

			@speeds = []

			nextOffset = step

			speed = distances[0].speed
			previousSpeed = speed
			@speeds.push(speed)
			offset = 0
			previousOffset = offset
			currentAverageSpeed = 0

			for distance, i in distances
				if i==0 then continue

				previousSpeed = speed
				speed = distance.speed

				previousOffset = offset
				offset = distance.offset

				currentAverageSpeed += ((speed+previousSpeed)/2.0)*(offset-previousOffset)/step

				if offset==nextOffset
					@speeds.push(Math.min(currentAverageSpeed, @constructor.maxSpeed))
					currentAverageSpeed = 0
					nextOffset += step

			return

		# show the speed group (called on @select())
		showSpeed: ()->
			@speedGroup?.visible = @data.showSpeed
			if not @speeds? or not @data.showSpeed then return
			@speedGroup?.bringToFront()
			return

		modifySpeed: (@speeds, update)->
			@updateSpeed()
			@draw()
			if not @socketAction
				if update then @update('speed')
				R.socket.emit "bounce", itemPk: @pk, function: "modifySpeed", arguments: [@speeds, false]
			else
				@speedGroup?.visible = @selected? and @data.showSpeed
			return

		# update the speed group (curve and handles to visualize and edit the speeds)
		updateSpeed: ()->
			# TODO: Remove unecessary handle group, replace by speedCurve segments...
			# 		Anyway, this should be replace by a nice, smooth speed curve...

			@speedGroup?.visible = @data.showSpeed

			if not @speeds? or not @data.showSpeed then return

			step = @constructor.speedStep

			# create the speed group if it does not exist (add it to the main group)
			alreadyExists = @speedGroup?

			if alreadyExists
				@speedGroup.bringToFront()
				speedCurve = @speedGroup.firstChild
			else
				@speedGroup = new P.Group()
				@speedGroup.name = "speed group"
				@speedGroup.strokeWidth = 1
				@speedGroup.strokeColor = R.selectionBlue
				@speedGroup.controller = @
				@group.addChild(@speedGroup)

				speedCurve = new P.Path()
				speedCurve.name = "speed curve"
				speedCurve.strokeWidth = 1
				speedCurve.strokeColor = R.selectionBlue
				speedCurve.controller = @
				@speedGroup.addChild(speedCurve)

				@handleGroup = new P.Group()
				@handleGroup.name = "speed handle group"
				@speedGroup.addChild(@handleGroup)

			speedHandles = @handleGroup.children

			offset = 0
			controlPathLength = @controlPath.length

			while (@speeds.length-1)*step < controlPathLength
				@speeds.push(_.last(@speeds))

			i = 0

			# for all speed values: draw or update the corresponding curve point and handle
			for speed, i in @speeds

				offset = if i>0 then i*step else 0.1
				o = if offset<controlPathLength then offset else controlPathLength - 0.1

				point = @controlPath.getPointAt(o)
				normalNormalized = @controlPath.getNormalAt(o).normalize()
				normal = normalNormalized.multiply(@speeds[i])
				handlePoint = point.add(normal)

				# if the speed point (curve, segment and handle) already exists, move it the to correct place
				if alreadyExists and i<speedCurve.segments.length

					speedCurve.segments[i].point = handlePoint
					speedHandles[i].position = handlePoint
					speedHandles[i].rsegment.firstSegment.point = point
					speedHandles[i].rsegment.lastSegment.point = handlePoint
					speedHandles[i].rnormal = normalNormalized

				# else (if the speed point does not exist) create it
				else
					speedCurve.add(handlePoint)

					s = new P.Path()
					s.name = 'speed segment'
					s.strokeWidth = 1
					s.strokeColor = R.selectionBlue
					s.add(point)
					s.add(handlePoint)
					s.controller = @
					@speedGroup.addChild(s)

					handle = new P.Path.Rectangle(handlePoint.subtract(2), 4)
					handle.name = 'speed handle'
					handle.strokeWidth = 1
					handle.strokeColor = R.selectionBlue
					handle.fillColor = 'white'
					handle.rnormal = normalNormalized
					handle.rindex = i
					handle.rsegment = s
					handle.controller = @
					@handleGroup.addChild(handle)

				if offset>controlPathLength
					break

			# remove speed curve point and handles which are not on the control path anymore (if the curve path has been shrinked)
			if offset > controlPathLength and i+1 <= speedHandles.length-1
				speedHandlesLengthM1 = speedHandles.length-1
				for j in [i+1 .. speedHandlesLengthM1]
					speedHandle = @handleGroup.lastChild
					speedHandle.rsegment.remove()
					speedHandle.remove()
					speedCurve.lastSegment.remove()

			return

		# get the speed at *offset*
		# @param offset [Number] the offset along the control path at which getting the speed
		# @return [Number] the computed speed:
		# - the value is interpolated from the two closest speed values
		# - if speeds are not computed yet: return half of the max speed
		speedAt: (offset)->
			f = offset%@constructor.speedStep
			i = (offset-f) / @constructor.speedStep
			f /= @constructor.speedStep
			if @speeds?
				if i<@speeds.length-1
					return Utils.linearInterpolation(@speeds[i], @speeds[i+1], f)
				else
					return _.last(@speeds)
			else
				@constructor.maxSpeed/2
			return

		# overload {PrecisePath#draw} and add speed update when *loading* is false
		draw: (simplified=false)->
			@speedOffset = 0
			super(simplified)
			if @controlPath.selected then @updateSpeed()
			return

		# overload {PrecisePath#getData} and adds the speeds in @data.speeds (unused speed values are not stored)
		getData: ()->
			delete @data.usePenPressure 		# there is no need to store whether the pen was used or not
			data = jQuery.extend({}, super())
			data.speeds = if @speeds? and @handleGroup? then @speeds.slice(0, @handleGroup.children.length+1) else @speeds
			return data

		# overload {PrecisePath#select}, update speeds and show speed group
		select: ()->
			if not super() then return false
			@showSpeed()
			if @data.showSpeed
				if not @speedGroup? then @updateSpeed()
				@speedGroup?.visible = true
			return true

		# overload {PrecisePath#deselect} and hide speed group
		deselect: ()->
			if not super() then return false
			@speedGroup?.visible = false
			return true

		# # overload {PrecisePath#initializeSelection} but add the possibility to select speed handles
		# initializeSelection: (event, hitResult) ->
		# 	@speedSelectionHighlight?.remove()
		# 	@speedSelectionHighlight = null
		#
		# 	if hitResult.item.name == "speed handle"
		# 		@selectionState = speedHandle: hitResult.item
		# 		return
		# 	super(event, hitResult)
		# 	return

		hitTest: (event)->
			point = event.point

			@speedSelectionHighlight?.remove()
			@speedSelectionHighlight = null
			@selectedSpeedHandle = null

			if @speedGroup? and @speedGroup.visible
				hitResult = @handleGroup.hitTest(point, @constructor.hitOptions)

				if hitResult?.item?.name == "speed handle"
					@selectedSpeedHandle =  hitResult.item
					R.commandManager.beginAction(new Command.ModifySpeed(@))
					return
			super(event)
			return

		updateModifySpeed: (event)->
			if @selectedSpeedHandle?
				@speedSelectionHighlight?.remove()

				maxSpeed = @constructor.maxSpeed

				# initialize a line between the mouse and the handle, orthogonal to the normal
				# the length of this line determines how much influence the change will have over the neighbour handles
				@speedSelectionHighlight = new P.Path()
				@speedSelectionHighlight.name = 'speed selection highlight'
				@speedSelectionHighlight.strokeWidth = 1
				@speedSelectionHighlight.strokeColor = 'blue'
				@speedGroup.addChild(@speedSelectionHighlight)

				handle = @selectedSpeedHandle
				handlePosition = handle.bounds.center

				handleToPoint = event.point.subtract(handlePosition)
				projection = handleToPoint.project(handle.rnormal)
				projectionLength = projection.length

				# compute the new speed value
				sign = Math.sign(projection.x) == Math.sign(handle.rnormal.x) and Math.sign(projection.y) == Math.sign(handle.rnormal.y)
				sign = if sign then 1 else -1

				@speeds[handle.rindex] += sign * projectionLength

				if @speeds[handle.rindex] < 0
					@speeds[handle.rindex] = 0
				else if @speeds[handle.rindex] > maxSpeed
					@speeds[handle.rindex] = maxSpeed

				newHandleToPoint = event.point.subtract(handle.position.add(projection))
				influenceFactor = newHandleToPoint.length/(@constructor.speedStep*3)

				# spread the influence of this new speed value
				max = Utils.gaussian(0, influenceFactor, 0)
				i = 1
				influence = 1
				while influence > 0.1 and i<20
					influence = Utils.gaussian(0, influenceFactor, i)/max

					delta = projectionLength*influence

					for n in [-1 .. 1] by 2
						index = handle.rindex+n*i
						if index >= 0 and index < @handleGroup.children.length
							handlei = @handleGroup.children[index]

							@speeds[index] += sign * delta
							if @speeds[index] < 0
								@speeds[index] = 0
							else if @speeds[index] > maxSpeed
								@speeds[index] = maxSpeed
					i++

				# create the line between the mouse and the handle, orthogonal to the normal
				@speedSelectionHighlight.strokeColor.hue -= Math.min(240*(influenceFactor/10), 240)
				@speedSelectionHighlight.add(handle.position.add(projection))
				@speedSelectionHighlight.add(event.point)

				@draw(true)
			return

		endModifySpeed: ()->
			@draw()
			@rasterize()
			@update('speed')
			@speedSelectionHighlight?.remove()
			@speedSelectionHighlight = null
			if not @socketAction then R.socket.emit "bounce", itemPk: @pk, function: "modifySpeed", arguments: [@speeds, false]
			return

		# overload {PrecisePath#remove} and remove speed group
		remove: ()->
			@speedGroup = null
			super()
			return

	return SpeedPath
