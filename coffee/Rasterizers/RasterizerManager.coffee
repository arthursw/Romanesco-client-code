define [ 'Rasterizers/Rasterizer', 'UI/Controllers/Folder' ], (Rasterizer, Folder) ->

	class RasterizerManager

		constructor: ()->
			return

		initializeRasterizers: ()->
			@rasterizers = {}
			new Rasterizer()
			new Rasterizer.CanvasTile()
			new Rasterizer.InstantPaperTile()
			R.rasterizer = new Rasterizer.PaperTile()

			@addRasterizerParameters()
			return

		addRasterizerParameters: ()->

			renderingModes = []
			for type, rasterizer of @rasterizers
				renderingModes.push(type)

			@rasterizerFolder = new Folder('Rasterizer', true, R.controllerManager.folders['General'])

			divJ = $('<div>')
			divJ.addClass('loadingBar')
			$(@rasterizerFolder.datFolder.__ul).find('li.title').append(divJ)
			Rasterizer.Tile.loadingBarJ = divJ

			parameters =
				renderingMode:
					default: R.rasterizer.constructor.TYPE
					values: renderingModes
					label: 'Render mode'
					onFinishChange: @setRasterizerType
				rasterizeItems:
					default: true
					label: 'Rasterize items'
					onFinishChange: (value)->
						R.rasterizer.rasterizeItems = value

						if not value
							R.rasterizer.renderInView = true

						for controller in @rasterizerFolder.datFolder.__controllers
							if controller.property == 'renderInView'
								if value
									$(controller.__li).show()
								else
									$(controller.__li).hide()
						return
				renderInView:
					default: false
					label: 'Render in view'
					onFinishChange: (value)->
						R.rasterizer.renderInView = value
						return
				autoRasterization:
					default: 'deferred'
					values: ['immediate', 'deferred', 'disabled']
					label: 'Auto rasterization'
					onFinishChange: (value)->
						R.rasterizer.autoRasterization = value
						return
				rasterizationDelay:
					default: 800
					min: 0
					max: 10000
					lable: 'Delay'
					onFinishChange: (value)->
						R.rasterizer.rasterizationDelay = value
						return
				rasterizeImmediately:
					default: ()->
						R.rasterizer.rasterizeImmediately()
						return
					label: 'Rasterize'

			for name, parameter of parameters
				R.controllerManager.createController(name, parameter, @rasterizerFolder)

			return

		setRasterizerType: (type)->
			if type == Rasterizer.TYPE
				for controller in @rasterizerFolder.datFolder.__controllers
					if controller.property in [ 'renderInView', 'autoRasterization', 'rasterizationDelay', 'rasterizeImmediately' ]
						$(controller.__li).hide()
			else
				for controller in @rasterizerFolder.datFolder.__controllers
					$(controller.__li).show()

			R.loader.unload()
			R.rasterizer = @rasterizers[type]

			for controller in @rasterizerFolder.datFolder.__controllers
				if R.rasterizer[controller.property]?
					onFinishChange = controller.__onFinishChange
					controller.__onFinishChange = ()->return
					controller.setValue(R.rasterizer[controller.property])
					controller.__onFinishChange = onFinishChange

			R.loader.load()
			return

		hideCanvas: ()->
			R.canvasJ.css opacity: 0
			return

		showCanvas: ()->
			R.canvasJ.css opacity: 1
			return

		hideRasters: ()->
			R.rasterizer.hideRasters()
			return

		showRasters: ()->
			R.rasterizer.showRasters()
			return

	return RasterizerManager