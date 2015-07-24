define [ 'Items/Paths/Shapes/Shape' ], (Shape) ->

	class StripeAnimation extends Shape
		@Shape = P.Path.Rectangle
		@label = 'Stripe animation'
		@description = "Creates a stripe animation from a set sequence of image."
		@squareByDefault = false

		@initializeParameters: ()->
			parameters = super()

			parameters['Parameters'] ?= {}
			parameters['Parameters'].stripeWidth =
				type: 'slider'
				label: 'Stripe width'
				min: 1
				max: 5
				default: 1
			parameters['Parameters'].maskWidth =
				type: 'slider'
				label: 'Mask width'
				min: 1
				max: 4
				default: 1
			parameters['Parameters'].speed =
				type: 'slider'
				label: 'Speed'
				min: 0.01
				max: 1.0
				default: 0.1

			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		# animted paths must be initialized
		initialize: ()->
			@data.animate = true
			@setAnimated(@data.animate)

			@modalJ = $('#customModal')
			modalBodyJ = @modalJ.find('.modal-body')
			modalBodyJ.empty()
			modalContentJ = $("""
				<div id="stripeAnimationContent" class="form-group url-group">
	                <label for="stripeAnimationModalURL">Add your images</label>
	                <input id="stripeAnimationFileInput" type="file" class="form-control" name="files[]" multiple/>
	                <div id="stripeAnimationDropZone">Drop your image files here.</div>
	                <div id="stripeAnimationGallery"></div>
	            </div>
	            """)
			modalBodyJ.append(modalContentJ)

			@modalJ.modal('show')
			# @modalJ.find('.btn-primary').click( (event)=> @modalSubmit() ) 		# submit modal when click submit button

			if window.File and window.FileReader and window.FileList and window.Blob
				#Great success! All the File APIs are supported.
				console.log 'File upload supported'
			else
				console.log 'File upload not supported'
				R.alertManager.alert 'File upload not supported', 'error'

			handleFileSelect = (evt) =>
				evt.stopPropagation()
				evt.preventDefault()
				files = evt.dataTransfer?.files or evt.target?.files

				# FileList object
				# Loop through the FileList and render image files as thumbnails.

				@nRasterToLoad = files.length
				@nRasterLoaded = 0
				@rasters = []

				i = 0
				f = undefined
				while f = files[i]
					# Only process image files.
					if not f.type.match('image.*')
						i++
						continue
					reader = new FileReader
					# Closure to capture the file information.
					reader.onload = ((theFile, stripeAnimation) ->
						(e) ->
							# Render thumbnail.
							span = document.createElement('span')
							span.innerHTML = [
								'<img class="thumb" src="'
								e.target.result
								'" title="'
								escape(theFile.name)
								'"/>'
							].join('')
							$("#stripeAnimationGallery").append(span)

							stripeAnimation.rasters.push(new P.Raster(e.target.result))

							stripeAnimation.nRasterLoaded++
							if stripeAnimation.nRasterLoaded == stripeAnimation.nRasterToLoad then stripeAnimation.rasterLoaded()

							return
					)(f, @)
					# Read in the image file as a data URL.
					reader.readAsDataURL f
					i++
				return

			$("#stripeAnimationFileInput").change(handleFileSelect)

			handleDragOver = (evt) ->
				evt.stopPropagation()
				evt.preventDefault()
				evt.dataTransfer.dropEffect = 'copy'
				# Explicitly show this is a copy.
				return

			dropZone = document.getElementById('stripeAnimationDropZone')
			dropZone.addEventListener 'dragover', handleDragOver, false
			dropZone.addEventListener 'drop', handleFileSelect, false

			return

		# modalSubmit: ()->
		# 	inputs = @modalJ.find("input.url")
		# 	@nRasterToLoad = inputs.length
		# 	@nRasterLoaded = 0
		# 	@rasters = []
		# 	for input in inputs
		# 		raster = new P.Raster(input.value)
		# 		raster.onLoad = @rasterOnLoad
		# 		@rasters.push(raster)
		# 	return

		rasterLoaded: ()=>
			if not @rasters? or @rasters.length==0 then return
			if @nRasterLoaded != @nRasterToLoad then return

			@minSize = new P.Size()
			for raster in @rasters
				if @minSize.width == 0 or raster.width < @minSize.width
					@minSize.width = raster.width
				if @minSize.height == 0 or raster.height < @minSize.height
					@minSize.height = raster.height

			for raster in @rasters
				raster.size = @minSize

			size = @rasters[0].size

			@result = new P.Raster()
			@result.position = @rectangle.center
			@result.size = size
			@result.name = 'stripe animation raster'
			@result.controller = @
			@drawing.addChild(@result)

			@stripes = new P.Raster()
			@stripes.size = new P.Size(size.width*2, size.height)
			@stripes.position = @rectangle.center
			@stripes.name = 'stripe mask raster'
			@stripes.controller = @
			@drawing.addChild(@stripes)

			n = @rasters.length
			width = @data.stripeWidth

			black = new P.Color(0, 0, 0)
			transparent = new P.Color(0, 0, 0, 0)

			# for x in [0 .. (2*size.width)-1]
			# 	for y in [0 .. size.height-1]
			# 		i = Utils.floorToMultiple(x, width) % n
			# 		if x < size.width
			# 			@result.setPixel(x, y, @rasters[i].getPixel(x, y))
			# 		@stripes.setPixel(x, y, if i==0 then transparent else black)

			nStripes = Math.floor(size.width/width)
			for i in [0 .. nStripes]
				stripeData = @rasters[i%n].getImageData(new P.Rectangle(i*width, 0, width, size.height))
				@result.setImageData(stripeData, new P.Point(i*width, 0))

			stripesContext = @stripes.canvas.getContext("2d")
			stripesContext.fillStyle = "rgb(0, 0, 0)"

			nVisibleFrames = Math.min(@data.maskWidth, n-1)
			blackStripeWidth = width*(n-nVisibleFrames)
			position = nVisibleFrames*width

			while position < @stripes.width
				stripesContext.fillRect(position, 0, blackStripeWidth, size.height)
				position += width*n

			return

		createShape: ()->
			@rasterLoaded()
			return

		# called at each frame event
		# this is the place where animated paths should be updated
		onFrame: (event)=>
			# very simple example of path animation
			if not @stripes? then return
			@stripes.position.x -= @data.speed
			if @stripes.bounds.center.x < @rectangle.left
				@stripes.bounds.center.x = @rectangle.right
			return

	return StripeAnimation
