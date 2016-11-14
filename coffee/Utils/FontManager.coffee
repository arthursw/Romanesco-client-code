define [ ], () ->

	class FontManager

		constructor: ()->

			@availableFonts = []
			@usedFonts = []
			jQuery.support.cors = true

			# $.getJSON("https://www.googleapis.com/webfonts/v1/webfonts?key=AIzaSyD2ZjTQxVfi34-TMKjB5WYK3U8K6y-IQH0", initTextOptions)

			if R.offline then return
			jqxhr = $.getJSON("https://www.googleapis.com/webfonts/v1/webfonts?key=AIzaSyBVfBj_ugQO_w0AK1x9F6yiXByhcNgjQZU", @initTextOptions)
			jqxhr.done (json)=>
				console.log 'done'
				@initializeTextOptions(json)
				return
			jqxhr.fail (jqxhr, textStatus, error)->
				err = textStatus + ", " + error
				console.log 'failed: ' + err
				return
			jqxhr.always (jqxhr, textStatus, error)->
				err = textStatus + ", " + error
				console.log 'always: ' + err
				return

			return

		# add font to the page:
		# - check if the font is already loaded, and with which effect
		# - load web font from google font if needed
		addFont: (fontFamily, effect)->
			if not fontFamily? then return

			fontFamilyURL = fontFamily.split(" ").join("+")

			# update @usedFonts, check if the font is already
			fontAlreadyUsed = false
			for font in @usedFonts
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
				@usedFonts.push( family: fontFamilyURL, effects: effects )
			return

		# todo: use google web api to update text font on load callback
		# fonts could have multiple effects at once, but the gui does not allow this yet
		# since having multiple effects would not be of great use
		# must be improved!!
		loadFonts: ()=>
			$('head').remove("link.fonts")

			for font in @usedFonts
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

					if R.offline then continue

					fontLink = $('<link class="fonts" data-font-family="' + font.family + '" rel="stylesheet" type="text/css">')
					fontLink.attr('href', "http://fonts.googleapis.com/css?family=" + newFont)
					$('head').append(fontLink)
			return

		# initialize typeahead font engine to quickly search for a font by typing its first letters
		initializeTextOptions: (data, textStatus, jqXHR) =>

			# gather all font names
			fontFamilyNames = []
			for item in data.items
				fontFamilyNames.push({ value: item.family })

			# initialize typeahead font engine
			@typeaheadFontEngine = new Bloodhound({
				name: 'Font families',
				local: fontFamilyNames,
				datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
				queryTokenizer: Bloodhound.tokenizers.whitespace
			})
			promise = @typeaheadFontEngine.initialize()

			@availableFonts = data.items

			# test
			# @familyPickerJ = @textOptionsJ.find('#fontFamily')
			# @familyPickerJ.typeahead(
			# 	{ hint: true, highlight: true, minLength: 1 },
			# 	{ valueKey: 'value', displayKey: 'value', source: typeaheadFontEngine.ttAdapter() }
			# )

			# @fontSubmitJ = @textOptionsJ.find('#fontSubmit')


			# @fontSubmitJ.click( (event) ->
			# 	@setFontStyles()
			# )

			return

	return FontManager
