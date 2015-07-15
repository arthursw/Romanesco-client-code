define ['Utils/Utils', 'UI/Modal'], (Utils, Modal) ->

	class CityManager

		constructor: ()->
			@cityPanelJ = $('#CityPanel')
			@citiesListJ = @cityPanelJ.find('.city-list')

			@createCityBtnJ = @cityPanelJ.find('.create-city')
			@citiesListBtnJ = @cityPanelJ.find('.load-city')

			@createCityBtnJ.click @createCityModal
			@citiesListBtnJ.click @citiesModal

			Dajaxice.draw.loadPrivateCities(@addPrivateCities)
			return

		createCity: (data)->
			Dajaxice.draw.createCity(R.loadCityFromServer, name: data.name, public: data.public)
			return

		createCityModal: ()->
			modal = Modal.createModal( title: 'Create city', submit: @createCity, postSubmit: 'load' )
			modal.addTextInput( label: "City name", name: 'name', required: true, submitShortcut: true, placeholder: 'Paris' )
			modal.addCheckbox( label: "Public", name: 'public', helpMessage: "Public cities will be accessible by anyone.", defaultValue: true )
			modal.show()
			return

		addPrivateCities: (result)->
			if not R.loader.checkError(result) then return

			userCities = JSON.parse(result.userCities)

			for city in userCities
				cityJ = $("<li>")
				cityJ.text(city.name)
				cityJ.attr('data-owner', city.owner).attr('data-pk', city._id.$oid).attr('data-public', 0)
				cityJ.click @loadCity
				btnJ = $('<button type="button"><span class="glyphicon glyphicon-cog" aria-hidden="true"></span></button>')
				btnJ.click @openCitySettings
				cityJ.append(btnJ)
				@citiesListJ.apppend(cityJ)

			return

		loadCity: (name, owner)->
			name ?= $(this).parents('tr:first').attr('data-name')
			owner ?= $(this).parents('tr:first').attr('data-owner')
			R.unload()
			R.city =
				owner: owner
				name: name
				site: null
			R.loader.load()
			R.view.updateHash()
			return

		openCitySettings: (event)->
			event.stopPropagation()

			buttonJ = $(this)
			parentJ = buttonJ.parents('tr:first')
			name = parentJ.attr('data-name')
			isPublic = parseInt(parentJ.attr('data-public'))
			pk = parentJ.attr('data-pk')

			modal = Modal.createModal(title: 'Modify city', submit: @updateCity, data: { pk: pk }, postSubmit: 'load' )
			modal.addTextInput( name: 'name', label: 'Name', defaultValue: name, required: true, submitShortcut: true )
			modal.addCheckbox( name: 'public', label: 'Public', helpMessage: "Public cities will be accessible by anyone.", defaultValue: isPublic )
			modal.show()
			return

		updateCity: (data)=>
			Dajaxice.draw.updateCity(@updateCityCallback, pk: data.data.pk, name: data.name, public: data.public )
			return

		updateCityCallback: ()->
			modal = Modal.getModalByTitle('Modify city')
			modal.hide()
			if not R.loader.checkError(result) then return
			city = JSON.parse(result.city)
			R.alertManager.alert "City successfully renamed to: " + city.name, "info"
			modalBodyJ = Modal.getModalByTitle('Open city').modalBodyJ
			rowJ = modalBodyJ.find('[data-pk="' + city._id.$oid + '"]')
			rowJ.attr('data-name', city.name)
			rowJ.attr('data-public', Number(city.public or 0))
			rowJ.find('.name').text(city.name)
			rowJ.find('.public').text(if city.public then 'Public' else 'Private')
			return

		displayCities: ()->
			Dajaxice.draw.loadPublicCities(@loadPublicCitiesCallback)
			return

		cityRowClicked: (field, value, row, $element)=>
			console.log row.pk
			@loadCity(row.name, row.author)
			return

		loadPublicCitiesCallback: (result)->
			if not R.loader.checkError(result) then return

			modal = Modal.createModal( title: 'Cities', submit: null )

			tableData =
				columns: [
					field: 'name'
					title: 'Name'
				,
					field: 'author'
					title: 'Author'
				,
					field: 'date'
					title: 'Date'
				,
					field: 'public'
					title: 'Public'
				]
				data: []

			for city in publicCities
				tableData.data.push( name: city.name, author: city.author, date: city.date, public: city.public, pk: city._id.$oid )

			tableJ = modal.addTable(tableData)
			tableJ.on 'click-cell.bs.table', @cityRowClicked
			modal.show()
			return

	# R.initializeCities = ()->
	# 	R.toolsJ.find("[data-name='Create']").click ()->
	# 		submit = (data)->
	# 			Dajaxice.draw.createCity(R.loadCityFromServer, name: data.name, public: data.public)
	# 			return
	# 		modal = Modal.createModal( title: 'Create city', submit: submit, postSubmit: 'load' )
	# 		modal.addTextInput( label: "City name", name: 'name', required: true, submitShortcut: true, placeholder: 'Paris' )
	# 		modal.addCheckbox( label: "Public", name: 'public', helpMessage: "Public cities will be accessible by anyone.", defaultValue: true )
	# 		modal.show()
	# 		return

	# 	R.toolsJ.find("[data-name='Open']").click ()->
	# 		modal = Modal.createModal( title: 'Open city', name: 'open-city' )
	# 		modal.modalBodyJ.find('.modal-footer').hide()
	# 		modal.addProgressBar()
	# 		modal.show()
	# 		Dajaxice.draw.loadCities(R.loadCities)
	# 		return
	# 	return

	# R.modifyCity = (event)->

	# 	event.stopPropagation()
	# 	buttonJ = $(this)
	# 	parentJ = buttonJ.parents('tr:first')
	# 	name = parentJ.attr('data-name')
	# 	isPublic = parseInt(parentJ.attr('data-public'))
	# 	pk = parentJ.attr('data-pk')

	# 	updateCity = (data)->

	# 		callback = (result)->
	# 			modal = Modal.getModalByTitle('Modify city')
	# 			modal.hide()
	# 			if not R.loader.checkError(result) then return
	# 			city = JSON.parse(result.city)
	# 			R.alertManager.alert "City successfully renamed to: " + city.name, "info"
	# 			modalBodyJ = Modal.getModalByTitle('Open city').modalBodyJ
	# 			rowJ = modalBodyJ.find('[data-pk="' + city._id.$oid + '"]')
	# 			rowJ.attr('data-name', city.name)
	# 			rowJ.attr('data-public', Number(city.public or 0))
	# 			rowJ.find('.name').text(city.name)
	# 			rowJ.find('.public').text(if city.public then 'Public' else 'Private')
	# 			return

	# 		Dajaxice.draw.updateCity(callback, pk: data.data.pk, name: data.name, public: data.public )
	# 		return

	# 	modal = Modal.createModal(title: 'Modify city', submit: updateCity, data: { pk: pk }, postSubmit: 'load' )
	# 	modal.addTextInput( name: 'name', label: 'Name', defaultValue: name, required: true, submitShortcut: true )
	# 	modal.addCheckbox( name: 'public', label: 'Public', helpMessage: "Public cities will be accessible by anyone.", defaultValue: isPublic )
	# 	modal.show()

	# 	# event.stopPropagation()
	# 	# buttonJ = $(this)
	# 	# parentJ = buttonJ.parents('tr:first')
	# 	# parentJ.find('input.name').show()
	# 	# parentJ.find('input.public').attr('disabled', false)
	# 	# buttonJ.text('Ok')
	# 	# buttonJ.off('click').click (event)->
	# 	# 	event.stopPropagation()
	# 	# 	buttonJ = $(this)
	# 	# 	parentJ = buttonJ.parents('tr:first')
	# 	# 	inputJ = parentJ.find('input.name')
	# 	# 	publicJ = parentJ.find('input.public')
	# 	# 	pk = parentJ.attr('data-pk')
	# 	# 	newName = inputJ.val()
	# 	# 	isPublic = publicJ.is(':checked')

	# 	# 	callback = (result)->
	# 	# 		if not R.loader.checkError(result) then return
	# 	# 		city = JSON.parse(result.city)
	# 	# 		R.alertManager.alert "City successfully renamed to: " + city.name, "info"
	# 	# 		return

	# 	# 	Dajaxice.draw.updateCity(callback, pk: pk, name: newName, 'public': isPublic )
	# 	# 	inputJ.hide()
	# 	# 	publicJ.attr('disabled', true)
	# 	# 	buttonJ.off('click').click(R.modifyCity)
	# 	# 	return

	# 	return

	# R.loadCities = (result)->
	# 	if not R.loader.checkError(result) then return
	# 	userCities = JSON.parse(result.userCities)
	# 	publicCities = JSON.parse(result.publicCities)

	# 	modal = Modal.getModalByTitle('Open city')
	# 	modal.removeProgressBar()
	# 	modalBodyJ = modal.modalBodyJ

	# 	for citiesList, i in [userCities, publicCities]

	# 		if i==0 and userCities.length>0
	# 			titleJ = $('<h3>').text('Your cities')
	# 			modalBodyJ.append(titleJ)
	# 			# tdJ.append(titleJ)
	# 		else
	# 			titleJ = $('<h3>').text('Public cities')
	# 			modalBodyJ.append(titleJ)
	# 			# tdJ.append(titleJ)

	# 		tableJ = $('<table>').addClass("table table-hover").css( width: "100%" )
	# 		tbodyJ = $('<tbody>')

	# 		for city in citiesList
	# 			rowJ = $("<tr>").attr('data-name', city.name).attr('data-owner', city.owner).attr('data-pk', city._id.$oid).attr('data-public', Number(city.public or 0))
	# 			td1J = $('<td>')
	# 			td2J = $('<td>')
	# 			td3J = $('<td>')
	# 			# rowJ.css( display: 'inline-block' )
	# 			nameJ = $("<span class='name'>").text(city.name)

	# 			# date = new Date(city.date)
	# 			# dateJ = $("<div>").text(date.toLocaleString())
	# 			td1J.append(nameJ)
	# 			# rowJ.append(dateJ)
	# 			if i==0
	# 				publicJ = $("<span class='public'>").text(if city.public then 'Public' else 'Private')
	# 				td2J.append(publicJ)

	# 				modifyButtonJ = $('<button class="btn btn-default">').text('Modify')
	# 				modifyButtonJ.click(R.modifyCity)

	# 				deleteButtonJ = $('<button class="btn  btn-default">').text('Delete')
	# 				deleteButtonJ.click (event)->
	# 					event.stopPropagation()
	# 					name = $(this).parents('tr:first').attr('data-name')
	# 					Dajaxice.draw.deleteCity(R.loader.checkError, name: name)
	# 					return
	# 				td3J.append(modifyButtonJ)
	# 				td3J.append(deleteButtonJ)

	# 			loadButtonJ = $('<button class="btn  btn-primary">').text('Load')
	# 			loadButtonJ.click ()->
	# 				name = $(this).parents('tr:first').attr('data-name')
	# 				owner = $(this).parents('tr:first').attr('data-owner')
	# 				R.loadCity(name, owner)
	# 				return

	# 			td3J.append(loadButtonJ)
	# 			rowJ.append(td1J, td2J, td3J)
	# 			tbodyJ.append(rowJ)

	# 			tableJ.append(tbodyJ)
	# 			modalBodyJ.append(tableJ)

	# 	return

	return CityManager
