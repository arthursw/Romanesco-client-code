define [ 'UI/Controllers/Controller', 'UI/Controllers/ColorController', 'UI/Controllers/Folder', 'gui' ], (Controller, ColorController, Folder, GUI) ->

	console.log 'ControllerManager'

	class ControllerManager

		@initializeGlobalParameters: ()->
			console.log 'initializeGlobalParameters'
			# R.defaultColors = ['#bfb7e6', '#7d86c1', '#403874', '#261c4e', '#1f0937', '#574331', '#9d9121', '#a49959', '#b6b37e', '#91a3f5' ]
			# R.defaultColors = ['#d7dddb', '#4f8a83', '#e76278', '#fac699', '#712164']
			# R.defaultColors = ['#395A8F', '#4A79B1', '#659ADF', '#A4D2F3', '#EBEEF3']

			R.defaultColors = []

			R.polygonMode = false					# whether to draw in polygon mode or not (in polygon mode: each time the user clicks a point
													# will be created, in default mode: each time the user moves the mouse a point will be created)
			R.selectionBlue = '#2fa1d6'

			hueRange = Utils.random(10, 180)
			minHue = Utils.random(0, 360-hueRange)
			step = hueRange/10

			for i in [0 .. 10]
				R.defaultColors.push(new P.Color( hue: minHue + i * step, saturation: Utils.random(0.3, 0.9), lightness: Utils.random(0.5, 0.7) ).toCSS())
				# R.defaultColors.push(Color.random().toCSS())

			R.parameters = {}
			R.parameters['General'] = {}
			R.parameters['General'].location =
				type: 'string'
				label: 'Location'
				default: '0.0, 0.0'
				permanent: true
				onFinishChange: (value)->
					R.view.setPositionFromString(value)
					return
			R.parameters['General'].zoom =
				type: 'slider'
				label: 'Zoom'
				min: 1
				max: 500
				default: 100
				permanent: true
				onChange: (value)->
					P.view.zoom = value/100.0
					R.view.grid.update()
					R.rasterizer.move()
					for div in R.divs
						div.updateTransform()
					return
				onFinishChange: (value) ->
					R.loader.load()
					return
			R.parameters['General'].displayGrid =
				type: 'checkbox'
				label: 'Display grid'
				default: false
				permanent: true
				onChange: (value)->
					R.displayGrid = !R.displayGrid
					R.view.grid.update()
					return
			R.parameters['General'].ignoreSockets =
				type: 'checkbox'
				label: 'Ignore sockets'
				default: false
				onChange: (value)->
					R.ignoreSockets = value
					return
			R.parameters['General'].snap =
				type: 'slider'
				label: 'Snap'
				min: 0
				max: 100
				step: 5
				default: 0
				snap: 0
				permanent: true
				onChange: ()-> R.view.grid.update()
			R.parameters['General'].sendToSpacebrew =
				type: 'button'
				label: 'Send Spacebrew'
				permanent: true
				default: ()-> item.requireAndSendToSpacebrew?() for item in R.selectedItems; return
				onChange: ()-> return
			R.parameters['General'].exportToSVG =
				type: 'button'
				label: 'Export to SVG'
				permanent: true
				default: ()-> item.exportToSVG?() for item in R.selectedItems; return
				onChange: ()-> return

			# R.parameters.fastMode =
			# 	type: 'checkbox'
			# 	label: 'Fast mode'
			# 	default: R.fastMode
			# 	permanent: true
			# 	onChange: (value)->
			# 		R.fastMode = value
			# 		return

			R.parameters.default = {}
			R.parameters.strokeWidth =
				type: 'slider'
				label: 'Stroke width'
				min: 1
				max: 100
				default: 5
			R.parameters.strokeColor =
				type: 'color'
				label: 'Stroke color'
				default: Utils.Array.random(R.defaultColors)
				# defaultFunction: () -> return R.selectedStrokeColor
				# defaultFunction: () -> return Utils.Array.random(R.defaultColors)
				defaultCheck: true 						# checked/activated by default or not
			R.parameters.fillColor =
				type: 'color'
				label: 'Fill color'
				default: Utils.Array.random(R.defaultColors)
				# defaultFunction: () -> return R.selectedFillColor
				defaultCheck: false 					# checked/activated by default or not
			R.parameters.delete =
				type: 'button'
				label: 'Delete items'
				default: ()->
					selectedItems = R.selectedItems.slice() # copy array because it will change; could be: while R.selectedItem.length>0: R.selectedItem[0].delete()
					for item in selectedItems
						item.deleteCommand()
					return
				onChange: ()-> return
			R.parameters.duplicate =
				type: 'button'
				label: 'Duplicate items'
				default: ()-> item.duplicateCommand() for item in R.selectedItems; return
			R.parameters.align =
				type: 'button-group'
				label: 'Align'
				default: ''
				initializeController: (controller)->
					domElement = controller.datController.domElement
					$(domElement).find('input').remove()

					align = (type)->
						items = R.selectedItems
						switch type
							when 'h-top'
								yMin = NaN
								for item in items
									top = item.getBounds().top
									if isNaN(yMin) or top < yMin
										yMin = top
								items.sort((a, b)-> return a.getBounds().top - b.getBounds().top)
								for item in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(bounds.centerX, top+bounds.height/2))
							when 'h-center'
								avgY = 0
								for item in items
									avgY += item.getBounds().centerY
								avgY /= items.length
								items.sort((a, b)-> return a.getBounds().centerY - b.getBounds().centerY)
								for item in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(bounds.centerX, avgY))
							when 'h-bottom'
								yMax = NaN
								for item in items
									bottom = item.getBounds().bottom
									if isNaN(yMax) or bottom > yMax
										yMax = bottom
								items.sort((a, b)-> return a.getBounds().bottom - b.getBounds().bottom)
								for item in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(bounds.centerX, bottom-bounds.height/2))
							when 'v-left'
								xMin = NaN
								for item in items
									left = item.getBounds().left
									if isNaN(xMin) or left < xMin
										xMin = left
								items.sort((a, b)-> return a.getBounds().left - b.getBounds().left)
								for item in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(xMin+bounds.width/2, bounds.centerY))
							when 'v-center'
								avgX = 0
								for item in items
									avgX += item.getBounds().centerX
								avgX /= items.length
								items.sort((a, b)-> return a.getBounds().centerY - b.getBounds().centerY)
								for item in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(avgX, bounds.centerY))
							when 'v-right'
								xMax = NaN
								for item in items
									right = item.getBounds().right
									if isNaN(xMax) or right > xMax
										xMax = right
								items.sort((a, b)-> return a.getBounds().right - b.getBounds().right)
								for item in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(xMax-bounds.width/2, bounds.centerY))
						return

					# todo: change fontStyle id to class
					R.templatesJ.find("#align").clone().appendTo(domElement)
					alignJ = $("#align:first")
					alignJ.find("button").click ()-> align($(this).attr("data-type"))
					return
			R.parameters.distribute =
				type: 'button-group'
				label: 'Distribute'
				default: ''
				initializeController: (controller)->
					domElement = controller.datController.domElement
					$(domElement).find('input').remove()

					distribute = (type)->
						items = R.selectedItems
						switch type
							when 'h-top'
								yMin = NaN
								yMax = NaN
								for item in items
									top = item.getBounds().top
									if isNaN(yMin) or top < yMin
										yMin = top
									if isNaN(yMax) or top > yMax
										yMax = top
								step = (yMax-yMin)/(items.length-1)
								items.sort((a, b)-> return a.getBounds().top - b.getBounds().top)
								for item, i in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(bounds.centerX, yMin+i*step+bounds.height/2))
							when 'h-center'
								yMin = NaN
								yMax = NaN
								for item in items
									center = item.getBounds().centerY
									if isNaN(yMin) or center < yMin
										yMin = center
									if isNaN(yMax) or center > yMax
										yMax = center
								step = (yMax-yMin)/(items.length-1)
								items.sort((a, b)-> return a.getBounds().centerY - b.getBounds().centerY)
								for item, i in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(bounds.centerX, yMin+i*step))
							when 'h-bottom'
								yMin = NaN
								yMax = NaN
								for item in items
									bottom = item.getBounds().bottom
									if isNaN(yMin) or bottom < yMin
										yMin = bottom
									if isNaN(yMax) or bottom > yMax
										yMax = bottom
								step = (yMax-yMin)/(items.length-1)
								items.sort((a, b)-> return a.getBounds().bottom - b.getBounds().bottom)
								for item, i in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(bounds.centerX, yMin+i*step-bounds.height/2))
							when 'v-left'
								xMin = NaN
								xMax = NaN
								for item in items
									left = item.getBounds().left
									if isNaN(xMin) or left < xMin
										xMin = left
									if isNaN(xMax) or left > xMax
										xMax = left
								step = (xMax-xMin)/(items.length-1)
								items.sort((a, b)-> return a.getBounds().left - b.getBounds().left)
								for item, i in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(xMin+i*step+bounds.width/2, bounds.centerY))
							when 'v-center'
								xMin = NaN
								xMax = NaN
								for item in items
									center = item.getBounds().centerX
									if isNaN(xMin) or center < xMin
										xMin = center
									if isNaN(xMax) or center > xMax
										xMax = center
								step = (xMax-xMin)/(items.length-1)
								items.sort((a, b)-> return a.getBounds().centerX - b.getBounds().centerX)
								for item, i in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(xMin+i*step, bounds.centerY))
							when 'v-right'
								xMin = NaN
								xMax = NaN
								for item in items
									right = item.getBounds().right
									if isNaN(xMin) or right < xMin
										xMin = right
									if isNaN(xMax) or right > xMax
										xMax = right
								step = (xMax-xMin)/(items.length-1)
								items.sort((a, b)-> return a.getBounds().right - b.getBounds().right)
								for item, i in items
									bounds = item.getBounds()
									item.moveTo(new P.Point(xMin+i*step-bounds.width/2, bounds.centerY))
						return

					# todo: change fontStyle id to class
					R.templatesJ.find("#distribute").clone().appendTo(domElement)
					distributeJ = $("#distribute:first")
					distributeJ.find("button").click ()-> distribute($(this).attr("data-type"))
					return

			colorName = Utils.Array.random(R.defaultColors)
			R.strokeColor = colorName
			R.fillColor = "rgb(255,255,255,255)"
			R.displayGrid = false
			return

		console.log 'call initializeGlobalParameters'
		@initializeGlobalParameters()


		constructor: ()->

			dat.GUI.autoPace = false
			R.gui = new dat.GUI()
			dat.GUI.toggleHide = ()-> return
			@folders = {}

			R.templatesJ.find("button.dat-gui-toggle").clone().appendTo(R.gui.domElement)
			toggleGuiButtonJ = $(R.gui.domElement).find("button.dat-gui-toggle")

			toggleGuiButtonJ.click(@toggleGui)

			if localStorage.optionsBarPosition? and localStorage.optionsBarPosition == 'sidebar'
				$(".dat-gui.dg-sidebar").append(R.gui.domElement)
			else
				$(".dat-gui.dg-right").append(R.gui.domElement)

			return

		createGlobalControllers: ()->
			generalFolder = new Folder('General')

			for name, parameter of R.parameters['General']
				@createController(name, parameter, generalFolder)

			return

		toggleGui: ()->
			parentJ = $(R.gui.domElement).parent()
			if parentJ.hasClass("dg-sidebar")
				$(".dat-gui.dg-right").append(R.gui.domElement)
				localStorage.optionsBarPosition = 'right'
			else if parentJ.hasClass("dg-right")
				$(".dat-gui.dg-sidebar").append(R.gui.domElement)
				localStorage.optionsBarPosition = 'sidebar'
			return

		removeUnusedControllers: ()->
			for folderName, folder of @folders
				if folder.name == 'General' then continue
				for name, controller of folder.controllers
					if not controller.used
						controller.remove()
					else
						controller.used = false 	# for the next time
			return

		updateHeight: ()->

			# # if dat.gui is in sidebar refresh its size and visibility in 500 milliseconds,
			# # (to fix a bug: sometimes dat.gui is too small, with a scrollbar )
			# if $(R.gui.domElement).parent().hasClass('dg-sidebar')
			# 	setTimeout( ()->
			# 		$(R.gui.domElement).find("ul:first").css( 'height': 'initial' )
			# 		$(R.gui.domElement).css( 'z-index': 'auto' )
			# 	,
			# 	500)

			return

		createController: (name, parameter, folder)->
			controller = null
			switch parameter.type
				when 'color'
					controller = new ColorController(name, parameter, folder)
				else
					controller = new Controller(name, parameter, folder)
			return controller

		initializeControllers: ()->
			for folderName, folder of @folders
				for name, controller of folder.controllers
					controller.parameter.initializeController?(controller)
			return

		# resetControllers: ()->
		# 	for folderName, folder of @folders
		# 		for name, controller of folder.controllers
		# 			controller.reset()
		# 	return

		initializeValue: (name, parameter, firstItem)->
			value = null
			if firstItem?.data?[name] isnt undefined
				value = firstItem.data[name]
			else if parameter.default?
				value = parameter.default
			else if parameter.defaultFunction?
				value = parameter.defaultFunction()
			return value

		updateControllers: (tools, resetValues=false)->
			# @resetControllers()

			for name, tool of tools

				for folderName, folderParameters of tool.parameters

					if folderName == 'General' then continue

					folder = @folders[folderName]
					folder ?= new Folder(folderName, folderParameters.folderIsClosedByDefault)

					for name, parameter of folderParameters  							# for all parameters of the folder
						if name == 'folderIsClosedByDefault' then continue

						controller = folder.controllers[name]

						if parameter.alwaysInitializeValue
							parameter.value = @initializeValue(name, parameter, tool.items[0])

						if controller?
							if resetValues then controller.setValue(parameter.value, false)
						else
							controller ?= @createController(name, parameter, folder)

						parameter.controller = controller

						controller.used = true

			@removeUnusedControllers()
			@initializeControllers()

			return

		updateController: (controllerName, value)->
			for folderName, folder of @folders
				for name, controller of folder.controllers
					if name == controllerName
						controller.setValue(value)
			return

		updateParametersForSelectedItems: ()->
			Utils.callNextFrame(@updateParametersForSelectedItemsCallback, 'updateParametersForSelectedItems')
			return

		updateParametersForSelectedItemsCallback: ()=>
			tools = {}

			for item in R.selectedItems

				tools[item.constructor.name] ?= parameters: item.constructor.parameters, items: []
				tools[item.constructor.name].items.push(item)

			console.log("updateControllers: ", R.selectedItems, tools)
			@updateControllers(tools, false)
			return

		setSelectedTool: (tool)->
			Utils.cancelCallNextFrame('updateParametersForSelectedItems')
			tools = {}
			tools[tool.name] = parameters: tool.parameters, items: []
			@updateControllers(tools, false)
			return

		updateItemData: (item)->
			for name, folder of @folders
				if name=='General' or name=='Items' then continue
				for name, controller of folder.controllers
					item.data[controller.name] ?= controller.getValue()
			return

		getController: (folderNames, controllerName)->
			if not Utils.Array.isArray(folderNames) then folderNames = [folderNames]
			folder = folders: @folders
			for folderName in folderNames
				folder = folder.folders[folderName]
				if not folder? then return
			return folder.controllers[controllerName]

		# todo: replace parameters() with getParameters() and get only once

	return ControllerManager
