define [ 'Items/Paths/Shapes/Shape', 'UI/Modal', 'jszip', 'fileSaver', 'color-classifier'], (Shape, Modal, JSZip, FileSaver, ColorClassifierFile) ->

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
				values: ['CMYKstripes']
				label: 'Effect type'
			parameters['Parameters'].keepLines =
				type: 'checkbox'
				label: 'keepLines'
				default: false
			parameters['Parameters'].circleSize =
				type: 'slider'
				label: 'circleSize'
				min: 1
				max: 1000
				default: 70
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
				default: 85
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
			parameters['Parameters'].fitToRectangle =
				type: 'checkbox'
				label: 'fitToRectangle'
				default: false
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

			@classifier = new ColorClassifier()

			get_dataset 'static/libs/color-dataset.js', (data)=>
				@classifier.learn(data)
				return

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
			return

		logItem: (item, prefix="")->
			console.log(prefix + item.className)
			prefix += " -"
			if not item.children? then return
			for child in item.children
				@logItem(child, prefix)
			return

		convertGroupsToCompoundPath: (item, fills, contous)->
			if (item instanceof P.Group or item instanceof P.CompoundPath) and item.children?
				for child in item.children
					@convertGroupsToCompoundPath(child, fills, contous)
			else if item?
				if item.fillColor?
					fills.addChild(item.clone())
				else
					contous.addChild(item.clone())
			return

		setItemColor: (item, color)->
			if item.strokeColor?
				item.strokeColor = color
			if item.fillColor?
				item.fillColor = color
			if not item.children? then return
			for child in item.children
				@setItemColor(child, color)
			return

		reduceColors: ()->
			originalRaster = @rasters[0].clone()
			if @data.fitToRectangle
				originalRaster.fitBounds(@rectangle, false)
			else
				originalRaster.position = @rectangle.center
				@rectangle.width = originalRaster.bounds.width
				@rectangle.height = originalRaster.bounds.height
				@rectangle.center = originalRaster.position

	# ROSE / ECO38A
	# VERT CLAIR / 8AC443
	# VERT MENTHE / 22B374
	# VERT MOYEN / 009F4C
	# ROUGE / EC1D24
	# BLEU CLAIR / 1E75B9
	# ORANGE / F06423
	# MARRON CLAIR / 895D3B
	# MARRON FONCE / 5F3713
	# JAUNE / FFDC23
	# BLEU FONCE / 2C388D
	# VIOLET / 7F3F95
	# NOIR / 221F1F


			color = 'white'
			index = 0
			# layers = new P.Group()
			for layer in originalRaster.children
				childIndex = 0
				for subLayer in layer.children
					if subLayer.name.indexOf("ROSE") != -1
						subLayer.name = "ROSE"
						color = "#ECO38A"
					else if subLayer.name.indexOf("VERT_CLAIR") != -1
						subLayer.name = "VERT_CLAIR"
						color = "#8AC443"
					else if subLayer.name.indexOf("VERT_MENTHE") != -1
						subLayer.name = "VERT_MENTHE"
						color = "#22B374"
					else if subLayer.name.indexOf("VERT_MOYEN") != -1
						subLayer.name = "VERT_MOYEN"
						color = "#009F4C"
					else if subLayer.name.indexOf("ROUGE") != -1
						subLayer.name = "ROUGE"
						color = "#EC1D24"
					else if subLayer.name.indexOf("ORANGE") != -1
						subLayer.name = "ORANGE"
						color = "#F06423"
					else if subLayer.name.indexOf("MARRON_CLAIR") != -1
						subLayer.name = "MARRON_CLAIR"
						color = "#895D3B"
					else if subLayer.name.indexOf("MARRON_FONCE") != -1
						subLayer.name = "MARRON_FONCE"
						color = "#5F3713"
					else if subLayer.name.indexOf("MARRON") != -1
						subLayer.name = "MARRON_FONCE"
						color = "#5F3713"
					else if subLayer.name.indexOf("JAUNE") != -1
						subLayer.name = "JAUNE"
						color = "#FFDC23"
					else if subLayer.name.indexOf("BLEU_FONCE") != -1
						subLayer.name = "BLEU_FONCE"
						color = "#2C388D"
					else if subLayer.name.indexOf("BLEU_CLAIR") != -1
						subLayer.name = "BLEU_CLAIR"
						color = "#1E75B9"
					else if subLayer.name.indexOf("VIOLET") != -1
						subLayer.name = "VIOLET"
						color = "#7F3F95"
					else if subLayer.name.indexOf("NOIR") != -1
						subLayer.name = "NOIR"
						color = "#000000"
					else
						console.log("Unknown color: " + subLayer.name)
					@setItemColor(subLayer, color)
					# subLayer.name = "Layer" + index + "." + childIndex + "-" + subLayer.name + ".svg"
					# newSubLayer = new P.Layer()
					# newSubLayer.name = "Layer" + index + "." + childIndex + "-" + subLayer.name + ".svg"
					# layers.addChild(newSubLayer)
					# newSubLayer.addChild(subLayer.clone())
					childIndex++
				index++

			# $("div[data-name='image-selector-drop-zone']").mCustomScrollbar()
			result = originalRaster
			result.position = new P.Point(result.bounds.size.multiply(0.5))
			svg = result.exportSVG( asString: true )
			svg = svg.replace(new RegExp('<g', 'g'), '<svg')
			svg = svg.replace(new RegExp('</g', 'g'), '</svg')

			blob = new Blob([svg], {type: 'image/svg+xml'})
			url = URL.createObjectURL(blob)

			filename = "plantsCleanedReduced.svg"

			link = document.createElement("a")
			document.body.appendChild(link)
			link.href = url
			link.download = filename
			link.text = filename
			link.click()
			document.body.removeChild(link)

			return

		drawCMYKstripesOld: ()->
			originalRaster = @rasters[0].clone()

			if @data.fitToRectangle
				originalRaster.fitBounds(@rectangle, false)
			else
				originalRaster.scale(1.36)
				originalRaster.position = new P.Point(0, originalRaster.bounds.height/2)
				@rectangle.width = originalRaster.bounds.width
				@rectangle.height = originalRaster.bounds.height
				@rectangle.center = originalRaster.position

			margin = 50
			yStepSize = (@rectangle.height+margin) / @data.nStripes

			stripes = new P.CompoundPath()
			stripes.strokeWidth = 1
			stripes.strokeColor = 'black'

			lines = new P.CompoundPath()
			lines.strokeWidth = 1
			lines.strokeColor = 'black'

			center = @rectangle.center
			position = @rectangle.topLeft.subtract(margin/2)

			yToKeep = []
			for i in [0 .. @data.nStripes]
				# console.log(position)
				stripe = new P.Path.Rectangle(position, new P.Size(@rectangle.width+margin, yStepSize/2))
				stripe.fillColor = 'black'
				stripes.addChild(stripe)
				line = new P.Path()
				line.add(stripe.bounds.topLeft)
				line.add(stripe.bounds.topRight)
				lines.addChild(line)
				position = position.add(0, yStepSize)
				yToKeep.push(stripe.bounds.top)

