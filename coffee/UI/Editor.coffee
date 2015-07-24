define [ 'coffee', 'ace/ace', 'typeahead' ], (CoffeeScript, ace) -> 			# 'ace/ext-language_tools', required?

	class CodeEditor

		constructor: ()->
			@mode = 'code'

			# editor
			@editorJ = $("#codeEditor")
			@editorJ.bind "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", @resize

			if R.sidebar.sidebarJ.hasClass("r-hidden")
				@editorJ.addClass("r-hidden")

			# handle
			handleJ = @editorJ.find(".editor-handle")
			handleJ.mousedown @onHandleDown
			handleJ.find('.handle-left').click(@setHalfSize)
			handleJ.find('.handle-right').click(@setFullSize)

			# header
			@fileNameJ = @editorJ.find(".header .fileName input")
			@linkFileInputJ = @editorJ.find("input.link-file")
			@linkFileInputJ.change(@linkFile)
			closeBtnJ = @editorJ.find("button.close-editor")
			closeBtnJ.click @close

			# body
			@codeJ = @editorJ.find(".code")
			@diffJ = @editorJ.find(".acediff")
			@codeJ.show()
			@diffJ.hide()

			# footer
			@footerJ = @editorJ.find(".footer")
			@diffFooterJ = @footerJ.find('.diff')
			@diffFooterJ.hide()

			# @pushRequestBtnJ = @editorJ.find("button.request")
			runBtnJ = @editorJ.find("button.submit.run")
			runBtnJ.click @runFile

			@console = new Console(@)
			@initializeEditor()

			return

		initializeEditor: ()->

			@editor = ace.edit(@codeJ[0])
			@editor.$blockScrolling = Infinity
			@editor.setOptions(
				enableBasicAutocompletion: true
				enableSnippets: true
				enableLiveAutocompletion: false
			)
			ace.config.set("packaged", true)
			ace.config.set("basePath", require.toUrl("ace"))
			@editor.setTheme("ace/theme/monokai")
			# @editor.setShowInvisibles(true)
			# @editor.getSession().setTabSize(4)
			@editor.getSession().setUseSoftTabs(false)
			@editor.getSession().setMode("ace/mode/coffee")

			@editor.getSession().setValue("""
				class NewPath extends R.PrecisePath
				  @label = 'NewPath'
				  @description = "A fancy path."

				  drawBegin: ()->

				    @initializeDrawing(false)

				    @path = @addPath()
				    return

				  drawUpdateStep: (length)->

				    point = @controlPath.getPointAt(length)
				    @path.add(point)
				    return

				  drawEnd: ()->
				    return

				""", 1)

			# @editorJ.keyup (event)->
			# 	switch Utils.specialKeys[event.keyCode]
			# 		when 'up'
			# 		when 'down'
			# 	return

			@editor.commands.addCommand(
				name: 'execute'
				bindKey:
					win: 'Ctrl-Shift-Enter'
					mac: 'Command-Shift-Enter'
					sender: 'editor|cli'
				exec: @runFile
			)

			@editor.commands.addCommand(
				name: 'execute-command'
				bindKey:
					win: 'Ctrl-Enter'
					mac: 'Command-Enter'
					sender: 'editor|cli'
				exec: @executeCommand
			)

			@editor.commands.addCommand(
				name: 'previous-command'
				bindKey:
					win: 'Ctrl-Up'
					mac: 'Command-Up'
					sender: 'editor|cli'
				exec: @previousCommand
			)
			@editor.commands.addCommand(
				name: 'next-command'
				bindKey:
					win: 'Ctrl-Down'
					mac: 'Command-Down'
					sender: 'editor|cli'
				exec: @nextCommand
			)

			return

		### commande manager in console mode ###

		addCommand: (command)->
			@commandQueue.push(command)
			if @commandQueue.length>@MAX_COMMANDS
				@commandQueue.shift()
			@commandIndex = @commandQueue.length
			return

		executeCommand: (env, args, request)=>
			command = @editor.getValue()
			if command.length == 0 then return
			@addCommand(command)
			@runFile()
			@editor.setValue('')
			return

		previousCommand: (env, args, request)=>
			cursorPosition = @editor.getCursorPosition()
			if cursorPosition.row == 0 and cursorPosition.column == 0
				if @commandIndex == @commandQueue.length
					command = @editor.getValue()
					if command.length > 0
						@addCommand(command)
						@commandIndex--
				if @commandIndex > 0
					@commandIndex--
					@editor.setValue(@commandQueue[@commandIndex])
			else
				@editor.gotoLine(0,0)
			return

		nextCommand: (env, args, request)=>
			cursorPosition = @editor.getCursorPosition()
			lastRow = @editor.getSession().getLength()-1
			lastColumn = @editor.getSession().getLine(lastRow).length
			if cursorPosition.row == lastRow and cursorPosition.column == lastColumn
				if @commandIndex < @commandQueue.length - 1
					@commandIndex++
					@editor.setValue(@commandQueue[@commandIndex])
			else
				@editor.gotoLine(lastRow+1, lastColumn+1)
			return

		### mouse interaction ###

		onHandleDown: ()=>
			@draggingEditor = true
			$("body").css( 'user-select': 'none' )
			return

		setHalfSize: ()=>
			@editorJ.css(right: '50%')
			@resize()
			return

		setFullSize: ()=>
			@editorJ.css(right: 0)
			@resize()
			return

		resize: ()=>
			@editor.resize()
			return

		onMouseMove: (event)->
			if @draggingEditor
				@editorJ.css( right: window.innerWidth-event.pageX)
			@console.onMouseMove(event)
			return

		onMouseUp: (event)=>
			if @draggingEditor
				@editor.resize()
			@draggingEditor = false
			@console.onMouseUp(event)
			$("body").css('user-select': 'text')
			return

		### open close ###
		open: ()->
			@editorJ.show()
			@editorJ.addClass('visible')
			@console.setNativeLogs()
			return

		close: ()=>
			@editorJ.hide()
			@editorJ.removeClass('visible')
			@console.resetNativeLogs()
			return

		### file linker ###

		linkFile: (evt) ->
			evt.stopPropagation()
			evt.preventDefault()

			if @linkFileInputJ.hasClass('link-file')
				@linkFileInputJ.removeClass('link-file').addClass('unlink-file')
				@editorJ.find('span.glyphicon-floppy-open').removeClass('glyphicon-floppy-open').addClass('glyphicon-floppy-remove')
				@linkFileInputJ.hide()
				@editorJ.find('button.link-file').on('click', @linkFile)

				files = evt.dataTransfer?.files or evt.target?.files

				@linkedFile = files[0]
				@fileReader = new FileReader()

				@lookForChangesInterval = setInterval(@readFile, 1000)

			else if @linkFileInputJ.hasClass('unlink-file')
				@linkFileInputJ.removeClass('unlink-file').addClass('link-file')
				@editorJ.find('span.glyphicon-floppy-remove').removeClass('glyphicon-floppy-remove').addClass('glyphicon-floppy-open')
				@linkFileInputJ.show()
				@editorJ.find('button.link-file').off('click', @linkFile)

				clearInterval(@lookForChangesInterval)
				@fileReader = null
				@linkedFile = null
				@readFile = null

			return

		readLinkedFile: ()=>
			@fileReader.readAsText(@linkedFile)
			return

		onLoadLinkedFile: ()=>
			@editor.getSession().setValue( event.target.result )
			return

		### set, compile and run scripts ###

		clearFile: (closeEditor=true)->
			@setFile(null)
			if closeEditor
				@close()
			return

		setFile: (node)->
			if @mode == 'code'
				@node = node
				@setSource(node?.source or '')
			else if @mode == 'difference'
				@setDifferenceFromNode(node)
			return

		setSource: (source)->
			@editor.getSession().off('change', @onChange)
			@editor.getSession().setValue(source)
			@editor.getSession().on('change', @onChange)
			return

		compile: (source)->
			source ?= @editor.getValue()

			try
				return CoffeeScript.compile source, bare: on 			# compile coffeescript to javascript
			catch {location, message} 	# compilation error, or className was not found: log & display error
				if location?
					errorMessage = "Error on line #{location.first_line + 1}: #{message}"
					if message == "unmatched OUTDENT"
						errorMessage += "\nThis error is generally due to indention problem or unbalanced parenthesis/brackets/braces."
				console.error errorMessage
				return null
			return

		run: (script)->
			try
				result = eval script
				console.log result
			catch error 									# display and throw error if any
				console.error error
				throw error
				return null
			return script

		define: (modulesNames, f)->
			args = []
			for moduleName in modulesNames
				module = modules[moduleName]
				if not module?
					R.alertManager.alert 'module ' + moduleName + ' does not exist.'
				args.push(module)
			f.apply(window, args)
			return

		runFile: ()->
			if not require?.s?.contexts?._?.defined?
				R.alertManager.alert 'requirejs not loaded?'
				return
			code = @editor.getValue()
			js = @compile(code)
			if not js then return
			if @mode == 'code' and @node? then R.fileManager.updateFile(@node, code, js)
			# replace the requirejs 'define' function by a custom define function to execute the code
			requirejsDefine = window.define
			modules = require.s.contexts._.defined
			window.define = @define
			@run(js)
			window.define = requirejsDefine
			return

		# save on change:

		onChange: ()=>
			if R.codeEditor.fileNode? then Utils.deferredExecution(R.codeEditor.save, 'save:'+R.codeEditor.fileNode.path)
			return

		save: ()=>
			if @node? then R.fileManager.updateFile(@node, @editor.getValue())
			return

		# Diffing

		initializeDifferenceValidation: (@differences)->
			require ['aceDiff'], @aceDiffLoaded
			return

		aceDiffLoaded: (AceDiff)=>
			# initialize html
			@codeJ.hide()
			@diffJ.show()
			@diffFooterJ.show()
			@setFullSize()
			@mode = 'difference'

			@previousBtnJ = @diffFooterJ.find('button.previous')
			@nextBtnJ = @diffFooterJ.find('button.next')
			@copyMainBtnJ = @diffFooterJ.find('button.copy-main')
			@commitBtnJ = @diffFooterJ.find('button.commit')
			@pullRequestBtnJ = @diffFooterJ.find('button.pull-request')

			@previousBtnJ.click @onPreviousDifference
			@nextBtnJ.click @onNextDifference
			@commitBtnJ.click @finishDifferenceValidationAndCommit
			@commitBtnJ.hide()
			@pullRequestBtnJ.click @finishDifferenceValidationAndCreatePullRequest
			@pullRequestBtnJ.show()

			@aceDiff = new AceDiff(
				mode: "ace/mode/coffee"
				theme: "ace/theme/monokai"
				right:
					copyLinkEnabled: false
				left:
					editable: false
			)
			@currentDifference = 0
			if @differences.length > 0 then @updateCurrentDifference()
			return

		setCurrentDifference: (i)->
			@currentDifference = Utils.clamp(0, i, @differences.length-1)
			@updateCurrentDifference()
			return

		updateCurrentDifference: ()->
			difference = @differences[@currentDifference]
			difference.checked = true

			if not difference.main?
				@copyMainBtnJ.text("Delete file on fork")
			else if not difference.fork?
				@copyMainBtnJ.text("Create file on fork")
			else
				@copyMainBtnJ.text("Replace file on fork")

			@aceDiff.setOptions
				right:
					content: difference.main
				left:
					content: difference.fork
			return

		setDifferenceFromNode: (node)->
			for difference, i in @differences
				if difference.fork == node.file
					@setCurrentDifference(i)
					return
			R.alertManager.alert('This file does not differ.', 'warning')
			return

		onPreviousDifference: ()=>
			@setCurrentDifference(@currentDifference--)
			if @currentDifference <= 0 then @previousBtnJ.addClass("disabled") else @previousBtnJ.removeClass("disabled")
			return

		onNextDifference: ()=>
			@setCurrentDifference(@currentDifference++)
			if @currentDifference >= @differences.length-1 then @nextBtnJ.addClass("disabled") else @nextBtnJ.removeClass("disabled")
			return

		onCopyFile: ()=>
			@changeDifference(@differences[@currentDifference], difference.main?.content)
			return

		onDifferenceChange: ()=>
			Utils.deferredExecution(@changeDifference, 'changeDifference')
			return

		changeDifference: ()=>
			R.fileManager.changeDifference(@differences[@currentDifference], @editor.getValue())
			@commitBtnJ.show()
			@pullRequestBtnJ.hide()
			return

		finishDifferenceValidation: ()->
			for difference, i in @differences
				if not difference.checked
					R.alertManager.alert('You have not validate a difference', 'warning')
					@setCurrentDifference(i)
					return
				else
					$(difference.fork.element).removeClass('difference')
			@mode = 'code'
			@codeJ.show()
			@diffJ.hide()
			@diffFooterJ.hide()
			@setHalfSize()
			return

		finishDifferenceValidationAndCommit: ()=>
			@finishDifferenceValidation()
			R.fileManager.commitChanges()
			return

		finishDifferenceValidationAndCreatePullRequest: ()=>
			@finishDifferenceValidation()
			R.fileManager.pullRequestModal()
			return

	class Console

		constructor: (@codeEditor)->
			@consoleJ = @codeEditor.editorJ.find(".console")
			@consoleContentJ = @consoleJ.find(".content")
			consoleHandleJ = @codeEditor.editorJ.find(".console-handle")
			@consoleToggleBtnJ = consoleHandleJ.find(".close")

			@consoleToggleBtnJ.click @toggle
			consoleHandleJ.mousedown @onConsoleHandleDown

			@height = 200

			return

		close: (height=null)->
			@height = height or @consoleJ.height()
			@consoleJ.css( height: 0 ).addClass('closed')
			@consoleToggleBtnJ.find('.glyphicon').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-up')
			@codeEditor.resize()
			return

		open: (consoleHeight=null)->
			if @consoleJ.hasClass('closed')
				@consoleJ.removeClass("highlight")
				@consoleJ.css( height: consoleHeight or @consoleHeight ).removeClass('closed')
				@consoleToggleBtnJ.find('.glyphicon').removeClass('glyphicon-chevron-up').addClass('glyphicon-chevron-down')
				@codeEditor.resize()
			return

		toggle: ()=>
			if @consoleJ.hasClass('closed')
				@open()
			else
				@close()
			return

		### mouse interaction ###

		onConsoleHandleDown: ()=>
			@draggingConsole = true
			$("body").css( 'user-select': 'none' )
			return

		onMouseMove: (event)->
			if @draggingConsole
				footerHeight = @codeEditor.footerJ.outerHeight()
				bottom = @codeEditor.editorJ.outerHeight() - footerHeight
				height = Math.min(bottom - event.pageY, window.innerHeight - footerHeight )
				@consoleJ.css( height: height )
				minHeight = 20
				if @consoleJ.hasClass('closed') 			# the console is closed
					if height > minHeight 						# user manually opened it
						@open(height)
				else 										# the console is opened
					if height <= minHeight 						# user manually closed it
						@close(200)
			return

		onMouseUp: (event)=>
			if @draggingConsole
				@coeEditor.editor.resize()
			@draggingConsole = false
			return

		### log functions ###

		logMessage: (message)->
			@nativeLog(message)
			if typeof message != 'string' or not message instanceof String
				message = JSON.stringify(message)
			@consoleContentJ.append( $("<p>").append(message) )
			@consoleContentJ.scrollTop(@consoleContentJ[0].scrollHeight)
			if @consoleJ.hasClass("closed")
				@consoleJ.addClass("highlight")
			return

		logError: (message)->
			@nativeError(message)
			@consoleContentJ.append( $("<p>").append(message).addClass("error") )
			@consoleContentJ.scrollTop(@consoleContentJ[0].scrollHeight)
			@openConsole()
			message = "An error occured, you can open the debug console (Command + Option + I)"
			message += " to have more information about the problem."
			R.alertManager.alert message, "info"
			return

		setNativeLogs: ()->
			@nativeLog = console.log
			@nativeError = console.error
			return

		resetNativeLogs: ()->
			console.log = @nativeLog
			console.error = @nativeError
			return

	return CodeEditor
