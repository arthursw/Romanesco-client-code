define [
	'utils', 'RTool'
], (utils, RTool) ->

	# CarTool gives a car to travel in the world with arrow key (and play video games)
	class CarTool extends RTool

		@rname = 'Car'
		@description = ''
		@iconURL = 'car.png'
		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 0, y:0
			name: 'default'

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
							if g.selectedTool.constructor.name == "CarTool"
								if value>0
									if not g.sound.isPlaying
										g.sound.play()
										g.sound.setLoopStart(3.26)
										g.sound.setLoopEnd(5.22)
									g.sound.setVolume(0.1*value)
								else
									g.sound.stop()
							return
			return parameters

		@parameters = @initializeParameters()

		constructor: () ->
			super(true) 		# no cursor when car is selected (might change)
			return

		# Select car tool
		# load the car image, and initialize the car and the sound
		select: (deselectItems=true, updateParameters=true)->
			super

			# create Paper raster and initialize car parameters
			@car = new Raster("/static/images/car.png")
			g.carLayer.addChild(@car)
			@car.position = view.center
			@car.speed = 0
			@car.direction = new Point(0, -1)
			@car.onLoad = ()->
				console.log 'car loaded'
				return

			@car.previousSpeed = 0

			# initialize sound
			g.sound.setVolume(0.1)
			g.sound.play(0)
			g.sound.setLoopStart(3.26)
			g.sound.setLoopEnd(5.22)

			@lastUpdate = Date.now()

			return

		# Deselect tool: remove car and stop sound
		deselect: ()->
			super()
			@car.remove()
			@car = null
			g.sound.stop()
			return

		# on frame event:
		# - update car position, speed and direction according to user inputs
		# - update sound rate
		onFrame: ()->
			if not @car? then return

			# update car position, speed and direction according to user inputs
			minSpeed = 0.05
			maxSpeed = 100

			if Key.isDown('right')
				@car.direction.angle += 5
			if Key.isDown('left')
				@car.direction.angle -= 5
			if Key.isDown('up')
				if @car.speed<maxSpeed then @car.speed++
			else if Key.isDown('down')
				if @car.speed>-maxSpeed then @car.speed--
			else
				@car.speed *= 0.9
				if Math.abs(@car.speed) < minSpeed
					@car.speed = 0

			# update sound rate
			minRate = 0.25
			maxRate = 3
			rate = minRate+Math.abs(@car.speed)/maxSpeed*(maxRate-minRate)
			# console.log rate
			g.sound.setRate(rate)

			# acc = @speed-@previousSpeed

			# if @speed > 0 and @speed < maxSpeed
			# 	if acc > 0 and not g.sound.plays('acc')
			# 		console.log 'acc'
			# 		g.sound.playAt('acc', Math.abs(@speed/maxSpeed))
			# 	else if acc < 0 and not g.sound.plays('dec')
			# 		console.log 'dec:' + g.sound.pos()
			# 		g.sound.playAt('dec', 0) #1.0-Math.abs(@speed/maxSpeed))
			# else if Math.abs(@speed) == maxSpeed and not g.sound.plays('max')
			# 	console.log 'max'
			# 	g.sound.stop()
			# 	g.sound.spriteName = 'max'
			# 	g.sound.play('max')
			# else if @speed == 0 and not g.sound.plays('idle')
			# 	console.log 'idle'
			# 	g.sound.stop()
			# 	g.sound.spriteName = 'idle'
			# 	g.sound.play('idle')
			# else if @speed < 0 and Math.abs(@speed) < maxSpeed
			# 	if acc < 0 and not g.sound.plays('acc')
			# 		console.log '-acc'
			# 		g.sound.playAt('acc', Math.abs(@speed/maxSpeed))
			# 	else if acc > 0 and not g.sound.plays('dec')
			# 		console.log '-dec'
			# 		g.sound.playAt('dec', 1.0-Math.abs(@speed/maxSpeed))

			@car.previousSpeed = @car.speed

			@constructor.parameters['Car'].speed.controller.setValue(@car.speed.toFixed(2), false)

			@car.rotation = @car.direction.angle+90

			if Math.abs(@car.speed) > minSpeed
				@car.position = @car.position.add(@car.direction.multiply(@car.speed))
				g.RMoveTo(@car.position)

			g.gameAt(@car.position)?.updateGame(@)

			if Date.now()-@lastUpdate>150 			# emit car position every 150 milliseconds
				if g.me? then g.chatSocket.emit "car move", g.me, @car.position, @car.rotation, @car.speed
				@lastUpdate = Date.now()

			#project.view.center = @car.position
			return

		keyUp: (event)->
			switch event.key
				when 'escape'
					g.tools['Move'].select()

			return

	return CarTool