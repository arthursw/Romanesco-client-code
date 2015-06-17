// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['utils', 'Item/item', 'jquery', 'paper'], function(utils) {
    var RPath, g;
    g = utils.g();
    RPath = (function(_super) {
      __extends(RPath, _super);

      RPath.rname = 'Pen';

      RPath.rdescription = "The classic and basic pen tool";

      RPath.cursorPosition = {
        x: 24,
        y: 0
      };

      RPath.cursorDefault = "crosshair";

      RPath.constructor.secureDistance = 2;

      RPath.initializeParameters = function() {
        var parameters;
        return parameters = {
          'Items': {
            align: g.parameters.align,
            distribute: g.parameters.distribute,
            duplicate: g.parameters.duplicate,
            "delete": g.parameters["delete"],
            editTool: {
              type: 'button',
              label: 'Edit tool',
              "default": (function(_this) {
                return function() {
                  return g.showCodeEditor(_this.source);
                };
              })(this)
            }
          },
          'Style': {
            strokeWidth: $.extend(true, {}, g.parameters.strokeWidth),
            strokeColor: $.extend(true, {}, g.parameters.strokeColor),
            fillColor: $.extend(true, {}, g.parameters.fillColor)
          },
          'Shadow': {
            folderIsClosedByDefault: true,
            shadowOffsetX: {
              type: 'slider',
              label: 'Shadow offset x',
              min: -25,
              max: 25,
              "default": 0
            },
            shadowOffsetY: {
              type: 'slider',
              label: 'Shadow offset y',
              min: -25,
              max: 25,
              "default": 0
            },
            shadowBlur: {
              type: 'slider',
              label: 'Shadow blur',
              min: 0,
              max: 50,
              "default": 0
            },
            shadowColor: {
              type: 'color',
              label: 'Shadow color',
              "default": '#000',
              defaultCheck: false
            }
          }
        };
      };

      RPath.parameters = RPath.initializeParameters();

      RPath.create = function(duplicateData) {
        var copy;
        if (duplicateData == null) {
          duplicateData = this.getDuplicateData();
        }
        copy = new this(duplicateData.date, duplicateData.data, null, duplicateData.points);
        copy.draw();
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

      function RPath(date, data, pk, points, lock) {
        this.date = date != null ? date : null;
        this.data = data != null ? data : null;
        this.pk = pk != null ? pk : null;
        if (points == null) {
          points = null;
        }
        this.lock = lock != null ? lock : null;
        this.update = __bind(this.update, this);
        this.saveCallback = __bind(this.saveCallback, this);
        if (!this.lock) {
          RPath.__super__.constructor.call(this, this.data, this.pk, this.date, g.pathList, g.sortedPaths);
        } else {
          RPath.__super__.constructor.call(this, this.data, this.pk, this.date, this.lock.itemListsJ.find('.rPath-list'), this.lock.sortedPaths);
        }
        this.selectionHighlight = null;
        if (points != null) {
          this.loadPath(points);
        }
        return;
      }

      RPath.prototype.getDuplicateData = function() {
        return {
          data: this.getData(),
          points: this.pathOnPlanet(),
          date: this.date
        };
      };

      RPath.prototype.getDrawingBounds = function() {
        if (!this.canvasRaster && (this.drawing != null) && this.drawing.strokeBounds.area > 0) {
          if (this.raster != null) {
            return this.raster.bounds;
          }
          return this.drawing.strokeBounds;
        }
        return this.getBounds().expand(this.data.strokeWidth);
      };

      RPath.prototype.endSetRectangle = function() {
        RPath.__super__.endSetRectangle.call(this);
        this.draw();
        this.rasterize();
      };

      RPath.prototype.setRectangle = function(event, update) {
        RPath.__super__.setRectangle.call(this, event, update);
        this.draw(update);
      };

      RPath.prototype.projectToRaster = function(point) {
        return point.subtract(this.canvasRaster.bounds.topLeft);
      };

      RPath.prototype.prepareHitTest = function(fullySelected, strokeWidth) {
        var _ref;
        RPath.__super__.prepareHitTest.call(this);
        this.stateBeforeHitTest = {};
        this.stateBeforeHitTest.groupWasVisible = this.group.visible;
        this.stateBeforeHitTest.controlPathWasVisible = this.controlPath.visible;
        this.stateBeforeHitTest.controlPathWasSelected = this.controlPath.selected;
        this.stateBeforeHitTest.controlPathWasFullySelected = this.controlPath.fullySelected;
        this.stateBeforeHitTest.controlPathStrokeWidth = this.controlPath.strokeWidth;
        this.group.visible = true;
        this.controlPath.visible = true;
        this.controlPath.selected = true;
        if (strokeWidth) {
          this.controlPath.strokeWidth = strokeWidth;
        }
        if (fullySelected) {
          this.controlPath.fullySelected = true;
        }
        if ((_ref = this.speedGroup) != null) {
          _ref.selected = true;
        }
      };

      RPath.prototype.finishHitTest = function(fullySelected) {
        var _ref;
        if (fullySelected == null) {
          fullySelected = true;
        }
        RPath.__super__.finishHitTest.call(this, fullySelected);
        this.group.visible = this.stateBeforeHitTest.groupWasVisible;
        this.controlPath.visible = this.stateBeforeHitTest.controlPathWasVisible;
        this.controlPath.strokeWidth = this.stateBeforeHitTest.controlPathStrokeWidth;
        this.controlPath.fullySelected = this.stateBeforeHitTest.controlPathWasFullySelected;
        if (!this.controlPath.fullySelected) {
          this.controlPath.selected = this.stateBeforeHitTest.controlPathWasSelected;
        }
        this.stateBeforeHitTest = null;
        if ((_ref = this.speedGroup) != null) {
          _ref.selected = false;
        }
      };

      RPath.prototype.select = function() {
        if (!RPath.__super__.select.call(this) || (this.controlPath == null)) {
          return false;
        }
        return true;
      };

      RPath.prototype.deselect = function() {
        if (!RPath.__super__.deselect.call(this)) {
          return false;
        }
        return true;
      };

      RPath.prototype.beginAction = function(command) {
        RPath.__super__.beginAction.call(this, command);
      };

      RPath.prototype.endAction = function() {
        RPath.__super__.endAction.call(this);
      };

      RPath.prototype.updateSelect = function(event) {
        RPath.__super__.updateSelect.call(this, event);
      };

      RPath.prototype.doubleClick = function(event) {};

      RPath.prototype.loadPath = function(points) {};

      RPath.prototype.setParameter = function(controller, value, updateGUI, update) {
        RPath.__super__.setParameter.call(this, controller, value, updateGUI, update);
        if (this.previousBoundingBox == null) {
          this.previousBoundingBox = this.getDrawingBounds();
        }
        this.draw();
      };

      RPath.prototype.applyStylesToPath = function(path) {
        path.strokeColor = this.data.strokeColor;
        path.strokeWidth = this.data.strokeWidth;
        path.fillColor = this.data.fillColor;
        if (this.data.shadowOffsetY != null) {
          path.shadowOffset = new Point(this.data.shadowOffsetX, this.data.shadowOffsetY);
        }
        if (this.data.shadowBlur != null) {
          path.shadowBlur = this.data.shadowBlur;
        }
        if (this.data.shadowColor != null) {
          path.shadowColor = this.data.shadowColor;
        }
      };

      RPath.prototype.addPath = function(path, applyStyles) {
        if (applyStyles == null) {
          applyStyles = true;
        }
        if (path == null) {
          path = new Path();
        }
        path.controller = this;
        if (applyStyles) {
          this.applyStylesToPath(path);
        }
        this.drawing.addChild(path);
        return path;
      };

      RPath.prototype.addControlPath = function(controlPath) {
        this.controlPath = controlPath;
        if (this.lock) {
          this.lock.group.addChild(this.group);
        }
        if (this.controlPath == null) {
          this.controlPath = new Path();
        }
        this.group.addChild(this.controlPath);
        this.controlPath.name = "controlPath";
        this.controlPath.controller = this;
        this.controlPath.strokeWidth = 10;
        this.controlPath.strokeColor = g.selectionBlue;
        this.controlPath.strokeColor.alpha = 0.25;
        this.controlPath.strokeCap = 'round';
        this.controlPath.visible = false;
      };

      RPath.prototype.initializeDrawing = function(createCanvas) {
        var bounds, canvas, position, _ref, _ref1, _ref2;
        if (createCanvas == null) {
          createCanvas = false;
        }
        if ((_ref = this.raster) != null) {
          _ref.remove();
        }
        this.raster = null;
        this.controlPath.strokeWidth = 10;
        if ((_ref1 = this.drawing) != null) {
          _ref1.remove();
        }
        this.drawing = new Group();
        this.drawing.name = "drawing";
        this.drawing.strokeColor = this.data.strokeColor;
        this.drawing.strokeWidth = this.data.strokeWidth;
        this.drawing.fillColor = this.data.fillColor;
        this.drawing.insertBelow(this.controlPath);
        this.drawing.controlPath = this.controlPath;
        this.drawing.controller = this;
        this.group.addChild(this.drawing);
        if (createCanvas) {
          canvas = document.createElement("canvas");
          if (this.rectangle.area < 2) {
            canvas.width = view.size.width;
            canvas.height = view.size.height;
            position = view.center;
          } else {
            bounds = this.getDrawingBounds();
            canvas.width = bounds.width;
            canvas.height = bounds.height;
            position = bounds.center;
          }
          if ((_ref2 = this.canvasRaster) != null) {
            _ref2.remove();
          }
          this.canvasRaster = new Raster(canvas, position);
          this.drawing.addChild(this.canvasRaster);
          this.context = this.canvasRaster.canvas.getContext("2d");
          this.context.strokeStyle = this.data.strokeColor;
          this.context.fillStyle = this.data.fillColor;
          this.context.lineWidth = this.data.strokeWidth;
        }
      };

      RPath.prototype.setAnimated = function(animated) {
        if (animated) {
          g.registerAnimation(this);
        } else {
          g.deregisterAnimation(this);
        }
      };

      RPath.prototype.draw = function(simplified) {
        if (simplified == null) {
          simplified = false;
        }
      };

      RPath.prototype.initialize = function() {};

      RPath.prototype.beginCreate = function(point, event) {};

      RPath.prototype.updateCreate = function(point, event) {};

      RPath.prototype.endCreate = function(point, event) {};

      RPath.prototype.insertAbove = function(path, index, update) {
        if (index == null) {
          index = null;
        }
        if (update == null) {
          update = false;
        }
        this.zindex = this.group.index;
        RPath.__super__.insertAbove.call(this, path, index, update);
      };

      RPath.prototype.insertBelow = function(path, index, update) {
        if (index == null) {
          index = null;
        }
        if (update == null) {
          update = false;
        }
        this.zindex = this.group.index;
        RPath.__super__.insertBelow.call(this, path, index, update);
      };

      RPath.prototype.getData = function() {
        return this.data;
      };

      RPath.prototype.getStringifiedData = function() {
        return JSON.stringify(this.getData());
      };

      RPath.prototype.getPlanet = function() {
        return g.projectToPlanet(this.controlPath.segments[0].point);
      };

      RPath.prototype.save = function(addCreateCommand) {
        var args;
        if (addCreateCommand == null) {
          addCreateCommand = true;
        }
        if (this.controlPath == null) {
          return;
        }
        g.paths[this.pk != null ? this.pk : this.id] = this;
        args = {
          city: g.city,
          box: g.boxFromRectangle(this.getDrawingBounds()),
          points: this.pathOnPlanet(),
          data: this.getStringifiedData(),
          date: this.date,
          object_type: this.constructor.rname
        };
        Dajaxice.draw.savePath(this.saveCallback, args);
        RPath.__super__.save.apply(this, arguments);
      };

      RPath.prototype.saveCallback = function(result) {
        g.checkError(result);
        if (result.pk == null) {
          return;
        }
        this.setPK(result.pk);
        if (this.updateAfterSave != null) {
          this.update(this.updateAfterSave);
        }
        RPath.__super__.saveCallback.apply(this, arguments);
      };

      RPath.prototype.getUpdateFunction = function() {
        return 'updatePath';
      };

      RPath.prototype.getUpdateArguments = function(type) {
        var args;
        switch (type) {
          case 'z-index':
            args = {
              pk: this.pk,
              date: this.date
            };
            break;
          default:
            args = {
              pk: this.pk,
              points: this.pathOnPlanet(),
              data: this.getStringifiedData(),
              box: g.boxFromRectangle(this.getDrawingBounds())
            };
        }
        return args;
      };

      RPath.prototype.update = function(type) {
        if (this.pk == null) {
          this.updateAfterSave = type;
          return;
        }
        delete this.updateAfterSave;
        Dajaxice.draw.updatePath(this.updatePathCallback, this.getUpdateArguments(type));
      };

      RPath.prototype.updatePathCallback = function(result) {
        g.checkError(result);
      };

      RPath.prototype.setPK = function(pk) {
        RPath.__super__.setPK.apply(this, arguments);
        g.paths[pk] = this;
        delete g.paths[this.id];
      };

      RPath.prototype.remove = function() {
        if (!this.group) {
          return;
        }
        g.deregisterAnimation();
        this.controlPath = null;
        this.drawing = null;
        if (this.raster == null) {
          this.raster = null;
        }
        if (this.canvasRaster == null) {
          this.canvasRaster = null;
        }
        if (this.pk != null) {
          delete g.paths[this.pk];
        } else {
          delete g.paths[this.id];
        }
        RPath.__super__.remove.call(this);
      };

      RPath.prototype["delete"] = function() {
        if ((this.lock != null) && this.lock.owner !== g.me) {
          return;
        }
        this.group.visible = false;
        this.remove();
        if (this.pk == null) {
          return;
        }
        console.log(this.pk);
        if (!this.socketAction) {
          Dajaxice.draw.deletePath(g.checkError, {
            pk: this.pk
          });
        }
        RPath.__super__["delete"].apply(this, arguments);
      };

      RPath.prototype.pathOnPlanet = function(controlSegments) {
        var p, planet, points, segment, _i, _len;
        if (controlSegments == null) {
          controlSegments = this.controlPath.segments;
        }
        points = [];
        planet = this.getPlanet();
        for (_i = 0, _len = controlSegments.length; _i < _len; _i++) {
          segment = controlSegments[_i];
          p = g.projectToPosOnPlanet(segment.point, planet);
          points.push(g.pointToArray(p));
        }
        return points;
      };

      return RPath;

    })(g.RContent);
  });

}).call(this);

//# sourceMappingURL=Path.map
