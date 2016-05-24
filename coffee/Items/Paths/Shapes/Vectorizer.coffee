define [ 'Items/Paths/Shapes/Shape', 'UI/Modal'], (Shape, Modal) ->

	class Vectorizer extends Shape
		@Shape = P.Path.Rectangle
		@label = 'Vectorizer'
		@description = "Creates a vectorized version of an image."
		@squareByDefault = true

		@initializeParameters: ()->
			parameters = super()

			parameters['Style'].strokeWidth.default = 1
			parameters['Style'].strokeColor.default = 'black'
			parameters['Style'].strokeColor.defaultFunction = null

			parameters['Parameters'] ?= {}
			parameters['Parameters'].effectType =
				default: 'multipleStrokes'
				values: ['multipleStrokes', 'color', 'blackAndWhite', 'CMYKstripes', 'CMYKdots']
				label: 'Effect type'
			parameters['Parameters'].nStrokes =
				type: 'slider'
				label: 'StrokeNumber'
				min: 2
				max: 16
				default: 4
			parameters['Parameters'].spiralWidth =
				type: 'slider'
				label: 'Spiral width'
				min: 1
				max: 16
				default: 7
			parameters['Parameters'].pixelSize =
				type: 'slider'
				label: 'pixelSize'
				min: 1
				max: 16
				default: 7
			parameters['Parameters'].nStripes =
				type: 'slider'
				label: 'nStripes'
				min: 10
				max: 160
				default: 15
			parameters['Parameters'].blackThreshold =
				type: 'slider'
				label: 'blackThreshold'
				min: 0
				max: 255
				default: 50
			parameters['Parameters'].cyanThreshold =
				type: 'slider'
				label: 'cyanThreshold'
				min: 0
				max: 255
				default: 128
			parameters['Parameters'].magentaThreshold =
				type: 'slider'
				label: 'magentaThreshold'
				min: 0
				max: 255
				default: 128
			parameters['Parameters'].yellowThreshold =
				type: 'slider'
				label: 'yellowThreshold'
				min: 0
				max: 255
				default: 128
			parameters['Parameters'].blackAngle =
				type: 'slider'
				label: 'blackAngle'
				min: 0
				max: 360
				default: 45
			parameters['Parameters'].cyanAngle =
				type: 'slider'
				label: 'cyanAngle'
				min: 0
				max: 360
				default: 15
			parameters['Parameters'].magentaAngle =
				type: 'slider'
				label: 'magentaAngle'
				min: 0
				max: 360
				default: 75
			parameters['Parameters'].yellowAngle =
				type: 'slider'
				label: 'yellowAngle'
				min: 0
				max: 360
				default: 0
			parameters['Parameters'].dotSize =
				type: 'slider'
				label: 'dotSize'
				min: 0.1
				max: 10
				default: 2
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		# animted paths must be initialized
		initialize: ()->

			if not (window.File and window.FileReader and window.FileList and window.Blob)
				console.log 'File upload not supported.'
				R.alertManager.alert 'File upload not supported', 'error'
				return

			modal = Modal.createModal( title: 'Select an image', submit: ()->return )
			modal.addImageSelector( { name: "image-selector", rastersLoadedCallback: @allRastersLoaded, extractor: ()=> return @rasters.length>0 } )
			modal.show()

			return

		allRastersLoaded: (rasters)=>
			if ((not @rasters?) or @rasters.length==0) and (not rasters?) then return

			if not @rasters?
				@rasters = []
				for file, raster of rasters
					@rasters.push(raster)

			switch @data.effectType
				when 'multipleStrokes'
					@drawSpiralMultipleStrokes()
				when 'color'
					@drawSpiralColor()
				when 'blackAndWhite'
					@drawSpiralColor(true)
				when 'CMYKstripes'
					@drawCMYKstripes()
				when 'CMYKdots'
					@drawCMYKdots()
			return

		drawSpiralColor: (blackAndWhite=false)->

			raster = @rasters[0]
			raster.fitBounds(@rectangle, true)
			raster.visible = false

			colors = if blackAndWhite then ['black'] else ['red', 'green', 'blue']
			offsets = if blackAndWhite then {'black':0} else {'red': -3.7/1.5, 'green': 0, 'blue': 3.7/1.5}
			@paths = {}
			for color in colors
				path = @addPath(new P.Path())
				path.fillColor = color
				path.strokeColor = null
				path.strokeWidth = 0
				path.closed = true
				@paths[color] = path

			position = @rectangle.center
			count = 0
			while @rectangle.center.subtract(position).length < @rectangle.width/2
				vector = new P.Point( angle: count * 5, length: count/100 )
				rot = vector.rotate(90)
				offset = rot.clone()
				offset.length = 1
				color = raster.getAverageColor(position.add(vector.divide(2)))
				for c in colors
					v = if blackAndWhite then color.gray else color[c]
					value = if color then (1 - v) * @data.spiralWidth / 2.5 else 0
					rot.length = Math.max(value, 0.1)
					@paths[c].add(position.add(vector).add(offset.multiply(offsets[c])).subtract(rot))
					@paths[c].insert(0, position.add(vector).add(offset.multiply(offsets[c])).add(rot))
				position = position.add(vector)
				count++

			for color, path of @paths
				path.smooth()

			return

		drawSpiralMultipleStrokes: ()->

			raster = @rasters[0]
			raster.fitBounds(@rectangle, true)
			raster.visible = false

			@paths = []
			for i in [1 .. @data.nStrokes]
				path = @addPath(new P.Path())
				path.strokeColor = @data.strokeColor
				path.strokeWidth = @data.strokeWidth
				path.closed = false
				@paths.push(path)

			position = @rectangle.center
			count = 0
			while @rectangle.center.subtract(position).length < @rectangle.width/2
				vector = new P.Point( angle: count * 5, length: count/100 )
				rot = vector.rotate(90)
				offset = rot.clone()
				offset.length = 1
				color = raster.getAverageColor(position.add(vector.divide(2)))
				value = if color then (1 - color.gray) * @data.spiralWidth / 2.5 else 0
				rot.length = Math.max(value, 0.1)
				offset = -1
				step = 2/@paths.length
				for path in @paths
					path.add(position.add(vector).add(rot.multiply(offset)))
					offset += step
				position = position.add(vector)
				count++

			for path in @paths
				path.smooth()

			return

		colorToCMYK: (color)->
			r = color.red
			g = color.green
			b = color.blue
			k = Math.min(1 - r, 1 - g, 1 - b)
			result = {
				c: (1 - r - k) / (1 - k) or 0
				m: (1 - g - k) / (1 - k) or 0
				y: (1 - b - k) / (1 - k) or 0
				k: k
			}
			return result

		drawCMYKdots: ()->

			raster = @rasters[0]
			raster.fitBounds(@rectangle, true)
			raster.visible = false

			maxSize = Math.max(@rectangle.width, @rectangle.height)
			square = new P.Rectangle(maxSize, maxSize)

			pixel = new P.Rectangle(-@data.pixelSize/2, -@data.pixelSize/2, @data.pixelSize, @data.pixelSize)

			nSteps = maxSize / @data.pixelSize

			colorsToNames = { c: 'cyan', m: 'magenta', y: 'yellow', k: 'black' }
			colorsToAngles = { c: @data.cyanAngle, m: @data.magentaAngle, y: @data.yellowAngle, k: @data.blackAngle }
			colorsToThreshold = { c: @data.cyanThreshold, m: @data.magentaThreshold, y: @data.yellowThreshold, k: @data.blackThreshold }

			colors = ['k', 'm', 'c', 'y']
			# stripeGroups = new P.Group()
			for c in colors
				# stripeGroup = new P.Group()
				angle = colorsToAngles[c]
				center = @rectangle.center
				position = center.subtract(maxSize/2)
				position = position.rotate(angle, center)
				deltaX = new P.Point(1, 0).rotate(angle).multiply(@data.pixelSize)
				deltaY = new P.Point(0, 1).rotate(angle).multiply(@data.pixelSize)
				previousColor = null
				path = null

				for i in [0 .. nSteps ]
					startPosition = position.clone()
					if i%2 == 0 then position = position.add(deltaX.divide(2))
					for j in [0 .. nSteps]
						# fix paper.js bug (position.x must not be 0):
						if position.x == 0 then position.x = 0.001
						color = raster.getAverageColor(position)
						if color?
							cymk = @colorToCMYK(color)
							dot = @addPath(new P.Path.Circle(position, cymk[c]*@data.pixelSize*@data.dotSize))
							dot.fillColor = colorsToNames[c]
							dot.strokeWidth = 0
						position = position.add(deltaX)
					position = startPosition.add(deltaY)
				# stripeGroups.addChild(stripeGroup)
			return

		drawCMYKstripes: ()->

			raster = @rasters[0]
			raster.fitBounds(@rectangle, true)
			raster.visible = false

			maxSize = Math.max(@rectangle.width, @rectangle.height)
			square = new P.Rectangle(maxSize, maxSize)

			pixel = new P.Rectangle(-@data.pixelSize/2, -@data.pixelSize/2, @data.pixelSize, @data.pixelSize)

			nSteps = maxSize / @data.pixelSize
			yStepSize = maxSize / @data.nStripes

			colorsToNames = {c: 'cyan', m: 'magenta', y: 'yellow', k: 'black'}
			colorsToAngles = { c: @data.cyanAngle, m: @data.magentaAngle, y: @data.yellowAngle, k: @data.blackAngle }
			colorsToThreshold = { c: @data.cyanThreshold, m: @data.magentaThreshold, y: @data.yellowThreshold, k: @data.blackThreshold }
			colors = ['k', 'm', 'c', 'y']
			angles = [15, 75, 0, 45]
			# stripeGroups = new P.Group()
			for c in colors
				# stripeGroup = new P.Group()
				angle = colorsToAngles[c]
				center = @rectangle.center
				position = center.subtract(maxSize/2)
				center = @rectangle.center
				position = position.rotate(angle, center)
				deltaX = new P.Point(1, 0).rotate(angle).multiply(@data.pixelSize)
				deltaY = new P.Point(0, 1).rotate(angle).multiply(yStepSize)
				previousColor = null
				path = null
				for i in [0 .. @data.nStripes ] # @data.nStripes]
					startPosition = position.clone()
					# console.log(startPosition)
					for j in [0 .. nSteps]
						# fix paper.js bug (position.x must not be 0):
						if position.x == 0 then position.x = 0.001
						color = raster.getAverageColor(new P.Rectangle(position.subtract(@data.pixelSize/2), new P.Size(@data.pixelSize, @data.pixelSize)))
						if color?
							cymk = @colorToCMYK(color)
							if cymk[c] > ( colorsToThreshold[c] / 255 )
								if not path?
									path = @addPath(new P.Path())
									path.strokeColor = colorsToNames[c]
									path.strokeWidth = @data.spiralWidth
									# stripeGroup.addChild(path)
									path.add(position)
							else if path?
								path.add(previousPosition)
								path = null
						previousPosition = position.clone()
						position = position.add(deltaX)
					path = null
					previousPosition = position.clone()
					position = startPosition.add(deltaY)
				# stripeGroups.addChild(stripeGroup)
			return

		createShape: ()->
			# super()
			@shape = new P.Group()
			@allRastersLoaded()
			return

	return Vectorizer
