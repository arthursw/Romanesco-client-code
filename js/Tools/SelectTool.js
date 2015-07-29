var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['Tools/Tool', 'Items/Lock', 'Commands/Command', 'View/SelectionRectangle'], function(Tool, Lock, Command, SelectionRectangle) {
  var SelectTool;
  SelectTool = (function(_super) {
    __extends(SelectTool, _super);

    SelectTool.SelectionRectangle = SelectionRectangle;

    SelectTool.label = 'Select';

    SelectTool.description = '';

    SelectTool.iconURL = 'cursor.png';

    SelectTool.cursor = {
      position: {
        x: 0,
        y: 0
      },
      name: 'default'
    };

    SelectTool.drawItems = false;

    SelectTool.order = 1;

    SelectTool.hitOptions = {
      stroke: true,
      fill: true,
      handles: true,
      selected: true
    };

    function SelectTool() {
      this.updateSelectionRectangleCallback = __bind(this.updateSelectionRectangleCallback, this);
      this.setSelectionRectangleVisibility = __bind(this.setSelectionRectangleVisibility, this);
      SelectTool.__super__.constructor.call(this, true);
      this.selectedItem = null;
      this.selectionRectangle = null;
      return;
    }

    SelectTool.prototype.deselectAll = function() {
      var _ref;
      if (R.selectedItems.length > 0) {
        R.commandManager.add(new Command.Deselect(), true);
        if ((_ref = this.selectionRectangle) != null) {
          _ref.remove();
        }
        this.selectionRectangle = null;
      }
      P.project.activeLayer.selected = false;
    };

    SelectTool.prototype.setSelectionRectangleVisibility = function(value) {
      var _ref;
      if ((_ref = this.selectionRectangle) != null) {
        _ref.setVisibility(value);
      }
    };

    SelectTool.prototype.updateSelectionRectangle = function(rotation) {
      Utils.callNextFrame(this.updateSelectionRectangleCallback, 'updateSelectionRectangleCallback', [rotation]);
    };

    SelectTool.prototype.updateSelectionRectangleCallback = function() {
      var _ref;
      if (R.selectedItems.length > 0) {
        if (this.selectionRectangle == null) {
          this.selectionRectangle = SelectionRectangle.create();
        }
        this.selectionRectangle.update();
        $(this).trigger('selectionRectangleUpdated');
      } else {
        if ((_ref = this.selectionRectangle) != null) {
          _ref.remove();
        }
        this.selectionRectangle = null;
      }
    };

    SelectTool.prototype.select = function(deselectItems, updateParameters) {
      if (deselectItems == null) {
        deselectItems = false;
      }
      if (updateParameters == null) {
        updateParameters = true;
      }
      SelectTool.__super__.select.call(this, false, updateParameters);
    };

    SelectTool.prototype.updateParameters = function() {
      R.controllerManager.updateParametersForSelectedItems();
    };

    SelectTool.prototype.highlightItemsUnderRectangle = function(rectangle) {
      var bounds, item, itemsToHighlight, name, _ref;
      itemsToHighlight = [];
      _ref = R.items;
      for (name in _ref) {
        item = _ref[name];
        item.unhighlight();
        bounds = item.getBounds();
        if (bounds.intersects(rectangle)) {
          item.highlight();
        }
        if (rectangle.area === 0) {
          break;
        }
      }
    };

    SelectTool.prototype.unhighlightItems = function() {
      var item, name, _ref;
      _ref = R.items;
      for (name in _ref) {
        item = _ref[name];
        item.unhighlight();
      }
    };

    SelectTool.prototype.createSelectionHighlight = function(event) {
      var highlightPath, rectangle;
      rectangle = new P.Rectangle(event.downPoint, event.point);
      highlightPath = new P.Path.Rectangle(rectangle);
      highlightPath.name = 'select tool selection rectangle';
      highlightPath.strokeColor = R.selectionBlue;
      highlightPath.strokeScaling = false;
      highlightPath.dashArray = [10, 4];
      R.view.selectionLayer.addChild(highlightPath);
      R.currentPaths[R.me] = highlightPath;
      this.highlightItemsUnderRectangle(rectangle);
    };

    SelectTool.prototype.updateSelectionHighlight = function(event) {
      var rectangle;
      rectangle = new P.Rectangle(event.downPoint, event.point);
      Utils.Rectangle.updatePathRectangle(R.currentPaths[R.me], rectangle);
      this.highlightItemsUnderRectangle(rectangle);
    };

    SelectTool.prototype.populateItemsToSelect = function(itemsToSelect, locksToSelect, rectangle) {
      var item, name, _ref;
      _ref = R.items;
      for (name in _ref) {
        item = _ref[name];
        if (item.getBounds().intersects(rectangle)) {
          if (Lock.prototype.isPrototypeOf(item)) {
            locksToSelect.push(item);
          } else {
            itemsToSelect.push(item);
          }
        }
      }
    };

    SelectTool.prototype.itemsAreSiblings = function(itemsToSelect) {
      var item, itemsAreSiblings, parent, _i, _len;
      itemsAreSiblings = true;
      parent = itemsToSelect[0].group.parent;
      for (_i = 0, _len = itemsToSelect.length; _i < _len; _i++) {
        item = itemsToSelect[_i];
        if (item.group.parent !== parent) {
          itemsAreSiblings = false;
          break;
        }
      }
      return itemsAreSiblings;
    };

    SelectTool.prototype.removeLocksChildren = function(itemsToSelect, locksToSelect) {
      var child, lock, _i, _j, _len, _len1, _ref;
      for (_i = 0, _len = locksToSelect.length; _i < _len; _i++) {
        lock = locksToSelect[_i];
        _ref = lock.children();
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          child = _ref[_j];
          Utils.Array.remove(itemsToSelect, child);
        }
      }
    };

    SelectTool.prototype.selectItems = function(event) {
      var itemsToSelect, locksToSelect, rectangle;
      rectangle = new P.Rectangle(event.downPoint, event.point);
      itemsToSelect = [];
      locksToSelect = [];
      this.populateItemsToSelect(itemsToSelect, locksToSelect, rectangle);
      if (itemsToSelect.length === 0) {
        itemsToSelect = locksToSelect;
      }
      if (itemsToSelect.length > 0) {
        if (!this.itemsAreSiblings(itemsToSelect)) {
          this.removeLocksChildren(itemsToSelect, locksToSelect);
          itemsToSelect = itemsToSelect.concat(locksToSelect);
        }
        if (rectangle.area === 0) {
          itemsToSelect = [itemsToSelect[0]];
        }
        R.commandManager.add(new Command.Select(itemsToSelect), true);
      }
    };

    SelectTool.prototype.begin = function(event) {
      var controller, hitResult, itemWasHit, name, path, _ref, _ref1;
      if (event.event.which === 2) {
        return;
      }
      itemWasHit = false;
      if (this.selectionRectangle != null) {
        itemWasHit = this.selectionRectangle.hitTest(event);
      }
      if (!itemWasHit) {
        _ref = R.paths;
        for (name in _ref) {
          path = _ref[name];
          path.prepareHitTest();
        }
        hitResult = P.project.hitTest(event.point, this.constructor.hitOptions);
        _ref1 = R.paths;
        for (name in _ref1) {
          path = _ref1[name];
          path.finishHitTest();
        }
        controller = hitResult != null ? hitResult.item.controller : void 0;
        if (controller != null) {
          controller.hitTest(event);
        }
        itemWasHit = controller != null;
      }
      if (!itemWasHit) {
        this.deselectAll();
        this.createSelectionHighlight(event);
      }
    };

    SelectTool.prototype.update = function(event) {
      if (this.selectionRectangle != null) {
        R.commandManager.updateAction(event);
      } else if (R.currentPaths[R.me] != null) {
        this.updateSelectionHighlight(event);
      }
    };

    SelectTool.prototype.end = function(event) {
      if (this.selectionRectangle != null) {
        R.commandManager.endAction(event);
      } else if (R.currentPaths[R.me] != null) {
        this.selectItems(event);
        R.currentPaths[R.me].remove();
        delete R.currentPaths[R.me];
        this.unhighlightItems();
      }
    };

    SelectTool.prototype.doubleClick = function(event) {
      var item, _i, _len, _ref;
      _ref = R.selectedItems;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (typeof item.doubleClick === "function") {
          item.doubleClick(event);
        }
      }
    };

    SelectTool.prototype.disableSnap = function() {
      return R.currentPaths[R.me] != null;
    };

    SelectTool.prototype.keyUp = function(event) {
      var delta, item, selectedItems, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
      if ((_ref = event.key) === 'left' || _ref === 'right' || _ref === 'up' || _ref === 'down') {
        delta = event.modifiers.shift ? 50 : event.modifiers.option ? 5 : 1;
      }
      switch (event.key) {
        case 'right':
          _ref1 = R.selectedItems;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            item = _ref1[_i];
            item.moveBy(new P.Point(delta, 0), true);
          }
          break;
        case 'left':
          _ref2 = R.selectedItems;
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            item = _ref2[_j];
            item.moveBy(new P.Point(-delta, 0), true);
          }
          break;
        case 'up':
          _ref3 = R.selectedItems;
          for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
            item = _ref3[_k];
            item.moveBy(new P.Point(0, -delta), true);
          }
          break;
        case 'down':
          _ref4 = R.selectedItems;
          for (_l = 0, _len3 = _ref4.length; _l < _len3; _l++) {
            item = _ref4[_l];
            item.moveBy(new P.Point(0, delta), true);
          }
          break;
        case 'escape':
          this.deselectAll();
          break;
        case 'delete':
        case 'backspace':
          selectedItems = R.selectedItems.slice();
          for (_m = 0, _len4 = selectedItems.length; _m < _len4; _m++) {
            item = selectedItems[_m];
            if (((_ref5 = item.selectionState) != null ? _ref5.segment : void 0) != null) {
              item.deletePointCommand();
            } else {
              item.deleteCommand();
            }
          }
      }
    };

    return SelectTool;

  })(Tool);
  R.Tools.Select = SelectTool;
  return SelectTool;
});
