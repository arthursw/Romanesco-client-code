define [ 'Tools/Tool' ], (Tool) ->

	class Button

		constructor: (parameters)->
			name = parameters.name
			iconURL = parameters.iconURL
			favorite = parameters.favorite
			category = parameters.category
			order = parameters.order
			@file = parameters.file

			parentJ = R.sidebar.allToolsJ
			if category? and category != ""
				# split into sub categories
				categories = category.split("/")

				for category in categories
					# look for category
					ulJ = parentJ.find("li[data-name='#{category}'] > ul")
					if ulJ.length==0
						liJ = $("<li data-name='#{category}'>")
						liJ.addClass('category')
						hJ = $('<h6>')
						hJ.text(category).addClass("title")
						liJ.append(hJ)
						ulJ = $("<ul>")
						ulJ.addClass('folder')
						liJ.append(ulJ)
						hJ.click(@toggleCategory)
						parentJ.append(liJ)

					parentJ = ulJ

			# initialize button
			@btnJ = $("<li>")
			@btnJ.attr("data-name", name)
			# @@btnJ.attr("data-cursor", @cursorDefault)
			@btnJ.attr("alt", name)

			if iconURL? and iconURL != '' 															# set icon if url is provided
				iconRootURL = 'static/images/icons/inverted/'
				if iconURL.indexOf('//') < 0 and iconURL.indexOf(iconRootURL) < 0
					iconURL = iconRootURL + iconURL
				if iconURL.indexOf(iconRootURL) == 0
					iconURL = location.origin + '/' + iconURL
				@btnJ.append('<img src="' + iconURL + '" alt="' + name + '-icon">')
			else 																					# create icon if url is not provided
				@btnJ.addClass("text-btn")
				words = name.split(" ")
				shortName = ""
																# the icon will be made with
				if words.length>1 								# the first letter of each words of the name
					shortName += word.substring(0,1) for word in words
				else 											# or the first two letters of the name (if it has only one word)
					shortName += name.substring(0,2)
				shortNameJ = $('<span class="short-name">').text(shortName + ".")
				@btnJ.append(shortNameJ)

			parentJ.append(@btnJ)

			toolNameJ = $('<span class="tool-name">').text(name)
			@btnJ.append(toolNameJ)
			@btnJ.addClass("tool-btn")
			favoriteBtnJ = $("""<button type="button" class="btn btn-default favorite-btn">
	  			<span class="glyphicon glyphicon-star" aria-hidden="true"></span>
			</button>""")
			favoriteBtnJ.click(R.sidebar.toggleToolToFavorite)

			@btnJ.append(favoriteBtnJ)
			@btnJ.attr('data-order': if order? then order else 999)
			@btnJ.click(if @file? then @onClickWhenNotLoaded else @onClickWhenLoaded)


			if favorite
				R.sidebar.toggleToolToFavorite(null, @btnJ)

			if parameters.description? or parameters.popover
				@addPopover(parameters)
			return

		addPopover: (parameters)->
			# initialize the popover (help tooltip)
			# popoverOptions =
			# 	placement: 'right'
			# 	container: 'body'
			# 	trigger: 'hover'
			# 	delay:
			# 		show: 500
			# 		hide: 100

			@btnJ.attr('data-placement', 'right')
			@btnJ.attr('data-container', 'body')
			@btnJ.attr('data-trigger', 'hover')
			@btnJ.attr('data-delay', {show: 500, hide: 100})

			if not parameters.description? or parameters.description == ''
				# popoverOptions.content = parameters.name
				@btnJ.attr('data-content', parameters.name)
			else
				# popoverOptions.title = parameters.name
				# popoverOptions.content = parameters.description
				@btnJ.attr('data-title', parameters.name)
				@btnJ.attr('data-content', parameters.description)

			@btnJ.popover()
			return

		toggleCategory: (event)->
			categoryJ = $(this).parent()
			categoryJ.toggleClass('closed')
			categoryJ.children('.folder').children().show()
			return

		fileLoaded: ()=>
			@btnJ.off('click')
			@btnJ.click(@onClickWhenLoaded)
			@onClickWhenLoaded()
			return

		onClickWhenNotLoaded: (event)=>
			require([@file], @fileLoaded)
			return

		onClickWhenLoaded: (event)=>
			toolName = @btnJ.attr("data-name")
			R.tools[toolName]?.select()
			return

	return Button
