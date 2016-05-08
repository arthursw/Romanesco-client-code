define ['Items/Item', 'Items/Divs/Div', 'UI/Modal', 'oembed'], (Item, Div, Modal) ->

	# todo: remove @url? duplicated in @data.url or remove data.url
	# todo: websocket the url change

	# Media holds an image, video or any content inside an iframe (can be a [shadertoy](https://www.shadertoy.com/))
	# The first attempt is to load the media as an image:
	# - if it succeeds, the image is embedded as a simple image tag,
	#   and can be either be fit (proportion are kept) or resized (dimensions will be the same as Media) in the Media
	#   (the user can modify this in the gui with the 'fit image' button)
	# - if it fails, Media checks if the url start with 'iframe'
	#   if it does, the iframe is embedded as is (this enables to embed shadertoys for example)
	# - otherwise Media tries to embed it with jquery oembed (this enable to embed youtube and vimeo videos just with the video link)
	class Media extends Div
		@label = 'Media'
		@modalTitle = "Insert a media"
		@modalTitleUpdate = "Modify your media"
		@object_type = 'media'

		@initialize: (rectangle)->
			submit = (data)->
				div = new Media(rectangle, data)
				# div.setURL(data.url)
				div.finish()
				if not div.group then return
				div.save()
				div.select()
				return

			modal = Modal.createModal( title: 'Add media', submit: submit )
			modal.addTextInput(name: 'url', placeholder: 'http:// or <iframe>', type: 'url', class: 'url', label: 'URL', required: true)
			modal.show()
			return

		@initializeParameters: ()->

			parameters = super()

			parameters['Media'] =
				url:
					type: 'string'
					label: 'URL'
					default: 'http://'
				fitImage:
					type: 'checkbox'
					label: 'Fit image'
					default: false

			return parameters

		@parameters = @initializeParameters()

		constructor: (bounds, @data=null, @pk=null, @date, @lock=null) ->
			super(bounds, @data, @pk, @date, @lock)
			@url = @data.url
			if @url? and @url.length>0
				@setURL(@url, false)
			return

		dispatchLoadedEvent: ()->
			return

		beginSelect: (event)->
			super(event)
			@contentJ?.css( 'pointer-events': 'none' )
			return

		endSelect: (event)->
			super(event)
			@contentJ?.css( 'pointer-events': 'auto' )
			return

		select: (updateOptions=true, updateSelectionRectangle=true)->
			if not super(updateOptions, updateSelectionRectangle) then return false
			@contentJ?.css( 'pointer-events': 'auto' )
			return true

		deselect: ()->
			if not super() then return false
			@contentJ?.css( 'pointer-events': 'none' )
			return true

		# update the size of the iframe according to the size of @divJ
		setRectangle: (rectangle, update=true)->
			super(rectangle, update)
			width = @divJ.width()
			height = @divJ.height()
			# @contentJ.attr("width", width).attr("height", height).css( "max-width": width, "max-height": height )
			# if @contentJ.find('iframe').length>0
			# 	@contentJ.find('iframe').attr("width", width).attr("height", height).css( "max-width": width, "max-height": height )
			# iframeJ = if @contentJ?.is('iframe') then @contentJ else @contentJ?.find('iframe')
			# iframeJ?.attr("width", width).attr("height", height).css( "max-width": width, "max-height": height )
			@contentJ.attr("width", width).attr("height", height).css( "max-width": width, "max-height": height )
			if not @contentJ?.is('iframe')
				@contentJ.find('iframe').attr("width", width).attr("height", height).css( "max-width": width, "max-height": height )
			return

		# called when user clicks in the "fit image" button in the gui
		# toggle the 'fit-image' class to fit (proportion are kept) or resize (dimensions will be the same as Media) the image in the Media
		toggleFitImage: ()->
			if @isImage?
				@contentJ.toggleClass("fit-image", @data.fitImage)
			return

		# overload {Div#setParameter}
		# update = false when called by parameter.onChange from websocket
		# toggle fit image if required
		setParameter: (name, value)->
			super(name, value)
			switch name
				when 'fitImage'
					@toggleFitImage()
				when 'url'
					@setURL(value, false)
			return

		# return [Boolean] true if the url ends with an image extension: "jpeg", "jpg", "gif" or "png"
		hasImageUrlExt: (url)->
			exts = [ "jpeg", "jpg", "gif", "png" ]
			ext = url.substring(url.lastIndexOf(".")+1)
			if ext in exts
				return true
			return false

		# try to load the url as an image: and call {Media#loadMedia} with the following string:
		# - 'success' if it succeeds
		# - 'error' if it fails
		# - 'timeout' if there was no response for 1 seconds (wait 5 seconds if the url as an image extension since it is likely that it will succeed)
		checkIsImage: ()->
			timedOut = false
			timeout = if @hasImageUrlExt(@url) then 5000 else 1000
			image = new Image()
			timer = setTimeout(()=>
				timedOut = true
				@loadMedia("timeout")
				return
			, timeout)
			image.onerror = image.onabort = ()=>
				if not timedOut
					clearTimeout(timer)
					@loadMedia('error')
				return
			image.onload = ()=>
				if not timedOut
					clearTimeout(timer)
				else
					@contentJ?.remove()
				@loadMedia('success')
				return
			image.src = @url
			return

		# embed the media in the div (this will load it) and update css
		# called by {Media#checkIsImage}
		# @param imageLoadResult [String] the result of the image load test: 'success', 'error' or 'timeout'
		loadMedia: (imageLoadResult)=>
			if imageLoadResult == 'success'
				@contentJ = $('<img class="content image" src="'+@url+'" alt="'+@url+'"">')
				@contentJ.mousedown( (event) -> event.preventDefault() )
				@isImage = true
			else
				# @contentJ = $(@url.replace("http://", ""))

				oembbedContent = ()=>
					@contentJ = $('<div class="content oembedall-container"></div>')
					args =
						includeHandle: false
						embedMethod: 'fill'
						maxWidth: @divJ.width()
						maxHeight: @divJ.height()
						afterEmbed: @afterEmbed
					@contentJ.oembed(@url, args)
					return

				if @url.indexOf("http://")!=0 and @url.indexOf("https://")!=0
					@contentJ = $(@url)
					# if 'url' starts with 'iframe', the user wants to integrate an iframe, not embed using jquery oembed
					if @contentJ.is('iframe')
						@contentJ.attr('width', @divJ.width())
						@contentJ.attr('height', @divJ.height())
					else
						oembbedContent()
				else
					oembbedContent()

			@contentJ.insertBefore(@maskJ)

			@setCss()

			if not @isSelected()
				@contentJ.css( 'pointer-events': 'none' )

			commandEvent = document.createEvent('Event')
			commandEvent.initEvent('command executed', true, true)
			document.dispatchEvent(commandEvent)
			return

		# bug?: called many times when div is resized, maybe because update called urlChanged

		# remove the Media content and embed the media from *url*
		# update the Media if *updateDiv*
		# @param url [String] the url of the media to embed
		# @param updateDiv [Boolean] whether to update the Media
		setURL: (url, updateDiv=false) =>
			console.log 'setURL, updateDiv: ' + updateDiv + ', ' + @pk
			@url = url

			if @contentJ?
				@contentJ.remove()
				$("#jqoembeddata").remove()

			@checkIsImage()

			# websocket urlchange
			if updateDiv
				# if R.me? then R.socket.emit( "parameter change", R.me, @pk, "url", @url ) # will not work unless url is in @data.url
				@update()
			return

		# set the size of the iframe to fit the size of the media once the media is loaded
		# called when the media embedded with jquery oembed is loaded
		afterEmbed: ()=>
			width = @divJ.width()
			height = @divJ.height()
			@contentJ?.find("iframe").attr("width",width).attr("height",height)
			return

	Item.Media = Media
	return Media
