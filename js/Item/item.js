// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['utils', 'global', 'coordinateSystems', 'options', 'jquery', 'paper'], function(utils) {
    var RContent, RItem, RSelectionRectangle, g;
    g = utils.g();
    RItem = (function() {
      RItem.indexToName = {
        0: 'bottomLeft',
        1: 'left',
        2: 'topLeft',
        3: 'top',
        4: 'topRight',
        5: 'right',
        6: 'bottomRight',
        7: 'bottom'
      };

      RItem.oppositeName = {
        'top': 'bottom',
        'bottom': 'top',
        'left': 'right',
        'right': 'left',
        'topLeft': 'bottomRight',
        'topRight': 'bottomLeft',
        'bottomRight': 'topLeft',
        'bottomLeft': 'topRight'
      };

      RItem.cornersNames = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'];

      RItem.sidesNames = ['left', 'right', 'top', 'bottom'];

      RItem.valueFromName = function(point, name) {
        switch (name) {
          case 'left':
          case 'right':
            return point.x;
          case 'top':
          case 'bottom':
            return point.y;
          default:
            return point;
        }
      };

      RItem.hitOptions = {
        segments: true,
        stroke: true,
        fill: true,
        selected: true,
        tolerance: 5
      };

      RItem.initializeParameters = function() {
        var parameters;
        parameters = {
          'Items': {
            align: g.parameters.align,
            distribute: g.parameters.distribute,
            "delete": g.parameters["delete"]
          },
          'Style': {
            strokeWidth: g.parameters.strokeWidth,
            strokeColor: g.parameters.strokeColor,
            fillColor: g.parameters.fillColor
          },
          'Pos. & size': {
            position: {
              "default": '',
              label: 'Position',
              onChange: function() {},
              onFinishChange: this.onPositionFinishChange
            },
            size: {
              "default": '',
              label: 'Size',
              onChange: function() {},
              onFinishChange: this.onSizeFinishChange
            }
          }
        };
        return parameters;
      };

      RItem.parameters = RItem.initializeParameters();

      RItem.create = function(duplicateData) {
        var copy;
        copy = new this(duplicateData.rectangle, duplicateData.data);
        if (!this.socketAction) {
          copy.save(false);
          g.chatSocket.emit("bounce", {
            itemClass: this.name,
            "function": "create",
            "arguments": [duplicateData]
          });
        }
        return copy;
      };

      function RItem(data, pk) {
        var _ref;
        this.data = data;
        this.pk = pk;
        this.endAction = __bind(this.endAction, this);
        if (this.pk != null) {
          this.setPK(this.pk, true);
        } else {
          this.id = ((_ref = this.data) != null ? _ref.id : void 0) != null ? this.data.id : Math.random();
          g.items[this.id] = this;
        }
        if (this.data != null) {
          this.secureData();
        } else {
          this.data = new Object();
          g.controllerManager.updateItemData(this);
        }
        if (this.rectangle == null) {
          this.rectangle = null;
        }
        this.selectionState = null;
        this.selectionRectangle = null;
        this.group = new Group();
        this.group.name = "group";
        this.group.controller = this;
        return;
      }

      RItem.prototype.secureData = function() {
        var name, parameter, value, _ref;
        _ref = this.constructor.parameters;
        for (name in _ref) {
          parameter = _ref[name];
          if (parameter.secure != null) {
            this.data[name] = parameter.secure(this.data, parameter);
          } else {
            value = this.data[name];
            if ((value != null) && (parameter.min != null) && (parameter.max != null)) {
              if (value < parameter.min || value > parameter.max) {
                this.data[name] = g.clamp(parameter.min, value, parameter.max);
              }
            }
          }
        }
      };

      RItem.prototype.setParameterCommand = function(controller, value) {
        this.deferredAction(g.SetParameterCommand, controller, value);
      };

      RItem.prototype.setParameter = function(controller, value, update) {
        var name;
        name = controller.name;
        this.data[name] = value;
        this.changed = name;
        if (!this.socketAction) {
          if (update) {
            this.update(name);
            controller.setValue(value);
          }
          g.chatSocket.emit("bounce", {
            itemPk: this.pk,
            "function": "setParameter",
            "arguments": [name, value, false, false]
          });
        }
      };

      RItem.prototype.prepareHitTest = function() {
        var _ref;
        if ((_ref = this.selectionRectangle) != null) {
          _ref.strokeColor = g.selectionBlue;
        }
      };

      RItem.prototype.finishHitTest = function() {
        var _ref;
        if ((_ref = this.selectionRectangle) != null) {
          _ref.strokeColor = null;
        }
      };

      RItem.prototype.hitTest = function(point, hitOptions) {
        return this.selectionRectangle.hitTest(point);
      };

      RItem.prototype.performHitTest = function(point, hitOptions, fullySelected) {
        var hitResult;
        if (fullySelected == null) {
          fullySelected = true;
        }
        this.prepareHitTest(fullySelected, 1);
        hitResult = this.hitTest(point, hitOptions);
        this.finishHitTest(fullySelected);
        return hitResult;
      };

      RItem.prototype.initializeSelection = function(event, hitResult) {
        var cornerName, distance, minDistance, selectionBounds, _i, _len, _ref;
        if (hitResult.item === this.selectionRectangle) {
          this.selectionState = {
            move: true
          };
          if ((hitResult != null ? hitResult.type : void 0) === 'stroke') {
            selectionBounds = this.rectangle.clone().expand(10);
            minDistance = Infinity;
            _ref = this.constructor.cornersNames;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              cornerName = _ref[_i];
              distance = selectionBounds[cornerName].getDistance(hitResult.point, true);
              if (distance < minDistance) {
                this.selectionState.move = cornerName;
                minDistance = distance;
              }
            }
          } else if ((hitResult != null ? hitResult.type : void 0) === 'segment') {
            this.selectionState = {
              resize: {
                index: hitResult.segment.index
              }
            };
          }
        }
      };

      RItem.prototype.beginSelect = function(event) {
        var hitResult;
        this.selectionState = {
          move: true
        };
        if (!this.isSelected()) {
          g.commandManager.add(new g.SelectCommand([this]), true);
        } else {
          hitResult = this.performHitTest(event.point, this.constructor.hitOptions);
          if (hitResult != null) {
            this.initializeSelection(event, hitResult);
          }
        }
        if (this.selectionState.move != null) {
          this.beginAction(new g.MoveCommand(this));
        } else if (this.selectionState.resize != null) {
          this.beginAction(new g.ResizeCommand(this));
        }
      };

      RItem.prototype.updateSelect = function(event) {
        this.updateAction(event);
      };

      RItem.prototype.endSelect = function(event) {
        this.endAction();
      };

      RItem.prototype.beginAction = function(command) {
        if (this.currentCommand) {
          this.endAction();
          clearTimeout(g.updateTimeout['addCurrentCommand-' + (this.id || this.pk)]);
        }
        this.currentCommand = command;
      };

      RItem.prototype.updateAction = function() {
        this.currentCommand.update.apply(this.currentCommand, arguments);
      };

      RItem.prototype.endAction = function() {
        var commandChanged, positionIsValid;
        positionIsValid = this.currentCommand.constructor.needValidPosition ? g.validatePosition(this) : true;
        commandChanged = this.currentCommand.end(positionIsValid);
        if (positionIsValid) {
          if (commandChanged) {
            g.commandManager.add(this.currentCommand);
          }
        } else {
          this.currentCommand.undo();
        }
        this.currentCommand = null;
      };

      RItem.prototype.deferredAction = function() {
        var ActionCommand, args;
        ActionCommand = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (!ActionCommand.prototype.isPrototypeOf(this.currentCommand)) {
          this.beginAction(new ActionCommand(this, args));
        }
        this.updateAction.apply(this, args);
        g.deferredExecution(this.endAction, 'addCurrentCommand-' + (this.id || this.pk));
      };

      RItem.prototype.doAction = function(ActionCommand, args) {
        this.beginAction(new ActionCommand(this));
        this.updateAction.apply(this, args);
        this.endAction();
      };

      RItem.prototype.createSelectionRectangle = function(bounds) {
        this.selectionRectangle.insert(1, new Point(bounds.left, bounds.center.y));
        this.selectionRectangle.insert(3, new Point(bounds.center.x, bounds.top));
        this.selectionRectangle.insert(5, new Point(bounds.right, bounds.center.y));
        this.selectionRectangle.insert(7, new Point(bounds.center.x, bounds.bottom));
      };

      RItem.prototype.updateSelectionRectangle = function() {
        var bounds, _ref;
        bounds = this.rectangle.clone().expand(10);
        if ((_ref = this.selectionRectangle) != null) {
          _ref.remove();
        }
        this.selectionRectangle = new Path.Rectangle(bounds);
        this.group.addChild(this.selectionRectangle);
        this.selectionRectangle.name = "selection rectangle";
        this.selectionRectangle.pivot = bounds.center;
        this.createSelectionRectangle(bounds);
        this.selectionRectangle.selected = true;
        this.selectionRectangle.controller = this;
      };

      RItem.prototype.setRectangle = function(rectangle, update) {
        if (update == null) {
          update = false;
        }
        if (!Rectangle.prototype.isPrototypeOf(rectangle)) {
          rectangle = new Rectangle(rectangle);
        }
        this.rectangle = rectangle;
        if (this.selectionRectangle) {
          this.updateSelectionRectangle();
        }
        if (!this.socketAction) {
          if (update) {
            this.update('rectangle');
          }
          g.chatSocket.emit("bounce", {
            itemPk: this.pk,
            "function": "setRectangle",
            "arguments": [this.rectangle, false]
          });
        }
      };

      RItem.prototype.updateSetRectangle = function(event) {
        var center, delta, dx, dy, index, name, rectangle, rotation, x, y;
        event.point = g.snap2D(event.point);
        rotation = this.rotation || 0;
        rectangle = this.rectangle.clone();
        delta = event.point.subtract(this.rectangle.center);
        x = new Point(1, 0);
        x.angle += rotation;
        dx = x.dot(delta);
        y = new Point(0, 1);
        y.angle += rotation;
        dy = y.dot(delta);
        index = this.selectionState.resize.index;
        name = this.constructor.indexToName[index];
        if (!event.modifiers.shift && __indexOf.call(this.constructor.cornersNames, name) >= 0 && rectangle.width > 0 && rectangle.height > 0) {
          if (Math.abs(dx / rectangle.width) > Math.abs(dy / rectangle.height)) {
            dx = g.sign(dx) * Math.abs(rectangle.width * dy / rectangle.height);
          } else {
            dy = g.sign(dy) * Math.abs(rectangle.height * dx / rectangle.width);
          }
        }
        center = rectangle.center.clone();
        rectangle[name] = this.constructor.valueFromName(center.add(dx, dy), name);
        if (!g.specialKey(event)) {
          rectangle[this.constructor.oppositeName[name]] = this.constructor.valueFromName(center.subtract(dx, dy), name);
        } else {
          rectangle.center = center.add(rectangle.center.subtract(center).rotate(rotation));
        }
        if (rectangle.width < 0) {
          rectangle.width = Math.abs(rectangle.width);
          rectangle.center.x = center.x;
        }
        if (rectangle.height < 0) {
          rectangle.height = Math.abs(rectangle.height);
          rectangle.center.y = center.y;
        }
        this.setRectangle(rectangle);
        g.highlightValidity(this);
      };

      RItem.prototype.endSetRectangle = function() {
        this.update('rectangle');
      };

      RItem.prototype.moveTo = function(position, update) {
        var delta;
        if (!Point.prototype.isPrototypeOf(position)) {
          position = new Point(position);
        }
        delta = position.subtract(this.rectangle.center);
        this.rectangle.center = position;
        this.group.translate(delta);
        if (!this.socketAction) {
          if (update) {
            this.update('position');
          }
          g.chatSocket.emit("bounce", {
            itemPk: this.pk,
            "function": "moveTo",
            "arguments": [position, false]
          });
        }
      };

      RItem.prototype.moveBy = function(delta, update) {
        this.moveTo(this.rectangle.center.add(delta), update);
      };

      RItem.prototype.updateMove = function(event) {
        var cornerName, destination, rectangle;
        if (g.getSnap() > 1) {
          if (this.selectionState.move !== true) {
            cornerName = this.selectionState.move;
            rectangle = this.rectangle.clone();
            if (this.dragOffset == null) {
              this.dragOffset = rectangle[cornerName].subtract(event.downPoint);
            }
            destination = g.snap2D(event.point.add(this.dragOffset));
            rectangle.moveCorner(cornerName, destination);
            this.moveTo(rectangle.center);
          } else {
            if (this.dragOffset == null) {
              this.dragOffset = this.rectangle.center.subtract(event.downPoint);
            }
            destination = g.snap2D(event.point.add(this.dragOffset));
            this.moveTo(destination);
          }
        } else {
          this.moveBy(event.delta);
        }
        g.highlightValidity(this);
      };

      RItem.prototype.endMove = function(update) {
        this.dragOffset = null;
        if (update) {
          this.update('position');
        }
      };

      RItem.prototype.moveToCommand = function(position) {
        g.commandManager.add(new g.MoveCommand(this, position), true);
      };

      RItem.prototype.resizeCommand = function(rectangle) {
        g.commandManager.add(new g.ResizeCommand(this, rectangle), true);
      };

      RItem.prototype.moveByCommand = function(delta) {
        this.moveToCommand(this.rectangle.center.add(delta), true);
      };

      RItem.prototype.getData = function() {
        var data;
        data = jQuery.extend({}, this.data);
        data.rectangle = this.rectangle.toJSON();
        data.rotation = this.rotation;
        return data;
      };

      RItem.prototype.getStringifiedData = function() {
        return JSON.stringify(this.getData());
      };

      RItem.prototype.getBounds = function() {
        return this.rectangle;
      };

      RItem.prototype.getDrawingBounds = function() {
        return this.rectangle.expand(this.data.strokeWidth);
      };

      RItem.prototype.highlight = function() {
        if (this.highlightRectangle != null) {
          g.updatePathRectangle(this.highlightRectangle, this.getBounds());
          return;
        }
        this.highlightRectangle = new Path.Rectangle(this.getBounds());
        this.highlightRectangle.strokeColor = g.selectionBlue;
        this.highlightRectangle.strokeScaling = false;
        this.highlightRectangle.dashArray = [4, 10];
        g.selectionLayer.addChild(this.highlightRectangle);
      };

      RItem.prototype.unhighlight = function() {
        if (this.highlightRectangle == null) {
          return;
        }
        this.highlightRectangle.remove();
        this.highlightRectangle = null;
      };

      RItem.prototype.setPK = function(pk, loading) {
        this.pk = pk;
        if (loading == null) {
          loading = false;
        }
        g.items[this.pk] = this;
        delete g.items[this.id];
        if (!loading && !this.socketAction) {
          g.chatSocket.emit("bounce", {
            itemPk: this.id,
            "function": "setPK",
            "arguments": [this.pk]
          });
        }
      };

      RItem.prototype.isSelected = function() {
        return this.selectionRectangle != null;
      };

      RItem.prototype.select = function() {
        var _ref;
        if (this.selectionRectangle != null) {
          return false;
        }
        if ((_ref = this.lock) != null) {
          _ref.deselect();
        }
        this.selectionState = {
          move: true
        };
        g.s = this;
        this.updateSelectionRectangle(true);
        g.selectedItems.push(this);
        g.controllerManager.updateParametersForSelectedItems();
        g.rasterizer.selectItem(this);
        this.zindex = this.group.index;
        g.selectionLayer.addChild(this.group);
        return true;
      };

      RItem.prototype.deselect = function() {
        var _ref;
        if (this.selectionRectangle == null) {
          return false;
        }
        if ((_ref = this.selectionRectangle) != null) {
          _ref.remove();
        }
        this.selectionRectangle = null;
        g.selectedItems.remove(this);
        g.controllerManager.updateParametersForSelectedItems();
        if (this.group != null) {
          g.rasterizer.deselectItem(this);
          if (!this.lock) {
            this.group = g.mainLayer.insertChild(this.zindex, this.group);
          } else {
            this.group = this.lock.group.insertChild(this.zindex, this.group);
          }
        }
        g.RDiv.showDivs();
        return true;
      };

      RItem.prototype.remove = function() {
        var _ref;
        if (!this.group) {
          return;
        }
        this.group.remove();
        this.group = null;
        this.deselect();
        if ((_ref = this.highlightRectangle) != null) {
          _ref.remove();
        }
        if (this.pk != null) {
          delete g.items[this.pk];
        } else {
          delete g.items[this.id];
        }
      };

      RItem.prototype.finish = function() {
        if (this.rectangle.area === 0) {
          this.remove();
          return false;
        }
        return true;
      };

      RItem.prototype.save = function(addCreateCommand) {
        this.addCreateCommand = addCreateCommand;
      };

      RItem.prototype.saveCallback = function() {
        if (this.addCreateCommand) {
          g.commandManager.add(new g.CreateItemCommand(this));
          delete this.addCreateCommand;
        }
      };

      RItem.prototype["delete"] = function() {
        if (!this.socketAction) {
          g.chatSocket.emit("bounce", {
            itemPk: this.pk,
            "function": "delete",
            "arguments": []
          });
        }
        this.pk = null;
      };

      RItem.prototype.deleteCommand = function() {
        g.commandManager.add(new g.DeleteItemCommand(this), true);
      };

      RItem.prototype.getDuplicateData = function() {
        return {
          data: this.getData(),
          rectangle: this.rectangle
        };
      };

      RItem.prototype.duplicateCommand = function() {
        g.commandManager.add(new g.DuplicateItemCommand(this), true);
      };

      RItem.prototype.removeDrawing = function() {
        var _ref;
        if (((_ref = this.drawing) != null ? _ref.parent : void 0) == null) {
          return;
        }
        this.drawingRelativePosition = this.drawing.position.subtract(this.rectangle.center);
        this.drawing.remove();
      };

      RItem.prototype.replaceDrawing = function() {
        var _ref;
        if ((this.drawing == null) || (this.drawingRelativePosition == null)) {
          return;
        }
        if ((_ref = this.raster) != null) {
          _ref.remove();
        }
        this.group.addChild(this.drawing);
        this.drawing.position = this.rectangle.center.add(this.drawingRelativePosition);
        this.drawingRelativePosition = null;
      };

      RItem.prototype.rasterize = function() {
        if ((this.raster != null) || (this.drawing == null)) {
          return;
        }
        if (!g.rasterizer.rasterizeItems) {
          return;
        }
        this.raster = this.drawing.rasterize();
        this.group.addChild(this.raster);
        this.raster.sendToBack();
        this.removeDrawing();
      };

      return RItem;

    })();
    g.RItem = RItem;
    RContent = (function(_super) {
      __extends(RContent, _super);

      RContent.indexToName = {
        0: 'bottomLeft',
        1: 'left',
        2: 'topLeft',
        3: 'top',
        4: 'rotation-handle',
        5: 'top',
        6: 'topRight',
        7: 'right',
        8: 'bottomRight',
        9: 'bottom'
      };

      RContent.initializeParameters = function() {
        var parameters;
        parameters = RContent.__super__.constructor.initializeParameters.call(this);
        delete parameters['Items'].align;
        parameters['Items'].duplicate = g.parameters.duplicate;
        return parameters;
      };

      RContent.parameters = RContent.initializeParameters();

      function RContent(data, pk, date, itemListJ, sortedItems) {
        this.data = data;
        this.pk = pk;
        this.date = date;
        this.sortedItems = sortedItems;
        this.onLiClick = __bind(this.onLiClick, this);
        RContent.__super__.constructor.call(this, this.data, this.pk);
        if (this.date == null) {
          this.date = Date.now();
        }
        this.rotation = this.data.rotation || 0;
        this.liJ = $("<li>");
        this.setZindexLabel();
        this.liJ.attr("data-pk", this.pk);
        this.liJ.click(this.onLiClick);
        this.liJ.mouseover((function(_this) {
          return function(event) {
            _this.highlight();
          };
        })(this));
        this.liJ.mouseout((function(_this) {
          return function(event) {
            _this.unhighlight();
          };
        })(this));
        this.liJ.rItem = this;
        itemListJ.prepend(this.liJ);
        $("#RItems .mCustomScrollbar").mCustomScrollbar("scrollTo", "bottom");
        if (this.pk != null) {
          this.updateZIndex();
        }
        return;
      }

      RContent.prototype.onLiClick = function(event) {
        var bounds;
        if (!event.shiftKey) {
          g.deselectAll();
          bounds = this.getBounds();
          if (!view.bounds.intersects(bounds)) {
            g.RMoveTo(bounds.center, 1000);
          }
        }
        this.select();
      };

      RContent.prototype.setZindexLabel = function() {
        var dateLabel, zindexLabel;
        dateLabel = '' + this.date;
        dateLabel = dateLabel.substring(dateLabel.length - 7, dateLabel.length - 3);
        zindexLabel = this.constructor.rname;
        if (dateLabel.length > 0) {
          zindexLabel += ' - ' + dateLabel;
        }
        this.liJ.text(zindexLabel);
      };

      RContent.prototype.initializeSelection = function(event, hitResult) {
        RContent.__super__.initializeSelection.call(this, event, hitResult);
        if ((hitResult != null ? hitResult.type : void 0) === 'segment') {
          if (hitResult.item === this.selectionRectangle) {
            if (this.constructor.indexToName[hitResult.segment.index] === 'rotation-handle') {
              this.selectionState = {
                rotation: true
              };
            }
          }
        }
      };

      RContent.prototype.beginSelect = function(event) {
        RContent.__super__.beginSelect.call(this, event);
        if (this.selectionState.rotation != null) {
          this.beginAction(new g.RotationCommand(this));
        }
      };

      RContent.prototype.createSelectionRectangle = function(bounds) {
        this.selectionRectangle.insert(1, new Point(bounds.left, bounds.center.y));
        this.selectionRectangle.insert(3, new Point(bounds.center.x, bounds.top));
        this.selectionRectangle.insert(3, new Point(bounds.center.x, bounds.top - 25));
        this.selectionRectangle.insert(3, new Point(bounds.center.x, bounds.top));
        this.selectionRectangle.insert(7, new Point(bounds.right, bounds.center.y));
        this.selectionRectangle.insert(9, new Point(bounds.center.x, bounds.bottom));
      };

      RContent.prototype.updateSelectionRectangle = function() {
        RContent.__super__.updateSelectionRectangle.call(this);
        this.selectionRectangle.rotation = this.rotation;
      };

      RContent.prototype.setRotation = function(rotation, update) {
        var previousRotation;
        previousRotation = this.rotation;
        this.group.pivot = this.rectangle.center;
        this.rotation = rotation;
        this.group.rotate(rotation - previousRotation);
        if (!this.socketAction) {
          if (update) {
            this.update('rotation');
          }
          g.chatSocket.emit("bounce", {
            itemPk: this.pk,
            "function": "setRotation",
            "arguments": [this.rotation, false]
          });
        }
      };

      RContent.prototype.updateSetRotation = function(event) {
        var rotation;
        rotation = event.point.subtract(this.rectangle.center).angle + 90;
        if (event.modifiers.shift || g.specialKey(event) || g.getSnap() > 1) {
          rotation = g.roundToMultiple(rotation, event.modifiers.shift ? 10 : 5);
        }
        this.setRotation(rotation);
        g.highlightValidity(this);
      };

      RContent.prototype.endSetRotation = function() {
        this.update('rotation');
      };

      RContent.prototype.getData = function() {
        var data;
        data = jQuery.extend({}, RContent.__super__.getData.call(this));
        data.rotation = this.rotation;
        return data;
      };

      RContent.prototype.getBounds = function() {
        if (this.rotation === 0) {
          return this.rectangle;
        }
        return g.getRotatedBounds(this.rectangle, this.rotation);
      };

      RContent.prototype.updateZIndex = function() {
        var found, i, item, _i, _len, _ref;
        if (this.date == null) {
          return;
        }
        if (this.sortedItems.length === 0) {
          this.sortedItems.push(this);
          return;
        }
        found = false;
        _ref = this.sortedItems;
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          item = _ref[i];
          if (this.date < item.date) {
            this.insertBelow(item, i);
            found = true;
            break;
          }
        }
        if (!found) {
          this.insertAbove(this.sortedItems.last());
        }
      };

      RContent.prototype.insertAbove = function(item, index, update) {
        var nextDate, previousDate;
        if (index == null) {
          index = null;
        }
        if (update == null) {
          update = false;
        }
        this.group.insertAbove(item.group);
        if (!index) {
          this.sortedItems.remove(this);
          index = this.sortedItems.indexOf(item) + 1;
        }
        this.sortedItems.splice(index, 0, this);
        this.liJ.insertBefore(item.liJ);
        if (update) {
          if (this.sortedItems[index + 1] == null) {
            this.date = Date.now();
          } else {
            previousDate = this.sortedItems[index - 1].date;
            nextDate = this.sortedItems[index + 1].date;
            this.date = (previousDate + nextDate) / 2;
          }
          this.update('z-index');
        }
        this.setZindexLabel();
      };

      RContent.prototype.insertBelow = function(item, index, update) {
        var nextDate, previousDate;
        if (index == null) {
          index = null;
        }
        if (update == null) {
          update = false;
        }
        this.group.insertBelow(item.group);
        if (!index) {
          this.sortedItems.remove(this);
          index = this.sortedItems.indexOf(item);
        }
        this.sortedItems.splice(index, 0, this);
        this.liJ.insertAfter(item.liJ);
        if (update) {
          if (this.sortedItems[index - 1] == null) {
            this.date = this.sortedItems[index + 1].date - 1000;
          } else {
            previousDate = this.sortedItems[index - 1].date;
            nextDate = this.sortedItems[index + 1].date;
            this.date = (previousDate + nextDate) / 2;
          }
          this.update('z-index');
        }
        this.setZindexLabel();
      };

      RContent.prototype.setPK = function(pk) {
        var _ref;
        RContent.__super__.setPK.apply(this, arguments);
        if ((_ref = this.liJ) != null) {
          _ref.attr("data-pk", this.pk);
        }
      };

      RContent.prototype.select = function() {
        if (!RContent.__super__.select.call(this)) {
          return false;
        }
        this.liJ.addClass('selected');
        return true;
      };

      RContent.prototype.deselect = function() {
        if (!RContent.__super__.deselect.call(this)) {
          return false;
        }
        this.liJ.removeClass('selected');
        return true;
      };

      RContent.prototype.finish = function() {
        var bounds, lock, locks, _i, _len;
        if (!RContent.__super__.finish.call(this)) {
          return false;
        }
        bounds = this.getBounds();
        if (bounds.area > g.rasterizer.maxArea()) {
          g.romanesco_alert("The item is too big", "Warning");
          this.remove();
          return false;
        }
        locks = g.RLock.getLocksWhichIntersect(bounds);
        for (_i = 0, _len = locks.length; _i < _len; _i++) {
          lock = locks[_i];
          if (lock.rectangle.contains(bounds)) {
            if (lock.owner === g.me) {
              lock.addItem(this);
            } else {
              g.romanesco_alert("The item intersects with a lock", "Warning");
              this.remove();
              return false;
            }
          }
        }
        return true;
      };

      RContent.prototype.remove = function() {
        var _ref, _ref1;
        RContent.__super__.remove.call(this);
        if ((_ref = this.sortedItems) != null) {
          _ref.remove(this);
        }
        if ((_ref1 = this.liJ) != null) {
          _ref1.remove();
        }
      };

      RContent.prototype.update = function() {};

      return RContent;

    })(RItem);
    g.RContent = RContent;
    RSelectionRectangle = (function(_super) {
      __extends(RSelectionRectangle, _super);

      function RSelectionRectangle(rectangle, extractImage) {
        var separatorJ;
        this.rectangle = rectangle;
        RSelectionRectangle.__super__.constructor.call(this);
        this.drawing = new Path.Rectangle(this.rectangle);
        this.drawing.name = 'selection rectangle background';
        this.drawing.strokeWidth = 1;
        this.drawing.strokeColor = g.selectionBlue;
        this.drawing.controller = this;
        this.group.addChild(this.drawing);
        separatorJ = g.stageJ.find(".text-separator");
        this.buttonJ = g.templatesJ.find(".screenshot-btn").clone().insertAfter(separatorJ);
        this.buttonJ.find('.extract-btn').click(function(event) {
          var redraw;
          redraw = $(this).attr('data-click') === 'redraw-snapshot';
          extractImage(redraw);
        });
        this.updateTransform();
        this.select();
        g.tools['Select'].select();
        return;
      }

      RSelectionRectangle.prototype.remove = function() {
        this.removing = true;
        RSelectionRectangle.__super__.remove.call(this);
        this.buttonJ.remove();
        g.tools['Screenshot'].selectionRectangle = null;
      };

      RSelectionRectangle.prototype.deselect = function() {
        if (!RSelectionRectangle.__super__.deselect.call(this)) {
          return false;
        }
        if (!this.removing) {
          this.remove();
        }
        return true;
      };

      RSelectionRectangle.prototype.setRectangle = function(rectangle, update) {
        RSelectionRectangle.__super__.setRectangle.call(this, rectangle, update);
        g.updatePathRectangle(this.drawing, rectangle);
        this.updateTransform();
      };

      RSelectionRectangle.prototype.moveTo = function(position, update) {
        RSelectionRectangle.__super__.moveTo.call(this, position, update);
        this.updateTransform();
      };

      RSelectionRectangle.prototype.updateTransform = function() {
        var transfrom, viewPos;
        viewPos = view.projectToView(this.rectangle.center);
        transfrom = 'translate(' + viewPos.x + 'px,' + viewPos.y + 'px)';
        transfrom += 'translate(-50%, -50%)';
        this.buttonJ.css({
          'position': 'absolute',
          'transform': transfrom,
          'top': 0,
          'left': 0,
          'transform-origin': '50% 50%',
          'z-index': 999
        });
      };

      RSelectionRectangle.prototype.update = function() {};

      return RSelectionRectangle;

    })(RItem);
    g.RSelectionRectangle = RSelectionRectangle;
  });

}).call(this);

//# sourceMappingURL=Item.map
