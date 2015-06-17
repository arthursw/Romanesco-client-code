define [
	'utils', 'jquery'
], (utils) ->

	g = utils.g()

	g.initializeCities = ()->
		g.toolsJ.find("[data-name='Create']").click ()->
			submit = (data)->
				Dajaxice.draw.createCity(g.loadCityFromServer, name: data.name, public: data.public)
				return
			modal = g.RModal.createModal( title: 'Create city', submit: submit, postSubmit: 'load' )
			modal.addTextInput( label: "City name", name: 'name', required: true, submitShortcut: true, placeholder: 'Paris' )
			modal.addCheckbox( label: "Public", name: 'public', helpMessage: "Public cities will be accessible by anyone.", defaultValue: true )
			modal.show()
			return

		g.toolsJ.find("[data-name='Open']").click ()->
			modal = g.RModal.createModal( title: 'Open city', name: 'open-city' )
			modal.modalBodyJ.find('.modal-footer').hide()
			modal.addProgressBar()
			modal.show()
			Dajaxice.draw.loadCities(g.loadCities)
			return
		return

	g.modifyCity = (event)->

		event.stopPropagation()
		buttonJ = $(this)
		parentJ = buttonJ.parents('tr:first')
		name = parentJ.attr('data-name')
		isPublic = parseInt(parentJ.attr('data-public'))
		pk = parentJ.attr('data-pk')

		updateCity = (data)->

			callback = (result)->
				modal = g.RModal.getModalByTitle('Modify city')
				modal.hide()
				if not g.checkError(result) then return
				city = JSON.parse(result.city)
				g.romanesco_alert "City successfully renamed to: " + city.name, "info"
				modalBodyJ = g.RModal.getModalByTitle('Open city').modalBodyJ
				rowJ = modalBodyJ.find('[data-pk="' + city._id.$oid + '"]')
				rowJ.attr('data-name', city.name)
				rowJ.attr('data-public', Number(city.public or 0))
				rowJ.find('.name').text(city.name)
				rowJ.find('.public').text(if city.public then 'Public' else 'Private')
				return

			Dajaxice.draw.updateCity(callback, pk: data.data.pk, name: data.name, public: data.public )
			return

		modal = g.RModal.createModal(title: 'Modify city', submit: updateCity, data: { pk: pk }, postSubmit: 'load' )
		modal.addTextInput( name: 'name', label: 'Name', defaultValue: name, required: true, submitShortcut: true )
		modal.addCheckbox( name: 'public', label: 'Public', helpMessage: "Public cities will be accessible by anyone.", defaultValue: isPublic )
		modal.show()

		# event.stopPropagation()
		# buttonJ = $(this)
		# parentJ = buttonJ.parents('tr:first')
		# parentJ.find('input.name').show()
		# parentJ.find('input.public').attr('disabled', false)
		# buttonJ.text('Ok')
		# buttonJ.off('click').click (event)->
		# 	event.stopPropagation()
		# 	buttonJ = $(this)
		# 	parentJ = buttonJ.parents('tr:first')
		# 	inputJ = parentJ.find('input.name')
		# 	publicJ = parentJ.find('input.public')
		# 	pk = parentJ.attr('data-pk')
		# 	newName = inputJ.val()
		# 	isPublic = publicJ.is(':checked')

		# 	callback = (result)->
		# 		if not g.checkError(result) then return
		# 		city = JSON.parse(result.city)
		# 		g.romanesco_alert "City successfully renamed to: " + city.name, "info"
		# 		return

		# 	Dajaxice.draw.updateCity(callback, pk: pk, name: newName, 'public': isPublic )
		# 	inputJ.hide()
		# 	publicJ.attr('disabled', true)
		# 	buttonJ.off('click').click(g.modifyCity)
		# 	return

		return

	g.loadCities = (result)->
		if not g.checkError(result) then return
		userCities = JSON.parse(result.userCities)
		publicCities = JSON.parse(result.publicCities)

		modal = g.RModal.getModalByTitle('Open city')
		modal.removeProgressBar()
		modalBodyJ = modal.modalBodyJ

		for citiesList, i in [userCities, publicCities]

			if i==0 and userCities.length>0
				titleJ = $('<h3>').text('Your cities')
				modalBodyJ.append(titleJ)
				# tdJ.append(titleJ)
			else
				titleJ = $('<h3>').text('Public cities')
				modalBodyJ.append(titleJ)
				# tdJ.append(titleJ)

			tableJ = $('<table>').addClass("table table-hover").css( width: "100%" )
			tbodyJ = $('<tbody>')

			for city in citiesList
				rowJ = $("<tr>").attr('data-name', city.name).attr('data-owner', city.owner).attr('data-pk', city._id.$oid).attr('data-public', Number(city.public or 0))
				td1J = $('<td>')
				td2J = $('<td>')
				td3J = $('<td>')
				# rowJ.css( display: 'inline-block' )
				nameJ = $("<span class='name'>").text(city.name)

				# date = new Date(city.date)
				# dateJ = $("<div>").text(date.toLocaleString())
				td1J.append(nameJ)
				# rowJ.append(dateJ)
				if i==0
					publicJ = $("<span class='public'>").text(if city.public then 'Public' else 'Private')
					td2J.append(publicJ)

					modifyButtonJ = $('<button class="btn btn-default">').text('Modify')
					modifyButtonJ.click(g.modifyCity)

					deleteButtonJ = $('<button class="btn  btn-default">').text('Delete')
					deleteButtonJ.click (event)->
						event.stopPropagation()
						name = $(this).parents('tr:first').attr('data-name')
						Dajaxice.draw.deleteCity(g.checkError, name: name)
						return
					td3J.append(modifyButtonJ)
					td3J.append(deleteButtonJ)

				loadButtonJ = $('<button class="btn  btn-primary">').text('Load')
				loadButtonJ.click ()->
					name = $(this).parents('tr:first').attr('data-name')
					owner = $(this).parents('tr:first').attr('data-owner')
					g.loadCity(name, owner)
					return

				td3J.append(loadButtonJ)
				rowJ.append(td1J, td2J, td3J)
				tbodyJ.append(rowJ)

				tableJ.append(tbodyJ)
				modalBodyJ.append(tableJ)

		return

	g.loadCityFromServer = (result)->
		g.RModal.getModalByTitle('Create city')?.hide()
		if not g.checkError(result) then return
		city = JSON.parse(result.city)
		g.loadCity(city.name, city.owner)
		return

	g.loadCity = (name, owner)->
		g.RModal.getModalByTitle('Open city')?.hide()
		g.unload()
		g.city =
			owner: owner
			name: name
			site: null
		g.load()
		g.updateHash()
		return

	return