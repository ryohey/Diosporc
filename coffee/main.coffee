conf = require "./config.coffee"
Point = require "./point.coffee"
Size = require "./size.coffee"
Rect = require "./rect.coffee"
Machine = require "./machine.coffee"
Port = require "./port.coffee"
Func = require "./func.coffee"
PortView = require "./port_view.coffee"
FuncView = require "./func_view.coffee"
ViewController = require "./view_controller.coffee"
ActionRouter = require "./action_router.coffee"

width = 960
height = 500
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

$ = (q) -> document.querySelector(q)

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

actionRouter.addPort
  x: 0
  y: 0

document.stage = stage

##

fromPort = null
toPort = null

canvas.onmousedown = (e) ->
  obj = stage.getObjectUnderPoint e.layerX, e.layerY, 1
  if e.button is 2 and obj instanceof PortView
    fromPort = obj.port
  console.log "start: #{obj}"

canvas.onmousemove = (e) ->

canvas.onmouseup = (e) ->
  obj = stage.getObjectUnderPoint e.layerX, e.layerY, 1

  switch e.button
    when 0
      actionRouter.addPort
        x: e.layerX
        y: e.layerY
    when 2
      if fromPort? and obj instanceof PortView
        toPort = obj.port
        actionRouter.addLink fromPort, toPort

count = 0

setInterval ->
  p = machine.ports[0]
  p.setValue count++
, 1000

###

drawFrames = ->
  drawFrame f for f in frames

drawLinks = ->
  for fromPort in machine.allPorts()
    for toPort in fromPort.outPorts
      drawLink fromPort.getOutputPosition(), 
               toPort.getInputPosition()

drawDrag = ->
  return if dragEvent?.state isnt DragState.Move
  if dragEvent.button isnt 0
    drawLinkPreview dragEvent
    return
  switch dragEvent.targetType
    when TargetType.Canvas
      drawFramePreview dragEvent
    when TargetType.Func
      drawDragFuncPreview dragEvent
    when TargetType.Frame
      drawDragFramePreview dragEvent
    when TargetType.FrameEdge
      resizeFramePreview dragEvent

redraw = ->
  rect = canvas.getBoundingClientRect()
  ctx.clearRect 0, 0, rect.width, rect.height
  stage.update()
  drawFrames()
  drawLinks()
  drawDrag()

getTarget = (pos) ->
  frame = findFrameContainsPoint pos
  port = null

  type = TargetType.Canvas
  target = null

  if frame?
    target = frame
    if isFrameEdge pos, frame
      type = TargetType.FrameEdge
    else
      type = TargetType.Frame
  else if port?
    target = port
    if port.parent instanceof Func
      type = TargetType.Func

  [type, target]

findFrameContainsPoint = (p, margin = FRAME_EDGE_SIZE) ->
  _.find frames, (f) -> 
    f.inset(-margin, -margin).contains p

# point, frame
isFrameEdge = (p, f) ->
  a = f.inset(-FRAME_EDGE_SIZE, -FRAME_EDGE_SIZE).contains p
  b = f.inset(FRAME_EDGE_SIZE, FRAME_EDGE_SIZE).contains p
  a and not b

addFrame = (rect) ->
  frames.push rect

addFuncLink = (memoryIndex, funcIndex) ->
  funcLinks[memoryIndex] ?= []
  funcLinks[memoryIndex].push funcIndex

drawLinkPreview = (dragEvent) ->
  drawLink dragEvent.start, 
           dragEvent.current,
           "rgba(0, 0, 0, 0.2)"

drawFramePreview = (dragEvent) ->
  size = Size.fromPoint dragEvent.current.sub(dragEvent.start)

  drawFrame Rect.fromPoint(dragEvent.start, size)
  , "rgba(0, 0, 0, 0.2)"

resizeFramePreview = (dragEvent) ->
  size = Size.fromPoint dragEvent.current.sub(dragEvent.target.point())

  drawFrame Rect.fromPoint(dragEvent.target, size)
  , "rgba(0, 0, 0, 0.2)"

drawDragFramePreview = (dragEvent) ->
  pos = dragEvent.current.add dragEvent.target.point().sub(dragEvent.start)

  drawFrame Rect.fromPoint(pos, dragEvent.target)
  , "rgba(0, 0, 0, 0.2)"

drawDragFuncPreview = (dragEvent) ->
  f = new Func dragEvent.target.parent.func
  f.view.x = dragEvent.current.x
  f.view.y = dragEvent.current.y
  f.view.draw ctx

cursorForTargetType = (type) ->
  switch type
    when TargetType.Canvas
      "default"
    when TargetType.Func
      "move"
    when TargetType.Frame
      "move"
    when TargetType.FrameEdge
      "se-resize"

# change cursor over canvas when dragging
canvas.onselectstart = -> false

canvas.onmousedown = (e) ->
  pos = new Point(e.layerX, e.layerY)
  dragEvent.start = pos
  dragEvent.state = DragState.Down
  dragEvent.button = e.button

  [targetType, target] = getTarget pos
  if target?
    dragEvent.target = target
    dragEvent.targetType = targetType
  else
    port = machine.portContainsPoint pos
    dragEvent.target = port
    if port.parent instanceof Memory
      dragEvent.targetType = TargetType.Canvas
    else if port.parent instanceof Func
      dragEvent.targetType = TargetType.Func

canvas.onmousemove = (e) ->
  pos = new Point(e.layerX, e.layerY)

  #change cursor
  if dragEvent.state is DragState.None
    canvas.style.cursor = cursorForTargetType getTarget(pos)[0]
    return 
  else if e.button is 0 # left click
    canvas.style.cursor = cursorForTargetType dragEvent.targetType
  else
    canvas.style.cursor = "default"

  dragEvent.state = DragState.Move
  dragEvent.current = pos

canvas.onmouseup = (e) ->
  if e.button is 0
    switch dragEvent.state
      when DragState.Down
        # on click
        switch dragEvent.targetType
          when TargetType.Canvas
            func = new Func (a, b) -> a + b
            pos = new Point(e.layerX, e.layerY).roundGrid()
            func.view.x = pos.x
            func.view.y = pos.y
            machine.addFunc func
      when DragState.Move
        # finish dragging
        switch dragEvent.targetType
          when TargetType.Canvas
            addFrame Rect.fromPoint(
              dragEvent.start.roundGrid(), 
              Size.fromPoint(dragEvent.current.sub(dragEvent.start).roundGrid())
            )
          when TargetType.Frame
            offset = dragEvent.target.point().sub dragEvent.start
            targetPos = dragEvent.current.add offset
            dragEvent.target.setPoint targetPos.roundGrid()
          when TargetType.FrameEdge
            size = Size.fromPoint dragEvent.current.sub(dragEvent.target.point()).roundGrid()
            dragEvent.target.setSize size
          when TargetType.Func
            port = machine.portContainsPoint dragEvent.start
            port.parent.pos = dragEvent.current.roundGrid()
  else if e.button is 2
    from = machine.portContainsPoint dragEvent.start
    to   = machine.portContainsPoint dragEvent.current
    from.outPorts.push to

  dragEvent.state = DragState.None  

# do not show context menu on canvas
canvas.oncontextmenu = (e) -> e.preventDefault()
###