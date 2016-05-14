define [ 'Utils/Utils' ], () ->

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

	# Initialize general and default parameters
	# R.initParameters = () ->

	# 	R.optionsJ = $(".option-list")


		# --- DAT GUI/ --- #

		# todo: use addItems for general settings!!!



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


		# --- /DAT GUI --- #

		# --- Text options --- #

		# R.textOptionsJ = R.optionsJ.find(".text-options")

		# R.stylePickerJ = R.textOptionsJ.find('#fontStyle')
		# # R.subsetPickerJ = R.optionsJ.find('#fontSubset')
		# R.effectPickerJ = R.textOptionsJ.find('#fontEffect')
		# R.sizePickerJ = R.textOptionsJ.find('#fontSizeSlider')
		# R.sizePickerJ.slider().on('slide', (event)-> R.fontSize = event.value )
		# return

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
	# # @param name [String] name of the parameter (short name without spaces, same as Item.data[name] )
	# # @param parameter [Parameter] the parameter to add
	# # @param item [Item] optional Item, the controller will be initialized with *item.data* if any
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
	# 	# @param [Item] (optional) the Item
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
	# 				# if R.me? and datFolder.name != 'General' then R.socket.emit( "parameter change", R.me, item.pk, name, value )
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
	# 					R.tools.select.select()
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
	# 			# 			R.tools.select.select()
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
	# # @param tools [{ tool: RTool constructor, item: Item } or Array of { tool: RTool constructor, item: Item }] list of tools from which controllers will be created or updated
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

			@parameter.value ?= if @parameter.defaultFunction? then @parameter.defaultFunction() else @parameter.default
			firstOptionalParameter = if @parameter.min? then @parameter.min else @parameter.values

			if @parameter.type == 'button' or @parameter.type == 'action' or typeof(@parameter.default) == 'function'
				if not @parameter.onChange? and not @parameter.default? then throw "Action parameter has no function."
				@parameter.onChange ?= @parameter.default
				@parameter.default ?= @parameter.onChange

			controllerBox = @folder.datFolder.add(@parameter, 'value', firstOptionalParameter, @parameter.max)
			.name(@parameter.label)
			.onChange(@parameter.onChange or @onChange)
			.onFinishChange(@parameter.onFinishChange)

			@datController = _.last(@folder.datFolder.__controllers)

			if @parameter.step? then @datController.step(@parameter.step)

			return

		onChange: (value) =>
			R.c = @
			if R.selectedItems.length > 0
				R.commandManager.deferredAction(R.Command.SetParameter, R.selectedItems, null, @name, value)
			# itemsToUpdate = []
			# for item in R.selectedItems
			# 	# do not update if the value was never set (not even to null), update if it was set (even to null, for colors)
			# 	if typeof item.data?[@name] isnt 'undefined'
			# 		itemsToUpdate.push(item)
			# 		# item.setParameterCommand(@, value)
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
			# $(@).triggerHandler('delete', [@])
			@parameter.controller = null

			if @defaultOnChange
				@parameter.onChange = null

			@folder.datFolder.remove(@datController)
			Utils.Array.remove(@folder.datFolder.__controllers, @datController)

			delete @folder.controllers[@name]
			if Object.keys(@folder.controllers).length == 0
				@folder.remove()

			@folder = null
			@name = null
			return

	return Controller
