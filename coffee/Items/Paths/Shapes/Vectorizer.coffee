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
				values: ['multipleStrokes', 'color', 'blackAndWhite']
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
			r = color.r
			g = color.g
			b = color.b
			k = Math.min(1 - r, 1 - g, 1 - b)
			result = {
				c: (1 - r - k) / (1 - k) or 0
				m: (1 - g - k) / (1 - k) or 0
				y: (1 - b - k) / (1 - k) or 0
				k: k
			}
			return result

		drawCMYKstripes: ()->

			raster = @rasters[0]
			raster.fitBounds(@rectangle, true)
			raster.visible = false

			maxSize = Math.max(raster.with, raster.height)
			square = new P.Rectangle(maxSize, maxSize)

			pixel = new P.Rectangle(@data.pixelSize, @data.pixelSize)

			colorsToNames = {c: 'cyan', m: 'magenta', y: 'yellow', k: 'black'}
			colorsTo = {c: 15, m: 75, y: 0, k: 45}
			colors = [k, m, c, y]
			# angles = [15, 75, 0, 45]
			stripeGroups = new P.Group()
			for c in colors
				stripeGroup = new P.Group()
				angle = colorsToAngle[c]
				position = @rectangle.topLeft
				center = @rectangle.center
				position = position.rotate(angle, center)
				delta = new P.Point(@data.pixelSize, 0)
				deltaX = delta.rotate(angle)
				deltaY = deltaX.rotate(-90)
				previousColor = null
				path = null
				for i in [0 .. @data.nStripes]
					startPosition = position.clone()
					for j in [0 .. nSteps]
						color = raster.getAverageColor(position, pixel)
						cymk = @drawCMYKstripes(color)
						if cymk[c] > 0.5
							if not path?
								path = new P.Path()
								path.strokeColor = colorsToNames[c]
								path.strokeWidth = @data.pixelSize
								stripeGroup.addChild(path)
							path.add(position)
						else if path?
							path = null
						position = position.add(deltaX)
					position = startPosition.add(deltaY)
				stripeGroups.addChild(stripeGroup)
			return

		createShape: ()->
			super()
			@allRastersLoaded()
			return

	return Vectorizer
