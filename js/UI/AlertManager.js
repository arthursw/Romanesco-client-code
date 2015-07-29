var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define([], function() {
  var AlertManager;
  AlertManager = (function() {
    function AlertManager() {
      this.hide = __bind(this.hide, this);
      this.alertsContainer = $("#Romanesco_alerts");
      this.alerts = [];
      this.currentAlert = -1;
      this.alertTimeOut = -1;
      this.alertsContainer.find(".btn-up").click((function(_this) {
        return function() {
          return _this.showAlert(_this.currentAlert - 1);
        };
      })(this));
      this.alertsContainer.find(".btn-down").click((function(_this) {
        return function() {
          return _this.showAlert(_this.currentAlert + 1);
        };
      })(this));
      return;
    }

    AlertManager.prototype.showAlert = function(index) {
      var alertJ, previousType, _ref;
      if (this.alerts.length <= 0 || index < 0 || index >= this.alerts.length) {
        return;
      }
      previousType = (_ref = this.alerts[this.currentAlert]) != null ? _ref.type : void 0;
      this.currentAlert = index;
      alertJ = this.alertsContainer.find(".alert");
      alertJ.removeClass(previousType).addClass(this.alerts[this.currentAlert].type).text(this.alerts[this.currentAlert].message);
      this.alertsContainer.find(".alert-number").text(this.currentAlert + 1);
    };

    AlertManager.prototype.alert = function(message, type, delay) {
      var alertJ;
      if (type == null) {
        type = "";
      }
      if (delay == null) {
        delay = 2000;
      }
      if (type.length === 0) {
        type = "info";
      } else if (type === "error") {
        type = "danger";
      }
      type = " alert-" + type;
      alertJ = this.alertsContainer.find(".alert");
      this.alertsContainer.removeClass("r-hidden");
      this.alerts.push({
        type: type,
        message: message
      });
      if (this.alerts.length > 0) {
        this.alertsContainer.addClass("activated");
      }
      this.showAlert(this.alerts.length - 1);
      this.alertsContainer.addClass("show");
      if (delay !== 0) {
        clearTimeout(R.alertTimeOut);
        this.alertTimeOut = setTimeout(this.hide, delay);
      }
    };

    AlertManager.prototype.hide = function() {
      this.alertsContainer.removeClass("show");
    };

    return AlertManager;

  })();
  return AlertManager;
});
