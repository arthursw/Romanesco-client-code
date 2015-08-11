// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  define(['Utils/Utils', 'UI/Controllers/ControllerManager'], function(Utils, ControllerManager) {
    var AddPointCommand, Command, CreateItemCommand, DeferredCommand, DeleteItemCommand, DeletePointCommand, DeselectCommand, DuplicateItemCommand, ItemCommand, ItemsCommand, ModifyControlPathCommand, ModifyPointCommand, ModifyPointTypeCommand, ModifySpeedCommand, ModifyTextCommand, MoveViewCommand, RotateCommand, ScaleCommand, SelectCommand, SelectionRectangleCommand, SetParameterCommand, TranslateCommand;
    Command = (function() {
      function Command(name) {
        this.click = __bind(this.click, this);
        this.liJ = $("<li>").text(name);
        this.liJ.click(this.click);
        this.id = Math.random();
        return;
      }

      Command.prototype.superDo = function() {
        this.done = true;
        this.liJ.addClass('done');
      };

      Command.prototype.superUndo = function() {
        this.done = false;
        this.liJ.removeClass('done');
      };

      Command.prototype["do"] = function() {
        this.superDo();
      };

      Command.prototype.undo = function() {
        this.superUndo();
      };

      Command.prototype.click = function() {
        R.commandManager.commandClicked(this);
      };

      Command.prototype.toggle = function() {
        if (this.done) {
          return this.undo();
        } else {
          return this["do"]();
        }
      };

      Command.prototype["delete"] = function() {
        this.liJ.remove();
      };

      Command.prototype.begin = function() {};

      Command.prototype.update = function() {};

      Command.prototype.end = function() {
        this.superDo();
      };

      return Command;

    })();
    ItemsCommand = (function(_super) {
      __extends(ItemsCommand, _super);

      function ItemsCommand(name, items) {
        ItemsCommand.__super__.constructor.call(this, name);
        this.items = this.mapItems(items);
        return;
      }

      ItemsCommand.prototype.mapItems = function(items) {
        var item, map, _i, _len;
        map = {};
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          map[item.getPk()] = item;
        }
        return map;
      };

      ItemsCommand.prototype.apply = function(method, args) {
        var item, pk, _ref;
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          item[method].apply(item, args);
        }
      };

      ItemsCommand.prototype.call = function() {
        var args, method;
        method = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        this.apply(method, args);
      };

      ItemsCommand.prototype.update = function() {};

      ItemsCommand.prototype.end = function() {
        if (this.positionIsValid()) {
          ItemsCommand.__super__.end.call(this);
        } else {
          this.undo();
        }
      };

      ItemsCommand.prototype.positionIsValid = function() {
        var item, pk, _ref;
        if (this.constructor.disablePositionCheck) {
          return true;
        }
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          if (!item.validatePosition()) {
            return false;
          }
        }
        return true;
      };

      ItemsCommand.prototype.unloadItem = function(item) {
        delete this.items[item.pk];
      };

      ItemsCommand.prototype.loadItem = function(item) {
        this.items[item.pk] = item;
      };

      ItemsCommand.prototype.setItemPk = function(id, pk) {
        this.items[pk] = this.items[id];
        delete this.items[id];
      };

      ItemsCommand.prototype.resurrectItem = function(item) {
        this.items[item.getPk()] = item;
      };

      ItemsCommand.prototype["delete"] = function() {
        var item, pk, _ref;
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          Utils.Array.remove(R.commandManager.itemToCommands[pk], this);
        }
        ItemsCommand.__super__["delete"].call(this);
      };

      return ItemsCommand;

    })(Command);
    ItemCommand = (function(_super) {
      __extends(ItemCommand, _super);

      function ItemCommand(name, items) {
        items = Utils.Array.isArray(items) ? items : [items];
        this.item = items[0];
        ItemCommand.__super__.constructor.call(this, name, items);
        return;
      }

      ItemCommand.prototype.unloadItem = function(item) {
        this.item = null;
        ItemCommand.__super__.unloadItem.call(this, item);
      };

      ItemCommand.prototype.loadItem = function(item) {
        this.item = item;
        ItemCommand.__super__.loadItem.call(this, item);
      };

      ItemCommand.prototype.resurrectItem = function(item) {
        this.item = item;
        ItemCommand.__super__.resurrectItem.call(this, item);
      };

      return ItemCommand;

    })(ItemsCommand);
    DeferredCommand = (function(_super) {
      __extends(DeferredCommand, _super);

      DeferredCommand.initialize = function(method) {
        this.method = method;
        this.Method = Utils.capitalizeFirstLetter(method);
        this.beginMethod = 'begin' + this.Method;
        this.updateMethod = 'update' + this.Method;
        this.endMethod = 'end' + this.Method;
      };

      function DeferredCommand(name, items) {
        DeferredCommand.__super__.constructor.call(this, name, items);
        return;
      }

      DeferredCommand.prototype.update = function() {};

      DeferredCommand.prototype.end = function() {
        DeferredCommand.__super__.end.call(this);
        if (!this.commandChanged()) {
          return;
        }
        R.commandManager.add(this);
        this.updateItems();
      };

      DeferredCommand.prototype.commandChanged = function() {};

      DeferredCommand.prototype.updateItems = function(type) {
        var args, item, pk, _ref;
        if (type == null) {
          type = this.updateType;
        }
        args = [];
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          item.addUpdateFunctionAndArguments(args, type);
        }
        Dajaxice.draw.multipleCalls(this.updateCallback, {
          functionsAndArguments: args
        });
      };

      DeferredCommand.prototype.updateCallback = function(results) {
        var result, _i, _len;
        for (_i = 0, _len = results.length; _i < _len; _i++) {
          result = results[_i];
          R.loader.checkError(result);
        }
      };

      return DeferredCommand;

    })(ItemCommand);
    SelectionRectangleCommand = (function(_super) {
      __extends(SelectionRectangleCommand, _super);

      SelectionRectangleCommand.create = function(items, state) {
        var command;
        command = new this(items);
        command.state = state;
        return command;
      };

      function SelectionRectangleCommand(items) {
        SelectionRectangleCommand.__super__.constructor.call(this, this.constructor.Method + ' items', items);
        this.updateType = this.constructor.method;
        return;
      }

      SelectionRectangleCommand.prototype.begin = function(event) {
        R.tools.select.selectionRectangle[this.constructor.beginMethod](event);
      };

      SelectionRectangleCommand.prototype.update = function(event) {
        R.tools.select.selectionRectangle[this.constructor.updateMethod](event);
        SelectionRectangleCommand.__super__.update.call(this, event);
      };

      SelectionRectangleCommand.prototype.updateSelectionRectangle = function(rotation) {
        R.tools.select.updateSelectionRectangle(rotation);
      };

      SelectionRectangleCommand.prototype.end = function(event) {
        this.state = R.tools.select.selectionRectangle[this.constructor.endMethod](event);
        SelectionRectangleCommand.__super__.end.call(this, event);
      };

      SelectionRectangleCommand.prototype["do"] = function() {
        this.apply(this.constructor.method, this.newState());
        this.updateSelectionRectangle();
        SelectionRectangleCommand.__super__["do"].call(this);
      };

      SelectionRectangleCommand.prototype.undo = function() {
        this.apply(this.constructor.method, this.previousState());
        this.updateSelectionRectangle();
        SelectionRectangleCommand.__super__.undo.call(this);
      };

      return SelectionRectangleCommand;

    })(DeferredCommand);
    ScaleCommand = (function(_super) {
      __extends(ScaleCommand, _super);

      function ScaleCommand() {
        return ScaleCommand.__super__.constructor.apply(this, arguments);
      }

      ScaleCommand.initialize('scale');

      ScaleCommand.method = 'setRectangle';

      ScaleCommand.prototype.getItemArray = function() {
        var item, pk, _ref;
        if (this.itemsArray != null) {
          return this.itemsArray;
        }
        this.itemsArray = [];
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          this.itemsArray.push(item);
        }
        return this.itemsArray;
      };

      ScaleCommand.prototype["do"] = function() {
        R.SelectionRectangle.setRectangle(this.getItemArray(), this.state.previous, this.state["new"], this.state.rotation, false);
        this.updateSelectionRectangle(this.state.rotation);
        this.superDo();
      };

      ScaleCommand.prototype.undo = function() {
        R.SelectionRectangle.setRectangle(this.getItemArray(), this.state["new"], this.state.previous, this.state.rotation, false);
        this.updateSelectionRectangle(this.state.rotation);
        this.superUndo();
      };

      ScaleCommand.prototype.commandChanged = function() {
        return !this.state["new"].equals(this.state.previous);
      };

      return ScaleCommand;

    })(SelectionRectangleCommand);
    RotateCommand = (function(_super) {
      __extends(RotateCommand, _super);

      function RotateCommand() {
        return RotateCommand.__super__.constructor.apply(this, arguments);
      }

      RotateCommand.initialize('rotate');

      RotateCommand.prototype.newState = function() {
        return [this.state.delta, this.state.center];
      };

      RotateCommand.prototype.previousState = function() {
        return [-this.state.delta, this.state.center];
      };

      RotateCommand.prototype.commandChanged = function() {
        return this.state.delta !== 0;
      };

      return RotateCommand;

    })(SelectionRectangleCommand);
    TranslateCommand = (function(_super) {
      __extends(TranslateCommand, _super);

      function TranslateCommand() {
        return TranslateCommand.__super__.constructor.apply(this, arguments);
      }

      TranslateCommand.initialize('translate');

      TranslateCommand.prototype.newState = function() {
        return [this.state.delta];
      };

      TranslateCommand.prototype.previousState = function() {
        return [this.state.delta.multiply(-1)];
      };

      TranslateCommand.prototype.commandChanged = function() {
        return !this.state.delta.isZero();
      };

      return TranslateCommand;

    })(SelectionRectangleCommand);

    /*
    		class BeforeAfterCommand extends DeferredCommand
    
    			@initialize: (method, @name)->
    				super(method)
    				return
    
    			constructor: (name, item)->
    				super(name or @constructor.name, item)
    				@beforeArgs = @getState()
    				return
    
    			getState: ()->
    				return
    
    			update: ()->
    				@apply(@constructor.updateMethod, arguments.push(true))
    				return
    
    			commandChanged: ()->
    				for beforeArg, i in @beforeArgs
    					if beforeArg != @afterArgs[i] then return false
    				return true
    
    			do: ()->
    				@apply(@constructor.method, @afterArgs)
    				super()
    				return
    
    			undo: ()->
    				@afterArgs = @getState()
    				@apply(@constructor.method, @beforeArgs)
    				super()
    				return
     */
    ModifyPointCommand = (function(_super) {
      __extends(ModifyPointCommand, _super);

      function ModifyPointCommand(item) {
        ModifyPointCommand.__super__.constructor.call(this, 'Modify point', item);
        this.index = this.item.selectedSegment.index;
        this.previousPoint = this.getPoint();
        this.updateType = 'points';
        return;
      }

      ModifyPointCommand.prototype.update = function(event) {
        this.item.updateModifyPoint(event);
      };

      ModifyPointCommand.prototype.end = function(event) {
        this.item.endModifyPoint(event);
        this.newPoint = this.getPoint();
        ModifyPointCommand.__super__.end.call(this, event);
      };

      ModifyPointCommand.prototype["do"] = function() {
        this.item.modifyPoint.apply(this.item, this.newPoint);
        ModifyPointCommand.__super__["do"].call(this);
      };

      ModifyPointCommand.prototype.undo = function() {
        this.item.modifyPoint.apply(this.item, this.previousPoint);
        ModifyPointCommand.__super__.undo.call(this);
      };

      ModifyPointCommand.prototype.getPoint = function() {
        var segment;
        segment = this.item.controlPath.segments[this.index];
        return [segment.index, segment.point.clone(), segment.handleIn.clone(), segment.handleOut.clone(), true];
      };

      ModifyPointCommand.prototype.commandChanged = function() {
        var i, _i;
        for (i = _i = 1; _i <= 3; i = ++_i) {
          if (!this.previousPoint[i].equals(this.newPoint[i])) {
            return true;
          }
        }
        return false;
      };

      return ModifyPointCommand;

    })(DeferredCommand);
    ModifySpeedCommand = (function(_super) {
      __extends(ModifySpeedCommand, _super);

      function ModifySpeedCommand(item) {
        ModifySpeedCommand.__super__.constructor.call(this, 'Modify speed', item);
        this.previousSpeeds = this.item.speeds.slice();
        this.updateType = 'speed';
        return;
      }

      ModifySpeedCommand.prototype.update = function(event) {
        this.item.updateModifySpeed(event);
      };

      ModifySpeedCommand.prototype.end = function(event) {
        this.item.endModifySpeed(event);
        ModifySpeedCommand.__super__.end.call(this, event);
      };

      ModifySpeedCommand.prototype["do"] = function() {
        this.item.modifySpeed(this.newSpeeds, true);
        this.updateItems('speed');
        ModifySpeedCommand.__super__["do"].call(this);
      };

      ModifySpeedCommand.prototype.undo = function() {
        if (this.newSpeeds == null) {
          this.newSpeeds = this.item.speeds.slice();
        }
        this.item.modifySpeed(this.previousSpeeds, true);
        this.updateItems('speed');
        ModifySpeedCommand.__super__.undo.call(this);
      };

      ModifySpeedCommand.prototype.commandChanged = function() {
        return true;
      };

      return ModifySpeedCommand;

    })(DeferredCommand);
    SetParameterCommand = (function(_super) {
      __extends(SetParameterCommand, _super);

      function SetParameterCommand(items, args) {
        var item, pk, _ref;
        this.name = args[0];
        this.previousValue = args[1];
        SetParameterCommand.__super__.constructor.call(this, 'Change item parameter "' + this.name + '"', items);
        this.updateType = 'parameters';
        this.previousValues = {};
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          this.previousValues[pk] = item.data[this.name];
        }
        return;
      }

      SetParameterCommand.prototype["do"] = function() {
        var item, pk, _ref;
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          item.setParameter(this.name, this.newValue);
        }
        R.controllerManager.updateController(this.name, this.newValue);
        this.updateItems(this.name);
        SetParameterCommand.__super__["do"].call(this);
      };

      SetParameterCommand.prototype.undo = function() {
        var item, pk, _ref;
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          item.setParameter(this.name, this.previousValues[pk]);
        }
        R.controllerManager.updateController(this.name, this.previousValue);
        this.updateItems(this.name);
        SetParameterCommand.__super__.undo.call(this);
      };

      SetParameterCommand.prototype.update = function(name, value) {
        var item, pk, _ref;
        this.newValue = value;
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          item.setParameter(name, value);
        }
      };

      SetParameterCommand.prototype.commandChanged = function() {
        return true;
      };

      return SetParameterCommand;

    })(DeferredCommand);
    AddPointCommand = (function(_super) {
      __extends(AddPointCommand, _super);

      function AddPointCommand(item, location, name) {
        this.location = location;
        if (name == null) {
          name = 'Add point on item';
        }
        AddPointCommand.__super__.constructor.call(this, name, [item]);
        return;
      }

      AddPointCommand.prototype.addPoint = function(update) {
        if (update == null) {
          update = true;
        }
        this.segment = this.item.addPointAt(this.location, update);
      };

      AddPointCommand.prototype.deletePoint = function() {
        this.location = this.item.deletePoint(this.segment);
      };

      AddPointCommand.prototype["do"] = function() {
        this.addPoint();
        AddPointCommand.__super__["do"].call(this);
      };

      AddPointCommand.prototype.undo = function() {
        this.deletePoint();
        AddPointCommand.__super__.undo.call(this);
      };

      return AddPointCommand;

    })(ItemCommand);
    DeletePointCommand = (function(_super) {
      __extends(DeletePointCommand, _super);

      function DeletePointCommand(item, segment) {
        this.segment = segment;
        DeletePointCommand.__super__.constructor.call(this, item, this.segment, 'Delete point on item');
      }

      DeletePointCommand.prototype["do"] = function() {
        this.previousPosition = new P.Point(this.segment.point);
        this.previousHandleIn = new P.Point(this.segment.handleIn);
        this.previousHandleOut = new P.Point(this.segment.handleOut);
        this.deletePoint();
        this.superDo();
      };

      DeletePointCommand.prototype.undo = function() {
        this.addPoint(false);
        this.item.modifyPoint(this.segment, this.previousPosition, this.previousHandleIn, this.previousHandleOut);
        this.superUndo();
      };

      return DeletePointCommand;

    })(AddPointCommand);
    ModifyPointTypeCommand = (function(_super) {
      __extends(ModifyPointTypeCommand, _super);

      function ModifyPointTypeCommand(item, segment, rtype) {
        this.segment = segment;
        this.rtype = rtype;
        this.previousRType = this.segment.rtype;
        this.previousPosition = new P.Point(this.segment.point);
        this.previousHandleIn = new P.Point(this.segment.handleIn);
        this.previousHandleOut = new P.Point(this.segment.handleOut);
        ModifyPointTypeCommand.__super__.constructor.call(this, 'Change point type on item', [item]);
        return;
      }

      ModifyPointTypeCommand.prototype["do"] = function() {
        this.item.modifyPointType(this.segment, this.rtype);
        ModifyPointTypeCommand.__super__["do"].call(this);
      };

      ModifyPointTypeCommand.prototype.undo = function() {
        this.item.modifyPointType(this.segment, this.previousRType, true, false);
        this.item.modifyPoint(this.segment, this.previousPosition, this.previousHandleIn, this.previousHandleOut);
        ModifyPointTypeCommand.__super__.undo.call(this);
      };

      return ModifyPointTypeCommand;

    })(ItemCommand);

    /* --- Custom command for all kinds of command which modifiy the path --- */
    ModifyControlPathCommand = (function(_super) {
      __extends(ModifyControlPathCommand, _super);

      function ModifyControlPathCommand(item, previousPointsAndPlanet, newPointsAndPlanet) {
        this.previousPointsAndPlanet = previousPointsAndPlanet;
        this.newPointsAndPlanet = newPointsAndPlanet;
        ModifyControlPathCommand.__super__.constructor.call(this, 'Modify path', item);
        this.superDo();
        return;
      }

      ModifyControlPathCommand.prototype["do"] = function() {
        this.item.modifyControlPath(this.newPointsAndPlanet);
        ModifyControlPathCommand.__super__["do"].call(this);
      };

      ModifyControlPathCommand.prototype.undo = function() {
        this.item.modifyControlPath(this.previousPointsAndPlanet);
        ModifyControlPathCommand.__super__.undo.call(this);
      };

      return ModifyControlPathCommand;

    })(ItemCommand);
    MoveViewCommand = (function(_super) {
      __extends(MoveViewCommand, _super);

      function MoveViewCommand(previousPosition, newPosition) {
        this.previousPosition = previousPosition;
        this.newPosition = newPosition;
        MoveViewCommand.__super__.constructor.call(this, "Move view");
        this.superDo();
        return;
      }

      MoveViewCommand.prototype["do"] = function() {
        var somethingToLoad;
        somethingToLoad = R.view.moveBy(this.newPosition.subtract(this.previousPosition), false);
        MoveViewCommand.__super__["do"].call(this);
        return somethingToLoad;
      };

      MoveViewCommand.prototype.undo = function() {
        var somethingToLoad;
        somethingToLoad = R.view.moveBy(this.previousPosition.subtract(this.newPosition), false);
        MoveViewCommand.__super__.undo.call(this);
        return somethingToLoad;
      };

      return MoveViewCommand;

    })(Command);
    SelectCommand = (function(_super) {
      __extends(SelectCommand, _super);

      function SelectCommand(items, name) {
        SelectCommand.__super__.constructor.call(this, name || "Select items", items);
        return;
      }

      SelectCommand.prototype.selectItems = function() {
        var item, pk, _ref;
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          item.select();
        }
      };

      SelectCommand.prototype.deselectItems = function() {
        var item, pk, _ref;
        _ref = this.items;
        for (pk in _ref) {
          item = _ref[pk];
          item.deselect();
        }
      };

      SelectCommand.prototype["do"] = function() {
        this.selectItems();
        SelectCommand.__super__["do"].call(this);
      };

      SelectCommand.prototype.undo = function() {
        this.deselectItems();
        SelectCommand.__super__.undo.call(this);
      };

      return SelectCommand;

    })(ItemsCommand);
    DeselectCommand = (function(_super) {
      __extends(DeselectCommand, _super);

      function DeselectCommand(items) {
        DeselectCommand.__super__.constructor.call(this, items || R.selectedItems.slice(), 'Deselect items');
        return;
      }

      DeselectCommand.prototype["do"] = function() {
        this.deselectItems();
        this.superDo();
      };

      DeselectCommand.prototype.undo = function() {
        this.selectItems();
        this.superUndo();
      };

      return DeselectCommand;

    })(SelectCommand);
    CreateItemCommand = (function(_super) {
      __extends(CreateItemCommand, _super);

      function CreateItemCommand(item, name) {
        if (name == null) {
          name = 'Create item';
        }
        this.itemConstructor = item.constructor;
        CreateItemCommand.__super__.constructor.call(this, name, item);
        this.superDo();
        return;
      }

      CreateItemCommand.prototype.duplicateItem = function() {
        this.item = this.itemConstructor.create(this.duplicateData);
        R.commandManager.resurrectItem(this.duplicateData.pk, this.item);
        this.item.select();
      };

      CreateItemCommand.prototype.deleteItem = function() {
        this.duplicateData = this.item.getDuplicateData();
        this.item["delete"]();
        this.item = null;
      };

      CreateItemCommand.prototype["do"] = function() {
        this.duplicateItem();
        CreateItemCommand.__super__["do"].call(this);
      };

      CreateItemCommand.prototype.undo = function() {
        this.deleteItem();
        CreateItemCommand.__super__.undo.call(this);
      };

      return CreateItemCommand;

    })(ItemCommand);
    DeleteItemCommand = (function(_super) {
      __extends(DeleteItemCommand, _super);

      function DeleteItemCommand(item) {
        DeleteItemCommand.__super__.constructor.call(this, item, 'Delete item');
      }

      DeleteItemCommand.prototype["do"] = function() {
        this.deleteItem();
        this.superDo();
      };

      DeleteItemCommand.prototype.undo = function() {
        this.duplicateItem();
        this.superUndo();
      };

      return DeleteItemCommand;

    })(CreateItemCommand);
    DuplicateItemCommand = (function(_super) {
      __extends(DuplicateItemCommand, _super);

      function DuplicateItemCommand(item) {
        this.duplicateData = item.getDuplicateData();
        DuplicateItemCommand.__super__.constructor.call(this, item, 'Duplicate item');
      }

      return DuplicateItemCommand;

    })(CreateItemCommand);
    ModifyTextCommand = (function(_super) {
      __extends(ModifyTextCommand, _super);

      function ModifyTextCommand(items, args) {
        ModifyTextCommand.__super__.constructor.call(this, "Change text", items);
        this.newText = args[0];
        this.previousText = this.item.data.message;
        return;
      }

      ModifyTextCommand.prototype["do"] = function() {
        this.item.data.message = this.newText;
        this.item.contentJ.val(this.newText);
        ModifyTextCommand.__super__["do"].call(this);
      };

      ModifyTextCommand.prototype.undo = function() {
        this.item.data.message = this.previousText;
        this.item.contentJ.val(this.previousText);
        ModifyTextCommand.__super__.undo.call(this);
      };

      ModifyTextCommand.prototype.update = function(newText) {
        this.newText = newText;
        this.item.setText(this.newText, false);
      };

      ModifyTextCommand.prototype.commandChanged = function() {
        return this.newText !== this.previousText;
      };

      return ModifyTextCommand;

    })(DeferredCommand);
    R.Command = Command;
    Command.Scale = ScaleCommand;
    Command.Rotate = RotateCommand;
    Command.Translate = TranslateCommand;
    Command.ModifyPoint = ModifyPointCommand;
    Command.ModifySpeed = ModifySpeedCommand;
    Command.AddPoint = AddPointCommand;
    Command.DeletePoint = DeletePointCommand;
    Command.ModifyPointType = ModifyPointTypeCommand;
    Command.ModifyControlPath = ModifyControlPathCommand;
    Command.SetParameter = SetParameterCommand;
    Command.ModifyText = ModifyTextCommand;
    Command.CreateItem = CreateItemCommand;
    Command.DeleteItem = DeleteItemCommand;
    Command.DuplicateItem = DuplicateItemCommand;
    Command.Select = SelectCommand;
    Command.Deselect = DeselectCommand;
    Command.MoveView = MoveViewCommand;
    return Command;
  });

}).call(this);
