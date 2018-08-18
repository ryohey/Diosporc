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
    when 0
      if not toObj? and not fromObj?
        actionRouter.addPort pos
    when 2
      if fromObj instanceof PortView and toObj instanceof PortView and fromObj isnt toObj
        actionRouter.addLink fromObj.port.id, toObj.port.id

defaultFuncPos = 
  x: 220
  y: 120

getJSONSync = (url) ->
  result = null
  $.ajax
    type: "GET",
    url: url,
    dataType: "json",
    success: (d) -> result = d,
    async: false
  result

addFunc = (json) ->   
  for n in json.nodes
    if n.script?
      f = new Function n.script[0], n.script[1]
      f = actionRouter.addFunc n.position, f, 1, n.name

    else if n.src?
      addFunc getJSONSync "files/#{n.src}"
    else if n.value?
      actionRouter.addPort pos, defaultFuncPos

  for e in json.edges
    actionRouter.addLinks e

$("#button-if2").on "click", ->
  $.getJSON "files/if.json", (d) -> addFunc d

$("#button-plus").on "click", ->
  $.getJSON "files/plus.json", (d) -> addFunc d

$("#button-minus").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a - b), 1, "-"

$("#button-multi").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a * b), 1, "*"
  
$("#button-div").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> a / b), 1, "/"

boolToNum = (b) -> if b then 1 else 0

$("#button-equal").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> boolToNum(a is b)), 1, "="

$("#button-and").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> boolToNum(a and b)), 1, "and"

$("#button-or").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> boolToNum(a or b)), 1, "or"

$("#button-greater").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> boolToNum(a > b)), 1, ">"

$("#button-less").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a, b) -> boolToNum(a < b)), 1, "<"

$("#button-if").on "click", ->
  actionRouter.addFunc defaultFuncPos, (flag, a, b) -> 
    if flag then a else b
  , 1, "if"

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

$("#button-tochar").on "click", ->
  actionRouter.addFunc defaultFuncPos, ((a) -> String.fromCharCode(a)), 1, "toChar"