# ROSE / ECO38A
# VERT CLAIR / 8AC443
# VERT MENTHE / 22B374
# VERT MOYEN / 009F4C
# ROUGE / EC1D24
# BLEU CLAIR / 1E75B9
# ORANGE / F06423
# MARRON CLAIR / 895D3B
# MARRON FONCE / 5F3713
# JAUNE / FFDC23
# BLEU FONCE / 2C388D
# VIOLET / 7F3F95
# NOIR / 221F1F

			zip = new JSZip()
			img = zip.folder("Layers")
			group = new P.Group()

			color = 'white'
			index = 0
			for layer in originalRaster.children
				if not layer.children? then continue
				for subLayer, j in layer.children
					if subLayer.name.indexOf("ROSE") != -1
						subLayer.name = "ROSE"
						color = "#ECO38A"
					else if subLayer.name.indexOf("VERT_CLAIR") != -1
						subLayer.name = "VERT_CLAIR"
						color = "#8AC443"
					else if subLayer.name.indexOf("VERT_MENTHE") != -1
						subLayer.name = "VERT_MENTHE"
						color = "#22B374"
					else if subLayer.name.indexOf("VERT_MOYEN") != -1
						subLayer.name = "VERT_MOYEN"
						color = "#009F4C"
					else if subLayer.name.indexOf("ROUGE") != -1
						subLayer.name = "ROUGE"
						color = "#EC1D24"
					else if subLayer.name.indexOf("ORANGE") != -1
						subLayer.name = "ORANGE"
						color = "#F06423"
					else if subLayer.name.indexOf("MARRON_CLAIR") != -1
						subLayer.name = "MARRON_CLAIR"
						color = "#895D3B"
					else if subLayer.name.indexOf("MARRON_FONCE") != -1
						subLayer.name = "MARRON_FONCE"
						color = "#5F3713"
					else if subLayer.name.indexOf("MARRON") != -1
						subLayer.name = "MARRON"
						color = "#895D3B"
					else if subLayer.name.indexOf("JAUNE") != -1
						subLayer.name = "JAUNE"
						color = "#FFDC23"
					else if subLayer.name.indexOf("BLEU_FONCE") != -1
						subLayer.name = "BLEU_FONCE"
						color = "#2C388D"
					else if subLayer.name.indexOf("BLEU_CLAIR") != -1
						subLayer.name = "BLEU_CLAIR"
						color = "#1E75B9"
					else if subLayer.name.indexOf("VIOLET") != -1
						subLayer.name = "VIOLET"
						color = "#7F3F95"
					else if subLayer.name.indexOf("NOIR") != -1
						subLayer.name = "NOIR"
						color = "#000000"
					else
						console.log("UNKNOW COLOR")
						color = "#2C388D"
					@setItemColor(subLayer, color)

					compoundLayer = new P.CompoundPath()
					contours = new P.CompoundPath()
					@convertGroupsToCompoundPath(subLayer, compoundLayer, contours)

					contours.simplify()

					intersection = compoundLayer.clone().intersect(stripes.clone())
					intersections = contours.getIntersections(lines)

					interesctionPoints = new P.CompoundPath()
					for curveLocation in intersections
						interesctionPoint = new P.Path()
						interesctionPoint.add(curveLocation.point)
						interesctionPoint.add(curveLocation.point.add(50, 0))
						interesctionPoints.addChild(interesctionPoint)

					result = new P.Group()
					result.addChild(interesctionPoints)

					if intersection.children
						# result.addChild(intersection)
						pathWithoutContour = new P.CompoundPath()
						# nHLines = 0

						for p in  intersection.children
							for segment in p.segments
								# findY = (y)->
								# 	return Math.abs(y-segment.point.y)<0.5
								# if segment.next? && Math.abs(segment.point.y - segment.next.point.y) < 0.5 and yToKeep.find(findY) != null
								if segment.next? && Math.abs(segment.point.y - segment.next.point.y) < 0.5
									found = false
									for y in yToKeep
										if Math.abs(y-segment.point.y) < 0.5
											found = true
											break
									if found
										# if nHLines%2 == 0
										line = new P.Path()
										line.add(segment.point)
										line.add(segment.next.point)
										pathWithoutContour.addChild(line)

									# nHLines++
						result.addChild(pathWithoutContour)

					# result.addChild(contoursAndFills)

					result.fillColor = null
					result.strokeColor = color
					result.strokeWidth = 27
					result.name = subLayer.name

					group.addChild(result)

					svg = result.exportSVG( asString: true )
					svg = svg.replace(new RegExp('<g', 'g'), '<svg')
					svg = svg.replace(new RegExp('</g', 'g'), '</svg')

					blob = new Blob([svg], {type: 'image/svg+xml'})
					filename = "Layer" + index + "." + j + "-" + subLayer.name + ".svg"
					img.file(filename, blob, {base64: true})
				index++

			border = new P.Path.Rectangle(@rectangle)
			border.strokeWidth = 1
			border.strokeColor = "black"
			group.addChild(border)
			result = group
			# result.position = new P.Point(result.bounds.size.multiply(0.5))
			svg = result.exportSVG( asString: true )
			svg = svg.replace(new RegExp('<g', 'g'), '<svg')
			svg = svg.replace(new RegExp('</g', 'g'), '</svg')

			blob = new Blob([svg], {type: 'image/svg+xml'})
			url = URL.createObjectURL(blob)

			filename = "plantsCleanedReduced.svg"

			link = document.createElement("a")
			document.body.appendChild(link)
			link.href = url
			link.download = filename
			link.text = filename
			link.click()
			document.body.removeChild(link)

			saveZip = ()->
				zip.generateAsync({type:"blob"}).then((content)->
					saveAs(content, "Layers.zip")
				)
				return

			setTimeout(saveZip, 5000)

			return

			# raster = new P.CompoundPath()
			# @convertGroupsToCompoundPath(originalRaster, raster)
			#
			# console.log("originalRaster")
			# @logItem(originalRaster)
			# console.log("raster")
			# @logItem(raster)
			#
			# raster.position = @rectangle.center
			# if @data.fitToRectangle
			# 	raster.fitBounds(@rectangle, false)
			# else
			# 	raster.position = @rectangle.center
			# 	@rectangle.width = originalRaster.bounds.width
			# 	@rectangle.height = originalRaster.bounds.height
			# 	@rectangle.center = originalRaster.position
			#
			# margin = 50
			# yStepSize = (@rectangle.height+margin) / @data.nStripes
			#
			# stripes = new P.CompoundPath()
			# stripes.strokeWidth = 1
			# stripes.strokeColor = 'black'
			#
			# center = @rectangle.center
			# position = @rectangle.left - margin/2
			#
			# for i in [0 .. @data.nStripes]
			# 	# console.log(position)
			# 	stripe = new P.Path.Rectangle(position, new P.Size(@rectangle.width+margin, yStepSize/2))
			# 	stripe.fillColor = 'black'
			# 	stripes.addChild(stripe)
			# 	position = position.add(0, yStepSize)
			#
			# path = stripes.intersect(raster.clone())
			#
			# if @data.removeContours
			# 	pathWithoutContour = new P.CompoundPath()
			# 	for p in  path.children
			# 		for segment in p.segments
			# 			if segment.next? && Math.abs(segment.point.y - segment.next.point.y) < 1.5
			# 				line = new P.Path()
			# 				line.add(segment.point)
			# 				line.add(segment.next.point)
			# 				pathWithoutContour.addChild(line)
			# 	path.remove()
			# 	path = pathWithoutContour
			# path.strokeWidth = 1
			# path.strokeColor = 'black'
			# @drawing.addChild(path)
			# @drawing.addChild(raster)
			# raster.fillColor = null
			# raster.strokeColor = 'black'
			# raster.strokeWidth = 1
			#
			# stripes.remove()

			return

		convertPathsToDots: (item, group, colorsToCompoundPath, saveLayer, img, index, color)->

			if saveLayer == 1
				color = "rien"

			if item.strokeColor?
				color = item.strokeColor

			if item.children?
				length = item.children.length
				childToRemove = []
				for i in [0 .. length-1]
					child = item.children[i]
					if @convertPathsToDots(child, group, colorsToCompoundPath, saveLayer+1, img, i, color)
						childToRemove.push(child)
				for child in childToRemove
					child.remove()

			if saveLayer == 1
				svg = item.exportSVG( asString: true )
				svg = svg.replace(new RegExp('<g', 'g'), '<svg')
				svg = svg.replace(new RegExp('</g', 'g'), '</svg')

				blob = new Blob([svg], {type: 'image/svg+xml'})
				colorHexString = tinycolor(color.toCSS()).toHexString()
				colorName = @classifier.classify(colorHexString)
				console.log(colorName)
				# console.log(item.strokeColor.toCSS())
				filename = "Layer" + index + "-" + colorName + ".svg"
				img.file(filename, blob, {base64: true})


			if item instanceof P.Path # and item.strokeColor?
				#
				# compoundPath = colorsToCompoundPath[item.strokeColor]
				# if not compoundPath?
				# 	compoundPath = new P.CompoundPath()
				# 	colorsToCompoundPath[item.strokeColor] = compoundPath
				# 	compoundPath.strokeColor = item.strokeColor
				# 	compoundPath.strokeWidth = 80
				# 	group.addChild(compoundPath)

				if @data.keepLines
					if item.segments.length == 2 and item.firstSegment.point.y == item.lastSegment.point.y
						return false

				position = 0
				length = item.length
				# console.log("lenght: "+length)

				while position < length

					p = item.getPointAt(position)
					path = new P.Path()
					path.add(p)
					path.add(p.add(1, 0))
					# path.strokeWidth = 80
					# path.strokeColor = item.strokeColor
					# path.fillColor = item.strokeColor
					# console.log("color: " + path.strokeColor.toCSS() + " - " + p.toString())
					# compoundPath.addChild(path)
					# compoundPath.addChild(path)
					item.parent.addChild(path)
					position += @data.circleSize
				return true

			return false

		convertLinesToDots: ()->
			originalRaster = @rasters[0].clone()

			# originalRaster.scale(1.36)
			originalRaster.position = new P.Point(0, originalRaster.bounds.height/2)
			@rectangle.width = originalRaster.bounds.width
			@rectangle.height = originalRaster.bounds.height
			@rectangle.center = originalRaster.position

			group = new P.Group()
			colorsToCompoundPath = {}

			zip = new JSZip()
			img = zip.folder("Layers")

			@convertPathsToDots(originalRaster, group, colorsToCompoundPath, 0, img)
			result = originalRaster

			# result = new P.Group()
			# result.addChild(compoundPath)

			svg = result.exportSVG( asString: true )
			svg = svg.replace(new RegExp('<g', 'g'), '<svg')
			svg = svg.replace(new RegExp('</g', 'g'), '</svg')

			blob = new Blob([svg], {type: 'image/svg+xml'})
			filename = "dots.svg"

			url = URL.createObjectURL(blob)

			link = document.createElement("a")
			document.body.appendChild(link)
			link.href = url
			link.download = filename
			link.text = filename
			link.click()
			document.body.removeChild(link)

			saveZip = ()->
				zip.generateAsync({type:"blob"}).then((content)->
					saveAs(content, "Layers.zip")
				)
				return

			setTimeout(saveZip, 5000)

			return

		drawCMYKstripes: ()->
			originalRaster = @rasters[0].clone()

			if @data.fitToRectangle
				originalRaster.fitBounds(@rectangle, false)
			else
				originalRaster.scale(1.36)
				originalRaster.position = new P.Point(0, originalRaster.bounds.height/2)
				@rectangle.width = originalRaster.bounds.width
				@rectangle.height = originalRaster.bounds.height
				@rectangle.center = originalRaster.position

			margin = 50
			yStepSize = (@rectangle.height+margin) / @data.nStripes

			stripes = new P.CompoundPath()
			stripes.strokeWidth = 1
			stripes.strokeColor = 'black'

			lines = new P.CompoundPath()
			lines.strokeWidth = 1
			lines.strokeColor = 'black'

			center = @rectangle.center
			position = @rectangle.topLeft.subtract(margin/2)

			yToKeep = []
			for i in [0 .. @data.nStripes]
				# console.log(position)
				stripe = new P.Path.Rectangle(position, new P.Size(@rectangle.width+margin, yStepSize/2))
				stripe.fillColor = 'black'
				stripes.addChild(stripe)
				line = new P.Path()
				line.add(stripe.bounds.topLeft)
				line.add(stripe.bounds.topRight)
				lines.addChild(line)
				position = position.add(0, yStepSize)
				yToKeep.push(stripe.bounds.top)

			zip = new JSZip()
			img = zip.folder("simpleStriped")
			group = new P.Group()

			colors = {}

			for item in originalRaster.children
				if not item.fillColor?
					console.log('no fill color')
					continue
				if not colors[item.fillColor]?
					colors[item.fillColor] = new P.CompoundPath()
					colors[item.fillColor].fillColor = item.fillColor
				colors[item.fillColor].addChild(item.clone())

			index = 0
			for color, item of colors

				fillColor = item.fillColor
				intersection = item.intersect(stripes.clone())

				result = new P.Group()

				if intersection.children
					# result.addChild(intersection)
					pathWithoutContour = new P.CompoundPath()
					# nHLines = 0

					for p in  intersection.children
						for segment in p.segments
							# findY = (y)->
							# 	return Math.abs(y-segment.point.y)<0.5
							# if segment.next? && Math.abs(segment.point.y - segment.next.point.y) < 0.5 and yToKeep.find(findY) != null
							if segment.next? && Math.abs(segment.point.y - segment.next.point.y) < 0.5
								found = false
								for y in yToKeep
									if Math.abs(y-segment.point.y) < 0.5
										found = true
										break
								if found
									# if nHLines%2 == 0
									line = new P.Path()
									line.add(segment.point)
									line.add(segment.next.point)
									pathWithoutContour.addChild(line)

								# nHLines++
					result.addChild(pathWithoutContour)

				result.fillColor = null
				result.strokeColor = fillColor
				result.strokeWidth = 	6

				group.addChild(result)

				svg = result.exportSVG( asString: true )
				svg = svg.replace(new RegExp('<g', 'g'), '<svg')
				svg = svg.replace(new RegExp('</g', 'g'), '</svg')

				blob = new Blob([svg], {type: 'image/svg+xml'})

				colorHexString = tinycolor(fillColor.toCSS()).toHexString()
				colorName = @classifier.classify(colorHexString)

				filename = "Layer-" + index + "-" + colorName + ".svg"
				img.file(filename, blob, {base64: true})
				index++

			border = new P.Path.Rectangle(@rectangle)
			border.strokeWidth = 1
			border.strokeColor = "black"
			group.addChild(border)
			result = group
			# result.position = new P.Point(result.bounds.size.multiply(0.5))
			svg = result.exportSVG( asString: true )
			svg = svg.replace(new RegExp('<g', 'g'), '<svg')
			svg = svg.replace(new RegExp('</g', 'g'), '</svg')

			blob = new Blob([svg], {type: 'image/svg+xml'})
			url = URL.createObjectURL(blob)

			filename = "simpleStriped.svg"

			link = document.createElement("a")
			document.body.appendChild(link)
			link.href = url
			link.download = filename
			link.text = filename
			link.click()
			document.body.removeChild(link)

			saveZip = ()->
				zip.generateAsync({type:"blob"}).then((content)->
					saveAs(content, "simpleStriped.zip")
				)
				return

			setTimeout(saveZip, 5000)

			return

		createShape: ()->
			# super()
			@shape = new P.Group()
			@allRastersLoaded()
			return

	return Striper
