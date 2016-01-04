conf = require "./config.coffee"
Point = require "./point.coffee"
Size = require "./size.coffee"
Rect = require "./rect.coffee"
Machine = require "./machine.coffee"

width = 960
height = 500
GRID_SIZE = conf.gridSize
FRAME_EDGE_SIZE = 3
FUNC_RADIUS = GRID_SIZE / 3
MEMORY_COLS = Math.round(width / GRID_SIZE)
MEMORY_ROWS = Math.round(height / GRID_SIZE)

machine = new Machine MEMORY_COLS * MEMORY_ROWS

canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"
stage = new createjs.Stage "canvas"

createjs.Ticker.setFPS 60
createjs.Ticker.addEventListener "tick", stage
createjs.Ticker.addEventListener "tick", (e) -> redraw()

$ = (q) -> document.querySelector(q)

frames = []
funcs = []

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
  moved: false
  start: new Point(0, 0)
  current: new Point(0, 0)

addressFromPoint = (point) ->
  p = point.sub(GRID_SIZE / 2).roundGrid()
  (p.x / GRID_SIZE +
   p.y / GRID_SIZE * MEMORY_COLS)

CanvasRenderingContext2D.prototype.gridPath = (gridSize, width, height) ->
  for dx in [0..width / gridSize]
    x = dx * gridSize + 0.5
    @moveTo x, 0
    @lineTo x, height

  for dy in [0..height / gridSize]
    y = dy * gridSize + 0.5
    @moveTo 0, y
    @lineTo width, y

drawGrid = ->
  ctx.beginPath()
  ctx.lineWidth = 1
  ctx.strokeStyle = "rgba(0, 0, 0, 0.1)"
  ctx.gridPath GRID_SIZE, width, height
  ctx.stroke()

highlightMemory = (index) ->
  dy = Math.floor(index / MEMORY_COLS)
  dx = index - dy * MEMORY_COLS
  x = dx * GRID_SIZE
  y = dy * GRID_SIZE

  rect = new createjs.Shape()
  rect.graphics.beginFill("rgba(255, 0, 0, 0.2)").drawRect x, y, GRID_SIZE, GRID_SIZE
  stage.addChild rect
  createjs.Tween.get rect
    .to { alpha: 0 }, 500, createjs.Ease.getPowInOut(2)
    .call (e) -> stage.removeChild e.target

machine.onMemoryUpdated = (index, value) ->
  highlightMemory index

count = 0

setInterval ->
  machine.setMemory 0, count++
, 1000

drawMemory = ->
  fontSize = 12
  lineHeight = fontSize
  fontFamily = window.getComputedStyle($("body")).getPropertyValue("font-family")
  ctx.font = "#{fontSize}px #{fontFamily}"
  ctx.fillStyle = "rgba(0, 0, 0, 0.2)"
  ctx.textAlign = "center"
  for x in [0..MEMORY_COLS - 1]
    for y in [0..MEMORY_ROWS - 1]
      value = machine.getMemory(x + y * MEMORY_COLS)
      ctx.fillText "#{value}", 
                   (x + 0.5) * GRID_SIZE, 
                   (y + 0.5) * GRID_SIZE + lineHeight / 2, 
                   GRID_SIZE

drawFunc = (pos, style = "rgba(0, 0, 0, 0.4)") ->
  ctx.beginPath()
  ctx.arc pos.x + 0.5, pos.y + 0.5, FUNC_RADIUS, 0, 2 * Math.PI
  ctx.lineWidth = 2
  ctx.strokeStyle = style
  ctx.stroke()

drawFrame = (rect, style = "rgba(0, 0, 0, 0.4)") ->
  ctx.beginPath()
  ctx.rect rect.x + 0.5, rect.y + 0.5, 
           rect.width,   rect.height
  ctx.lineWidth = 2
  ctx.strokeStyle = style
  ctx.stroke()

drawFrames = ->
  drawFrame f for f in frames

drawFuncs = ->
  drawFunc f for f in funcs

drawDrag = ->
  return if dragEvent?.state isnt DragState.Move
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
  drawGrid()
  drawMemory()
  drawFrames()
  drawFuncs()
  drawDrag()

# change cursor over canvas when dragging
canvas.onselectstart = -> false

getTarget = (pos) ->
  frame = findFrameContainsPoint pos
  func = findFuncContainsPoint pos

  type = TargetType.None
  target = null

  if frame?
    target = frame
    if isFrameEdge pos, frame
      type = TargetType.FrameEdge
    else
      type = TargetType.Frame
  else if func?
    type = TargetType.Func
    target = func
  else
    type = TargetType.Canvas

  [type, target]

findFuncContainsPoint = (p) ->
  _.find funcs, (f) ->
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

addFunc = (point) ->
  funcs.push point

addFrame = (rect) ->
  frames.push rect

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
  drawFunc dragEvent.current, "rgba(0, 0, 0, 0.2)"

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

canvas.onmousedown = (e) ->
  pos = new Point(e.layerX, e.layerY)

  dragEvent.state = DragState.Down
  dragEvent.start = pos
  [dragEvent.targetType, dragEvent.target] = getTarget pos
  console.log "[onmousedown] type: #{dragEvent.targetType}"
  true

canvas.onmousemove = (e) ->
  pos = new Point(e.layerX, e.layerY)

  #change cursor
  if dragEvent.state is DragState.None
    canvas.style.cursor = cursorForTargetType getTarget(pos)[0]
    return 
  else
    canvas.style.cursor = cursorForTargetType dragEvent.targetType

  dragEvent.state = DragState.Move
  dragEvent.current = pos

canvas.onmouseup = (e) ->
  switch dragEvent.state
    when DragState.Down
      # on click
      switch dragEvent.targetType
        when TargetType.Canvas
          addFunc new Point(e.layerX, e.layerY).roundGrid()
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
          dragEvent.target.copyFrom dragEvent.current.roundGrid()
  redraw()
  dragEvent.state = DragState.None  
