define [ 'Tools/Tool', 'zeroClipboard' ], (Tool, ZeroClipboard) ->

	# todo: ZeroClipboard.destroy()
	# ScreenshotTool to take a screenshot and save it or publish it on different social platforms (facebook, pinterest or twitter)
	# - the user will create a selection rectangle with the mouse
	# - when the user release the mouse, a special (temporary) resizable Div (RSelectionRectangle) is created so that the user can adjust the screenshot box to fit his needs (this must be imporved, with better visibility and the possibility to better snap the box to the grid)
	# - once the user adjusted the box, he can take the screenshot by clicking the "Take screenshot" button at the center of the RSelectionRectangle
	# - a modal window asks the user how to exploit the newly created image (copy it, save it, or publish it on facebook, twitter or pinterest)
	class ScreenshotTool extends Tool

		@label = 'Screenshot'
		@description = ''
		@iconURL = 'screenshot.png'
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'
			icon: 'screenshot'
		@drawItems = false

		# Initialize screenshot modal (init button click event handlers)
		constructor: () ->
			super(true)
			@modalJ = $("#screenshotModal")
			# @modalJ.find('button[name="copy-data-url"]').click( ()=> @copyDataUrl() )
			@modalJ.find('button[name="publish-on-facebook"]').click( ()=> @publishOnFacebook() )
			@modalJ.find('button[name="publish-on-facebook-photo"]').click( ()=> @publishOnFacebookAsPhoto() )
			@modalJ.find('button[name="download-png"]').click( ()=> @downloadPNG() )
			@modalJ.find('button[name="download-svg"]').click( ()=> @downloadSVG() )
			@modalJ.find('button[name="publish-on-pinterest"]').click ()=>@publishOnPinterest()
			@descriptionJ = @modalJ.find('input[name="message"]')
			@descriptionJ.change ()=>
				@modalJ.find('a[name="publish-on-twitter"]').attr("data-text", @getDescription())
				return

			ZeroClipboard.config( swfPath: R.romanescoURL + "static/libs/ZeroClipboard/ZeroClipboard.swf" )
			# ZeroClipboard.destroy()
			@selectionRectangle = null

			return

		# Get description input value, or default description: "Artwork made with Romanesco: http://romanesc.co/#0.0,0.0"
		getDescription: ()->
			return if @descriptionJ.val().length>0 then @descriptionJ.val() else "Artwork made with Romanesco: " + @locationURL

		checkRemoveScreenshotRectangle: (item)->
			if @selectionRectangle? and item != @selectionRectangle
				@selectionRectangle.remove()
			return

		# create selection rectangle
		begin: (event) ->
			from = R.me
			R.currentPaths[from] = new P.Path.Rectangle(event.point, event.point)
			R.currentPaths[from].name = 'screenshot tool selection rectangle'
			R.currentPaths[from].dashArray = [4, 10]
			R.currentPaths[from].strokeColor = 'black'
			R.currentPaths[from].strokeWidth = 1
			R.selectionLayer.addChild(R.currentPaths[from])
			return

		# update selection rectangle
		update: (event) ->
			from = R.me
			R.currentPaths[from].lastSegment.point = event.point
			R.currentPaths[from].lastSegment.next.point.y = event.point.y
			R.currentPaths[from].lastSegment.previous.point.x = event.point.x
			return

		# - remove selection rectangle
		# - return if rectangle is too small
		# - create the RSelectionRectangle (so that the user can adjust the screenshot box to fit his needs)
		end: (event) ->
			from = R.me
			# remove selection rectangle
			R.currentPaths[from].remove()
			delete R.currentPaths[from]
			# P.view.update()

			# return if rectangle is too small
			r = new P.Rectangle(event.downPoint, event.point)
			if r.area<100
				return

			@selectionRectangle = new R.RSelectionRectangle(new P.Rectangle(event.downPoint, event.point), @extractImage)

			return

		# Extract image and initialize & display modal (so that the user can choose what to do with it)
		# todo: use something like [rasterizeHTML.js](http://cburgmer.github.io/rasterizeHTML.js/) to render RDivs in the image
		extractImage: (redraw)=>
			@rectangle = @selectionRectangle.getBounds()
			@selectionRectangle.remove()

			@dataURL = R.rasterizer.extractImage(@rectangle, redraw)

			@locationURL = R.romanescoURL + location.hash

			@descriptionJ.attr('placeholder', 'Artwork made with Romanesco: ' + @locationURL)
			# initialize modal (data url and image)
			copyDataBtnJ = @modalJ.find('button[name="copy-data-url"]')
			copyDataBtnJ.attr("data-clipboard-text", @dataURL)
			imgJ = @modalJ.find("img.png")
			imgJ.attr("src", @dataURL)
			maxHeight = window.innerHeight - 220
			imgJ.css( 'max-height': maxHeight + "px" )
			@modalJ.find("a.png").attr("href", @dataURL)

			# initialize twitter button
			twitterLinkJ = @modalJ.find('a[name="publish-on-twitter"]')
			twitterLinkJ.empty().text("Publish on Twitter")
			twitterLinkJ.attr "data-url", @locationURL
			twitterScriptJ = $("""<script type="text/javascript">
				window.twttr=(function(d,s,id){var t,js,fjs=d.getElementsByTagName(s)[0];
				if(d.getElementById(id)){return}js=d.createElement(s);
				js.id=id;js.src="https://platform.twitter.com/widgets.js";
				fjs.parentNode.insertBefore(js,fjs);
				return window.twttr||(t={_e:[],ready:function(f){t._e.push(f)}})}(document,"script","twitter-wjs"));
			</script>""")
			twitterLinkJ.append(twitterScriptJ)

			# show modal, and initialize ZeroClipboard once it is on screen (ZeroClipboard enables users to copy the image data in the clipboard)
			@modalJ.modal('show')
			@modalJ.on 'shown.bs.modal', (e)->
				client = new ZeroClipboard( copyDataBtnJ )
				client.on "ready", (readyEvent)->
					console.log "ZeroClipboard SWF is ready!"
					client.on "aftercopy", (event)->
						# `this` === `client`
						# `event.target` === the element that was clicked
						# event.target.style.display = "none"
						R.alertManager.alert("Image data url was successfully copied into the clipboard!", "success")
						this.destroy()
						return
					return
				return
			return

		# copyDataUrl: ()=>
		# 	@modalJ.modal('hide')
		# 	return

		# Some actions require to upload the image on the server
		# makes an ajax request to save the image
		saveImage: (callback)->
			# ajaxPost '/saveImage', {'image': @dataURL } , callback
			Dajaxice.draw.saveImage( callback, {'image': @dataURL } )
			R.alertManager.alert "Your image is being uploaded...", "info"
			return

		# Save image and call publish on facebook callback
		publishOnFacebook: ()=>
			@saveImage(@publishOnFacebookCallback)
			return

		# (Called once the image is uploaded) add a facebook dialog box in which user can add more info and publish the image
		# todo: check if upload was successful?
		publishOnFacebookCallback: (result)=>
			R.alertManager.alert "Your image was successfully uploaded to Romanesco, posting to Facebook...", "info"
			caption = @getDescription()
			FB.ui(
				method: "feed"
				name: "Romanesco"
				caption: caption
				description: ("Romanesco is an infinite collaborative drawing app.")
				link: @locationURL
				picture: R.romanescoURL + result.url
			, (response) ->
				if response and response.post_id
					R.alertManager.alert "Your Post was successfully published!", "success"
				else
					R.alertManager.alert "An error occured. Your post was not published.", "error"
				return
			)

			# @modalJ.modal('hide')

			# imageData = 'data:image/png;base64,'+result.image
			# image = new Image()
			# image.src = imageData
			# R.canvasJ[0].getContext("2d").drawImage(image, 300, 300)

			# # FB.login( () ->
			# # 	if (response.session) {
			# # 		if (response.perms) {
			# # 			# // user is logged in and granted some permissions.
			# # 			# // perms is a comma separated list of granted permissions
			# # 		} else {
			# # 			# // user is logged in, but did not grant any permissions
			# # 		}
			# # 	} else {
			# # 		# // user is not logged in
			# # 	}
			# # }, {perms:'read_stream,publish_stream,offline_access'})

			# FB.api(
			# 	"/me/photos",
			# 	"POST",
			# 	{
			# 		"object": {
			# 			"url": result.url
			# 		}
			# 	},
			# 	(response) ->
			# 		# if (response && !response.error)
			# 			# handle response
			# 		return
			# )
			return

		# - log in to facebook (if not already logged in)
		# - save image to publish photo when/if logged in
		publishOnFacebookAsPhoto: ()=>
			if not R.loggedIntoFacebook
				FB.login( (response)=>
					if response and !response.error
						@saveImage(@publishOnFacebookAsPhotoCallback)
					else
						R.alertManager.alert "An error occured when trying to log you into facebook.", "error"
					return
				)
			else
				@saveImage(@publishOnFacebookAsPhotoCallback)
			return

		# (Called once the image is uploaded) directly publish the image
		# todo: check if upload was successful?
		publishOnFacebookAsPhotoCallback: (result)=>
			R.alertManager.alert "Your image was successfully uploaded to Romanesco, posting to Facebook...", "info"
			caption = @getDescription()
			FB.api(
				"/me/photos",
				"POST",
				{
					"url": R.romanescoURL + result.url
					"message": caption
				},
				(response)->
					if response and !response.error
						R.alertManager.alert "Your Post was successfully published!", "success"
					else
						R.alertManager.alert("An error occured. Your post was not published.", "error")
						console.log response.error
					return
			)
			return

		# Save image and call publish on pinterest callback
		publishOnPinterest: ()=>
			@saveImage(@publishOnPinterestCallback)
			return

		# (Called once the image is uploaded) add a modal dialog to publish the image on pinterest (the pinterest button must link to an image already existing on the server)
		# todo: check if upload was successful?
		publishOnPinterestCallback: (result)=>
			R.alertManager.alert "Your image was successfully uploaded to Romanesco...", "info"

			# initialize pinterest modal
			pinterestModalJ = $("#customModal")
			pinterestModalJ.modal('show')
			pinterestModalJ.addClass("pinterest-modal")
			pinterestModalJ.find(".modal-title").text("Publish on Pinterest")
			# siteUrl = encodeURI('http://romanesc.co/')
			siteUrl = encodeURI(R.romanescoURL)
			imageUrl = siteUrl+result.url
			caption = @getDescription()
			description = encodeURI(caption)

			linkJ = $("<a>")
			linkJ.addClass("image")
			linkJ.attr("href", "http://pinterest.com/pin/create/button/?url="+siteUrl+"&media="+imageUrl+"&description="+description)
			linkJcopy = linkJ.clone()

			imgJ = $('<img>')
			imgJ.attr( 'src', siteUrl+result.url )
			linkJ.append(imgJ)

			buttonJ = pinterestModalJ.find('button[name="submit"]')
			linkJcopy.addClass("btn btn-primary").text("Pin it!").insertBefore(buttonJ)
			buttonJ.hide()

			submit = ()->
				pinterestModalJ.modal('hide')
				return
			linkJ.click(submit)
			pinterestModalJ.find(".modal-body").empty().append(linkJ)

			pinterestModalJ.on 'hide.bs.modal', (event)->
				pinterestModalJ.removeClass("pinterest-modal")
				linkJcopy.remove()
				pinterestModalJ.off 'hide.bs.modal'
				return

			return

		# publishOnTwitter: ()=>
		# 	linkJ = $('<a name="publish-on-twitter" class="twitter-share-button" href="https://twitter.com/share" data-text="Artwork made on Romanesco" data-size="large" data-count="none">Publish on Twitter</a>')
		# 	linkJ.attr "data-url", "http://romanesc.co/" + location.hash
		# 	scriptJ = $('<script type="text/javascript">window.twttr=(function(d,s,id){var t,js,fjs=d.getElementsByTagName(s)[0];if(d.getElementById(id)){return}js=d.createElement(s);js.id=id;js.src="https://platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);return window.twttr||(t={_e:[],ready:function(f){t._e.push(f)}})}(document,"script","twitter-wjs"));</script>')
		# 	$("div.temporary").append(linkJ)
		# 	$("div.temporary").append(scriptJ)
		# 	linkJ.click()
		# 	return

		# on download png button click: simulate a click on the image link
		# (chrome will open the save image dialog, other browsers will open the image in a new window/tab for the user to be able to save it)
		downloadPNG: ()=>
			@modalJ.find("a.png")[0].click()
			@modalJ.modal('hide')
			return

		# on download svg button click: extract svg from the paper project (in the selected rectangle) and click on resulting svg image link
		# (chrome will open the save image dialog, other browsers will open the image in a new window/tab for the user to be able to save it)
		downloadSVG: ()=>
			# get rectangle and retrieve items in this rectangle
			rectanglePath = new P.Path.Rectangle(@rectangle)

			itemsToSave = []
			for item in P.project.activeLayer.children
				bounds = item.bounds
				if item.controller?
					controlPath = item.controller.controlPath
					if @rectangle.contains(bounds) or ( @rectangle.intersects(bounds) and controlPath?.getIntersections(rectanglePath).length>0 )
						Utils.Array.pushIfAbsent(itemsToSave, item.controller)

			# put the retrieved items in a group
			svgGroup = new P.Group()

			# draw items which were not drawn
			for item in itemsToSave
				if not item.drawing? then item.draw()

			P.view.update()

			# add items to svg group
			for item in itemsToSave
				svgGroup.addChild(item.drawing.clone())

			# create a new paper project and add the new P.Group (fit group and project positions and dimensions according to the selected rectangle)
			rectanglePath.remove()
			position = svgGroup.position.subtract(@rectangle.topLeft)
			fileName = "image.svg"

			canvasTemp = document.createElement('canvas')
			canvasTemp.width = @rectangle.width
			canvasTemp.height = @rectangle.height

			tempProject = new Project(canvasTemp)
			svgGroup.position = position
			tempProject.addChild(svgGroup)

			# export new Project to svg, remove the new Project
			svg = tempProject.exportSVG( asString: true )
			tempProject.remove()
			paper.projects[0].activate()

			# create an svg image, create a link to download the image, and click it
			blob = new Blob([svg], {type: 'image/svg+xml'})
			url = URL.createObjectURL(blob)
			link = document.createElement("a")
			link.download = fileName
			link.href = url
			link.click()

			@modalJ.modal('hide')
			return

		# nothing to do here: ZeroClipboard handles it
		copyURL: ()->
			return

	Tool.Screenshot = ScreenshotTool
	return ScreenshotTool
