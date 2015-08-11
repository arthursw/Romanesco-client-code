// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['Utils/Utils', 'UI/Modal'], function(Utils, Modal) {
    var CityManager;
    CityManager = (function() {
      function CityManager() {
        this.deleteCityCallback = __bind(this.deleteCityCallback, this);
        this.deleteCity = __bind(this.deleteCity, this);
        this.updateCityCallback = __bind(this.updateCityCallback, this);
        this.updateCity = __bind(this.updateCity, this);
        this.openCitySettings = __bind(this.openCitySettings, this);
        this.onCityClicked = __bind(this.onCityClicked, this);
        this.addCities = __bind(this.addCities, this);
        this.createCityModal = __bind(this.createCityModal, this);
        this.createCityCallback = __bind(this.createCityCallback, this);
        this.createCity = __bind(this.createCity, this);
        this.cityPanelJ = $('#City');
        this.citiesListsJ = this.cityPanelJ.find('.city-list');
        this.userCitiesJ = this.cityPanelJ.find('.user-cities');
        this.publicCitiesJ = this.cityPanelJ.find('.public-cities');
        this.createCityBtnJ = this.cityPanelJ.find('.create-city');
        this.citiesListBtnJ = this.cityPanelJ.find('.load-city');
        this.createCityBtnJ.click(this.createCityModal);
        this.citiesListBtnJ.click(this.citiesModal);
        Dajaxice.draw.loadCities(this.addCities);
        return;
      }

      CityManager.prototype.createCity = function(data) {
        Dajaxice.draw.createCity(this.createCityCallback, {
          name: data.name,
          "public": data["public"]
        });
      };

      CityManager.prototype.createCityCallback = function(result) {
        var city, modal;
        modal = Modal.getModalByTitle('Create city');
        modal.hide();
        if (!R.loader.checkError(result)) {
          return;
        }
        city = JSON.parse(result.city);
        this.addCity(city, true);
        this.loadCity(city.name, city.owner);
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

      CityManager.prototype.addCity = function(city, userCity) {
        var btnJ, cityJ;
        cityJ = $("<li>");
        cityJ.append($('<span>').addClass('name').text(city.name));
        cityJ.attr('data-owner', city.owner).attr('data-pk', city._id.$oid).attr('data-public', city["public"] || 0).attr('data-name', city.name);
        cityJ.click(this.onCityClicked);
        cityJ.attr('data-placement', 'right');
        cityJ.attr('data-container', 'body');
        cityJ.attr('data-trigger', 'hover');
        cityJ.attr('data-delay', {
          show: 500,
          hide: 100
        });
        cityJ.attr('data-content', 'by ' + city.owner);
        cityJ.popover();
        if (userCity) {
          btnJ = $('<button type="button"><span class="glyphicon glyphicon-cog" aria-hidden="true"></span></button>');
          btnJ.click(this.openCitySettings);
          cityJ.append(btnJ);
          this.userCitiesJ.append(cityJ);
        } else {
          this.publicCitiesJ.append(cityJ);
        }
      };

      CityManager.prototype.addCities = function(result) {
        var cities, city, i, publicCities, userCities, userCity, _i, _j, _len, _len1, _ref;
        if (!R.loader.checkError(result)) {
          return;
        }
        userCities = JSON.parse(result.userCities);
        publicCities = JSON.parse(result.publicCities);
        _ref = [userCities, publicCities];
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          cities = _ref[i];
          userCity = i === 0;
          for (_j = 0, _len1 = cities.length; _j < _len1; _j++) {
            city = cities[_j];
            this.addCity(city, userCity);
          }
        }
      };

      CityManager.prototype.onCityClicked = function(event) {
        var name, owner, parentJ;
        parentJ = $(event.target).closest('li');
        name = parentJ.attr('data-name');
        owner = parentJ.attr('data-owner');
        this.loadCity(name, owner);
      };

      CityManager.prototype.loadCity = function(name, owner) {
        R.loader.unload();
        R.city = {
          owner: owner,
          name: name,
          site: null
        };
        R.loader.load();
        R.view.updateHash();
      };

      CityManager.prototype.openCitySettings = function(event) {
        var isPublic, liJ, modal, name, pk;
        event.stopPropagation();
        liJ = $(event.target).closest('li');
        name = liJ.attr('data-name');
        isPublic = parseInt(liJ.attr('data-public'));
        pk = liJ.attr('data-pk');
        modal = Modal.createModal({
          title: 'Modify city',
          submit: this.updateCity,
          data: {
            pk: pk,
            name: name
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
        modal.addButton({
          name: 'Delete',
          type: 'danger',
          submit: this.deleteCity
        });
        modal.show();
      };

      CityManager.prototype.updateCity = function(data) {
        if (R.city.name === data.data.name) {
          this.modifyingCurrentCity = true;
        }
        Dajaxice.draw.updateCity(this.updateCityCallback, {
          pk: data.data.pk,
          name: data.name,
          "public": data["public"]
        });
      };

      CityManager.prototype.updateCityCallback = function(result) {
        var city, cityJ, modal;
        modal = Modal.getModalByTitle('Modify city');
        modal.hide();
        if (!R.loader.checkError(result)) {
          this.modifyingCurrentCity = false;
          return;
        }
        city = JSON.parse(result.city);
        if (this.modifyingCurrentCity) {
          R.city.name = city.name;
          R.city.owner = city.owner;
          R.view.updateHash();
          this.modifyingCurrentCity = false;
        }
        cityJ = this.citiesListsJ.find('li[data-pk="' + city._id.$oid + '"]');
        cityJ.attr('data-name', city.name);
        cityJ.attr('data-public', Number(city["public"] || 0));
        cityJ.attr('data-content', 'by ' + city.owner);
        cityJ.find('.name').text(city.name);
      };

      CityManager.prototype.deleteCity = function(data) {
        Dajaxice.draw.deleteCity(this.deleteCityCallback, {
          name: data.data.name
        });
      };

      CityManager.prototype.deleteCityCallback = function(result) {
        if (!R.loader.checkError(result)) {
          return;
        }
        this.citiesListsJ.find('li[data-pk="' + result.cityPk + '"]').remove();
      };

      return CityManager;

    })();
    return CityManager;
  });

}).call(this);
