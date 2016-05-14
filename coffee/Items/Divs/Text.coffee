define [ 'Items/Item', 'Items/Divs/Div', 'Commands/Command' ], (Item, Div, Command) ->

	# Text: a textarea to write some text.
	# The text can have any google font, any effect, but all the text has the same formating.
	class Text extends Div
		@label = 'Text'

		@modalTitle = "Insert some text"
		@modalTitleUpdate = "Modify your text"
		@object_type = 'text'

		# parameters of the Text highly customize the gui (add functionnalities like font selector, etc.)
		@initializeParameters: ()->

			parameters = super()

			parameters['Font'] =
				fontName:
					type: 'input-typeahead'
					label: 'Font name'
					default: ''
					initializeController: (controller)->
						typeaheadJ = $(controller.datController.domElement)
						input = typeaheadJ.find("input")
						inputValue = null

						input.typeahead(
							{ hint: true, highlight: true, minLength: 1 },
							{ valueKey: 'value', displayKey: 'value', source: R.fontManager.typeaheadFontEngine.ttAdapter() }
						)

						input.on 'typeahead:opened', ()->
							dropDown = typeaheadJ.find(".tt-dropdown-menu")
							dropDown.insertAfter(typeaheadJ.parents('.cr:first'))
							dropDown.css(position: 'relative', display: 'inline-block', right:0)
							return

						input.on 'typeahead:closed', ()->
							if inputValue?
								input.val(inputValue)
							else
								inputValue = input.val()
							for item in R.selectedItems
								item.setFontFamily?(inputValue) 	# not necessarly an Text
							return

						input.on 'typeahead:cursorchanged', ()->
							inputValue = input.val()
							return

						input.on 'typeahead:selected', ()->
							inputValue = input.val()
							return

						input.on 'typeahead:autocompleted', ()->
							inputValue = input.val()
							return

						firstItem = R.selectedItems[0]
						if firstItem?.data?.fontFamily?
							input.val(firstItem.data.fontFamily)

						return
				effect:
					type: 'dropdown'
					label: 'Effect'
					values: ['none', 'anaglyph', 'brick-sign', 'canvas-print', 'crackle', 'decaying', 'destruction',
					'distressed', 'distressed-wood', 'fire', 'fragile', 'grass', 'ice', 'mitosis', 'neon', 'outline',
					'puttinggreen', 'scuffed-steel', 'shadow-multiple', 'static', 'stonewash', '3d', '3d-float',
					'vintage', 'wallpaper']
					default: 'none'
				styles:
					type: 'button-group'
					label: 'Styles'
					default: ''
					setValue: (value)->
						fontStyleJ = $("#fontStyle:first")

						for item in R.selectedItems
							if item.data?.fontStyle?
								if item.data.fontStyle.italic then fontStyleJ.find("[name='italic']").addClass("active")
								if item.data.fontStyle.bold then fontStyleJ.find("[name='bold']").addClass("active")
								if item.data.fontStyle.decoration?.indexOf('underline')>=0
									fontStyleJ.find("[name='underline']").addClass("active")
								if item.data.fontStyle.decoration?.indexOf('overline')>=0
									fontStyleJ.find("[name='overline']").addClass("active")
								if item.data.fontStyle.decoration?.indexOf('line-through')>=0
									fontStyleJ.find("[name='line-through']").addClass("active")
					initializeController: (controller)->
						domElement = controller.datController.domElement
						$(domElement).find('input').remove()

						setStyles = (value)->
							for item in R.selectedItems
								item.changeFontStyle?(value)
							return

						# todo: change fontStyle id to class
						R.templatesJ.find("#fontStyle").clone().appendTo(domElement)
						fontStyleJ = $("#fontStyle:first")
						fontStyleJ.find("[name='italic']").click( (event)-> setStyles('italic') )
						fontStyleJ.find("[name='bold']").click( (event)-> setStyles('bold') )
						fontStyleJ.find("[name='underline']").click( (event)-> setStyles('underline') )
						fontStyleJ.find("[name='overline']").click( (event)-> setStyles('overline') )
						fontStyleJ.find("[name='line-through']").click( (event)-> setStyles('line-through') )

						controller.setValue()
						return
				align:
					type: 'radio-button-group'
					label: 'Align'
					default: ''
					initializeController: (controller)->
						domElement = controller.datController.domElement
						$(domElement).find('input').remove()

						setStyles = (value)->
							for item in R.selectedItems
								item.changeFontStyle?(value)
							return

						R.templatesJ.find("#textAlign").clone().appendTo(domElement)
						textAlignJ = $("#textAlign:first")
						textAlignJ.find(".justify").click( (event)-> setStyles('justify') )
						textAlignJ.find(".align-left").click( (event)-> setStyles('left') )
						textAlignJ.find(".align-center").click( (event)-> setStyles('center') )
						textAlignJ.find(".align-right").click( (event)-> setStyles('right') )
						return
				fontSize:
					type: 'slider'
					label: 'Font size'
					min: 5
					max: 300
					default: 11
				fontColor:
					type: 'color'
					label: 'Color'
					default: 'black'
					defaultCheck: true 					# checked/activated by default or not

			return parameters

		@parameters = @initializeParameters()

		# overload {Div#constructor}
		# initialize mouse event listeners to be able to select and edit text, bind key event listener to @textChanged
		constructor: (bounds, @data=null, @pk=null, @date, @lock=null) ->
			super(bounds, @data, @pk, @date, @lock)

			@contentJ = $("<textarea></textarea>")
			@contentJ.insertBefore(@maskJ)
			@contentJ.val(@data.message)

			lockedForMe = @owner != R.me and @lock?

			if lockedForMe
				# @contentJ.attr("readonly", "true")
				message = @data.message
				@contentJ[0].addEventListener("input", (()-> this.value = message), false)

			@setCss()

			@contentJ.focus(@onFocus)
			@contentJ.blur(@onBlur)

			# @contentJ.keydown (event)=>
			# 	if event.metaKey or event.ctrlKey
			# 		@deselect()
			# 		event.stopImmediatePropagation()
			# 		return false
			# 	return

			if not lockedForMe
				@contentJ.bind('input propertychange', (event) => @textChanged(event) )

			if @data? and Object.keys(@data).length>0
				@setFont(false)
			return

		onFocus: (event)=>
			$(event.target).addClass("selected form-control")
			@select()
			return

		onBlur: (event)=>
			$(event.target).removeClass("selected form-control")
			# @deselect()
			return
		#
		# select: (updateOptions=true, updateSelectionRectangle=true)->
		# 	if not super(updateOptions, updateSelectionRectangle) then return false
		# 	@contentJ.focus()
		# 	return true

		deselect: ()->
			if not super() then return false
			@contentJ.blur()
			return true

		# called whenever the text is changed:
		# emit the new text to websocket
		# update the Text in 1 second (deferred execution)
		# @param event [jQuery Event] the key event
		textChanged: (event) =>
			newText = @contentJ.val()
			R.commandManager.deferredAction(Command.ModifyText, @, event, newText)
			# Utils.deferredExecution(@update, 'update', 1000, ['text'], @)
			return

		setText: (newText, update=false)->
			@data.message = newText
			@contentJ.val(newText)
			if not @socketAction
				if update then @update('text')
				R.socket.emit "bounce", itemPk: @pk, function: "setText", arguments: [newText, false]
			return

		# set the font family for the text
		# - check font validity
		# - add font to the page header (in a script tag, this will load the font)
		# - update css
		# - update Text if *update*
		# @param fontFamily [String] the name of the font family
		# @param update [Boolean] whether to update the Text
		setFontFamily: (fontFamily, update=true)->
			if not fontFamily? then return

			# check font validity
			available = false
			for item in R.fontManager.availableFonts
				if item.family == fontFamily
					available = true
					break
			if not available then return

			@data.fontFamily = fontFamily

			# WebFont.load( google: {	families: ['Droid Sans', 'Droid Serif']	} )

			R.fontManager.addFont(fontFamily, @data.effect)
			R.fontManager.loadFonts()

			@contentJ.css( "font-family": "'" + fontFamily + "', 'Helvetica Neue', Helvetica, Arial, sans-serif")

			if update
				@update()
				# R.socket.emit( "parameter change", R.me, @pk, "fontFamily", @data.fontFamily)

			return

		# only called when user modifies GUI
		# add/remove (toggle) the font style of the text defined by *value*
		# if *value* is 'justify', 'left', 'right' or 'center', the text is aligned as the *value* (the previous value is ignored, no toggle)
		# this only modifies @data, the css will be modified in {Text#setFontStyle}
		# eit the change on websocket
		# @param value [String] the style to toggle, can be 'underline', 'overline', 'line-through', 'italic', 'bold', 'justify', 'left', 'right' or 'center'
		changeFontStyle: (value)=>

			if not value? then return

			if typeof(value) != 'string'
				return

			@data.fontStyle ?= {}
			@data.fontStyle.decoration ?= ''

			switch value
				when 'underline'
					if @data.fontStyle.decoration.indexOf(' underline')>=0
						@data.fontStyle.decoration = @data.fontStyle.decoration.replace(' underline', '')
					else
						@data.fontStyle.decoration += ' underline'
				when 'overline'
					if @data.fontStyle.decoration.indexOf(' overline')>=0
						@data.fontStyle.decoration = @data.fontStyle.decoration.replace(' overline', '')
					else
						@data.fontStyle.decoration += ' overline'
				when 'line-through'
					if @data.fontStyle.decoration.indexOf(' line-through')>=0
						@data.fontStyle.decoration = @data.fontStyle.decoration.replace(' line-through', '')
					else
						@data.fontStyle.decoration += ' line-through'
				when 'italic'
					@data.fontStyle.italic = !@data.fontStyle.italic
				when 'bold'
					@data.fontStyle.bold = !@data.fontStyle.bold
				when 'justify', 'left', 'right', 'center'
					@data.fontStyle.align = value

			# only called when user modifies GUI
			@setFontStyle(true)
			# R.socket.emit( "parameter change", R.me, @pk, "fontStyle", @data.fontStyle)
			return

		# set the font style of the text (update the css)
		# called by {Text#changeFontStyle}
		# @param update [Boolean] (optional) whether to update the Text
		setFontStyle: (update=true)->
			if @data.fontStyle?.italic?
				@contentJ.css( "font-style": if @data.fontStyle.italic then "italic" else "normal")
			if @data.fontStyle?.bold?
				@contentJ.css( "font-weight": if @data.fontStyle.bold then "bold" else "normal")
			if @data.fontStyle?.decoration?
				@contentJ.css( "text-decoration": @data.fontStyle.decoration)
			if @data.fontStyle?.align?
				@contentJ.css( "text-align": @data.fontStyle.align)
			if update
				@update()
			return

		# set the font size of the text (update @data and the css)
		# @param fontSize [Number] the new font size
		# @param update [Boolean] (optional) whether to update the Text
		setFontSize: (fontSize, update=true)->
			if not fontSize? then return
			@data.fontSize = fontSize
			@contentJ.css( "font-size": fontSize+"px")
			if update
				@update()
			return

		# set the font effect of the text, only one effect can be applied at the same time (for now)
		# @param fontEffect [String] the new font effect
		# @param update [Boolean] (optional) whether to update the Text
		setFontEffect: (fontEffect, update=true)->
			if not fontEffect? then return

			R.fontManager.addFont(@data.fontFamily, fontEffect)

			i = @contentJ[0].classList.length-1
			while i>=0
				className = @contentJ[0].classList[i]
				if className.indexOf("font-effect-")>=0
					@contentJ.removeClass(className)
				i--

			R.fontManager.loadFonts()

			@contentJ.addClass( "font-effect-" + fontEffect)
			if update
				@update()
			return

		# set the font color of the text, update css
		# @param fontColor [String] the new font color
		# @param update [Boolean] (optional) whether to update the Text
		setFontColor: (fontColor, update=true)->
			@contentJ.css( "color": fontColor ? 'black')
			return

		# update font to match the styles, effects and colors in @data
		# @param update [Boolean] (optional) whether to update the Text
		setFont: (update=true)->
			@setFontStyle(update)
			@setFontFamily(@data.fontFamily, update)
			@setFontSize(@data.fontSize, update)
			@setFontEffect(@data.effect, update)
			@setFontColor(@data.fontColor, update)
			return

		# update = false when called by parameter.onChange from websocket
		# overload {Div#setParameter}
		# update text content and font styles, effects and colors
		setParameter: (name, value)->
			super(name, value)
			switch name
				when 'fontStyle', 'fontFamily', 'fontSize', 'effect', 'fontColor'
					@setFont(false)
				else
					@setFont(false)
			return

		# overload {Div#delete}
		# do not delete Text if we are editing the text (the delete key is used to delete the text)
		delete: () ->
			if @contentJ.hasClass("selected")
				return
			super()
			return

	Item.Text = Text
	return Text
