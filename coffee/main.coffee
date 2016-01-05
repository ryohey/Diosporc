conf = require "./config.coffee"
Point = require "./point.coffee"
Size = require "./size.coffee"
Rect = require "./rect.coffee"
Machine = require "./machine.coffee"
Port = require "./port.coffee"
Memory = require "./memory.coffee"
Func = require "./func.coffee"

width = 960
height = 500
GRID_SIZE = conf.gridSize
FRAME_EDGE_SIZE = 3
FUNC_RADIUS = GRID_SIZE / 3
MEMORY_COLS = Math.round(width / GRID_SIZE)
MEMORY_ROWS = Math.round(height / GRID_SIZE)

machine = new Machine width, height
document.machine = machine

canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"
stage = new createjs.Stage "canvas"
Port.stage = stage

createjs.Ticker.setFPS 60
createjs.Ticker.addEventListener "tick", stage
createjs.Ticker.addEventListener "tick", (e) -> redraw()

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

count = 0

setInterval ->
  machine.memory.ports[0].setValue count++
, 1000

drawMemory = ->
  for p in machine.memory.ports
    p.draw ctx, 
      lineWidth: 1
      color: "rgba(210, 210, 210, 1)"

drawFunc = (func, style = "rgba(0, 0, 0, 0.4)") ->
  # draw background
  for p in func.ports
    f = p.getFrame()
    ctx.beginPath()
    ctx.rect f.x, f.y, f.width, f.height
    ctx.fillStyle = "white"
    ctx.fill()

  for p in func.ports
    p.draw ctx, 
      lineWidth: 2
      color: style

drawFrame = (rect, style = "rgba(0, 0, 0, 0.4)") ->
  ctx.beginPath()
  ctx.rect rect.x + 0.5, rect.y + 0.5, 
           rect.width,   rect.height
  ctx.lineWidth = 2
  ctx.strokeStyle = style
  ctx.stroke()

drawLink = (from, to, style = "rgba(0, 0, 0, 0.4)") ->
  ctx.beginPath()
  ctx.moveTo from.x, from.y
  ctx.lineTo to.x, to.y
  ctx.lineWidth = 2
  ctx.strokeStyle = style
  ctx.stroke()

  arrowWidth = 5
  arrowHeight = 12
  ctx.beginPath()
  ctx.moveTo from.x - arrowWidth, from.y - arrowHeight / 2
  ctx.lineTo from.x - arrowWidth, from.y + arrowHeight / 2
  ctx.lineTo from.x, from.y
  ctx.closePath()
  ctx.fillStyle = style
  ctx.fill()

  ctx.beginPath()
  ctx.moveTo to.x, to.y - arrowHeight / 2
  ctx.lineTo to.x, to.y + arrowHeight / 2
  ctx.lineTo to.x + arrowWidth, to.y
  ctx.closePath()
  ctx.fillStyle = style
  ctx.fill()

drawFrames = ->
  drawFrame f for f in frames

drawFuncs = ->
  drawFunc f for f in machine.funcs

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
  drawMemory()
  drawFrames()
  drawFuncs()
  drawLinks()
  drawDrag()

getTarget = (pos) ->
  frame = findFrameContainsPoint pos

  type = TargetType.None
  target = null

  if frame?
    target = frame
    if isFrameEdge pos, frame
      type = TargetType.FrameEdge
    else
      type = TargetType.Frame

  [type, target]

findFuncContainsPoint = (p) ->
  _.find machine.funcs, (f) ->
    rect = Rect.fromPoint f.sub(FUNC_RADIUS),
                          new Size(FUNC_RADIUS * 2, FUNC_RADIUS * 2)
    rect.contains p

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
  drawFunc new Func(dragEvent.current), "rgba(0, 0, 0, 0.2)"

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
            func = new Func(new Point(e.layerX, e.layerY).roundGrid(), (a, b) -> a + b)
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