// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['Utils/Utils'], function() {
    var Controller;
    Controller = (function() {
      function Controller(name, parameter, folder) {
        this.name = name;
        this.parameter = parameter;
        this.folder = folder;
        this.onChange = __bind(this.onChange, this);
        this.folder.controllers[this.name] = this;
        this.initialize();
        return;
      }

      Controller.prototype.initialize = function() {
        var controllerBox, firstOptionalParameter, _base, _base1, _base2;
        if ((_base = this.parameter).value == null) {
          _base.value = this.parameter.defaultFunction != null ? this.parameter.defaultFunction() : this.parameter["default"];
        }
        firstOptionalParameter = this.parameter.min != null ? this.parameter.min : this.parameter.values;
        if (this.parameter.type === 'button' || this.parameter.type === 'action' || typeof this.parameter["default"] === 'function') {
          if ((this.parameter.onChange == null) && (this.parameter["default"] == null)) {
            throw "Action parameter has no function.";
          }
          if ((_base1 = this.parameter).onChange == null) {
            _base1.onChange = this.parameter["default"];
          }
          if ((_base2 = this.parameter)["default"] == null) {
            _base2["default"] = this.parameter.onChange;
          }
        }
        controllerBox = this.folder.datFolder.add(this.parameter, 'value', firstOptionalParameter, this.parameter.max).name(this.parameter.label).onChange(this.parameter.onChange || this.onChange).onFinishChange(this.parameter.onFinishChange);
        this.datController = _.last(this.folder.datFolder.__controllers);
        if (this.parameter.step != null) {
          this.datController.step(this.parameter.step);
        }
      };

      Controller.prototype.onChange = function(value) {
        R.c = this;
        if (R.selectedItems.length > 0) {
          R.commandManager.deferredAction(R.Command.SetParameter, R.selectedItems, null, this.name, value);
        }
      };

      Controller.prototype.getValue = function() {
        return this.datController.getValue();
      };

      Controller.prototype.setValue = function(value) {
        var _base;
        this.datController.object[this.datController.property] = value;
        this.datController.updateDisplay();
        if (typeof (_base = this.parameter).setValue === "function") {
          _base.setValue(value);
        }
      };

      Controller.prototype.remove = function() {
        this.parameter.controller = null;
        if (this.defaultOnChange) {
          this.parameter.onChange = null;
        }
        this.folder.datFolder.remove(this.datController);
        Utils.Array.remove(this.folder.datFolder.__controllers, this.datController);
        delete this.folder.controllers[this.name];
        if (Object.keys(this.folder.controllers).length === 0) {
          this.folder.remove();
        }
        this.folder = null;
        this.name = null;
      };

      return Controller;

    })();
    return Controller;
  });

}).call(this);
