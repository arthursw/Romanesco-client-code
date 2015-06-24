define [ 'tinycolor', 'gui', 'colorpickersliders' ], (tinycolor, GUI) ->

	# --- Options --- #

	# todo: improve reset parameter values when selection

	# this.updateFillColor = ()->
	# 	if not R.itemsToUpdate?
	# 		return
	# 	for item in R.itemsToUpdate
	# 		if item.controller?
	# 			R.updatePath(item.controller, 'fillColor')
	# 	if R.itemsToUpdate.divJ?
	# 		updateDiv(R.itemsToUpdate)
	# 	return

	# this.updateStrokeColor = ()->
	# 	if not R.itemsToUpdate?
	# 		return
	# 	for item in R.itemsToUpdate
	# 		R.updatePath(item.controller, 'strokeColor')
	# 	if R.itemsToUpdate.divJ?
	# 		updateDiv(R.itemsToUpdate)
	# 	return

	R.initializeGlobalParameters = ()->

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
			R.defaultColors.push(Color.HSL( minHue + i * step, Utils.random(0.3, 0.9), Utils.random(0.5, 0.7) ).toCSS())
			# R.defaultColors.push(Color.random().toCSS())

		R.parameters = {}
		R.parameters['General'] = {}
		R.parameters['General'].location =
			type: 'string'
			label: 'Location'
			default: '0.0, 0.0'
			permanent: true
			onFinishChange: (value)->
				R.ignoreHashChange = false
				location.hash = value
				return
		R.parameters['General'].zoom =
			type: 'slider'
			label: 'Zoom'
			min: 1
			max: 500
			default: 100
			permanent: true
			onChange: (value)->
				P.project.P.view.zoom = value/100.0
				Grid.updateGrid()
				R.rasterizer.move()
				for div in R.divs
					div.updateTransform()
				return
			onFinishChange: (value) ->
				R.load()
				return
		R.parameters['General'].displayGrid =
			type: 'checkbox'
			label: 'Display grid'
			default: false
			permanent: true
			onChange: (value)->
				R.displayGrid = !R.displayGrid
				Grid.updateGrid()
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
			onChange: ()-> Grid.updateGrid()
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
			default: 1
		R.parameters.strokeColor =
			type: 'color'
			label: 'Stroke color'
			default: Utils.Array.random(R.defaultColors)
			defaultFunction: () -> return Utils.Array.random(R.defaultColors)
			defaultCheck: true 						# checked/activated by default or not
		R.parameters.fillColor =
			type: 'color'
			label: 'Fill color'
			default: Utils.Array.random(R.defaultColors)
			defaultCheck: false 					# checked/activated by default or not
		R.parameters.delete =
			type: 'button'
			label: 'Delete items'
			default: ()->
				selectedItems = R.selectedItems.slice() # copy array because it will change; could be: while R.selectedItem.length>0: R.selectedItem[0].delete()
				for item in selectedItems
					item.deleteCommand()
				return
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
		colorRGBstring = tinycolor(colorName).toRgbString()
		R.strokeColor = colorRGBstring
		R.fillColor = "rgb(255,255,255,255)"
		R.displayGrid = false

		return

	R.initializeGlobalParameters()

	# Initialize general and default parameters
	R.initParameters = () ->

		R.optionsJ = $(".option-list")


		# --- DAT GUI/ --- #

		# todo: use addItems for general settings!!!
		R.controllerManager = new R.ControllerManager()

		generalFolder = new R.Folder('General')

		for name, parameter of R.parameters['General']
			R.controllerManager.createController(name, parameter, generalFolder)

		# controller = R.generalFolder.add({location: R.parameters.location.default}, 'location')
		# .name("Location")
		# .onFinishChange( R.parameters.location.onFinishChange )

		# R.generalFolder.add({zoom: 100}, 'zoom', R.parameters.zoom.min, R.parameters.zoom.max)
		# .name("Zoom")
		# .onChange( R.parameters.zoom.onChange )
		# .onFinishChange( R.parameters.zoom.onFinishChange )

		# R.generalFolder.add({displayGrid: R.parameters.displayGrid.default}, 'displayGrid', true)
		# .name("Display grid")
		# .onChange(R.parameters.displayGrid.onChange)
		# # R.generalFolder.add({fastMode: R.parameters.fastMode.default}, 'fastMode', true).name("Fast mode").onChange(R.parameters.fastMode.onChange)

		# R.generalFolder.add({ignoreSockets: R.parameters.ignoreSockets.default}, 'ignoreSockets', false)
		# .name(R.parameters.ignoreSockets.name)
		# .onChange(R.parameters.ignoreSockets.onChange)

		# R.generalFolder.add(R.parameters.snap, 'snap', R.parameters.snap.min, R.parameters.snap.max)
		# .name(R.parameters.snap.label)
		# .step(R.parameters.snap.step)
		# .onChange(R.parameters.snap.onChange)

		R.addRasterizerParameters()

		# --- /DAT GUI --- #

		# --- Text options --- #

		# R.textOptionsJ = R.optionsJ.find(".text-options")

		# R.stylePickerJ = R.textOptionsJ.find('#fontStyle')
		# # R.subsetPickerJ = R.optionsJ.find('#fontSubset')
		# R.effectPickerJ = R.textOptionsJ.find('#fontEffect')
		# R.sizePickerJ = R.textOptionsJ.find('#fontSizeSlider')
		# R.sizePickerJ.slider().on('slide', (event)-> R.fontSize = event.value )

		R.availableFonts = []
		R.usedFonts = []
		jQuery.support.cors = true

		# $.getJSON("https://www.googleapis.com/webfonts/v1/webfonts?key=AIzaSyD2ZjTQxVfi34-TMKjB5WYK3U8K6y-IQH0", initTextOptions)
		jqxhr = $.getJSON("https://www.googleapis.com/webfonts/v1/webfonts?key=AIzaSyBVfBj_ugQO_w0AK1x9F6yiXByhcNgjQZU", R.initTextOptions)
		jqxhr.done (json)->
			console.log 'done'
			R.initTextOptions(json)
			return
		jqxhr.fail (jqxhr, textStatus, error)->
			err = textStatus + ", " + error
			console.log 'failed: ' + err
			return
		jqxhr.always (jqxhr, textStatus, error)->
			err = textStatus + ", " + error
			console.log 'always: ' + err
			return

	# add font to the page:
	# - check if the font is already loaded, and with which effect
	# - load web font from google font if needed
	R.addFont = (fontFamily, effect)->
		if not fontFamily? then return

		fontFamilyURL = fontFamily.split(" ").join("+")

		# update R.usedFonts, check if the font is already
		fontAlreadyUsed = false
		for font in R.usedFonts
			if font.family == fontFamilyURL
				# if font.subsets.indexOf(subset) == -1 and subset != 'latin'
				# 	font.subsets.push(subset)
				# if font.styles.indexOf(style) == -1
				# 	font.styles.push(style)
				if font.effects.indexOf(effect) == -1 and effect?
					font.effects.push(effect)
				fontAlreadyUsed = true
				break
		if not fontAlreadyUsed 		# if the font is not already used (loaded): load the font with the effect
			# subsets = [subset]
			# if subset!='latin'
			# 	subsets.push('latin')
			effects = []
			if effect?
				effects.push(effect)
			if not fontFamilyURL or fontFamilyURL == ''
				console.log 'ERROR: font family URL is null or empty'
			R.usedFonts.push( family: fontFamilyURL, effects: effects )
		return

	# todo: use google web api to update text font on load callback
	# fonts could have multiple effects at once, but the gui does not allow this yet
	# since having multiple effects would not be of great use
	# must be improved!!
	R.loadFonts = ()->
		$('head').remove("link.fonts")

		for font in R.usedFonts
			newFont = font.family
			# if font.styles.length>0
			# 	newFont += ":"
			# 	for style in font.styles
			# 		newFont += style + ','
			# 	newFont = newFont.slice(0,-1)
			# if font.subsets.length>0
			# 	newFont += "&subset="
			# 	for subset in font.subsets
			# 		newFont += subset + ','
			# 	newFont = newFont.slice(0,-1)

			if $('head').find('link[data-font-family="' + font.family + '"]').length==0

				if font.effects.length>0 and not (font.effects.length == 1 and font.effects[0] == 'none')
					newFont += "&effect="
					for effect, i in font.effects
						newFont += effect + '|'
					newFont = newFont.slice(0,-1)

				fontLink = $('<link class="fonts" data-font-family="' + font.family + '" rel="stylesheet" type="text/css">')
				fontLink.attr('href', "http://fonts.googleapis.com/css?family=" + newFont)
				$('head').append(fontLink)
		return

	# initialize typeahead font engine to quickly search for a font by typing its first letters
	R.initTextOptions = (data, textStatus, jqXHR) ->

		# gather all font names
		fontFamilyNames = []
		for item in data.items
			fontFamilyNames.push({ value: item.family })

		# initialize typeahead font engine
		R.typeaheadFontEngine = new Bloodhound({
			name: 'Font families',
			local: fontFamilyNames,
			datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
			queryTokenizer: Bloodhound.tokenizers.whitespace
		})
		promise = R.typeaheadFontEngine.initialize()

		R.availableFonts = data.items

		# test
		# R.familyPickerJ = R.textOptionsJ.find('#fontFamily')
		# R.familyPickerJ.typeahead(
		# 	{ hint: true, highlight: true, minLength: 1 },
		# 	{ valueKey: 'value', displayKey: 'value', source: typeaheadFontEngine.ttAdapter() }
		# )

		# R.fontSubmitJ = R.textOptionsJ.find('#fontSubmit')


		# R.fontSubmitJ.click( (event) ->
		# 	R.setFontStyles()
		# )

		return

	# R.setControllerValueByName = (name, value, item)->
	# 	checked = value?
	# 	for folderName, folder of R.gui.__folders
	# 		for controller in folder.__controllers
	# 			if controller.property == name
	# 				R.setControllerValue(controller, { min: controller.__min, max: controller.__max }, value, item, checked)
	# 				break
	# 	return

	# # todo: better manage parameter..
	# # set the value of the controller without calling its onChange and onFinishChange callback
	# # controller.rSetValue (a user defined callback) is called here
	# # called when the controller is updated (when it existed, and must be updated to fit data of a newly selected tool or item)
	# R.setControllerValue = (controller, parameter, value, item, checked=false)->
	# 	onChange = controller.__onChange
	# 	onFinishChange = controller.__onFinishChange
	# 	controller.__onChange = ()->return
	# 	controller.__onFinishChange = ()->return
	# 	if parameter?
	# 		controller.min?(parameter.min)
	# 		controller.max?(parameter.max)
	# 	controller.setValue(value)
	# 	controller.rSetValue?(value, item, checked)
	# 	controller.__onChange = onChange
	# 	controller.__onFinishChange = onFinishChange

	# # doctodo: copy deault parameter doc here
	# # add a controller to dat.gui (corresponding to a parameter, from a tool or an item)
	# # @param name [String] name of the parameter (short name without spaces, same as RItem.data[name] )
	# # @param parameter [Parameter] the parameter to add
	# # @param item [RItem] optional RItem, the controller will be initialized with *item.data* if any
	# # @param datFolder [DatFolder] folder in which to add the controller
	# # @param resetValues [Boolean] (optional) true if must reset value to default (create a new default if parameter has a defaultFunction)
	# addItem = (name, parameter, item, datFolder, resetValues)->

	# 	# intialize the default value
	# 	# a color can be null, then it is disabled
	# 	if item? and datFolder.name != 'General' and item.data? and (item.data[name]? or parameter.type=='color')
	# 		value = item.data[name]
	# 	else if parameter.value?
	# 		value = parameter.value
	# 	else if parameter.defaultFunction?
	# 		value = parameter.defaultFunction()
	# 	else
	# 		value = parameter.default

	# 	# add controller to the current tool or item if parameter.addController
	# 	# @param [Parameter] the parameter of the controller
	# 	# @param [String] the name of the parameter
	# 	# @param [RItem] (optional) the RItem
	# 	# @param [Dat Controller] the controller to add
	# 	updateItemControllers = (parameter, name, item, controller)->
	# 		if parameter.addController
	# 			if item?
	# 				item.parameterControllers ?= {}
	# 				item.parameterControllers[name] = controller
	# 			else
	# 				R.selectedTool.parameterControllers ?= {}
	# 				R.selectedTool.parameterControllers[name] = controller
	# 		return

	# 	# check if controller already exists for this parameter, and update if exists
	# 	for controller in datFolder.__controllers
	# 		if controller.property == name and not parameter.permanent
	# 			if resetValues
	# 				# disable onChange and onFinishChange when updating the GUI after selection
	# 				checked = if item? then item.data[name] else parameter.defaultCheck
	# 				R.setControllerValue(controller, parameter, value, item, checked)
	# 				updateItemControllers(parameter, name, item, controller)
	# 			R.unusedControllers.remove(controller)
	# 			return

	# 	# - snap the value according to parameter.step
	# 	# - update item.data[name] if it is defined
	# 	# - call item.parameterChanged()
	# 	# - emit "parameter change" on websocket
	# 	onParameterChange = (value) ->
	# 		R.c = this
	# 		for item in R.selectedItems
	# 			# do not update if the value was never set (not even to null), update if it was set (even to null, for colors)
	# 			if typeof item.data?[name] isnt 'undefined'
	# 				# if parameter.step? then value = value-value%parameter.step
	# 				item.setParameterCommand(name, value)
	# 				# if R.me? and datFolder.name != 'General' then R.chatSocket.emit( "parameter change", R.me, item.pk, name, value )
	# 		return

	# 	# if parameter has no onChange function: create a default one which will update item.data[name]
	# 	if parameter.type == 'string' and not parameter.fireOnEveryChange
	# 		parameter.onFinishChange ?= onParameterChange
	# 	else
	# 		parameter.onChange ?= onParameterChange


	# 	obj = {}

	# 	switch parameter.type
	# 		when 'color' 		# create a color controller
	# 			obj[name] = ''
	# 			controller = datFolder.add(obj, name).name(parameter.label)
	# 			colorInputJ = $(datFolder.domElement).find("div.c > input:last")
	# 			colorInputJ.addClass("color-input")
	# 			checkboxJ = $('<input type="checkbox">')
	# 			checkboxJ.insertBefore(colorInputJ)
	# 			checkboxJ[0].checked = if item? and datFolder.name != 'General' then item.data[name]? else parameter.defaultCheck

	# 			# colorGUI = new dat.GUI({ autoPlace: false })
	# 			# color = :
	# 			# 	hue: 0
	# 			# 	saturation: 0
	# 			# 	lightness: 0
	# 			# 	red: 0
	# 			# 	green: 0
	# 			# 	blue: 0

	# 			# colorGUI.add(color, 'hue', 0, 1).onChange( (value)-> tinycolor.("hsv 0 1 1"))
	# 			# colorGUI.add(color, 'saturation', 0, 1)
	# 			# colorGUI.add(color, 'lightness', 0, 1)
	# 			# colorGUI.add(color, 'red', 0, 1)
	# 			# colorGUI.add(color, 'green', 0, 1)
	# 			# colorGUI.add(color, 'blue', 0, 1)

	# 			# $("body").appendChild(colorGUI.domElement)
	# 			# colorGuiJ = $(colorGUI.domElement)
	# 			# colorGuiJ.css( position: 'absolute', left: inputJ.offset().left, top: inputJ.offset().top )

	# 			initialValue = tinycolor(if value? then value else parameter.default).toRgbString()
	# 			if initialValue.gradient?
	# 				initialValue = initialValue.gradient.stops[0][0].toCSS()

	# 			gradientCheckboxChanged = (event)->
	# 				colorInputJ = $(this).parent().siblings('.color-input')

	# 				parameterName = colorInputJ.attr('data-parameter-name')
	# 				value = R.items[colorInputJ.attr('data-item-pk')]?.data[parameterName]

	# 				if this.checked
	# 					R.tools['Gradient'].select(parameterName, colorInputJ, value)
	# 					colorInputJ.attr('data-gradient', 1)
	# 				else
	# 					R.tools['Select'].select()
	# 					colorInputJ.attr('data-gradient', 0)
	# 				return

	# 			initializeColorPicker = (colorInputJ, container, gradient, parameterName, value)->
	# 				checkboxJ = $("<label><input type='checkbox' class='gradient-checkbox' form-control>Gradient</label>")
	# 				checkboxJ.insertBefore(container.find('.cp-preview'))
	# 				checkboxJ.css( 'color': 'black' )

	# 				checkboxJ.find('input').click(gradientCheckboxChanged)

	# 				if gradient
	# 					checkboxJ.find('input').attr('checked', true)
	# 					R.tools['Gradient'].select(parameterName, colorInputJ, value)

	# 				colorInputJ.attr('data-initialized', 1)
	# 				container.attr('data-trigger', '')

	# 				return

	# 			colorInputJ.attr('data-trigger', 'click')

	# 			colorInputJ = colorInputJ.ColorPickerSliders({
	# 				title: parameter.label,
	# 				placement: 'auto',
	# 				size: 'sm',
	# 				# trigger: 'click',
	# 				# hsvpanel: true
	# 				color: initialValue,
	# 				order: {
	# 					hsl: 1,
	# 					rgb: 2,
	# 					opacity: 3,
	# 					preview: 4
	# 				},
	# 				labels: {
	# 					rgbred: 'Red',
	# 					rgbgreen: 'Green',
	# 					rgbblue: 'Blue',
	# 					hslhue: 'Hue',
	# 					hslsaturation: 'Saturation',
	# 					hsllightness: 'Lightness',
	# 					preview: 'Preview',
	# 					opacity: 'Opacity'
	# 				},
	# 				customswatches: "different-swatches-groupname",
	# 				swatches: false,
	# 				# swatches: R.defaultColors,
	# 				# hsvpanel: true,
	# 				onchange: (container, color) ->
	# 					colorInputJ = this.connectedinput
	# 					initialized = parseInt(colorInputJ.attr('data-initialized'))
	# 					gradient = parseInt(colorInputJ.attr('data-gradient')
	# 					parameterName = colorInputJ.attr('data-parameter-name')
	# 					value = R.items[colorInputJ.attr('data-item-pk')]?.data[parameterName])

	# 					if not initialized
	# 						initializeColorPicker(colorInputJ, container, gradient, parameterName, value)

	# 					if gradient
	# 						R.tools['Gradient'].colorChange(color.tiny.toRgbString(), parameterName, colorInputJ, value)
	# 					else
	# 						parameter.onChange(color.tiny.toRgbString())

	# 					colorInputCheckbox = colorInputJ.siblings('[type="checkbox"]')[0]
	# 					colorInputCheckbox.checked = true
	# 			})

	# 			colorInputJ.on 'shown.bs.popover', ()->
	# 				console.log 'shown'
	# 				return

	# 			colorInputJ.on 'hidden.bs.popover', ()->
	# 				console.log 'hidden'
	# 				return

	# 			# colorInputJ.popover( trigger: 'click' )

	# 			colorInputJ.attr('data-initialized', 0)
	# 			colorInputJ.attr('data-gradient', Number(value?.gradient?))
	# 			colorInputJ.attr('data-item-pk', item?.pk or item?.id)
	# 			colorInputJ.attr('data-parameter-name', name)

	# 			# inputJ.click ()->
	# 			# 	console.log 'color click'
	# 			# 	guiJ = $(R.gui.domElement)
	# 			# 	colorPickerPopoverJ = $(".cp-popover-container .popover")

	# 			# 	# # swatchesJ = colorPickerPopoverJ.find('.cp-swatches')
	# 			# 	checkboxJ = $("<label><input type='checkbox' class='gradient-checkbox' form-control>Gradient</label>")
	# 			# 	checkboxJ.insertBefore(colorPickerPopoverJ.find('.cp-preview'))
	# 			# 	checkboxJ.css( 'color': 'black' )
	# 			# 	checkboxJ.find('input').click (event)->
	# 			# 		if this.checked
	# 			# 			R.tools['Gradient'].select(parameter, colorPicker)
	# 			# 		else
	# 			# 			R.tools['Select'].select()
	# 			# 		return
	# 			# 	# # swatchesJ.append(gradientSwatchesJ)

	# 			# 	# if guiJ.parent().hasClass("dg-sidebar")
	# 			# 	# 	# position = guiJ.offset().left + guiJ.outerWidth()
	# 			# 	# 	# colorPickerPopoverJ.css( left: position )
	# 			# 	# 	colorPickerPopoverJ.removeClass("left").addClass("right")
	# 			# 	# 	# $(".cp-popover-container .arrow").hide()
	# 			# 	# # else
	# 			# 	# # 	position = guiJ.offset().left - colorPickerPopoverJ.width()
	# 			# 	# # 	colorPickerPopoverJ.css( left: position )
	# 			# 	return
	# 			checkboxJ.change ()-> if this.checked then parameter.onChange(colorInputJ.val()) else parameter.onChange(null)
	# 			datFolder.__controllers[datFolder.__controllers.length-1].rValue = () -> return if checkboxJ[0].checked then colorInputJ.val() else null
	# 			controller.rSetValue = (value, item, checked)->
	# 				if checked
	# 					if value? then colorInputJ.trigger("colorpickersliders.updateColor", value)
	# 				checkboxJ[0].checked = checked
	# 				return
	# 		when 'slider', 'checkbox', 'dropdown', 'button', 'button-group', 'radio-button-group', 'string', 'input-typeahead'
	# 			obj[name] = value
	# 			firstOptionalParameter = if parameter.min? then parameter.min else parameter.values
	# 			controllerBox = datFolder.add(obj, name, firstOptionalParameter, parameter.max)
	# 			.name(parameter.label)
	# 			.onChange(parameter.onChange)
	# 			.onFinishChange(parameter.onFinishChange)
	# 			controller = datFolder.__controllers.last()
	# 			if parameter.step? then controller.step?(parameter.step)
	# 			controller.rValue = controller.getValue

	# 			controller.rSetValue = parameter.setValue
	# 			updateItemControllers(parameter, name, item, controller)
	# 			parameter.initializeController?(controller, item)

	# 		else
	# 			console.log 'unknown parameter type'

	# 	return

	# # update parameters according to the selected tool or items
	# # @param tools [{ tool: RTool constructor, item: RItem } or Array of { tool: RTool constructor, item: RItem }] list of tools from which controllers will be created or updated
	# # @param resetValues [Boolean] true to reset controller values, false to let them untouched (values must be reset when selecting a new tool, but not when creating another similar shape... this must be improved)

	# R.updateParameters = (tools, resetValues=false)->

	# 	# add every controllers in R.unusedControllers (we will potentially remove them all)
	# 	R.unusedControllers = []
	# 	for folderName, folder of R.gui.__folders
	# 		for controller in folder.__controllers
	# 			if not R.parameters[controller.property]?.permanent
	# 				R.unusedControllers.push(controller)

	# 	if not Array.isArray(tools) # make tools an array if it was not
	# 		tools = [tools]

	# 	# for all tools: add one controller per parameter to corresponding folder (create folder if it does not exist)
	# 	for toolObject in tools											# for all tools
	# 		tool = toolObject.tool
	# 		item  = toolObject.item
	# 		for folderName, folder of tool.parameters() 				# for all folders of the tool
	# 			folderExists = R.gui.__folders[folderName]?
	# 			datFolder = if folderExists then R.gui.__folders[folderName] else R.gui.addFolder(folderName) 	# get or create folder
	# 			for name, parameter of folder  							# for all parameters of the folder
	# 				if name != 'folderIsClosedByDefault'
	# 					addItem(name, parameter, item, datFolder, resetValues)

	# 			# open folder if it did not exist (and is opened by default)
	# 			if not folderExists and not folder.folderIsClosedByDefault
	# 				datFolder.open()

	# 	# remove all controllers which are not used anymore
	# 	for unusedController in R.unusedControllers
	# 		for folderName, folder of R.gui.__folders
	# 			if folder.__controllers.indexOf(unusedController)>=0
	# 				folder.remove(unusedController)
	# 				folder.__controllers.remove(unusedController)
	# 				if folder.__controllers.length==0
	# 					R.gui.removeFolder(folderName)

	# 	# if dat.gui is in sidebar refresh its size and visibility in 500 milliseconds,
	# 	# (to fix a bug: sometimes dat.gui is too small, with a scrollbar or is not visible)
	# 	if $(R.gui.domElement).parent().hasClass('dg-sidebar')
	# 		setTimeout( ()->
	# 			$(R.gui.domElement).find("ul:first").css( 'height': 'initial' )
	# 			$(R.gui.domElement).css( 'opacity': 1, 'z-index': 'auto' )
	# 		,
	# 		500)
	# 	return

	# R.updateParametersForSelectedItems = ()->
	# 	Utils.callNextFrame(R.updateParametersForSelectedItemsCallback, 'updateParametersForSelectedItems')
	# 	return

	# R.updateParametersForSelectedItemsCallback = ()->
	# 	console.log 'updateParametersForSelectedItemsCallback'
	# 	items = R.selectedItems.map( (item)-> return { tool: item.constructor, item: item } )
	# 	R.updateParameters(items, true)
	# 	return



	# R.setControllerValueByName = (name, value, item)->
	# 	checked = value?
	# 	for folderName, folder of R.gui.__folders
	# 		for controller in folder.__controllers
	# 			if controller.property == name
	# 				R.setControllerValue(controller, { min: controller.__min, max: controller.__max }, value, item, checked)
	# 				break
	# 	return

	class Controller

		constructor: (@name, @parameter, @folder)->
			@folder.controllers[@name] = @
			@initialize()
			return

		initialize: ()->

			@parameter.value ?= @parameter.default
			firstOptionalParameter = if @parameter.min? then @parameter.min else @parameter.values

			controllerBox = @folder.datFolder.add(@parameter, 'value', firstOptionalParameter, @parameter.max)
			.name(@parameter.label)
			.onChange(@parameter.onChange or @onChange)
			.onFinishChange(@parameter.onFinishChange)

			@datController = _.last(@folder.datFolder.__controllers)

			if @parameter.step? then @datController.step(@parameter.step)

			return

		listen: (command)->
			$(command).on('do', @itemChanged)
			$(command).on('undo', @itemChanged)
			return

		itemChanged: ()->
			item = R.selectedItems[0]
			@setValue(item.data[@name])
			return

		onChange: (value) =>
			R.c = @
			for item in R.selectedItems
				# do not update if the value was never set (not even to null), update if it was set (even to null, for colors)
				if typeof item.data?[@name] isnt 'undefined'
					item.setParameterCommand(@, value)
			return

		getValue: ()->
			return @datController.getValue()

		setValue: (value)->
			@datController.object[@datController.property] = value
			@datController.updateDisplay()
			@parameter.setValue?(value)
			return

		# addItems: (items)->
		# 	@items = @items.concat(items)
		# 	controlled = @items[0] or R.selectedTool
		# 	controlled.parameterControllers ?= {}
		# 	controlled.parameterControllers[@name] = @
		# 	return

		# reset: ()->
		# 	@items = []
		# 	return

		remove: ()->
			@parameter.controller = null

			if @defaultOnChange
				@parameter.onChange = null

			@folder.datFolder.remove(@datController)
			@folder.datFolder.__controllers.remove(@datController)

			delete @folder.controllers[@name]
			if Object.keys(@folder.controllers).length == 0
				@folder.remove()

			@folder = null
			@name = null
			return

	R.Controller = Controller

	class ColorController extends R.Controller

		@initialize: ()->
			@containerJ = R.templatesJ.find('.color-picker')
			@colorPickerJ = @containerJ.find('.color-picker-slider')
			@colorTypeSelectorJ = @containerJ.find('[name="color-type"]')

			@options =
				title: 'Color picker'
				flat: true
				size: 'sm'
				color: 'blue'
				order:
					hsl: 1
					rgb: 2
					opacity: 3
					preview: 4
				labels:
					rgbred: 'Red'
					rgbgreen: 'Green'
					rgbblue: 'Blue'
					hslhue: 'Hue'
					hslsaturation: 'Saturation'
					hsllightness: 'Lightness'
					preview: 'Preview'
					opacity: 'Opacity'
				onchange: @onColorPickerChange
				swatches: false
				# customswatches: "swatches-group:" + @parameter.name
				# swatches: R.defaultColors
				# hsvpanel: true
				# trigger: 'click'
				# hsvpanel: true
				# placement: 'auto'

			@colorPickerJ = @colorPickerJ.ColorPickerSliders(@options)

			@colorTypeSelectorJ.change @onColorTypeChange

			return

		@popoverContent: ()=>
			return @containerJ

		@onColorPickerChange: (container, color)=>
			@controller?.onColorPickerChange(container, color)
			return

		@onColorTypeChange: (event)=>
			@controller?.onColorTypeChange(event.target.value)
			return

		@initialize()

		constructor: (@name, @parameter, @folder)->
			@gradientTool = R.tools['Gradient']
			@selectTool = R.tools['Select']
			# @ignoreNextColorCounter = 0
			super(@name, @parameter, @folder)
			return

		initialize: ()->
			value = @parameter.value
			if value?.gradient?
				@gradient = value
				@parameter.value = 'black' 	# dat.gui does not like when value is a gradient...
			super()

			@colorInputJ = $(@datController.domElement).find('input')
			@colorInputJ.popover( title: @parameter.label, container: 'body', placement: 'auto', content: @constructor.popoverContent, html: true )

			@colorInputJ.addClass("color-input")
			@enableCheckboxJ = $('<input type="checkbox">')
			@enableCheckboxJ.insertBefore(@colorInputJ)

			@colorInputJ.on 'show.bs.popover', @popoverOnShow
			@colorInputJ.on 'shown.bs.popover', @popoverOnShown
			@colorInputJ.on 'hide.bs.popover', @popoverOnHide
			@colorInputJ.on 'hide.bs.popover', @popoverOnHidden

			@enableCheckboxJ.change(@enableCheckboxChanged)

			@setColor(value, false)
			return

		popoverOnShow: (event)=>
			previousController = @constructor.controller

			if previousController and previousController != @
				previousController.colorInputJ.popover('hide')
			return

		popoverOnShown: (event)=>
			@constructor.controller = @
			@gradientTool.controller = @

			@setColor(@getValue())

			if @gradient
				@gradientTool.select()
			return

		popoverOnHide: ()=>
			popoverJ = $('#'+$(this).attr('aria-describedby'))
			size = new P.Size(popoverJ.width(), popoverJ.height())
			popoverJ.find('.color-picker').appendTo(R.templatesJ.find(".color-picker-container"))
			popoverJ.width(size.width).height(size.height)

			@constructor.controller = null
			@gradientTool.controller = null

			if @gradient
				@selectTool.select()
			return

		popoverOnHidden: ()->
			return

		onChange: (value) =>
			if value?.gradient?
				@gradient = value
			else
				@gradient = null
			super(value)
			return

		onColorPickerChange: (container, color)->
			# if @ignoreNextColorCounter > 0
			# 	@ignoreNextColorCounter--
			# 	return
			color = color.tiny.toRgbString()

			@setColor(color, false)

			if @gradient?
				@gradientTool.colorChange(color, @)
			else
				@onChange(color)

			@enableCheckboxJ[0].checked = true
			return

		onColorTypeChange: (value)->
			switch value
				when 'flat-color'
					@gradient = null
					@onChange(@getValue())
					@selectTool.select()
				when 'linear-gradient'
					@gradientTool.controller = @
					@gradientTool.setRadial(false)
				when 'radial-gradient'
					@gradientTool.controller = @
					@gradientTool.setRadial(true)
			return

		getValue: ()->
			if @enableCheckboxJ[0].checked
				return @gradient or @colorInputJ.val()
			else
				return null

		setValue: (value, updateTool=true)->
			super(value)

			if value?.gradient?
				@gradient = value
			else
				@gradient = null

			@setColor(value)

			if updateTool
				if @gradient?
					@gradientTool.controller = @
					@gradientTool.select(false, false)
				else
					@selectTool.select(false, false)
			return

		setColor: (color, updateColorPicker=true)->
			@enableCheckboxJ[0].checked = color?

			if @gradient
				@colorInputJ.val('Gradient')
				colors = ''
				for stop in @gradient.gradient.stops
					c = new Color(if stop.color? then stop.color else stop[0])
					colors += ', ' + c.toCSS()
				@colorInputJ.css 'background-color': ''
				@colorInputJ.css 'background-image': 'linear-gradient( to right' + colors + ')'
				if @gradient.gradient?.radial
					@constructor.colorTypeSelectorJ.find('[value="radial-gradient"]').prop('selected', true)
				else
					@constructor.colorTypeSelectorJ.find('[value="linear-gradient"]').prop('selected', true)
			else
				@colorInputJ.val(color)
				@colorInputJ.css 'background-image': ''
				@colorInputJ.css 'background-color': (color or 'transparent')
				@constructor.colorTypeSelectorJ.find('[value="flat-color"]').prop('selected', true)

			if updateColorPicker
				# @ignoreNextColorCounter++
				@constructor.colorPickerJ.trigger("colorpickersliders.updateColor", [color, true])
			return

		enableCheckboxChanged: (event)=>
			value = @getValue()
			@onChange(value)
			@setColor(value, false)
			return

		remove: ()->
			@onChange = ()->return
			@colorInputJ.popover('destroy')
			super()
			return

	R.ColorController = ColorController

	class Folder

		constructor: (@name, closedByDefault=false, @parentFolder)->
			@controllers = {}
			@folders = {}

			if not @parentFolder
				R.controllerManager.folders[@name] = @
				@datFolder = R.gui.addFolder(@name)
			else
				@parentFolder.folders[@name] = @
				@datFolder = @parentFolder.datFolder.addFolder(@name)

			if not closedByDefault
				@datFolder.open()
			return

		remove: ()->
			for name, controller of @controllers
				controller.remove()
				delete @controller[name]
			for name, folder of @folders
				folder.remove()
				delete @folders[name]
			@datFolder.close()
			$(@datFolder.domElement).parent().remove()
			delete @datFolder.parent.__folders[@datFolder.name]
			R.gui.onResize()
			delete R.controllerManager.folders[@name]
			return

	R.Folder = Folder

	class ControllerManager

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
					controller = new R.ColorController(name, parameter, folder)
				else
					controller = new R.Controller(name, parameter, folder)
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
					folder ?= new R.Folder(folderName, folderParameters.folderIsClosedByDefault)

					for name, parameter of folderParameters  							# for all parameters of the folder
						if name == 'folderIsClosedByDefault' then continue

						controller = folder.controllers[name]

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

		updateParametersForSelectedItems: ()->
			Utils.callNextFrame(@updateParametersForSelectedItemsCallback, 'updateParametersForSelectedItems')
			return

		updateParametersForSelectedItemsCallback: ()=>
			tools = {}

			for item in R.selectedItems

				tools[item.constructor.name] ?= parameters: item.constructor.parameters, items: []
				tools[item.constructor.name].items.push(item)

			@updateControllers(tools, true)
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

		# todo: replace parameters() with getParameters() and get only once

	return ControllerManager