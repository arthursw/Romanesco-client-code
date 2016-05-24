define [ 'Items/Paths/Shapes/Shape', 'UI/Modal'], (Shape, Modal) ->

	class Striper extends Shape
		@Shape = P.Path.Rectangle
		@label = 'Striper'
		@description = "Creates a striped version of an SVG."
		@squareByDefault = true

		@initializeParameters: ()->
			parameters = super()

			parameters['Style'].strokeWidth.default = 1
			parameters['Style'].strokeColor.default = 'black'
			parameters['Style'].strokeColor.defaultFunction = null

			parameters['Parameters'] ?= {}
			parameters['Parameters'].effectType =
				default: 'CMYKstripes'
				values: ['CMYKstripes', 'CMYKdots']
				label: 'Effect type'
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
			parameters['Parameters'].removeContours =
				type: 'checkbox'
				label: 'remove contours'
				default: true
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
			modal.addImageSelector( { name: "image-selector", svg: true, rastersLoadedCallback: @allRastersLoaded, extractor: ()=> return @rasters.length>0 } )
			modal.show()

			return

		allRastersLoaded: (rasters)=>
			if ((not @rasters?) or @rasters.length==0) and (not rasters?) then return

			if not @rasters?
				@rasters = []
				for file, raster of rasters
					@rasters.push(raster)

			switch @data.effectType
				when 'CMYKstripes'
					@drawCMYKstripes()
				when 'CMYKdots'
					@drawCMYKdots()
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

		logItem: (item, prefix="")->
			console.log(prefix + item.className)
			prefix += " -"
			if not item.children? then return
			for child in item.children
				@logItem(child, prefix)
			return

		convertGroupsToCompoundPath: (item, compoundPath)->
			if (item instanceof P.Group or item instanceof P.CompoundPath) and item.children?
				for child in item.children
					@convertGroupsToCompoundPath(child, compoundPath)
			else if item?
				console.log(item.className)
				compoundPath.addChild(item)
			return

		drawCMYKstripes: ()->
			originalRaster = @rasters[0].clone()
			originalRaster.fitBounds(@rectangle, false)
			raster = new P.CompoundPath()
			@convertGroupsToCompoundPath(originalRaster, raster)

			raster.position = @rectangle.center
			raster.fitBounds(@rectangle, false)

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

			stripes = new P.CompoundPath()
			stripes.strokeWidth = 1
			stripes.strokeColor = 'black'

			center = @rectangle.center
			position = center.subtract(maxSize/2)

			for i in [0 .. @data.nStripes]
				# console.log(position)
				stripe = new P.Path.Rectangle(position, new P.Size(maxSize, yStepSize/2))
				stripe.fillColor = 'black'
				stripes.addChild(stripe)
				position = position.add(0, yStepSize)

			# angle = 45
			# rotatedStripes = stripes.clone().rotate(angle)
			path = stripes.intersect(raster.clone())
			if @data.removeContours
				pathWithoutContour = new P.CompoundPath()
				for p in  path.children
					for segment in p.segments
						if segment.next? && Math.abs(segment.point.y - segment.next.point.y) < 1.5
							line = new P.Path()
							line.add(segment.point)
							line.add(segment.next.point)
							pathWithoutContour.addChild(line)
				path.remove()
				path = pathWithoutContour
			path.strokeWidth = 1
			path.strokeColor = 'black'
			@drawing.addChild(path)
			@drawing.addChild(raster)
			raster.fillColor = null
			raster.strokeColor = 'black'
			raster.strokeWidth = 1

			stripes.remove()

			return

		createShape: ()->
			# super()
			@shape = new P.Group()
			@allRastersLoaded()
			return

	return Striper
