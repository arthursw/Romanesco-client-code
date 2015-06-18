// Generated by CoffeeScript 1.7.1
(function() {
  define(['utils'], function() {
    R.initializeCities = function() {
      R.toolsJ.find("[data-name='Create']").click(function() {
        var modal, submit;
        submit = function(data) {
          Dajaxice.draw.createCity(R.loadCityFromServer, {
            name: data.name,
            "public": data["public"]
          });
        };
        modal = R.RModal.createModal({
          title: 'Create city',
          submit: submit,
          postSubmit: 'load'
        });
        modal.addTextInput({
          label: "City name",
          name: 'name',
          required: true,
          submitShortcut: true,
          placeholder: 'Paris'
        });
        modal.addCheckbox({
          label: "Public",
          name: 'public',
          helpMessage: "Public cities will be accessible by anyone.",
          defaultValue: true
        });
        modal.show();
      });
      R.toolsJ.find("[data-name='Open']").click(function() {
        var modal;
        modal = R.RModal.createModal({
          title: 'Open city',
          name: 'open-city'
        });
        modal.modalBodyJ.find('.modal-footer').hide();
        modal.addProgressBar();
        modal.show();
        Dajaxice.draw.loadCities(R.loadCities);
      });
    };
    R.modifyCity = function(event) {
      var buttonJ, isPublic, modal, name, parentJ, pk, updateCity;
      event.stopPropagation();
      buttonJ = $(this);
      parentJ = buttonJ.parents('tr:first');
      name = parentJ.attr('data-name');
      isPublic = parseInt(parentJ.attr('data-public'));
      pk = parentJ.attr('data-pk');
      updateCity = function(data) {
        var callback;
        callback = function(result) {
          var city, modal, modalBodyJ, rowJ;
          modal = R.RModal.getModalByTitle('Modify city');
          modal.hide();
          if (!R.loader.checkError(result)) {
            return;
          }
          city = JSON.parse(result.city);
          R.alertManager.alert("City successfully renamed to: " + city.name, "info");
          modalBodyJ = R.RModal.getModalByTitle('Open city').modalBodyJ;
          rowJ = modalBodyJ.find('[data-pk="' + city._id.$oid + '"]');
          rowJ.attr('data-name', city.name);
          rowJ.attr('data-public', Number(city["public"] || 0));
          rowJ.find('.name').text(city.name);
          rowJ.find('.public').text(city["public"] ? 'Public' : 'Private');
        };
        Dajaxice.draw.updateCity(callback, {
          pk: data.data.pk,
          name: data.name,
          "public": data["public"]
        });
      };
      modal = R.RModal.createModal({
        title: 'Modify city',
        submit: updateCity,
        data: {
          pk: pk
        },
        postSubmit: 'load'
      });
      modal.addTextInput({
        name: 'name',
        label: 'Name',
        defaultValue: name,
        required: true,
        submitShortcut: true
      });
      modal.addCheckbox({
        name: 'public',
        label: 'Public',
        helpMessage: "Public cities will be accessible by anyone.",
        defaultValue: isPublic
      });
      modal.show();
    };
    R.loadCities = function(result) {
      var citiesList, city, deleteButtonJ, i, loadButtonJ, modal, modalBodyJ, modifyButtonJ, nameJ, publicCities, publicJ, rowJ, tableJ, tbodyJ, td1J, td2J, td3J, titleJ, userCities, _i, _j, _len, _len1, _ref;
      if (!R.loader.checkError(result)) {
        return;
      }
      userCities = JSON.parse(result.userCities);
      publicCities = JSON.parse(result.publicCities);
      modal = R.RModal.getModalByTitle('Open city');
      modal.removeProgressBar();
      modalBodyJ = modal.modalBodyJ;
      _ref = [userCities, publicCities];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        citiesList = _ref[i];
        if (i === 0 && userCities.length > 0) {
          titleJ = $('<h3>').text('Your cities');
          modalBodyJ.append(titleJ);
        } else {
          titleJ = $('<h3>').text('Public cities');
          modalBodyJ.append(titleJ);
        }
        tableJ = $('<table>').addClass("table table-hover").css({
          width: "100%"
        });
        tbodyJ = $('<tbody>');
        for (_j = 0, _len1 = citiesList.length; _j < _len1; _j++) {
          city = citiesList[_j];
          rowJ = $("<tr>").attr('data-name', city.name).attr('data-owner', city.owner).attr('data-pk', city._id.$oid).attr('data-public', Number(city["public"] || 0));
          td1J = $('<td>');
          td2J = $('<td>');
          td3J = $('<td>');
          nameJ = $("<span class='name'>").text(city.name);
          td1J.append(nameJ);
          if (i === 0) {
            publicJ = $("<span class='public'>").text(city["public"] ? 'Public' : 'Private');
            td2J.append(publicJ);
            modifyButtonJ = $('<button class="btn btn-default">').text('Modify');
            modifyButtonJ.click(R.modifyCity);
            deleteButtonJ = $('<button class="btn  btn-default">').text('Delete');
            deleteButtonJ.click(function(event) {
              var name;
              event.stopPropagation();
              name = $(this).parents('tr:first').attr('data-name');
              Dajaxice.draw.deleteCity(R.loader.checkError, {
                name: name
              });
            });
            td3J.append(modifyButtonJ);
            td3J.append(deleteButtonJ);
          }
          loadButtonJ = $('<button class="btn  btn-primary">').text('Load');
          loadButtonJ.click(function() {
            var name, owner;
            name = $(this).parents('tr:first').attr('data-name');
            owner = $(this).parents('tr:first').attr('data-owner');
            R.loadCity(name, owner);
          });
          td3J.append(loadButtonJ);
          rowJ.append(td1J, td2J, td3J);
          tbodyJ.append(rowJ);
          tableJ.append(tbodyJ);
          modalBodyJ.append(tableJ);
        }
      }
    };
    R.loadCityFromServer = function(result) {
      var city, _ref;
      if ((_ref = R.RModal.getModalByTitle('Create city')) != null) {
        _ref.hide();
      }
      if (!R.loader.checkError(result)) {
        return;
      }
      city = JSON.parse(result.city);
      R.loadCity(city.name, city.owner);
    };
    R.loadCity = function(name, owner) {
      var _ref;
      if ((_ref = R.RModal.getModalByTitle('Open city')) != null) {
        _ref.hide();
      }
      R.unload();
      R.city = {
        owner: owner,
        name: name,
        site: null
      };
      R.load();
      View.updateHash();
    };
  });

}).call(this);

//# sourceMappingURL=City.map
