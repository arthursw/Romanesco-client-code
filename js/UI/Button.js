var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['Tools/Tool'], function(Tool) {
  var Button;
  Button = (function() {
    function Button(parameters) {
      this.onClickWhenLoaded = __bind(this.onClickWhenLoaded, this);
      this.onClickWhenNotLoaded = __bind(this.onClickWhenNotLoaded, this);
      this.fileLoaded = __bind(this.fileLoaded, this);
      var categories, category, favorite, favoriteBtnJ, hJ, iconURL, liJ, name, order, parentJ, shortName, shortNameJ, toolNameJ, ulJ, word, words, _i, _j, _len, _len1;
      name = parameters.name;
      iconURL = parameters.iconURL;
      favorite = parameters.favorite;
      category = parameters.category;
      order = parameters.order;
      this.file = parameters.file;
      parentJ = R.sidebar.allToolsJ;
      if ((category != null) && category !== "") {
        categories = category.split("/");
        for (_i = 0, _len = categories.length; _i < _len; _i++) {
          category = categories[_i];
          ulJ = parentJ.find("li[data-name='" + category + "'] > ul");
          if (ulJ.length === 0) {
            liJ = $("<li data-name='" + category + "'>");
            liJ.addClass('category');
            hJ = $('<h6>');
            hJ.text(category).addClass("title");
            liJ.append(hJ);
            ulJ = $("<ul>");
            ulJ.addClass('folder');
            liJ.append(ulJ);
            hJ.click(this.toggleCategory);
            parentJ.append(liJ);
          }
          parentJ = ulJ;
        }
      }
      this.btnJ = $("<li>");
      this.btnJ.attr("data-name", name);
      this.btnJ.attr("alt", name);
      if ((iconURL != null) && iconURL !== '') {
        if (iconURL.indexOf('//') < 0 && iconURL.indexOf('static/images/icons/inverted/') < 0) {
          iconURL = 'static/images/icons/inverted/' + iconURL;
        }
        this.btnJ.append('<img src="' + iconURL + '" alt="' + name + '-icon">');
      } else {
        this.btnJ.addClass("text-btn");
        words = name.split(" ");
        shortName = "";
        if (words.length > 1) {
          for (_j = 0, _len1 = words.length; _j < _len1; _j++) {
            word = words[_j];
            shortName += word.substring(0, 1);
          }
        } else {
          shortName += name.substring(0, 2);
        }
        shortNameJ = $('<span class="short-name">').text(shortName + ".");
        this.btnJ.append(shortNameJ);
      }
      parentJ.append(this.btnJ);
      toolNameJ = $('<span class="tool-name">').text(name);
      this.btnJ.append(toolNameJ);
      this.btnJ.addClass("tool-btn");
      favoriteBtnJ = $("<button type=\"button\" class=\"btn btn-default favorite-btn\">\n	  			<span class=\"glyphicon glyphicon-star\" aria-hidden=\"true\"></span>\n</button>");
      favoriteBtnJ.click(R.sidebar.toggleToolToFavorite);
      this.btnJ.append(favoriteBtnJ);
      this.btnJ.attr({
        'data-order': order != null ? order : 999
      });
      this.btnJ.click(this.file != null ? this.onClickWhenNotLoaded : this.onClickWhenLoaded);
      if (favorite) {
        R.sidebar.toggleToolToFavorite(null, this.btnJ);
      }
      if ((parameters.description != null) || parameters.popover) {
        this.addPopover(parameters);
      }
      return;
    }

    Button.prototype.addPopover = function(parameters) {
      this.btnJ.attr('data-placement', 'right');
      this.btnJ.attr('data-container', 'body');
      this.btnJ.attr('data-trigger', 'hover');
      this.btnJ.attr('data-delay', {
        show: 500,
        hide: 100
      });
      if ((parameters.description == null) || parameters.description === '') {
        this.btnJ.attr('data-content', parameters.name);
      } else {
        this.btnJ.attr('data-title', parameters.name);
        this.btnJ.attr('data-content', parameters.description);
      }
      this.btnJ.popover();
    };

    Button.prototype.toggleCategory = function(event) {
      var categoryJ;
      categoryJ = $(this).parent();
      categoryJ.toggleClass('closed');
      categoryJ.children('.folder').children().show();
    };

    Button.prototype.fileLoaded = function() {
      this.btnJ.off('click');
      this.btnJ.click(this.onClickWhenLoaded);
      this.onClickWhenLoaded();
    };

    Button.prototype.onClickWhenNotLoaded = function(event) {
      require([this.file], this.fileLoaded);
    };

    Button.prototype.onClickWhenLoaded = function(event) {
      var toolName, _ref;
      toolName = this.btnJ.attr("data-name");
      if ((_ref = R.tools[toolName]) != null) {
        _ref.select();
      }
    };

    return Button;

  })();
  return Button;
});
