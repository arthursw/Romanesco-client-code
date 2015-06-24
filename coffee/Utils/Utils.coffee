define ['underscore', 'jquery', 'paper'], (_) ->

	# window._ = _
	paper.install(window.P)
	Utils = {}

	R.templatesJ = $("#templates")
	#\
	#|*|
	#|*|  IE-specific polyfill which enables the passage of arbitrary arguments to the
	#|*|  callback functions of JavaScript timers (HTML5 standard syntax).
	#|*|
	#|*|  https://developer.mozilla.org/en-US/docs/DOM/window.setInterval
	#|*|
	#|*|  Syntax:
	#|*|  var timeoutID = window.setTimeout(func, delay, [param1, param2, ...]);
	#|*|  var timeoutID = window.setTimeout(code, delay);
	#|*|  var intervalID = window.setInterval(func, delay[, param1, param2, ...]);
	#|*|  var intervalID = window.setInterval(code, delay);
	#|*|
	#\
	if document.all and not window.setTimeout.isPolyfill
		__nativeST__ = window.setTimeout
		window.setTimeout = (vCallback, nDelay) -> #, argumentToPass1, argumentToPass2, etc.
			aArgs = Array::slice.call(arguments, 2)
			__nativeST__ (if vCallback instanceof Function then ->
				vCallback.apply null, aArgs
			else vCallback), nDelay

		window.setTimeout.isPolyfill = true
	if document.all and not window.setInterval.isPolyfill
		__nativeSI__ = window.setInterval
		window.setInterval = (vCallback, nDelay) -> #, argumentToPass1, argumentToPass2, etc.
			aArgs = Array::slice.call(arguments, 2)
			__nativeSI__ (if vCallback instanceof Function then ->
				vCallback.apply null, aArgs
			else vCallback), nDelay

	# $.ajaxSetup(
	# 	beforeSend: (xhr, settings)->
	# 		if (!/^(GET|HEAD|OPTIONS|TRACE)$/.test(settings.type) && !this.crossDomain)
	# 			xhr.setRequestHeader("X-CSRFToken", Cookies.get('csrftoken'))
	# )

	window.setInterval.isPolyfill = true

	R.specialKeys = {
		8: 'backspace',
		9: 'tab',
		13: 'enter',
		16: 'shift',
		17: 'control',
		18: 'option',
		19: 'pause',
		20: 'caps-lock',
		27: 'escape',
		32: 'space',
		35: 'end',
		36: 'home',
		37: 'left',
		38: 'up',
		39: 'right',
		40: 'down',
		46: 'delete',
		91: 'command',
		93: 'command',
		224: 'command'
	}

	# @return [Number] sign of *x* (+1 or -1)
	Utils.sign = (x) ->
		(if typeof x is "number" then (if x then (if x < 0 then -1 else 1) else (if x is x then 0 else NaN)) else NaN)

	# @return [Number] *value* clamped with *min* and *max* ( so that min <= value <= max )
	Utils.clamp = (min, value, max)->
		return Math.min(Math.max(value, min), max)

	Utils.random = (min, max)->
		return min + Math.random()*(max-min)

	Utils.Array = {}
	# removes *itemToRemove* from array
	# problem with array.splice(array.indexOf(item),1) :
	# removes the last element if item is not in array
	Utils.Array.remove = (array, itemToRemove) ->
		if not Array.prototype.isPrototypeOf(array) then return
		i = array.indexOf(itemToRemove)
		if i>=0 then array.splice(i, 1)
		# for item,i in this
		# 	if item is itemToRemove
		# 		this.splice(i,1)
		# 		break
		return

	# @return [Array item] random element of the array
	Utils.Array.random = (array) ->
		return array[Math.floor(Math.random()*array.length)]

	# @return [Array item] maximum
	Utils.Array.max = (array) ->
		max = array[0]
		for item in array
			if item>max then max = item
		return max

	# @return [Array item] minimum
	Utils.Array.min = (array) ->
		min = array[0]
		for item in array
			if item<min then min = item
		return min

	# @return [Array item] maximum
	Utils.Array.maxc = (array, biggerThan) ->
		max = array[0]
		for item in array
			if biggerThan(item,max) then max = item
		return max

	# @return [Array item] minimum
	Utils.Array.minc = (array, smallerThan) ->
		min = array[0]
		for item in array
			if smallerThan(item,min) then min = item
		return min

	# check if array is array
	Utils.Array.isArray = (array)->
		return array.constructor == Array

	# R.isNumber = (n)->
	# 	return not isNaN(n) and isFinite(n)

	# previously Array.prototype.pushIfAbsent, but there seem to be a colision with jQuery...
	# push if array does not contain item
	Utils.Array.pushIfAbsent = (array, item) ->
		if array.indexOf(item)<0 then array.push(item)
		return

	Utils.deferredExecutionCallbackWrapper = (callback, id, args, oThis)->
		console.log "deferredExecutionCallbackWrapper: " + id
		delete R.updateTimeout[id]
		if not args? then callback?() else callback?.apply(oThis, args)
		return

	# Execute *callback* after *n* milliseconds, reset the delay timer at each call
	# @param [function] callback function
	# @param [Anything] a unique id (usually the id or pk of RItems) to avoid collisions between deferred executions
	# @param [Number] delay before *callback* is called
	Utils.deferredExecution = (callback, id, n=500, args, oThis) ->
		if not id? then return
		# id ?= callback.name # for ECMAScript 6
		# console.log "deferredExecution: " + id + ", updateTimeout[id]: " + R.updateTimeout[id]
		if R.updateTimeout[id]? then clearTimeout(R.updateTimeout[id])
		console.log "deferred execution: " + id + ', ' + R.updateTimeout[id]
		R.updateTimeout[id] = setTimeout(Utils.deferredExecutionCallbackWrapper, n, callback, id, args, oThis)
		return

	# Execute *callback* at next animation frame
	# @param [function] callback function
	# @param [Anything] a unique id (usually the id or pk of RItems) to avoid collisions between deferred executions
	Utils.callNextFrame = (callback, id, args) ->
		id ?= callback
		callbackWrapper = ()->
			delete R.requestedCallbacks[id]
			if not args? then callback() else callback.apply(window, args)
			return
		R.requestedCallbacks[id] ?= window.requestAnimationFrame(callbackWrapper)
		return

	Utils.cancelCallNextFrame = (idToCancel)->
		window.cancelAnimationFrame(R.requestedCallbacks[idToCancel])
		delete R.requestedCallbacks[idToCancel]
		return

	sqrtTwoPi = Math.sqrt(2*Math.PI)

	# @param [Number] mean: expected value
	# @param [Number] sigma: standard deviation
	# @param [Number] x: parameter
	# @return [Number] value (at *x*) of the gaussian of expected value *mean* and standard deviation *sigma*
	Utils.gaussian = (mean, sigma, x)->
		expf = -((x-mean)*(x-mean)/(2*sigma*sigma))
		return ( 1.0/(sigma*sqrtTwoPi) ) * Math.exp(expf)

	# check if an object has no property
	# @param map [Object] the object to test
	# @return true if there is no property, false otherwise (provided that no library overloads Object)
	Utils.isEmpty = (map)->
		for key, value of map
			if map.hasOwnProperty(key)
				return false
		return true

	Utils.capitalizeFirstLetter = (string)->
    	return string.charAt(0).toUpperCase() + string.slice(1)

	# returns a linear interpolation of *v1* and *v2* according to *f*
	# @param v1 [Number] the first value
	# @param v2 [Number] the second value
	# @param f [Number] the parameter (between v1 and v2 ; f==0 returns v1 ; f==0.25 returns 0.75*v1+0.25*v2 ; f==0.5 returns (v1+v2)/2 ; f==1 returns v2)
	# @return a linear interpolation of *v1* and *v2* according to *f*
	Utils.linearInterpolation = (v1, v2, f)->
		return v1 * (1-f) + v2 * f


	# round *x* to the lower multiple of *m*
	# @param x [Number] the value to round
	# @param m [Number] the multiple
	# @return [Number] the multiple of *m* below *x*
	Utils.floorToMultiple = (x, m)->
		return Math.floor(x / m) * m

	# round *x* to the greater multiple of *m*
	# @param x [Number] the value to round
	# @param m [Number] the multiple
	# @return [Number] the multiple of *m* above *x*
	Utils.ceilToMultiple = (x, m)->
		return Math.ceil(x / m) * m

	# round *x* to the greater multiple of *m*
	# @param x [Number] the value to round
	# @param m [Number] the multiple
	# @return [Number] the multiple of *m* above *x*
	Utils.roundToMultiple = (x, m)->
		return Math.round(x / m) * m

	Utils.floorPointToMultiple = (point, m)->
		return new P.Point(Utils.floorToMultiple(point.x, m), Utils.floorToMultiple(point.y, m))

	Utils.ceilPointToMultiple = (point, m)->
		return new P.Point(Utils.ceilToMultiple(point.x, m), Utils.ceilToMultiple(point.y, m))

	Utils.roundPointToMultiple = (point, m)->
		return new P.Point(Utils.roundToMultiple(point.x, m), Utils.roundToMultiple(point.y, m))

	Utils.Rectangle = {}

	Utils.Rectangle.updatePathRectangle = (path, rectangle)->
		path.segments[0].point = rectangle.bottomLeft
		path.segments[1].point = rectangle.topLeft
		path.segments[2].point = rectangle.topRight
		path.segments[3].point = rectangle.bottomRight
		return

	# @return [Paper P.Rectangle] the bounding box of *rectangle* (smallest rectangle containing *rectangle*) when it is rotated by *rotation*
	Utils.Rectangle.getRotatedBounds = (rectangle, rotation=0)->
		topLeft = rectangle.topLeft.subtract(rectangle.center)
		topLeft.angle += rotation
		bottomRight = rectangle.bottomRight.subtract(rectangle.center)
		bottomRight.angle += rotation
		bottomLeft = rectangle.bottomLeft.subtract(rectangle.center)
		bottomLeft.angle += rotation
		topRight = rectangle.topRight.subtract(rectangle.center)
		topRight.angle += rotation
		bounds = new P.Rectangle(rectangle.center.add(topLeft), rectangle.center.add(bottomRight))
		bounds = bounds.include(rectangle.center.add(bottomLeft))
		bounds = bounds.include(rectangle.center.add(topRight))
		return bounds

	# return a rectangle with integer coordinates and dimensions: left and top positions will be ceiled, right and bottom position will be floored
	# @param rectangle [Paper P.Rectangle] the rectangle to round
	# @return [Paper P.Rectangle] the resulting shrinked rectangle
	Utils.Rectangle.shrinkRectangleToInteger = (rectangle)->
		# return new P.Rectangle(new P.Point(Math.ceil(rectangle.left), Math.ceil(rectangle.top)), new P.Point(Math.floor(rectangle.right), Math.floor(rectangle.bottom)))
		return new P.Rectangle(rectangle.topLeft.ceil(), rectangle.bottomRight.floor())

	# return a rectangle with integer coordinates and dimensions: left and top positions will be floored, right and bottom position will be ceiled
	# @param rectangle [Paper P.Rectangle] the rectangle to round
	# @return [Paper P.Rectangle] the resulting expanded rectangle
	Utils.Rectangle.expandRectangleToInteger = (rectangle)->
		# return new P.Rectangle(new P.Point(Math.floor(rectangle.left), Math.floor(rectangle.top)), new P.Point(Math.ceil(rectangle.right), Math.ceil(rectangle.bottom)))
		return new P.Rectangle(rectangle.topLeft.floor(), rectangle.bottomRight.ceil())

	# return a rectangle with coordinates and dimensions expanded to greater multiple
	# @param rectangle [Paper P.Rectangle] the rectangle to round
	# @return [Paper P.Rectangle] the resulting expanded rectangle
	Utils.Rectangle.expandRectangleToMultiple = (rectangle, multiple)->
		# return new P.Rectangle(new P.Point(Math.floor(rectangle.left), Math.floor(rectangle.top)), new P.Point(Math.ceil(rectangle.right), Math.ceil(rectangle.bottom)))
		return new P.Rectangle(Utils.floorPointToMultiple(rectangle.topLeft, multiple), Utils.ceilPointToMultiple(rectangle.bottomRight, multiple))

	# return a rounded rectangle with integer coordinates and dimensions
	# @param rectangle [Paper P.Rectangle] the rectangle to round
	# @return [Paper P.Rectangle] the resulting rounded rectangle
	Utils.Rectangle.roundRectangle = (rectangle)->
		return new P.Rectangle(rectangle.topLeft.round(), rectangle.bottomRight.round())

	# add custom methods to export Paper P.Point and P.Rectangle to JSON
	P.Point.prototype.toJSON = ()->
		return { x: this.x, y: this.y }
	P.Point.prototype.exportJSON = ()->
		return JSON.stringify(this.toJSON())
	P.Rectangle.prototype.toJSON = ()->
		return { x: this.x, y: this.y, width: this.width, height: this.height }
	P.Rectangle.prototype.exportJSON = ()->
		return JSON.stringify(this.toJSON())
	P.Rectangle.prototype.translate = (point)->
		return new P.Rectangle(this.x + point.x, this.y + point.y, this.width, this.height)
	P.Rectangle.prototype.scaleFromCenter = (scale, center)->
		delta = this.topLeft.subtract(center)
		delta = delta.multiply(scale.x, scale.y)
		topLeft = center.add(delta)
		return new P.Rectangle(topLeft, new Size(this.width * scale.x, this.height * scale.y))
	P.Rectangle.prototype.moveSide = (sideName, destination)->
		switch sideName
			when 'left'
				this.x = destination
			when 'right'
				this.x = destination - this.width
			when 'top'
				this.y = destination
			when 'bottom'
				this.y = destination - this.height
		return
	P.Rectangle.prototype.moveCorner = (cornerName, destination)->
		switch cornerName
			when 'topLeft'
				this.x = destination.x
				this.y = destination.y
			when 'topRight'
				this.x = destination.x - this.width
				this.y = destination.y
			when 'bottomRight'
				this.x = destination.x - this.width
				this.y = destination.y - this.height
			when 'bottomLeft'
				this.x = destination.x
				this.y = destination.y - this.height
		return
	P.Rectangle.prototype.moveCenter = (destination)->
		this.x = destination.x - this.width * 0.5
		this.y = destination.y - this.height * 0.5
		return

	Event.prototype.toJSON = ()->
		event =
			modifiers: this.modifiers
			event: which: this.event.which
			point: this.point
			downPoint: this.downPoint
			delta: this.delta
			middlePoint: this.middlePoint
			type: this.type
			count: this.count
		return event
	Event.prototype.fromJSON = (event)->
		if event.point? then event.point = new P.Point(event.point)
		if event.downPoint? then event.downPoint = new P.Point(event.downPoint)
		if event.delta? then event.delta = new P.Point(event.delta)
		if event.middlePoint? then event.middlePoint = new P.Point(event.middlePoint)
		return event

	# R.ajax = (url, callback, type="GET")->
	# 	xmlhttp = new RXMLHttpRequest()
	# 	xmlhttp.onreadystatechange = ()->
	# 		if xmlhttp.readyState == 4 and xmlhttp.status == 200
	# 			callback()
	# 		return
	# 	xmlhttp.open(type, url, true)
	# 	xmlhttp.send()
	# 	return xmlhttp.onreadystatechange

	# R.getParentPrototype = (object, ParentClass)->
	# 	prototype = object.constructor.prototype
	# 	while prototype != ParentClass.prototype
	# 		prototype = prototype.constructor.__super__
	# 	return prototype

	return