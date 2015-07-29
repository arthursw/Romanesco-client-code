var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['Items/Item', 'UI/ModuleLoader', 'jqueryUi', 'scrollbar', 'typeahead'], function(Item, ModuleLoader) {
  var Sidebar;
  Sidebar = (function() {
    function Sidebar() {
      this.displayDesiredTool = __bind(this.displayDesiredTool, this);
      this.queryDesiredTool = __bind(this.queryDesiredTool, this);
      this.toggleSidebar = __bind(this.toggleSidebar, this);
      this.toggleToolToFavorite = __bind(this.toggleToolToFavorite, this);
      this.sidebarJ = $("#sidebar");
      this.favoriteToolsJ = $("#FavoriteTools .tool-list");
      this.allToolsContainerJ = $("#AllTools");
      this.allToolsJ = this.allToolsContainerJ.find(".all-tool-list");
      this.searchToolInputJ = this.allToolsContainerJ.find('.search-tool');
      this.initializeFavoriteTools();
      this.handleJ = this.sidebarJ.find(".sidebar-handle");
      this.handleJ.click(this.toggleSidebar);
      this.itemListsJ = $("#RItems .layers");
      this.pathListJ = this.itemListsJ.find(".rPath-list");
      this.pathListJ.sortable({
        stop: Item.zIndexSortStop,
        delay: 250
      });
      this.pathListJ.disableSelection();
      this.divListJ = this.itemListsJ.find(".rDiv-list");
      this.divListJ.sortable({
        stop: Item.zIndexSortStop,
        delay: 250
      });
      this.divListJ.disableSelection();
      this.itemListsJ.find('.title').click(function(event) {
        $(this).parent().toggleClass('closed');
      });
      this.sortedPaths = R.sortedPaths;
      this.sortedDivs = R.sortedDivs;
      $(".mCustomScrollbar").mCustomScrollbar({
        keyboard: false
      });
      return;
    }

    Sidebar.prototype.initialize = function() {
      ModuleLoader.initialize();
      this.initializeTypeahead();
    };

    Sidebar.prototype.initializeFavoriteTools = function() {
      var defaultFavoriteTools, error;
      this.favoriteTools = [];
      if (typeof localStorage !== "undefined" && localStorage !== null) {
        try {
          this.favoriteTools = JSON.parse(localStorage.favorites);
        } catch (_error) {
          error = _error;
          console.log(error);
        }
      }
      defaultFavoriteTools = [];
      while (this.favoriteTools.length < 8 && defaultFavoriteTools.length > 0) {
        Utils.Array.pushIfAbsent(this.favoriteTools, defaultFavoriteTools.pop().label);
      }
    };

    Sidebar.prototype.toggleToolToFavorite = function(event, btnJ) {
      var attr, attrName, cloneJ, li, names, targetJ, toolName, _i, _j, _len, _len1, _ref, _ref1;
      if (btnJ == null) {
        event.stopPropagation();
        targetJ = $(event.target);
        btnJ = targetJ.parents("li.tool-btn:first");
      }
      toolName = btnJ.attr("data-name");
      if (btnJ.hasClass("selected")) {
        btnJ.removeClass("selected");
        this.favoriteToolsJ.find("[data-name='" + toolName + "']").remove();
        Utils.Array.remove(this.favoriteTools, toolName);
      } else {
        btnJ.addClass("selected");
        cloneJ = btnJ.clone();
        this.favoriteToolsJ.append(cloneJ);
        cloneJ.click(function() {
          return btnJ.click();
        });
        _ref = ['placement', 'container', 'trigger', 'delay', 'content', 'title'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          attrName = 'data-' + attr;
          cloneJ.attr(attrName, btnJ.attr(attrName));
          cloneJ.popover();
        }
        cloneJ.css({
          'order': btnJ.attr('data-order')
        });
        this.favoriteTools.push(toolName);
      }
      if (typeof localStorage === "undefined" || localStorage === null) {
        return;
      }
      names = [];
      _ref1 = this.favoriteToolsJ.children();
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        li = _ref1[_j];
        names.push($(li).attr("data-name"));
      }
      localStorage.favorites = JSON.stringify(names);
    };

    Sidebar.prototype.show = function() {
      var _ref;
      this.sidebarJ.removeClass("r-hidden");
      if ((_ref = R.codeEditor) != null) {
        _ref.editorJ.removeClass("r-hidden");
      }
      R.alertManager.alertsContainer.removeClass("r-sidebar-hidden");
      this.handleJ.find("span").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-left");
    };

    Sidebar.prototype.hide = function() {
      var _ref;
      this.sidebarJ.addClass("r-hidden");
      if ((_ref = R.codeEditor) != null) {
        _ref.editorJ.addClass("r-hidden");
      }
      R.alertManager.alertsContainer.addClass("r-sidebar-hidden");
      this.handleJ.find("span").removeClass("glyphicon-chevron-left").addClass("glyphicon-chevron-right");
    };

    Sidebar.prototype.toggleSidebar = function(show) {
      if ((show == null) || jQuery.Event.prototype.isPrototypeOf(show)) {
        show = this.sidebarJ.hasClass("r-hidden");
      }
      if (show) {
        this.show();
      } else {
        this.hide();
      }
    };

    Sidebar.prototype.initializeTypeahead = function() {
      var toolValues;
      toolValues = this.allToolsJ.find('.tool-btn,.category').map(function() {
        return {
          value: this.getAttribute('data-name')
        };
      }).get();
      this.typeaheadModuleEngine = new Bloodhound({
        name: 'Tools',
        local: toolValues,
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace
      });
      this.typeaheadModuleEngine.initialize();
      this.searchToolInputJ = this.allToolsContainerJ.find("input.search-tool");
      this.searchToolInputJ.keyup(this.queryDesiredTool);
    };

    Sidebar.prototype.queryDesiredTool = function(event) {
      var query;
      query = this.searchToolInputJ.val();
      if (query === "") {
        this.allToolsJ.find('.tool-btn').show();
        this.allToolsJ.find('.category').removeClass('closed').show();
        return;
      }
      this.allToolsJ.find('.tool-btn').hide();
      this.allToolsJ.find('.category').addClass('closed').hide();
      this.typeaheadModuleEngine.get(query, this.displayDesiredTool);
    };

    Sidebar.prototype.displayDesiredTool = function(suggestions) {
      var matchJ, suggestion, _i, _len;
      for (_i = 0, _len = suggestions.length; _i < _len; _i++) {
        suggestion = suggestions[_i];
        matchJ = this.allToolsJ.find("[data-name='" + suggestion.value + "']");
        matchJ.show();
        matchJ.parentsUntil(this.allToolsJ).removeClass('closed').show();
      }
    };

    return Sidebar;

  })();
  return Sidebar;
});
