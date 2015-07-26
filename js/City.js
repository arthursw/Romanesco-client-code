var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['Utils/Utils', 'UI/Modal'], function(Utils, Modal) {
  var CityManager;
  CityManager = (function() {
    function CityManager() {
      this.cityRowClicked = __bind(this.cityRowClicked, this);
      this.updateCity = __bind(this.updateCity, this);
      this.cityPanelJ = $('#CityPanel');
      this.citiesListJ = this.cityPanelJ.find('.city-list');
      this.createCityBtnJ = this.cityPanelJ.find('.create-city');
      this.citiesListBtnJ = this.cityPanelJ.find('.load-city');
      this.createCityBtnJ.click(this.createCityModal);
      this.citiesListBtnJ.click(this.citiesModal);
      Dajaxice.draw.loadPrivateCities(this.addPrivateCities);
      return;
    }

    CityManager.prototype.createCity = function(data) {
      Dajaxice.draw.createCity(R.loadCityFromServer, {
        name: data.name,
        "public": data["public"]
      });
    };

    CityManager.prototype.createCityModal = function() {
      var modal;
      modal = Modal.createModal({
        title: 'Create city',
        submit: this.createCity,
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
    };

    CityManager.prototype.addPrivateCities = function(result) {
      var btnJ, city, cityJ, userCities, _i, _len;
      if (!R.loader.checkError(result)) {
        return;
      }
      userCities = JSON.parse(result.userCities);
      for (_i = 0, _len = userCities.length; _i < _len; _i++) {
        city = userCities[_i];
        cityJ = $("<li>");
        cityJ.text(city.name);
        cityJ.attr('data-owner', city.owner).attr('data-pk', city._id.$oid).attr('data-public', 0);
        cityJ.click(this.loadCity);
        btnJ = $('<button type="button"><span class="glyphicon glyphicon-cog" aria-hidden="true"></span></button>');
        btnJ.click(this.openCitySettings);
        cityJ.append(btnJ);
        this.citiesListJ.apppend(cityJ);
      }
    };

    CityManager.prototype.loadCity = function(name, owner) {
      if (name == null) {
        name = $(this).parents('tr:first').attr('data-name');
      }
      if (owner == null) {
        owner = $(this).parents('tr:first').attr('data-owner');
      }
      R.unload();
      R.city = {
        owner: owner,
        name: name,
        site: null
      };
      R.loader.load();
      R.view.updateHash();
    };

    CityManager.prototype.openCitySettings = function(event) {
      var buttonJ, isPublic, modal, name, parentJ, pk;
      event.stopPropagation();
      buttonJ = $(this);
      parentJ = buttonJ.parents('tr:first');
      name = parentJ.attr('data-name');
      isPublic = parseInt(parentJ.attr('data-public'));
      pk = parentJ.attr('data-pk');
      modal = Modal.createModal({
        title: 'Modify city',
        submit: this.updateCity,
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

    CityManager.prototype.updateCity = function(data) {
      Dajaxice.draw.updateCity(this.updateCityCallback, {
        pk: data.data.pk,
        name: data.name,
        "public": data["public"]
      });
    };

    CityManager.prototype.updateCityCallback = function() {
      var city, modal, modalBodyJ, rowJ;
      modal = Modal.getModalByTitle('Modify city');
      modal.hide();
      if (!R.loader.checkError(result)) {
        return;
      }
      city = JSON.parse(result.city);
      R.alertManager.alert("City successfully renamed to: " + city.name, "info");
      modalBodyJ = Modal.getModalByTitle('Open city').modalBodyJ;
      rowJ = modalBodyJ.find('[data-pk="' + city._id.$oid + '"]');
      rowJ.attr('data-name', city.name);
      rowJ.attr('data-public', Number(city["public"] || 0));
      rowJ.find('.name').text(city.name);
      rowJ.find('.public').text(city["public"] ? 'Public' : 'Private');
    };

    CityManager.prototype.displayCities = function() {
      Dajaxice.draw.loadPublicCities(this.loadPublicCitiesCallback);
    };

    CityManager.prototype.cityRowClicked = function(field, value, row, $element) {
      console.log(row.pk);
      this.loadCity(row.name, row.author);
    };

    CityManager.prototype.loadPublicCitiesCallback = function(result) {
      var city, modal, tableData, tableJ, _i, _len;
      if (!R.loader.checkError(result)) {
        return;
      }
      modal = Modal.createModal({
        title: 'Cities',
        submit: null
      });
      tableData = {
        columns: [
          {
            field: 'name',
            title: 'Name'
          }, {
            field: 'author',
            title: 'Author'
          }, {
            field: 'date',
            title: 'Date'
          }, {
            field: 'public',
            title: 'Public'
          }
        ],
        data: []
      };
      for (_i = 0, _len = publicCities.length; _i < _len; _i++) {
        city = publicCities[_i];
        tableData.data.push({
          name: city.name,
          author: city.author,
          date: city.date,
          "public": city["public"],
          pk: city._id.$oid
        });
      }
      tableJ = modal.addTable(tableData);
      tableJ.on('click-cell.bs.table', this.cityRowClicked);
      modal.show();
    };

    return CityManager;

  })();
  return CityManager;
});
