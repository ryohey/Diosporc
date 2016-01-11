conf = require "./config.coffee"
Point = require "./point.coffee"
Size = require "./size.coffee"
Rect = require "./rect.coffee"
Machine = require "./machine.coffee"
Port = require "./port.coffee"
Func = require "./func.coffee"
PointerFunc = require "./pointer_func.coffee"
PortView = require "./port_view.coffee"
FuncView = require "./func_view.coffee"
ViewController = require "./view_controller.coffee"
ActionRouter = require "./action_router.coffee"

##

width = 960
height = 6400
GRID_SIZE = conf.gridSize
FRAME_EDGE_SIZE = 3
FUNC_RADIUS = GRID_SIZE / 3
MEMORY_COLS = Math.round(width / GRID_SIZE)
MEMORY_ROWS = Math.round(height / GRID_SIZE)

canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"
stage = new createjs.Stage "canvas"

createjs.Ticker.setFPS 60
createjs.Ticker.addEventListener "tick", stage

frames = []

DragState = 
  None: 0
  Down: 1
  Move: 2

TargetType =
  None: 0
  Frame: 10
  FrameEdge: 11
  Canvas: 20
  Func: 30

dragEvent = 
  state: DragState.None
  targetType: TargetType.None
  target: null
  button: 0
  moved: false
  start: new Point(0, 0)
  current: new Point(0, 0)

##

viewController = new ViewController()
stage.addChild viewController.view

machine = new Machine width, height
machine.onPortValueChanged = viewController.onPortValueChanged

actionRouter = new ActionRouter viewController, machine
ActionRouter.instance = actionRouter

actionRouter.addPort
  x: 0
  y: 0

document.stage = stage

##

fromObj = null

# do not show context menu on canvas
canvas.oncontextmenu = (e) -> e.preventDefault()

canvas.onmousedown = (e) ->
  fromObj = stage.getObjectUnderPoint e.layerX, e.layerY, 1

canvas.onmousemove = (e) ->

canvas.onmouseup = (e) ->
  toObj = stage.getObjectUnderPoint e.layerX, e.layerY, 1
  pos = 
    x: e.layerX
    y: e.layerY

  switch e.button
    when 1
      actionRouter.addFunc pos, (a, b) -> a + b
    when 2
      if fromObj instanceof PortView and toObj instanceof PortView
        actionRouter.addLink fromObj.port, toObj.port

defaultFuncPos = 
  x: 220
  y: 120

$("#button-plus").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a + b), 1, "+"

$("#button-minus").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a - b), 1, "-"

$("#button-multi").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a * b), 1, "*"

$("#button-equal").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a is b), 1, "="

$("#button-greater").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a > b), 1, ">"

$("#button-less").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a < b), 1, "<"

$("#button-if").on "click", ->
  actionRouter.addFunc defaultFuncPos, (a, b) -> 
    if b then [a, null] else [null, a]
  , 2, "if"

$("#button-const").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((_) -> 1), 1, "const"

$("#button-alloc").on "click", ->
  actionRouter.addAllocFunc defaultFuncPos

$("#button-pointer").on "click", ->
  actionRouter.addPointerFunc defaultFuncPos

$("#button-step").on "click", ->
  p = machine.ports[0]
  p.setValue p.getValue() + 1

$("#button-string").on "click", ->
  actionRouter.addPortFromString defaultFuncPos, "Hello, world!"

$("#button-stdout").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a) -> console.log(a)), 0, "stdout"
