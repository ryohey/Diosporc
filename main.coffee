width = 960
height = 500
GRID_SIZE = 24
FRAME_EDGE_SIZE = 3
FUNC_RADIUS = GRID_SIZE / 3

$ = (q) -> document.querySelector(q)
canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"

roundGrid = (x) -> 
  Math.round(x / GRID_SIZE) * GRID_SIZE

class Point
  constructor: (x, y) ->
    @x = x
    @y = y

  add: (v) ->
    if v instanceof Point
      new Point(@x + v.x, @y + v.y)
    else
      new Point(@x + v, @y + v)

  sub: (v) ->
    if v instanceof Point
      new Point(@x - v.x, @y - v.y)
    else
      new Point(@x - v, @y - v)

  roundGrid: ->
    new Point(roundGrid(@x), roundGrid(@y))

  copyFrom: (point) ->
    @x = point.x
    @y = point.y

class Size
  constructor: (width, height) ->
    @width = width
    @height = height

  @fromPoint = (point) ->
    new Size(point.x, point.y)

class Rect
  constructor: (x, y, width, height) ->
    @x = x
    @y = y
    @width = width
    @height = height
    @normalize()

  point: -> new Point(@x, @y)
  size: -> new Size(@width, @height)

  @fromPoint = (point, size) ->
    new Rect(point.x, point.y, size.width, size.height)

  inset: (dx, dy) ->
    new Rect(@x + dx, @y + dy, @width - dx * 2, @height - dy * 2)

  contains: (point) ->
    (point.x >= @x and
     point.y >= @y and
     point.x <= @x + @width and
     point.y <= @y + @height)

  setPoint: (point) ->
    @x = point.x
    @y = point.y

  setSize: (size) ->
    @width = size.width
    @height = size.height
    @normalize()

  normalize: ->
    if @width < 0
      @x += @width
      @width *= -1

    if @height < 0
      @y += @height
      @height *= -1

    if @width is 0
      @width = GRID_SIZE

    if @height is 0
      @height = GRID_SIZE

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

redraw = ->
  rect = canvas.getBoundingClientRect()
  ctx.clearRect 0, 0, rect.width, rect.height
  drawGrid()
  drawFrames()
  drawFuncs()

frames = []
funcs = []

redraw()

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
  dragEvent.start = pos.roundGrid()
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
  dragEvent.current = pos.roundGrid()

  redraw()
  switch dragEvent.targetType
    when TargetType.Canvas
      drawFramePreview dragEvent
    when TargetType.Func
      drawDragFuncPreview dragEvent
    when TargetType.Frame
      drawDragFramePreview dragEvent
    when TargetType.FrameEdge
      resizeFramePreview dragEvent

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
            dragEvent.start, 
            Size.fromPoint(dragEvent.current.sub dragEvent.start)
          )
        when TargetType.Frame
          offset = dragEvent.target.point().sub dragEvent.start
          targetPos = dragEvent.current.add offset
          dragEvent.target.setPoint targetPos
        when TargetType.FrameEdge
          size = Size.fromPoint(dragEvent.current.sub dragEvent.target.point())
          dragEvent.target.setSize size
        when TargetType.Func
          dragEvent.target.copyFrom dragEvent.current
  redraw()
  dragEvent.state = DragState.None  
