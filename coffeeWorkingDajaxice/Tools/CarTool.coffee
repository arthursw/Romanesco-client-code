define [ 'Tools/Tool' ], (Tool) ->

	# CarTool gives a car to travel in the world with arrow key (and play video games)
	class CarTool extends Tool

		@label = 'Car'
		@description = ''
		@iconURL = 'car.png'
		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 0, y:0
			name: 'default'
		@order = 7

		@minSpeed = 0.05
		@maxSpeed = 100

		@initializeParameters: ()->
			parameters =
				'Car':
					speed: 							# the speed of the car, just used as an indicator. Updated in @onFrame
						type: 'string'
						label: 'Speed'
						default: '0'
						addController: true
						onChange: ()-> return 		# disable the default callback
					volume: 						# volume of the car sound
						type: 'slider'
						label: 'Volume'
						default: 1
						min: 0
						max: 10
						onChange: (value)-> 		# set volume of the car, stop the sound if volume==0 and restart otherwise
							if R.selectedTool.constructor.name == "CarTool"
								sound = R.tools.car.sound
								if not sound? then return
								if value>0
									sound.play('car')
									sound.volume(0.1*value)
								else
									sound.stop()
							return
			return parameters

		@parameters = @initializeParameters()

		constructor: () ->
			super(true) 		# no cursor when car is selected (might change)
			@constructor.car = @
			return

		# Select car tool
		# load the car image, and initialize the car and the sound
		select: (deselectItems=true, updateParameters=true)->
			super
			require(['howler'], @howlerLoaded)
			return

		howlerLoaded: ()=>
			# create Paper raster and initialize car parameters
			@car = new P.Raster("/static/images/car.png")
			R.view.carLayer.addChild(@car)
			@car.position = P.view.center
			@car.speed = 0
			@car.direction = new P.Point(0, -1)
			@car.onLoad = ()->
				console.log 'car loaded'
				return

			@car.previousSpeed = 0

			# initialize sound
			@sound = new Howl
				urls: ['/static/sounds/viper.ogg']
				loop: true
				volume: 0.1
				sprite:
					car: [3260, 5220]
			@sound.play('car')

			@lastUpdate = Date.now()

			# on car move: create car (Raster) if the car for this user does not exist, and update position, rotation and speed.
			# the car will be removed if it is not updated for 1 second
			R.socket.socket.on "car move", @onCarMove
			return

		# Deselect tool: remove car and stop sound
		deselect: ()->
			super()
			@car.remove()
			@car = null
			@sound.stop()
			return

		# on frame event:
		# - update car position, speed and direction according to user inputs
		# - update sound rate
		onFrame: ()->
			if not @car? then return

			# update car position, speed and direction according to user inputs

			if P.Key.isDown('right')
				@car.direction.angle += 5
			if P.Key.isDown('left')
				@car.direction.angle -= 5
			if P.Key.isDown('up')
				if @car.speed<@constructor.maxSpeed then @car.speed++
			else if P.Key.isDown('down')
				if @car.speed>-@constructor.maxSpeed then @car.speed--
			else
				@car.speed *= 0.9
				if Math.abs(@car.speed) < @constructor.minSpeed
					@car.speed = 0

			@updateSound()

			# acc = @speed-@previousSpeed

			# if @speed > 0 and @speed < maxSpeed
			# 	if acc > 0 and not R.sound.plays('acc')
			# 		console.log 'acc'
			# 		R.sound.playAt('acc', Math.abs(@speed/maxSpeed))
			# 	else if acc < 0 and not R.sound.plays('dec')
			# 		console.log 'dec:' + R.sound.pos()
			# 		R.sound.playAt('dec', 0) #1.0-Math.abs(@speed/maxSpeed))
			# else if Math.abs(@speed) == maxSpeed and not R.sound.plays('max')
			# 	console.log 'max'
			# 	R.sound.stop()
			# 	R.sound.spriteName = 'max'
			# 	R.sound.play('max')
			# else if @speed == 0 and not R.sound.plays('idle')
			# 	console.log 'idle'
			# 	R.sound.stop()
			# 	R.sound.spriteName = 'idle'
			# 	R.sound.play('idle')
			# else if @speed < 0 and Math.abs(@speed) < maxSpeed
			# 	if acc < 0 and not R.sound.plays('acc')
			# 		console.log '-acc'
			# 		R.sound.playAt('acc', Math.abs(@speed/maxSpeed))
			# 	else if acc > 0 and not R.sound.plays('dec')
			# 		console.log '-dec'
			# 		R.sound.playAt('dec', 1.0-Math.abs(@speed/maxSpeed))

			@car.previousSpeed = @car.speed

			R.controllerManager.getController('Car', 'speed').setValue(@car.speed.toFixed(2))
			# @constructor.parameters['Car'].speed.controller.setValue(@car.speed.toFixed(2), false)

			@car.rotation = @car.direction.angle+90

			if Math.abs(@car.speed) > @constructor.minSpeed
				@car.position = @car.position.add(@car.direction.multiply(@car.speed))
				R.view.moveTo(@car.position)

			# R.gameAt(@car.position)?.updateGame(@)

			if Date.now()-@lastUpdate>150 			# emit car position every 150 milliseconds
				if R.me? then R.socket.emit "car move", R.me, @car.position, @car.rotation, @car.speed
				@lastUpdate = Date.now()


			#P.view.center = @car.position
			return

		updateSound: ()->
			minRate = 0.25
			maxRate = 3
			rate = minRate+Math.abs(@car.speed)/@constructor.maxSpeed*(maxRate-minRate)
			@sound._rate = rate
			@sound._activeNode()?.bufferSource?.playbackRate?.value = rate
			return

		onCarMove: (user, position, rotation, speed)->
			if R.ignoreSockets then return
			R.cars[user] ?= new P.Raster("/static/images/car.png")
			R.cars[user].position = new P.Point(position)
			R.cars[user].rotation = rotation
			R.cars[user].speed = speed
			R.cars[user].rLastUpdate = Date.now()
			return

		updateOtherCars: ()->
			for username, car of R.cars
				direction = new P.Point(1,0)
				direction.angle = car.rotation-90
				car.position = car.position.add(direction.multiply(car.speed))
				if Date.now() - car.rLastUpdate > 1000
					R.cars[username].remove()
					delete R.cars[username]
			return

		keyUp: (event)->
			switch event.key
				when 'escape'
					R.Tools.move.select()

			return

	R.Tools.Car = CarTool
	return CarTool
