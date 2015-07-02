define [ 'UI/Controllers/Controller', 'colorpickersliders' ], (Controller) ->

	class ColorController extends Controller

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
			@gradientTool = R.tools.gradient
			@selectTool = R.tools.select
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
					c = new P.Color(if stop.color? then stop.color else stop[0])
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

	return ColorController
