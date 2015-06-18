define [ 'Item' ], (Item) ->

	# RSelectionRectangle is just a helper to define a selection rectangle, it is used in {ScreenshotTool}
	class SelectionRectangle extends Item

		constructor: (@rectangle, extractImage) ->
			super()

			@drawing = new P.Path.Rectangle(@rectangle)
			@drawing.name = 'selection rectangle background'
			@drawing.strokeWidth = 1
			@drawing.strokeColor = R.selectionBlue
			@drawing.controller = @

			@group.addChild(@drawing)

			separatorJ = R.stageJ.find(".text-separator")
			@buttonJ = R.templatesJ.find(".screenshot-btn").clone().insertAfter(separatorJ)

			@buttonJ.find('.extract-btn').click (event)->
				redraw = $(this).attr('data-click') == 'redraw-snapshot'
				extractImage(redraw)
				return

			@updateTransform()

			@select()

			R.tools['Select'].select()

			return

		remove: ()->
			@removing = true
			super()
			@buttonJ.remove()
			R.tools['Screenshot'].selectionRectangle = null
			return

		deselect: ()->
			if not super() then return false
			if not @removing then @remove()
			return true

		setRectangle: (rectangle, update)->
			super(rectangle, update)
			Utils.P.Rectangle.updatePathRectangle(@drawing, rectangle)
			@updateTransform()
			return

		moveTo: (position, update)->
			super(position, update)
			@updateTransform()
			return

		updateTransform: ()->
			viewPos = P.view.projectToView(@rectangle.center)
			transfrom = 'translate(' + viewPos.x + 'px,' + viewPos.y + 'px)'
			transfrom += 'translate(-50%, -50%)'
			@buttonJ.css( 'position': 'absolute', 'transform': transfrom, 'top': 0, 'left': 0, 'transform-origin': '50% 50%', 'z-index': 999 )
			return

		update: ()->
			return

	return SelectionRectangle