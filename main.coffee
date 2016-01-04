conf = require "./config.coffee"
Point = require "./point.coffee"
Size = require "./size.coffee"
Rect = require "./rect.coffee"
Machine = require "./machine.coffee"
Node = require "./node.coffee"
{Memory, Func} = require "./io.coffee"

width = 960
height = 500
GRID_SIZE = conf.gridSize
FRAME_EDGE_SIZE = 3
FUNC_RADIUS = GRID_SIZE / 3
MEMORY_COLS = Math.round(width / GRID_SIZE)
MEMORY_ROWS = Math.round(height / GRID_SIZE)

machine = new Machine MEMORY_COLS * MEMORY_ROWS
document.machine = machine

canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"
stage = new createjs.Stage "canvas"

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

CanvasRenderingContext2D.prototype.gridPath = (gridSize, width, height, startX = 0, startY = 0) ->
  for dx in [0..width / gridSize]
    x = dx * gridSize + 0.5 + startX
    @moveTo x, startY
    @lineTo x, startY + height

  for dy in [0..height / gridSize]
    y = dy * gridSize + 0.5 + startY
    @moveTo startX, y
    @lineTo startX + width, y

drawGrid = ->
  ctx.beginPath()
  ctx.lineWidth = 1
  ctx.strokeStyle = "rgba(0, 0, 0, 0.1)"
  ctx.gridPath GRID_SIZE, width, height
  ctx.stroke()

pointToIndex = (point) ->
  p = point.sub(GRID_SIZE / 2).roundGrid()
  (p.x / GRID_SIZE +
   p.y / GRID_SIZE * MEMORY_COLS)

indexToPoint = (index) ->
  dy = Math.floor(index / MEMORY_COLS)
  dx = index - dy * MEMORY_COLS
  new Point dx * GRID_SIZE,
            dy * GRID_SIZE

highlightMemory = (index) ->
  pos = indexToPoint index

  rect = new createjs.Shape()
  rect.graphics.beginFill("rgba(255, 0, 0, 0.2)").drawRect pos.x, pos.y, GRID_SIZE, GRID_SIZE
  stage.addChild rect
  createjs.Tween.get rect
    .to { alpha: 0 }, 500, createjs.Ease.getPowInOut(2)
    .call (e) -> stage.removeChild e.target

machine.onMemoryUpdated = (index, value) ->
  highlightMemory index

count = 0

setInterval ->
  machine.memory.setInput 0, count++
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
      value = machine.memory.getOutput(x + y * MEMORY_COLS)
      ctx.fillText "#{value}", 
                   (x + 0.5) * GRID_SIZE, 
                   (y + 0.5) * GRID_SIZE + lineHeight / 2, 
                   GRID_SIZE

drawFunc = (func, style = "rgba(0, 0, 0, 0.4)") ->
  # draw input
  inHeight = GRID_SIZE * func.getInputNum()

  ctx.beginPath()
  ctx.rect func.x, func.y, GRID_SIZE, inHeight
  ctx.fillStyle = "white"
  ctx.fill()

  ctx.beginPath()
  ctx.gridPath GRID_SIZE, 
               GRID_SIZE, inHeight, 
               func.x, func.y
  ctx.lineWidth = 2
  ctx.strokeStyle = style
  ctx.stroke()

  #draw output
  outHeight = GRID_SIZE * func.getOutputNum()

  ctx.beginPath()
  ctx.rect func.x + GRID_SIZE, func.y, GRID_SIZE, outHeight
  ctx.fillStyle = "white"
  ctx.fill()

  ctx.beginPath()
  ctx.gridPath GRID_SIZE, 
               GRID_SIZE, outHeight, 
               func.x + GRID_SIZE, func.y
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

nodeToPoint = (node, direction = "in") ->
  switch node.type
    when Node.Type.Memory
      p = indexToPoint(node.indexes[0])
      if direction is "out"
        p.x += GRID_SIZE
      p.y += GRID_SIZE / 2
    when Node.Type.Func
      func = machine.funcs[node.indexes[0]]
      p = func.copy()
      p.y += GRID_SIZE / 2
      p.y += GRID_SIZE * node.indexes[1]
      if direction is "out"
        p.x += GRID_SIZE * 2
  p

drawLinks = ->
  for key, value of machine.links
    fromNode = Node.fromString key
    from = nodeToPoint fromNode, "out"
    for toNode in value
      to = nodeToPoint toNode, "in"
      drawLink from, to

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
  drawGrid()
  drawMemory()
  drawFrames()
  drawFuncs()
  drawLinks()
  drawDrag()

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
  console.log "[onmousedown] button: #{e.button}, type: #{dragEvent.targetType}"
  pos = new Point(e.layerX, e.layerY)

  dragEvent.state = DragState.Down
  dragEvent.button = e.button
  dragEvent.start = pos
  [dragEvent.targetType, dragEvent.target] = getTarget pos
  true

canvas.onmousemove = (e) ->
  console.log "[onmousemove] button: #{e.button}, type: #{dragEvent.targetType}"
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

nodeFromPoint = (point) ->
  [type, target] = getTarget point
  switch type 
    when TargetType.Canvas
      new Node Node.Type.Memory, [pointToIndex(point)]
    when TargetType.Frame
      new Node Node.Type.Memory, [pointToIndex(point)]
    when TargetType.Func
      new Node Node.Type.Func, [machine.funcs.indexOf(target), 0]

canvas.onmouseup = (e) ->
  if e.button is 0
    switch dragEvent.state
      when DragState.Down
        # on click
        switch dragEvent.targetType
          when TargetType.Canvas
            func = new Func(new Point(e.layerX, e.layerY).roundGrid())
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
            dragEvent.target.copyFrom dragEvent.current.roundGrid()
  else if e.button is 2
    from = nodeFromPoint dragEvent.start
    to   = nodeFromPoint dragEvent.current
    machine.addLink from, to

  dragEvent.state = DragState.None  

# do not show context menu on canvas
canvas.oncontextmenu = (e) -> e.preventDefault()