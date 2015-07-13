define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	# Checkpoint is a video game element:
	# if placed on a video game area, it will be registered in it
	class Checkpoint extends Shape
		@Shape = P.Path.Rectangle
		@label = 'Checkpoint'
		@description = """Draw checkpoints on a lock with a Racer to create a race
		(the players must go through each checkpoint as fast as possible, with the car tool)."""

		@category = 'Video game/Racer'
		@squareByDefault = false

		@initializeParameters: ()->
			return {} 		# we do not need any parameter

		@parameters = @initializeParameters()
		@createTool(@)

		# register the checkpoint if we are on a video game
		initialize: ()->
			@data.type = 'checkpoint'

			if @lock?
				if @lock.checkpoints.indexOf(@)<0 then @lock.checkpoints.push(@)
				@data.checkpointNumber ?= @game.checkpoints.indexOf(@)
			else
				R.alertManager.alert 'A checkpoint must be placed on a lock', 'error'
				@remove()
			return

		# just draw a red rectangle with the text 'Checkpoint N' N being the number of the checkpoint in the videogame
		# we could also prevent users to draw outside a video game
		createShape: ()->
			@data.strokeColor = 'rgb(150,30,30)'
			@data.fillColor = null
			@shape = @addPath(new P.Path.Rectangle(@rectangle))
			@text = @addPath(new P.PointText(@rectangle.center.add(0,4)))
			@text.content = if @data.checkpointNumber? then 'Checkpoint ' + @data.checkpointNumber else 'Checkpoint'
			@text.justification = 'center'
			return

		# checks if the checkpoints contains the point, used by the video game to test collisions between the car and the checkpoint
		contains: (point)->
			delta = point.subtract(@rectangle.center)
			delta.rotation = -@rotation
			return @rectangle.contains(@rectangle.center.add(delta))

		# we must unregister the checkpoint before removing it
		remove: ()->
			if @lock?.checkpoints? then Utils.Array.remove(@lock.checkpoints, @)
			super()
			return

	return Checkpoint
