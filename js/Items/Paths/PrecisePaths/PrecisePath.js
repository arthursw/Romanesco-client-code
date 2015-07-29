var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['Items/Item', 'Items/Paths/Path', 'Commands/Command'], function(Item, Path, Command) {
  var PrecisePath;
  PrecisePath = (function(_super) {
    __extends(PrecisePath, _super);

    PrecisePath.label = 'Precise path';

    PrecisePath.description = "This path offers precise controls, one can modify points along with their handles and their type.";

    PrecisePath.iconURL = 'static/images/icons/inverted/editCurve.png';

    PrecisePath.hitOptions = {
      segments: true,
      stroke: true,
      fill: true,
      curves: true,
      handles: true,
      tolerance: 5
    };

    PrecisePath.secureStep = 25;

    PrecisePath.polygonMode = true;

    PrecisePath.initializeParameters = function() {
      var parameters;
      parameters = PrecisePath.__super__.constructor.initializeParameters.call(this);
      if (this.polygonMode) {
        parameters['Items'].polygonMode = {
          type: 'checkbox',
          label: 'Polygon mode',
          "default": R.polygonMode,
          onChange: function(value) {
            return R.polygonMode = value;
          }
        };
      }
      parameters['Edit curve'] = {
        smooth: {
          type: 'checkbox',
          label: 'Smooth',
          "default": false,
          onChange: function(value) {
            var item, _i, _len, _ref;
            _ref = R.selectedItems;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              item = _ref[_i];
              if (typeof item.setSmooth === "function") {
                item.setSmooth(value);
              }
            }
          }
        },
        pointType: {
          type: 'dropdown',
          label: 'P.Point type',
          values: ['smooth', 'corner', 'point'],
          "default": 'smooth',
          addController: true,
          onChange: function(value) {
            var item, _i, _len, _ref;
            _ref = R.selectedItems;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              item = _ref[_i];
              if (typeof item.modifyPointTypeCommand === "function") {
                item.modifyPointTypeCommand(value);
              }
            }
          }
        },
        deletePoint: {
          type: 'button',
          label: 'Delete point',
          "default": function() {
            var item, _i, _len, _ref;
            _ref = R.selectedItems;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              item = _ref[_i];
              if (typeof item.deletePointCommand === "function") {
                item.deletePointCommand();
              }
            }
          }
        },
        simplify: {
          type: 'button',
          label: 'Simplify',
          "default": function(value) {
            var item, _i, _len, _ref;
            _ref = R.selectedItems;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              item = _ref[_i];
              if (typeof item.simplifyControlPath === "function") {
                item.simplifyControlPath(value);
              }
            }
          },
          onChange: function(value) {}
        },
        showSelectionRectangle: {
          type: 'checkbox',
          label: 'Selection box',
          "default": true,
          onChange: R.tools.select.setSelectionRectangleVisibility
        }
      };
      return parameters;
    };

    PrecisePath.parameters = PrecisePath.initializeParameters();

    PrecisePath.createTool(PrecisePath);

    function PrecisePath(date, data, pk, points, lock) {
      this.date = date != null ? date : null;
      this.data = data != null ? data : null;
      this.pk = pk != null ? pk : null;
      if (points == null) {
        points = null;
      }
      this.lock = lock;
      PrecisePath.__super__.constructor.call(this, this.date, this.data, this.pk, points, this.lock);
      if (this.constructor.polygonMode) {
        this.data.polygonMode = R.polygonMode;
      }
      this.rotation = this.data.rotation = 0;
      return;
    }

    PrecisePath.prototype.setControlPath = function(points, planet) {
      var i, point, _i, _len;
      for (i = _i = 0, _len = points.length; _i < _len; i = _i += 4) {
        point = points[i];
        this.controlPath.add(Utils.CS.posOnPlanetToProject(point, planet));
        this.controlPath.lastSegment.handleIn = new P.Point(points[i + 1]);
        this.controlPath.lastSegment.handleOut = new P.Point(points[i + 2]);
        this.controlPath.lastSegment.rtype = points[i + 3];
      }
    };

    PrecisePath.prototype.loadPath = function(points) {
      var distanceMax, flattenedPath, i, index, recordedPoint, resultingPoint, time, _i;
      this.addControlPath();
      this.setControlPath(this.data.points, this.data.planet);
      this.rectangle = this.controlPath.bounds.clone();
      if (this.data.smooth) {
        this.controlPath.smooth();
      }
      R.rasterizer.loadItem(this);
      time = Date.now();
      flattenedPath = this.controlPath.copyTo(P.project);
      flattenedPath.flatten(this.constructor.secureStep);
      distanceMax = this.constructor.secureDistance * this.constructor.secureDistance;
      for (i = _i = 1; _i <= 10; i = ++_i) {
        index = Math.floor(Math.random() * points.length);
        recordedPoint = new P.Point(points[index]);
        resultingPoint = flattenedPath.segments[index].point;
        if (recordedPoint.getDistance(resultingPoint, true) > distanceMax) {
          flattenedPath.strokeColor = 'red';
          P.view.center = flattenedPath.bounds.center;
          console.log("Error: invalid path");
          return;
        }
      }
      flattenedPath.remove();
      console.log("Time to secure the path: " + ((Date.now() - time) / 1000) + " sec.");
    };

    PrecisePath.prototype.deselectPoint = function() {
      this.selectedSegment = null;
      this.selectedHandle = null;
      this.removeSelectionHighlight();
    };

    PrecisePath.prototype.performHitTest = function(point) {
      var hitResult;
      this.controlPath.visible = true;
      hitResult = this.controlPath.hitTest(point, this.constructor.hitOptions);
      this.controlPath.visible = false;
      return hitResult;
    };

    PrecisePath.prototype.hitTest = function(event) {
      var hitResult, modifyPoint, specialKey, wasSelected;
      this.deselectPoint();
      wasSelected = this.selected;
      hitResult = PrecisePath.__super__.hitTest.call(this, event);
      if (!wasSelected || (hitResult == null)) {
        return;
      }
      specialKey = R.specialKey(event);
      this.selectedSegment = hitResult.segment;
      modifyPoint = false;
      if (hitResult.type === 'segment') {
        if (specialKey && hitResult.item === this.controlPath) {
          this.selectedSegment = hitResult.segment;
          this.deletePointCommand();
        } else {
          if (hitResult.item === this.controlPath) {
            this.selectedSegment = hitResult.segment;
            modifyPoint = true;
          }
        }
      }
      if (!this.data.smooth) {
        if (hitResult.type === "handle-in") {
          this.selectedHandle = hitResult.segment.handleIn;
          modifyPoint = true;
        } else if (hitResult.type === "handle-out") {
          this.selectedHandle = hitResult.segment.handleOut;
          modifyPoint = true;
        }
      }
      if (modifyPoint) {
        R.commandManager.beginAction(new Command.ModifyPoint(this));
      }
    };

    PrecisePath.prototype.initializeDrawing = function(createCanvas) {
      var _base;
      if (createCanvas == null) {
        createCanvas = false;
      }
      if ((_base = this.data).step == null) {
        _base.step = 20;
      }
      this.drawingOffset = 0;
      PrecisePath.__super__.initializeDrawing.call(this, createCanvas);
    };

    PrecisePath.prototype.beginDraw = function(redrawing) {
      if (redrawing == null) {
        redrawing = false;
      }
      this.initializeDrawing(false);
      this.path = this.addPath();
      this.path.segments = this.controlPath.segments;
      this.path.selected = false;
      this.path.strokeCap = 'round';
    };

    PrecisePath.prototype.updateDraw = function(offset, step, redrawing) {
      this.path.add(this.controlPath.lastSegment);
    };

    PrecisePath.prototype.endDraw = function(redrawing) {
      if (redrawing == null) {
        redrawing = false;
      }
    };

    PrecisePath.prototype.checkUpdateDrawing = function(segment, redrawing) {
      if (redrawing == null) {
        redrawing = true;
      }
      this.updateDraw();
    };

    PrecisePath.prototype.beginCreate = function(point, event) {
      PrecisePath.__super__.beginCreate.call(this);
      if (!this.data.polygonMode) {
        this.addControlPath();
        this.controlPath.add(point);
        this.rectangle = this.controlPath.bounds.clone();
        this.beginDraw(false);
      } else {
        if (this.controlPath == null) {
          this.addControlPath();
          this.controlPath.add(point);
          this.rectangle = this.controlPath.bounds.clone();
          this.controlPath.add(point);
          this.beginDraw(false);
        } else {
          this.controlPath.add(point);
        }
        this.controlPath.lastSegment.rtype = 'point';
      }
    };

    PrecisePath.prototype.updateCreate = function(point, event) {
      var lastSegment, previousSegment;
      if (!this.data.polygonMode) {
        this.controlPath.add(point);
        this.checkUpdateDrawing(this.controlPath.lastSegment, false);
      } else {
        lastSegment = this.controlPath.lastSegment;
        previousSegment = lastSegment.previous;
        previousSegment.rtype = 'smooth';
        previousSegment.handleOut = point.subtract(previousSegment.point);
        if (lastSegment !== this.controlPath.firstSegment) {
          previousSegment.handleIn = previousSegment.handleOut.multiply(-1);
        }
        lastSegment.handleIn = lastSegment.handleOut = null;
        lastSegment.point = point;
        console.log('update create');
        this.draw(true, false);
      }
    };

    PrecisePath.prototype.createMove = function(event) {
      this.controlPath.lastSegment.point = event.point;
      console.log('create move');
      this.draw(true, false);
    };

    PrecisePath.prototype.endCreate = function(point, event) {
      var segment, _i, _len, _ref;
      if (this.data.polygonMode) {
        return;
      }
      if (this.controlPath.segments.length >= 2) {
        this.controlPath.simplify();
        _ref = this.controlPath.segments;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          segment = _ref[_i];
          if (segment.handleIn.length > 200) {
            segment.handleIn = segment.handleIn.normalize().multiply(100);
            console.log('ADJUSTING HANDLE LENGTH');
          }
          if (segment.handleOut.length > 200) {
            segment.handleOut = segment.handleOut.normalize().multiply(100);
            console.log('ADJUSTING HANDLE LENGTH');
          }
        }
      }
      this.finish();
      PrecisePath.__super__.endCreate.call(this);
    };

    PrecisePath.prototype.finish = function() {
      if (this.data.polygonMode) {
        this.controlPath.lastSegment.remove();
        this.controlPath.lastSegment.handleOut = null;
      }
      if (this.controlPath.segments.length < 2) {
        this.remove();
        return false;
      }
      if (this.data.smooth) {
        this.controlPath.smooth();
      }
      this.endDraw();
      this.drawingOffset = 0;
      this.rectangle = this.controlPath.bounds.clone();
      if (!PrecisePath.__super__.finish.call(this)) {
        return false;
      }
      this.initialize();
      return true;
    };

    PrecisePath.prototype.simplifiedModeOn = function() {
      var folder, folderName, name, parameter, _ref;
      this.previousData = {};
      _ref = this.constructor.parameters;
      for (folderName in _ref) {
        folder = _ref[folderName];
        for (name in folder) {
          parameter = folder[name];
          if ((parameter.simplified != null) && (this.data[name] != null)) {
            this.previousData[name] = this.data[name];
            this.data[name] = parameter.simplified;
          }
        }
      }
    };

    PrecisePath.prototype.simplifiedModeOff = function() {
      var folder, folderName, name, parameter, _ref;
      _ref = this.constructor.parameters;
      for (folderName in _ref) {
        folder = _ref[folderName];
        for (name in folder) {
          parameter = folder[name];
          if ((parameter.simplified != null) && (this.data[name] != null) && (this.previousData[name] != null)) {
            this.data[name] = this.previousData[name];
            delete this.previousData[name];
          }
        }
      }
    };

    PrecisePath.prototype.processDrawing = function(redrawing) {
      var i, segment, _i, _len, _ref;
      this.beginDraw(redrawing);
      _ref = this.controlPath.segments;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        segment = _ref[i];
        if (i === 0) {
          continue;
        }
        this.checkUpdateDrawing(segment, redrawing);
      }
      this.endDraw(redrawing);
    };

    PrecisePath.prototype.draw = function(simplified, redrawing) {
      var controlPathLength, error, nIteration, nf, offset, reminder, step;
      if (simplified == null) {
        simplified = false;
      }
      if (redrawing == null) {
        redrawing = true;
      }
      this.drawn = false;
      if (!R.rasterizer.requestDraw(this, simplified, redrawing)) {
        return;
      }
      if (this.controlPath.segments.length < 2) {
        return;
      }
      if (simplified) {
        this.simplifiedModeOn();
      }
      step = this.data.step;
      controlPathLength = this.controlPath.length;
      nf = controlPathLength / step;
      nIteration = Math.floor(nf);
      reminder = nf - nIteration;
      offset = reminder * step / 2;
      this.drawingOffset = 0;
      try {
        this.processDrawing(redrawing);
      } catch (_error) {
        error = _error;
        console.error(error.stack);
        console.error(error);
        throw error;
      }
      if (simplified) {
        this.simplifiedModeOff();
      }
      this.drawn = true;
    };

    PrecisePath.prototype.pathOnPlanet = function() {
      var flatennedPath;
      flatennedPath = this.controlPath.copyTo(P.project);
      flatennedPath.flatten(this.constructor.secureStep);
      flatennedPath.remove();
      return PrecisePath.__super__.pathOnPlanet.call(this, flatennedPath.segments);
    };

    PrecisePath.prototype.getPoints = function() {
      var points, segment, _i, _len, _ref;
      points = [];
      _ref = this.controlPath.segments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        segment = _ref[_i];
        points.push(Utils.CS.projectToPosOnPlanet(segment.point));
        points.push(Utils.CS.pointToObj(segment.handleIn));
        points.push(Utils.CS.pointToObj(segment.handleOut));
        points.push(segment.rtype);
      }
      return points;
    };

    PrecisePath.prototype.getPointsAndPlanet = function() {
      return {
        planet: this.getPlanet(),
        points: this.getPoints()
      };
    };

    PrecisePath.prototype.getData = function() {
      this.data.planet = this.getPlanet();
      this.data.points = this.getPoints();
      return this.data;
    };

    PrecisePath.prototype.select = function() {
      if (!PrecisePath.__super__.select.call(this)) {
        return;
      }
      this.controlPath.selected = true;
      if (!this.data.smooth) {
        this.controlPath.fullySelected = true;
      }
      return true;
    };

    PrecisePath.prototype.deselect = function() {
      var _ref;
      if (!PrecisePath.__super__.deselect.call(this)) {
        return false;
      }
      if ((_ref = this.controlPath) != null) {
        _ref.selected = false;
      }
      this.removeSelectionHighlight();
      return true;
    };

    PrecisePath.prototype.highlightSelectedPoint = function() {
      var offset, point, _base;
      if (!this.controlPath.selected) {
        return;
      }
      this.removeSelectionHighlight();
      if (this.selectedSegment == null) {
        return;
      }
      point = this.selectedSegment.point;
      if ((_base = this.selectedSegment).rtype == null) {
        _base.rtype = 'smooth';
      }
      switch (this.selectedSegment.rtype) {
        case 'smooth':
          this.selectionHighlight = new P.Path.Circle(point, 5);
          break;
        case 'corner':
          offset = new P.Point(5, 5);
          this.selectionHighlight = new P.Path.Rectangle(point.subtract(offset), point.add(offset));
          break;
        case 'point':
          this.selectionHighlight = new P.Path.RegularPolygon(point, 3, 5);
      }
      this.selectionHighlight.name = 'selection highlight';
      this.selectionHighlight.controller = this;
      this.selectionHighlight.strokeColor = R.selectionBlue;
      this.selectionHighlight.strokeWidth = 1;
      R.view.selectionLayer.addChild(this.selectionHighlight);
      this.constructor.parameters['Edit curve'].pointType.controller.setValue(this.selectedSegment.rtype);
    };

    PrecisePath.prototype.updateSelectionHighlight = function() {
      if ((this.selectedSegment != null) && this.selectionHighlight) {
        this.selectionHighlight.position = this.selectedSegment.point;
      }
    };

    PrecisePath.prototype.removeSelectionHighlight = function() {
      var _ref;
      if ((_ref = this.selectionHighlight) != null) {
        _ref.remove();
      }
      this.selectionHighlight = null;
    };

    PrecisePath.prototype.moveTo = function(position, update) {
      PrecisePath.__super__.moveTo.call(this, position, update);
      this.updateSelectionHighlight();
    };

    PrecisePath.prototype.setRectangle = function(rectangle, update) {
      var previousRectangle;
      previousRectangle = this.rectangle.clone();
      PrecisePath.__super__.setRectangle.call(this, rectangle, update);
      this.controlPath.pivot = previousRectangle.center;
      this.controlPath.rotate(-this.rotation);
      this.controlPath.scale(this.rectangle.width / previousRectangle.width, this.rectangle.height / previousRectangle.height);
      this.controlPath.position = this.rectangle.center.clone();
      this.controlPath.pivot = this.rectangle.center.clone();
      this.controlPath.rotate(this.rotation);
      this.updateSelectionHighlight();
    };

    PrecisePath.prototype.setRotation = function(rotation, center, update) {
      PrecisePath.__super__.setRotation.call(this, rotation, center, update);
      this.updateSelectionHighlight();
    };

    PrecisePath.prototype.smoothPoint = function(segment, offset) {
      var tangent;
      segment.rtype = 'smooth';
      segment.linear = false;
      if (offset == null) {
        offset = segment.location.offset;
      }
      tangent = segment.path.getTangentAt(offset);
      if (segment.previous != null) {
        segment.handleIn = tangent.multiply(-0.25);
      }
      if (segment.next != null) {
        segment.handleOut = tangent.multiply(+0.25);
      }
    };

    PrecisePath.prototype.doubleClick = function(event) {
      var hitResult, point, segment;
      point = P.view.viewToProject(new P.Point(event.pageX, event.pageY));
      hitResult = this.performHitTest(point);
      if (hitResult == null) {
        return;
      }
      switch (hitResult.type) {
        case 'segment':
          segment = hitResult.segment;
          this.selectedSegment = segment;
          switch (segment.rtype) {
            case 'smooth':
            case null:
            case void 0:
              this.modifySelectedPointType('corner');
              break;
            case 'corner':
              this.modifySelectedPointType('point');
              break;
            case 'point':
              this.deletePointCommand();
              break;
            default:
              console.log("segment.rtype not known.");
          }
          break;
        case 'stroke':
        case 'curve':
          this.addPointCommand(hitResult.location);
      }
    };

    PrecisePath.prototype.addPointCommand = function(location) {
      R.commandManager.add(new Command.AddPoint(this, location), true);
    };

    PrecisePath.prototype.addPointAt = function(location, update) {
      if (update == null) {
        update = true;
      }
      if (!P.CurveLocation.prototype.isPrototypeOf(location)) {
        location = this.controlPath.getLocationAt(location);
      }
      return this.addPoint(location.index, location.point, location.offset, update);
    };

    PrecisePath.prototype.addPoint = function(index, point, offset, update) {
      var segment;
      if (update == null) {
        update = true;
      }
      segment = this.controlPath.insert(index + 1, new P.Point(point));
      if (this.data.smooth) {
        this.controlPath.smooth();
      } else {
        this.smoothPoint(segment, offset);
      }
      this.draw();
      if (!this.socketAction) {
        segment.selected = true;
        this.selectedSegment = segment;
        this.highlightSelectedPoint();
        if (update) {
          this.update('point');
        }
        R.socket.emit("bounce", {
          itemPk: this.pk,
          "function": "addPoint",
          "arguments": [index, point, offset, false]
        });
      }
      return segment;
    };

    PrecisePath.prototype.deletePointCommand = function() {
      if (this.selectedSegment == null) {
        return;
      }
      R.commandManager.add(new Command.DeletePoint(this, this.selectedSegment), true);
    };

    PrecisePath.prototype.deletePoint = function(segment, update) {
      var location;
      if (update == null) {
        update = true;
      }
      if (!segment) {
        return;
      }
      if (!P.Segment.prototype.isPrototypeOf(segment)) {
        segment = this.controlPath.segments[segment];
      }
      this.selectedSegment = segment.next != null ? segment.next : segment.previous;
      if (this.selectedSegment != null) {
        this.highlightSelectedPoint();
      }
      location = {
        index: segment.location.index - 1,
        point: segment.location.pointÂ 
      };
      segment.remove();
      if (this.controlPath.segments.length <= 1) {
        this.deleteCommand();
        return;
      }
      if (this.data.smooth) {
        this.controlPath.smooth();
      }
      this.draw();
      if (!this.socketAction) {
        R.tools.select.updateSelectionRectangle();
        if (update) {
          this.update('point');
        }
        R.socket.emit("bounce", {
          itemPk: this.pk,
          "function": "deletePoint",
          "arguments": [segment.index, false]
        });
      }
      return location;
    };

    PrecisePath.prototype.deleteSelectedPoint = function() {
      this.deletePoint(this.selectedSegment);
    };

    PrecisePath.prototype.modifySelectedPoint = function(position, handleIn, handleOut, fastDraw, update) {
      if (fastDraw == null) {
        fastDraw = true;
      }
      if (update == null) {
        update = true;
      }
      this.modifyPoint(this.selectedSegment, position, handleIn, handleOut, fastDraw, update);
    };

    PrecisePath.prototype.modifyPoint = function(segment, position, handleIn, handleOut, fastDraw, update) {
      if (fastDraw == null) {
        fastDraw = true;
      }
      if (update == null) {
        update = true;
      }
      if (!P.Segment.prototype.isPrototypeOf(segment)) {
        segment = this.controlPath.segments[segment];
      }
      segment.point = new P.Point(position);
      segment.handleIn = new P.Point(handleIn);
      segment.handleOut = new P.Point(handleOut);
      this.rectangle = this.controlPath.bounds.clone();
      R.tools.select.updateSelectionRectangle();
      this.draw(fastDraw);
      if (this.selectionHighlight == null) {
        this.highlightSelectedPoint();
      } else {
        this.updateSelectionHighlight();
      }
      if (!this.socketAction) {
        if (update) {
          this.update('segment');
        }
        R.socket.emit("bounce", {
          itemPk: this.pk,
          "function": "modifyPoint",
          "arguments": [segment.index, position, handleIn, handleOut, fastDraw, false]
        });
      }
    };

    PrecisePath.prototype.updateModifyPoint = function(event) {
      var handle, point, segment;
      segment = this.selectedSegment;
      handle = this.selectedHandle;
      if (handle != null) {
        if (Utils.Snap.getSnap() >= 1) {
          point = Utils.Snap.snap2D(event.point);
          handle.x = point.x - segment.point.x;
          handle.y = point.y - segment.point.y;
        } else {
          handle.x += event.delta.x;
          handle.y += event.delta.y;
        }
        if (segment.rtype === 'smooth' || (segment.rtype == null)) {
          if (handle === segment.handleOut && !segment.handleIn.isZero()) {
            if (!event.modifiers.shift) {
              segment.handleIn = segment.handleOut.normalize().multiply(-segment.handleIn.length);
            } else {
              segment.handleIn = segment.handleOut.multiply(-1);
            }
          }
          if (handle === segment.handleIn && !segment.handleOut.isZero()) {
            if (!event.modifiers.shift) {
              segment.handleOut = segment.handleIn.normalize().multiply(-segment.handleOut.length);
            } else {
              segment.handleOut = segment.handleIn.multiply(-1);
            }
          }
        }
      } else if (segment != null) {
        if (Utils.Snap.getSnap() >= 1) {
          point = Utils.Snap.snap2D(event.point);
          segment.point.x = point.x;
          segment.point.y = point.y;
        } else {
          segment.point.x += event.delta.x;
          segment.point.y += event.delta.y;
        }
      }
      Item.Lock.highlightValidity(this, null, true);
      this.modifyPoint(segment, segment.point, segment.handleIn, segment.handleOut, true, false);
    };

    PrecisePath.prototype.endModifyPoint = function(update) {
      var _ref;
      if (update) {
        if (this.data.smooth) {
          this.controlPath.smooth();
        }
        this.draw();
        this.rasterize();
        if ((_ref = this.selectionHighlight) != null) {
          _ref.bringToFront();
        }
        this.update('points');
      }
    };

    PrecisePath.prototype.modifyPointTypeCommand = function(rtype) {
      R.commandManager.add(new Command.ModifyPointType(this, this.selectedSegment, rtype), true);
    };

    PrecisePath.prototype.modifySelectedPointType = function(value, update) {
      if (update == null) {
        update = true;
      }
      if (this.selectedSegment == null) {
        return;
      }
      this.modifyPointType(this.selectedSegment, value, update);
    };

    PrecisePath.prototype.modifyPointType = function(segment, rtype, update) {
      if (update == null) {
        update = true;
      }
      if (!P.Segment.prototype.isPrototypeOf(segment)) {
        segment = this.controlPath.segments[segment];
      }
      if (this.data.smooth) {
        return;
      }
      this.selectedSegment.rtype = rtype;
      switch (rtype) {
        case 'corner':
          if (this.selectedSegment.linear = true) {
            this.selectedSegment.linear = false;
            this.selectedSegment.handleIn = this.selectedSegment.previous.point.subtract(this.selectedSegment.point).multiply(0.5);
            this.selectedSegment.handleOut = this.selectedSegment.next.point.subtract(this.selectedSegment.point).multiply(0.5);
          }
          break;
        case 'point':
          this.selectedSegment.linear = true;
          break;
        case 'smooth':
          this.smoothPoint(this.selectedSegment);
      }
      this.draw();
      this.highlightSelectedPoint();
      if (!this.socketAction) {
        if (update) {
          this.update('point');
        }
        R.socket.emit("bounce", {
          itemPk: this.pk,
          "function": "modifyPointType",
          "arguments": [segment.index, rtype, false]
        });
      }
    };

    PrecisePath.prototype.modifyControlPathCommand = function(previousPointsAndPlanet, newPointsAndPlanet) {
      R.commandManager.add(new Command.ModifyControlPath(this, previousPointsAndPlanet, newPointsAndPlanet), false);
    };

    PrecisePath.prototype.modifyControlPath = function(pointsAndPlanet, update) {
      var fullySelected, selected;
      if (update == null) {
        update = true;
      }
      selected = this.controlPath.selected;
      fullySelected = this.controlPath.fullySelected;
      this.controlPath.removeSegments();
      this.setControlPath(pointsAndPlanet.points, pointsAndPlanet.planet);
      this.controlPath.selected = selected;
      if (fullySelected) {
        this.controlPath.fullySelected = true;
      }
      this.deselectPoint();
      this.draw();
      if (!this.socketAction) {
        if (update) {
          this.update('point');
        }
        R.socket.emit("bounce", {
          itemPk: this.pk,
          "function": "modifyControlPath",
          "arguments": [pointsAndPlanet, false]
        });
      }
    };

    PrecisePath.prototype.setSmooth = function(smooth) {
      var previousPointsAndPlanet, segment, _i, _len, _ref;
      this.data.smooth = smooth;
      if (this.data.smooth) {
        previousPointsAndPlanet = this.getPointsAndPlanet();
        this.controlPath.smooth();
        this.controlPath.fullySelected = false;
        this.controlPath.selected = true;
        this.deselectPoint();
        _ref = this.controlPath.segments;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          segment = _ref[_i];
          segment.rtype = 'smooth';
        }
        this.draw();
        this.modifyControlPathCommand(previousPointsAndPlanet, this.getPointsAndPlanet());
      } else {
        this.controlPath.fullySelected = true;
        this.highlightSelectedPoint();
      }
    };

    PrecisePath.prototype.simplifyControlPath = function() {
      var previousPointsAndPlanet, _ref;
      previousPointsAndPlanet = this.getPointsAndPlanet();
      if ((_ref = this.controlPath) != null) {
        _ref.simplify();
      }
      this.draw();
      this.update();
      this.modifyControlPathCommand(previousPointsAndPlanet, this.getPointsAndPlanet());
    };

    PrecisePath.prototype.setParameter = function(name, value, updateGUI, update) {
      PrecisePath.__super__.setParameter.call(this, name, value, updateGUI, update);
    };

    PrecisePath.prototype.remove = function() {
      var _ref;
      if ((_ref = this.canvasRaster) != null) {
        _ref.remove();
      }
      this.canvasRaster = null;
      PrecisePath.__super__.remove.call(this);
    };

    return PrecisePath;

  })(Path);
  return PrecisePath;
});
