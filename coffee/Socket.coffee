define [ 'socketio' ], (ioo) ->

	class Socket

		constructor: ()->
			@initialize()
			return

		emit: ()->
			@socket.emit.apply(@socket, arguments)
			return
		# websocket communication
		# websockets are only used to transfer user actions in real time, however every request which will change the database are made with ajax (at a lower frequency)
		# this is due to historical and security reasons

		# todo: add a "n new messages" message at the bottom of the chat box when a user has new messages and he does not focus the chat
		# initialize socket:
		initialize: ()->

			# initialize jQuery objects
			@chatJ = $("#chatContent")
			@chatMainJ = @chatJ.find("#chatMain")
			@chatRoomJ = @chatMainJ.find("#chatRoom")
			@chatUsernamesJ = @chatMainJ.find("#chatUserNames")
			@chatMessagesJ = @chatMainJ.find("#chatMessages")
			# R.chatMessagesScrollJ = @chatMainJ.find("#chatMessagesScroll")
			@chatMessageJ = @chatMainJ.find("#chatSendMessageInput")
			@chatMessageJ.blur()
			# R.chatMessagesScrollJ.nanoScroller()

			# add message to chat message box
			# scroll sidebar and message box to bottom (depending on who is talking)
			# @param [String] message to add
			# @param [String] (optional) username of the author of the message
			# 				  if *from* is set to R.me, "me" is append before the message,
			# 				  if *from* is set to another user, *from* is append before the message,
			# 				  if *from* is not set, nothing is append before the message

			if R.offline
				@socket =
					emit: ()-> return
				return

			@socket = io.connect("/chat")

			# on connect: update room (join the room "x: X, y: Y")
			@socket.on "connect", @updateRoom

			# on annoucement:
			@socket.on "announcement", @addMessage

			# on nicknames:
			@socket.on "nicknames", (nicknames) =>
				@chatUsernamesJ.empty().append $("<span>Online: </span>")
				for i of nicknames
					@chatUsernamesJ.append $("<b>").text( if i>0 then ', ' + nicknames[i] else nicknames[i] )
				return

			# on message to room
			@socket.on "msg_to_room", (from, msg) =>
				@addMessage(msg, from)
				return

			@socket.on "reconnect", =>
				@chatMessagesJ.remove()
				@addMessage("Reconnected to the server", "System")
				return

			@socket.on "reconnecting", =>
				@addMessage("Attempting to re-connect to the server", "System")
				return

			@socket.on "error", (e) =>
				@addMessage((if e then e else "A unknown error occurred"), "System")
				return

			@chatMainJ.find("#chatSendMessageSubmit").submit(@sendMessage)

			# on key press: send message if key is return
			@chatMessageJ.keypress(@onKeyPress)

			@chatConnectionTimeout = setTimeout(@onConnectionError, 2000)

			# if user not logged: set a random name
			if @chatJ.find("#chatUserNameInput").length > 0

				@initializeUserName()

			## Tool creation websocket messages
			# on begin, update and end: call *tool*.begin(objectToEvent(*event*), *from*, *data*)

			# @socket.on "begin", (from, event, tool, data) ->
			# 	# if from == R.me then return	# should not be necessary since "emit_to_room" from gevent socektio's Room mixin send it to everybody except the sender
			# 	console.log "begin"
			# 	R.tools[tool].begin(objectToEvent(event), from, data)
			# 	return

			# @socket.on "update", (from, event, tool) ->
			# 	console.log "update"
			# 	R.tools[tool].update(objectToEvent(event), from)
			# 	P.view.update()
			# 	return

			# @socket.on "end", (from, event, tool) ->
			# 	console.log "end"
			# 	R.tools[tool].end(objectToEvent(event), from)
			# 	P.view.update()
			# 	return

			# @socket.on "setPK", (from, pid, pk) ->
			# 	console.log "setPK"
			# 	R.items[pid]?.setPK(pk, false)
			# 	return

			# @socket.on "delete", (pk) ->
			# 	console.log "delete"
			# 	R.items[pk]?.remove()
			# 	P.view.update()
			# 	return

			# @socket.on "beginSelect", (from, pk, event) ->
			# 	console.log "beginSelect"
			# 	R.items[pk].beginSelect(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "updateSelect", (from, pk, event) ->
			# 	console.log "updateSelect"
			# 	R.items[pk].updateSelect(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "doubleClick", (from, pk, event) ->
			# 	console.log "doubleClick"
			# 	R.items[pk].doubleClick(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "endSelect", (from, pk, event) ->
			# 	console.log "endSelect"
			# 	R.items[pk].endSelect(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "createDiv", (data) ->
			# 	console.log "createDiv"
			# 	Div.saveCallback(data, false)

			# @socket.on "deleteDiv", (pk) ->
			# 	console.log "deleteDiv"
			# 	R.items[pk]?.remove()
			# 	P.view.update()
			# 	return

			# # on parameter change:
			# # set items[pk].data[name] to value and call parameterChanged
			# # experimental *type* == 'rFunction' to call a custom function of the item
			# @socket.on "parameterChange", (from, pk, name, value, type=null) ->
			# 	if type != "rFunction"
			# 		R.items[pk].setParameter(name, value)
			# 	else
			# 		R.items[pk][name]?(false, value)
			# 	P.view.update()
			# 	return

			@socket.on "bounce", @onBounce

		initializeUserName: ()->
			@chatJ.find("a.sign-in").click(@onSignInClick)

			@chatJ.find("a.change-username").click(@onChangeUserNameClick)

			usernameJ = @chatJ.find("#chatUserName")

			usernameJ.find('#chatUserNameInput').keypress(@onUserNameInputKeypress)

			usernameJ.find("#chatUserNameSubmit").submit(@submitChatUserName)

			adjectives = ["Cool","Masked","Bloody","Super","Mega","Giga","Ultra","Big","Blue","Black","White",
			"Red","Purple","Golden","Silver","Dangerous","Crazy","Fast","Quick","Little","Funny","Extreme",
			"Awsome","Outstanding","Crunchy","Vicious","Zombie","Funky","Sweet"]

			things = ["Hamster","Moose","Lama","Duck","Bear","Eagle","Tiger","Rocket","Bullet","Knee",
			"Foot","Hand","Fox","Lion","King","Queen","Wizard","Elephant","Thunder","Storm","Lumberjack",
			"Pistol","Banana","Orange","Pinapple","Sugar","Leek","Blade"]

			username = Utils.Array.random(adjectives) + " " + Utils.Array.random(things)

			@submitChatUserName(username, false)
			return

		addMessage: (message, from=null) =>
			if from?
				author = if from == R.me then "me" else from
				@chatMessagesJ.append( $("<p>").append($("<b>").text(author + ": "), message) )
			else
				@chatMessagesJ.append( $("<p>").append(message) )
			@chatMessageJ.val('')

			# if I am the one talking: scroll both sidebar and chat box to bottom
			if from == R.me
				$("#chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
				$(".sidebar-scrollbar.chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
			# else if anything in the chat is active: scroll the chat box to bottom
			else if $(document.activeElement).parents("#Chat").length>0
				$("#chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
			return

		onKeyPress: (event) =>
			if event.which == 13
				event.preventDefault()
				@sendMessage()
			return

		onConnectionError: ()=>
			@chatMainJ.find("#chatConnectingMessage").text("Impossible to connect to chat.")
			return

		onSignInClick: (event)->
			$("#user-login-group > button").click()
			event.preventDefault()
			return false

		onChangeUserNameClick: (event)->
			$("#chatUserName").show()
			$("#chatUserNameInput").focus()
			event.preventDefault()
			return false

		onUserNameInputKeypress: (event) ->
			if event.which == 13
				event.preventDefault()
				@submitChatUserName()
			return

		submitChatUserName: (username, focusOnChat=true)=>
			$("#chatUserName").hide()
			username ?= usernameJ.find('#chatUserNameInput').val()
			@startChatting( username, false, focusOnChat )
			return

		# emit "user message" and add message to chat box
		sendMessage: ()=>
			@socket.emit( "user message", @chatMessageJ.val() )
			@addMessage( @chatMessageJ.val(), R.me)
			return

		# get room (string following the format: 'x: X, y: Y' X and Y being the coordinates of the view in project coordinates quantized by R.scale)
		# if current room is different: emit "join" room
		updateRoom: ()=>
			room = @getChatRoom()
			if R.room != room
				@chatRoomJ.empty().append("<span>Room: </span>" + room)
				@socket.emit("join", room)
				R.room = room

		# initialize chat: emit "nickname" (username) and on callback: initialize chat or show error
		startChatting: (username, realUsername=true, focusOnChat=true)=>
			@socket.emit("nickname", username, @onSetUserName)
			if focusOnChat then @chatMessageJ.focus()
			if realUsername
				@chatJ.find("#chatLogin").addClass("hidden")
			else
				@chatJ.find("#chatLogin p.default-username-message").html("You are logged as <strong>" + username + "</strong>")
			return

		onSetUserName: (set)=>
			if set
				window.clearTimeout(@chatConnectionTimeout)
				@chatMainJ.removeClass("hidden")
				@chatMainJ.find("#chatConnectingMessage").addClass("hidden")
				@chatJ.find("#chatUserNameError").addClass("hidden")
			else
				@chatJ.find("#chatUserNameError").removeClass("hidden")
			return

		onBounce: (data) ->
			if R.ignoreSockets then return
			if data.function? and data.arguments?
				if data.tool?
					tool = R.tools[data.tool]
					if data.function not in ['begin', 'update', 'end', 'createPath']
						console.log 'Error: not authorized to call' + data.function
						return
					rFunction = tool?[data.function]
					if rFunction?
						data.arguments[0] = Event.prototype.fromJSON(data.arguments[0])
						rFunction.apply(tool, data.arguments)
				else if data.itemPk?
					item = R.items[data.itemPk]
					if item? and not item.currentCommand?
						allowedFunctions =
							['setRectangle', 'setRotation', 'moveTo', 'setParameter', 'modifyPoint', 'modifyPointType',
							'modifySpeed', 'setPK', 'delete', 'create', 'addPoint', 'deletePoint', 'modifyControlPath', 'setText']
						if data.function not in allowedFunctions
							console.log 'Error: not authorized to call: ' + data.function
							return
						rFunction = item[data.function]
						if not rFunction?
							console.log 'Error: function is not valid: ' + data.function
							return

						id = 'rasterizeItem-'+item.pk

						itemMustBeRasterized = data.function not in ['setPK', 'create'] and not item.drawing.visible

						if not R.updateTimeout[id]? and itemMustBeRasterized
							R.rasterizer.drawItems()
							R.rasterizer.rasterize(item, true)

						item.drawing.visible = true

						item.socketAction = true
						rFunction.apply(item, data.arguments)
						delete item.socketAction

						if itemMustBeRasterized and data.function not in ['delete']
							Utils.deferredExecution(@rasterizeItem, id, 1000)
				else if data.itemClass and data.function == 'create'
					itemClass = g[data.itemClass]
					if Item.prototype.isPrototypeOf(itemClass)
						itemClass.socketAction = true
						itemClass.create.apply(itemClass, data.arguments)
				P.view.update()
			return

		rasterizeItem: ()->
			if not item.currentCommand then R.rasterizer.rasterize(item)
			return

		getChatRoom: ()->
			return 'x: ' + Math.round(P.view.center.x / R.scale) + ', y: ' + Math.round(P.view.center.y / R.scale)

	return Socket
