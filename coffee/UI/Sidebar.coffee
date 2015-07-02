define [ 'Items/Item', 'jqueryUi', 'scrollbar' ], (Item) ->

	class Sidebar

		constructor: ()->
			@sidebarJ = $("#sidebar")
			@favoriteToolsJ = $("#FavoriteTools .tool-list")
			@allToolsContainerJ = $("#AllTools")
			@allToolsJ = @allToolsContainerJ.find(".all-tool-list")
			@initializeFavoriteTools()

			# initialize sidebar handle
			@handleJ = @sidebarJ.find(".sidebar-handle")
			@handleJ.click(@toggleSidebar)

			# initialize sort
			@itemListsJ = $("#RItems .layers")
			@pathListJ = @itemListsJ.find(".rPath-list")
			@pathListJ.sortable( stop: Item.zIndexSortStop, delay: 250 )
			@pathListJ.disableSelection()
			@divListJ = @itemListsJ.find(".rDiv-list")
			@divListJ.sortable( stop: Item.zIndexSortStop, delay: 250 )
			@divListJ.disableSelection()
			@itemListsJ.find('.title').click (event)->
				$(this).parent().toggleClass('closed')
				return

			@sortedPaths = R.sortedPaths
			@sortedDivs = R.sortedDivs

			$(".mCustomScrollbar").mCustomScrollbar( keyboard: false )

			return

		initializeFavoriteTools: ()->
			# init @favoriteTools to see where to put the tools (in the 'favorite tools' panel or in 'other tools')
			@favoriteTools = []
			if localStorage?
				try
					@favoriteTools = JSON.parse(localStorage.favorites)
				catch error
					console.log error

			defaultFavoriteTools = [] # [PrecisePath, ThicknessPath, Meander, GeometricLines, RectangleShape, EllipseShape, StarShape, SpiralShape]

			while @favoriteTools.length < 8 and defaultFavoriteTools.length > 0
				Utils.Array.pushIfAbsent(@favoriteTools, defaultFavoriteTools.pop().label)
			return

		toggleToolToFavorite: (event, btnJ)=>
			if not btnJ?
				event.stopPropagation()
				targetJ = $(event.target)
				btnJ = targetJ.parents("li.tool-btn:first")

			toolName = btnJ.attr("data-name")

			if btnJ.hasClass("selected")
				btnJ.removeClass("selected")
				@favoriteToolsJ.find("[data-name='#{toolName}']").remove()
				Utils.Array.remove(@favoriteTools, toolName)
			else
				btnJ.addClass("selected")
				cloneJ = btnJ.clone()
				@favoriteToolsJ.append(cloneJ)
				cloneJ.click((event)->btnJ.click(event))
				for attr in ['placement', 'container', 'trigger', 'delay', 'content', 'title']
					attrName = 'data-' + attr
					cloneJ.attr(attrName, btnJ.attr(attrName))
					cloneJ.popover()

				@favoriteTools.push(toolName)

			if not localStorage? then return
			names = []
			for li in @favoriteToolsJ.children()
				names.push($(li).attr("data-name"))
			localStorage.favorites = JSON.stringify(names)

			return

		show: ()->
			@sidebarJ.removeClass("r-hidden")
			R.codeEditor?.editorJ.removeClass("r-hidden")
			R.alertManager.alertsContainer.removeClass("r-sidebar-hidden")
			@handleJ.find("span").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-left")
			return

		hide: ()->
			@sidebarJ.addClass("r-hidden")
			R.codeEditor?.editorJ.addClass("r-hidden")
			R.alertManager.alertsContainer.addClass("r-sidebar-hidden")
			@handleJ.find("span").removeClass("glyphicon-chevron-left").addClass("glyphicon-chevron-right")
			return

		# Toggle (hide/show) sidebar (called when user clicks on the sidebar handle)
		# @param show [Boolean] show the sidebar, defaults to the opposite of the current state (true if hidden, false if shown)
		toggleSidebar: (show)=>
			show ?= not @sidebarJ.hasClass("r-hidden")
			if show
				@show()
			else
				@hide()
			return

	# R.createToolButton = (name, iconURL, favorite, category=null, parentJ)->

	return Sidebar
