define [ ], () ->

	class AlertManager

		constructor: ()->
			@alertsContainer = $("#Romanesco_alerts")
			@alerts = []
			@currentAlert = -1
			@alertTimeOut = -1
			@alertsContainer.find(".btn-up").click( ()=> @showAlert(@currentAlert-1) )
			@alertsContainer.find(".btn-down").click( ()=> @showAlert(@currentAlert+1) )
			return

		showAlert: (index)->
			if @alerts.length<=0 || index<0 || index>=@alerts.length then return  	# check that index is valid

			prevType = @alerts[@currentAlert].type
			@currentAlert = index
			alertJ = @alertsContainer.find(".alert")
			alertJ.removeClass(prevType).addClass(@alerts[@currentAlert].type).text(@alerts[@currentAlert].message)

			@alertsContainer.find(".alert-number").text(@currentAlert+1)
			return

		alert: (message, type="", delay=2000) ->
			# set type ('info' to default, 'error' == 'danger')
			if type.length==0
				type = "info"
			else if type == "error"
				type = "danger"

			type = " alert-" + type

			# find and show the alert box
			alertJ = @alertsContainer.find(".alert")
			@alertsContainer.removeClass("r-hidden")

			# append alert to alert array
			@currentAlert = @alerts.length
			@alerts.push( { type: type, message: message } )

			if @alerts.length>0 then @alertsContainer.addClass("activated") 		# activate alert box (required for the first time)

			@showAlert(@alerts.length-1)

			# show and hide in *delay* milliseconds
			@alertsContainer.addClass("show")
			if delay!=0
				clearTimeout(R.alertTimeOut)
				@alertTimeOut = setTimeout( ( () -> @alertsContainer.removeClass("show") ) , delay )
			return

	return AlertManager