define [ 'Utils/Utils' ], () ->

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

	return Folder