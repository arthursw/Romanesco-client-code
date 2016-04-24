// Generated by CoffeeScript 1.7.1
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['Items/Paths/Shapes/Shape', 'Spacebrew'], function(Shape, spacebrew) {
    var SquareFractal;
    SquareFractal = (function(_super) {
      __extends(SquareFractal, _super);

      function SquareFractal() {
        return SquareFractal.__super__.constructor.apply(this, arguments);
      }

      SquareFractal.Shape = P.Path.Rectangle;

      SquareFractal.label = 'Square fractal';

      SquareFractal.description = "Square fractal.";

      SquareFractal.squareByDefault = true;

      SquareFractal.initializeParameters = function() {
        var parameters;
        parameters = SquareFractal.__super__.constructor.initializeParameters.call(this);
        if (parameters['Parameters'] == null) {
          parameters['Parameters'] = {};
        }
        parameters['Parameters'].depth = {
          type: 'slider',
          label: 'Depth',
          min: 1,
          max: 8,
          "default": 5
        };
        return parameters;
      };

      SquareFractal.parameters = SquareFractal.initializeParameters();

      SquareFractal.createTool(SquareFractal);

      SquareFractal.prototype.createShape = function() {
        SquareFractal.__super__.createShape.call(this);
        this.drawSquare(this.rectangle, this.data.depth);
      };

      SquareFractal.prototype.drawSquare = function(rectangle, n) {
        var halfSize, size, square;
        square = this.addPath(paper.Path.Rectangle(rectangle));
        n--;
        if (n === 0) {
          return;
        }
        size = rectangle.size.divide(2.05);
        halfSize = size.multiply(0.5);
        this.drawSquare(new paper.Rectangle(rectangle.topLeft.subtract(halfSize), size), n);
        this.drawSquare(new paper.Rectangle(rectangle.topRight.subtract(halfSize), size), n);
        this.drawSquare(new paper.Rectangle(rectangle.bottomLeft.subtract(halfSize), size), n);
        this.drawSquare(new paper.Rectangle(rectangle.bottomRight.subtract(halfSize), size), n);
      };

      return SquareFractal;

    })(Shape);
    return SquareFractal;
  });

}).call(this);
