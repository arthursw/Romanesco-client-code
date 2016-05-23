define ['UI/Button', 'UI/Code'], (Button) ->

    ModuleLoader = {}

    buttons = [
        { name: 'Precise path', description: "This path offers precise controls, one can modify points along with their handles and their type.", iconURL: 'static/images/icons/inverted/editCurve.png', file: "Items/Paths/PrecisePaths/PrecisePath", category: undefined, favorite: true, order: 8 }
        { name: 'Dynamic brush', description: "The stroke width is function of the drawing speed: the faster the wider.", iconURL: undefined, file: "Items/Paths/PrecisePaths/SpeedPaths/DynamicBrush", category: undefined, favorite: true, order: 9 }
        { name: 'Thickness path', description: "The stroke width is function of the drawing speed: the faster the wider.", iconURL: 'static/images/icons/inverted/rollerBrush.png', file: "Items/Paths/PrecisePaths/SpeedPaths/ThicknessPath", category: undefined, favorite: true, order: 10 }
        { name: 'Ellipse', description: "Simple ellipse, circle by default (use shift key to draw an ellipse).\nUse special key (command on a mac, control otherwise) to avoid the shape to be centered on the first point.", iconURL: 'static/images/icons/inverted/circle.png', file: "Items/Paths/Shapes/EllipseShape", category: 'Shape', favorite: true, order: 11 }
        { name: 'Rectangle', description: "Simple rectangle, square by default (use shift key to draw a rectangle) which can have rounded corners.\nUse special key (command on a mac, control otherwise) to center the shape on the first point.", iconURL: 'static/images/icons/inverted/rectangle.png', file: "Items/Paths/Shapes/RectangleShape", category: 'Shape', favorite: true, order: 12 }

        { name: 'Geometric lines', description: "Draws a line between pair of points which are close enough.", iconURL: 'static/images/icons/inverted/links.png', file: "Items/Paths/PrecisePaths/GeometricLines", category: undefined }
        { name: 'Meander', description: "As Karl Kerenyi pointed out, \"the meander is the figure of a labyrinth in linear form\".\nA meander or meandros (Greek: ÎÎ±Î¯Î±Î½Î´ÏÎ¿Ï) is a decorative border constructed from a continuous line, shaped into a repeated motif.\nSuch a design is also called the Greek fret or Greek key design, although these are modern designations.\n(source: http://en.wikipedia.org/wiki/Meander_(art))", iconURL: 'static/images/icons/inverted/squareSpiral.png', file: "Items/Paths/PrecisePaths/Meander", category: undefined }
        { name: 'Spiral', description: "The spiral shape can have an intern radius, and a custom number of sides.", iconURL: 'static/images/icons/inverted/spiral.png', file: "Items/Paths/Shapes/SpiralShape", category: 'Shape/Animated/Spiral' }
        { name: 'Star', description: "Draws a star which can be animated (the color changes and it rotates).", iconURL: 'static/images/icons/inverted/star.png', file: "Items/Paths/Shapes/StarShape", category: 'Shape/Animated' }
        { name: 'Shape path', description: "Draws rectangles or ellipses along the path. The size of the shapes is function of the drawing speed.", iconURL: undefined, file: "Items/Paths/PrecisePaths/SpeedPaths/ShapePath", category: undefined }
        { name: 'Grid path', description: "Draws a grid along the path, the thickness of the grid being function of the speed of the drawing.", iconURL: undefined, file: "Items/Paths/PrecisePaths/SpeedPaths/GridPath", category: undefined }

        { name: 'Pen', description: "The classic and basic pen tool", iconURL: undefined, file: "Items/Paths/Path", category: undefined }
        { name: 'Paint brush', description: "Paints a thick stroke with customable blur effects.", iconURL: 'static/images/icons/inverted/brush.png', file: "Items/Paths/PrecisePaths/PainBrush", category: undefined }
        { name: 'Paint gun', description: "The stroke width is function of the drawing speed: the faster the wider.", iconURL: undefined, file: "Items/Paths/PrecisePaths/SpeedPaths/PaintGun", category: undefined }

        # { name: 'Speed path', description: "This path offers speed.", iconURL: undefined, file: "Items/Paths/PrecisePaths/SpeedPaths/SpeedPath", category: undefined }
        { name: 'Checkpoint', description: "Draw checkpoints on a lock with a Racer to create a race\n(the players must go through each checkpoint as fast as possible, with the car tool).", iconURL: undefined, file: "Items/Paths/Shapes/Checkpoint", category: 'Video game/Racer' }
        { name: 'Medusa', description: "Creates a bunch of aniamted Medusa.", iconURL: undefined, file: "Items/Paths/Shapes/Medusa", category: undefined }
        # { name: 'Shape', description: "Base shape class", iconURL: undefined, file: "Items/Paths/Shapes/Shape", category: undefined }
        { name: 'Stripe animation', description: "Creates a stripe animation from a set sequence of image.", iconURL: undefined, file: "Items/Paths/Shapes/StripeAnimation", category: undefined }
        { name: 'Space path', description: "Precise path which sends draw commands to spacebrew.", iconURL: undefined, file: "Items/Paths/PrecisePaths/SpacePath", category: 'Spacebrew' }
        { name: 'Space colony', description: "Space colony algorithm.", iconURL: undefined, file: "Items/Paths/Shapes/SpaceColony", category: 'Spacebrew' }
        { name: 'Square fractal', description: "Square fractal.", iconURL: undefined, file: "Items/Paths/Shapes/SquareFractal", category: undefined }
        { name: 'Vectorizer', description: "Creates a vectorized version of an image.", iconURL: undefined, file: "Items/Paths/Shapes/Vectorizer", category: undefined }
        { name: 'Striper', description: "Creates stripes from SVG", iconURL: undefined, file: "Items/Paths/Shapes/Striper", category: undefined }
    ]

    ModuleLoader.initialize = ()->
        for button in buttons
            b = new Button(button)
        return

    ModuleLoader.load = (name, callback)->
        for button in buttons
            if button.name == name
                require([button.file], callback)
                return
        console.log 'unknown module: ' + name
        return

    return ModuleLoader
