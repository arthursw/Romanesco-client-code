define [ 'utils', 'socketio' ], (utils, ioo) ->

	# websocket communication
	# websockets are only used to transfer user actions in real time, however every request which will change the database are made with ajax (at a lower frequency)
	# this is due to historical and security reasons

	# get room (string following the format: 'x: X, y: Y' X and Y being the coordinates of the view in project coordinates quantized by R.scale)
	# if current room is different: emit "join" room
	R.updateRoom = ()->
		room = R.getChatRoom()
		if R.room != room
			R.chatRoomJ.empty().append("<span>Room: </span>" + room)
			R.chatSocket.emit("join", room)
			R.room = room

	# initialize chat: emit "nickname" (username) and on callback: initialize chat or show error
	R.startChatting = (username, realUsername=true, focusOnChat=true)->
		R.chatSocket.emit("nickname", username, (set) ->
			if set
				window.clearTimeout(R.chatConnectionTimeout)
				R.chatMainJ.removeClass("hidden")
				R.chatMainJ.find("#chatConnectingMessage").addClass("hidden")
				if realUsername
					R.chatJ.find("#chatLogin").addClass("hidden")
				else
					R.chatJ.find("#chatLogin p.default-username-message").html("You are logged as <strong>" + username + "</strong>")
				R.chatJ.find("#chatUserNameError").addClass("hidden")
				if focusOnChat then R.chatMessageJ.focus()
			else
				R.chatJ.find("#chatUserNameError").removeClass("hidden")
		)

	# todo: add a "n new messages" message at the bottom of the chat box when a user has new messages and he does not focus the chat
	# initialize socket:
	R.initSocket = ()->

		# initialize jQuery objects
		R.chatJ = R.sidebarJ.find("#chatContent")
		R.chatMainJ = R.chatJ.find("#chatMain")
		R.chatRoomJ = R.chatMainJ.find("#chatRoom")
		R.chatUsernamesJ = R.chatMainJ.find("#chatUserNames")
		R.chatMessagesJ = R.chatMainJ.find("#chatMessages")
		# R.chatMessagesScrollJ = R.chatMainJ.find("#chatMessagesScroll")
		R.chatMessageJ = R.chatMainJ.find("#chatSendMessageInput")
		R.chatMessageJ.blur()
		# R.chatMessagesScrollJ.nanoScroller()

		# add message to chat message box
		# scroll sidebar and message box to bottom (depending on who is talking)
		# @param [String] message to add
		# @param [String] (optional) username of the author of the message
		# 				  if *from* is set to R.me, "me" is append before the message,
		# 				  if *from* is set to another user, *from* is append before the message,
		# 				  if *from* is not set, nothing is append before the message
		addMessage = (message, from=null) ->
			if from?
				author = if from == R.me then "me" else from
				R.chatMessagesJ.append( $("<p>").append($("<b>").text(author + ": "), message) )
			else
				R.chatMessagesJ.append( $("<p>").append(message) )
			R.chatMessageJ.val('')

			# if I am the one talking: scroll both sidebar and chat box to bottom
			if from == R.me
				$("#chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
				$(".sidebar-scrollbar.chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
			# else if anything in the chat is active: scroll the chat box to bottom
			else if $(document.activeElement).parents("#Chat").length>0
				$("#chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
			return

		R.chatSocket = io.connect("/chat")

		# on connect: update room (join the room "x: X, y: Y")
		R.chatSocket.on "connect", ->
			R.updateRoom()
			return

		# on annoucement:
		R.chatSocket.on "announcement", (msg) ->
			addMessage(msg)
			return

		# on nicknames:
		R.chatSocket.on "nicknames", (nicknames) ->
			R.chatUsernamesJ.empty().append $("<span>Online: </span>")
			for i of nicknames
				R.chatUsernamesJ.append $("<b>").text( if i>0 then ', ' + nicknames[i] else nicknames[i] )
			return

		# on message to room
		R.chatSocket.on "msg_to_room", (from, msg) ->
			addMessage(msg, from)
			return

		R.chatSocket.on "reconnect", ->
			R.chatMessagesJ.remove()
			addMessage("Reconnected to the server", "System")
			return

		R.chatSocket.on "reconnecting", ->
			addMessage("Attempting to re-connect to the server", "System")
			return

		R.chatSocket.on "error", (e) ->
			addMessage((if e then e else "A unknown error occurred"), "System")
			return

		# emit "user message" and add message to chat box
		sendMessage = ()->
			R.chatSocket.emit( "user message", R.chatMessageJ.val() )
			addMessage( R.chatMessageJ.val(), R.me)
			return

		R.chatMainJ.find("#chatSendMessageSubmit").submit( () -> sendMessage() )

		# on key press: send message if key is return
		R.chatMessageJ.keypress( (event) ->
			if event.which == 13
				event.preventDefault()
				sendMessage()
		)

		connectionError = ()->
			R.chatMainJ.find("#chatConnectingMessage").text("Impossible to connect to chat.")

		R.chatConnectionTimeout = setTimeout(connectionError, 2000)

		# if user not logged: ask for username, start chatting when user entered a username
		if R.chatJ.find("#chatUserNameInput").length>0

			R.chatJ.find("a.sign-in").click (event)->
				$("#user-login-group > button").click()
				event.preventDefault()
				return false

			R.chatJ.find("a.change-username").click (event)->
				$("#chatUserName").show()
				$("#chatUserNameInput").focus()
				event.preventDefault()
				return false

			usernameJ = R.chatJ.find("#chatUserName")

			submitChatUserName = (username, focusOnChat=true)->
				$("#chatUserName").hide()
				username ?= usernameJ.find('#chatUserNameInput').val()
				R.startChatting( username, false, focusOnChat )
				return

			usernameJ.find('#chatUserNameInput').keypress( (event) ->
				if event.which == 13
					event.preventDefault()
					submitChatUserName()
			)

			usernameJ.find("#chatUserNameSubmit").submit( (event) -> submitChatUserName() )

			adjectives = ["Cool","Masked","Bloody","Super","Mega","Giga","Ultra","Big","Blue","Black","White",
			"Red","Purple","Golden","Silver","Dangerous","Crazy","Fast","Quick","Little","Funny","Extreme",
			"Awsome","Outstanding","Crunchy","Vicious","Zombie","Funky","Sweet"]

			things = ["Hamster","Moose","Lama","Duck","Bear","Eagle","Tiger","Rocket","Bullet","Knee",
			"Foot","Hand","Fox","Lion","King","Queen","Wizard","Elephant","Thunder","Storm","Lumberjack",
			"Pistol","Banana","Orange","Pinapple","Sugar","Leek","Blade"]

			username = Utils.Array.random(adjectives) + " " + Utils.Array.random(things)

			submitChatUserName(username, false)

		## Tool creation websocket messages
		# on begin, update and end: call *tool*.begin(objectToEvent(*event*), *from*, *data*)

		# R.chatSocket.on "begin", (from, event, tool, data) ->
		# 	# if from == R.me then return	# should not be necessary since "emit_to_room" from gevent socektio's Room mixin send it to everybody except the sender
		# 	console.log "begin"
		# 	R.tools[tool].begin(objectToEvent(event), from, data)
		# 	return

		# R.chatSocket.on "update", (from, event, tool) ->
		# 	console.log "update"
		# 	R.tools[tool].update(objectToEvent(event), from)
		# 	P.view.update()
		# 	return

		# R.chatSocket.on "end", (from, event, tool) ->
		# 	console.log "end"
		# 	R.tools[tool].end(objectToEvent(event), from)
		# 	P.view.update()
		# 	return

		# R.chatSocket.on "setPK", (from, pid, pk) ->
		# 	console.log "setPK"
		# 	R.items[pid]?.setPK(pk, false)
		# 	return

		# R.chatSocket.on "delete", (pk) ->
		# 	console.log "delete"
		# 	R.items[pk]?.remove()
		# 	P.view.update()
		# 	return

		# R.chatSocket.on "beginSelect", (from, pk, event) ->
		# 	console.log "beginSelect"
		# 	R.items[pk].beginSelect(objectToEvent(event), false)
		# 	P.view.update()
		# 	return

		# R.chatSocket.on "updateSelect", (from, pk, event) ->
		# 	console.log "updateSelect"
		# 	R.items[pk].updateSelect(objectToEvent(event), false)
		# 	P.view.update()
		# 	return

		# R.chatSocket.on "doubleClick", (from, pk, event) ->
		# 	console.log "doubleClick"
		# 	R.items[pk].doubleClick(objectToEvent(event), false)
		# 	P.view.update()
		# 	return

		# R.chatSocket.on "endSelect", (from, pk, event) ->
		# 	console.log "endSelect"
		# 	R.items[pk].endSelect(objectToEvent(event), false)
		# 	P.view.update()
		# 	return

		# R.chatSocket.on "createDiv", (data) ->
		# 	console.log "createDiv"
		# 	RDiv.saveCallback(data, false)

		# R.chatSocket.on "deleteDiv", (pk) ->
		# 	console.log "deleteDiv"
		# 	R.items[pk]?.remove()
		# 	P.view.update()
		# 	return

		# on car move: create car (Raster) if the car for this user does not exist, and update position, rotation and speed.
		# the car will be removed if it is not updated for 1 second
		R.chatSocket.on "car move", (user, position, rotation, speed)->
			if R.ignoreSockets then return
			R.cars[user] ?= new Raster("/static/images/car.png")
			R.cars[user].position = new P.Point(position)
			R.cars[user].rotation = rotation
			R.cars[user].speed = speed
			R.cars[user].rLastUpdate = Date.now()
			return

		# # on parameter change:
		# # set items[pk].data[name] to value and call parameterChanged
		# # experimental *type* == 'rFunction' to call a custom function of the item
		# R.chatSocket.on "parameterChange", (from, pk, name, value, type=null) ->
		# 	if type != "rFunction"
		# 		R.items[pk].setParameter(name, value)
		# 	else
		# 		R.items[pk][name]?(false, value)
		# 	P.view.update()
		# 	return

		R.chatSocket.on "bounce", (data) ->
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
							rasterizeItem = ()->
								if not item.currentCommand then R.rasterizer.rasterize(item)
								return
							Utils.deferredExecution(rasterizeItem, id, 1000)
				else if data.itemClass and data.function == 'create'
					itemClass = g[data.itemClass]
					if RItem.prototype.isPrototypeOf(itemClass)
						itemClass.socketAction = true
						itemClass.create.apply(itemClass, data.arguments)
				P.view.update()
			return

	return