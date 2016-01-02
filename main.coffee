width = 960
height = 500

$ = (q) -> document.querySelector(q)
canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"

createElement = (html, className) ->
  range = document.createRange()
  elem = range.createContextualFragment(html).firstChild
  elem.classList.add className
  elem.setAttribute "pm_original", html
  elem

$getJSON = (url, success, error = (e) -> console.error e) ->
  request = new XMLHttpRequest()
  request.open("GET", url, true)

  request.onload = ->
    if request.status < 200 or request.status >= 400
      error "unknown error"
      return
    success(JSON.parse(request.responseText))

  request.onerror = error
  request.send()

# query: 親を指定するクエリ
# className: 更新する要素を特定するクラス名
$u = (query, className, html, position = {x: 0, y: 0}) ->
  parent = $(query)
  return console.error "#{query} is not found" unless parent
  elem = parent?.querySelector ".#{className}"
  # 更新する必要がなければ何もしない
  return if elem?.getAttribute("pm_original") is html
  parent.removeChild elem if elem?
  elem = createElement(html, className)
  elem.setAttribute "style", "left: #{position.x}px; top: #{position.y}px;"
  parent.appendChild elem

getCenter = (query, direction = "left") ->
  e = document.querySelector(query).getBoundingClientRect()
  {
    x: if direction is "left" then e.left else e.right
    y: e.top + e.height / 2
  }

sortNear = (a, b, toPoint) ->
  r1 = Math.pow(toPoint.x - a.x, 2) + Math.pow(toPoint.y - a.y, 2)
  r2 = Math.pow(toPoint.x - b.x, 2) + Math.pow(toPoint.y - b.y, 2)
  if r1 < r2 then [a, b] else [b, a]

drawLine = (from, to, lineWidth = 2, strokeStyle = "gray") ->
  ctx.lineWidth = lineWidth
  ctx.strokeStyle = strokeStyle

  c = 
    x: (to.x + from.x) / 2
    y: (to.y + from.y) / 2

  h = Math.min(Math.abs(to.x - from.x), 
               Math.abs(to.y - from.y)) / 2

  sign = (a) -> a / Math.abs(a)

  mid1 = 
    x: c.x - h * sign(c.x - from.x)
    y: c.y - h * sign(c.y - from.y)
  
  mid2 = 
    x: c.x + h * sign(to.x - c.x)
    y: c.y + h * sign(to.y - c.y)

  ctx.beginPath();
  ctx.moveTo from.x, from.y
  ctx.lineTo mid1.x, mid1.y
  ctx.lineTo mid2.x, mid2.y
  ctx.lineTo to.x, to.y
  ctx.stroke()

last = (arr) -> arr[arr.length - 1]

updateScriptOutput = (frame) ->
  return unless frame?
  isEmpty = (str) ->
    return true unless str?
    return str.length is 0

  return unless frame.script?
  param1 = getFrameValue(frame.subframes[0].id)
  param2 = getFrameValue(frame.subframes[1].id)
  return if isEmpty(param1.length) or isEmpty(param2)

  # TODO: 引数の数の違いに対応する
  out = eval "(#{frame.script})(#{param1}, #{param2})"

  outId = last(frame.subframes).id
  updateValue outId, out

updateValue = (id, value) ->
  return unless id?
  input = getFrameValueInput(id)
  oldValue = Number input.value
  if Number value isnt oldValue
    input.value = value
    onInput getFrameValueInput(id)

onInput = (input) ->
  id = input.getAttribute "frame-id"
  type = input.getAttribute "class"
  return if type isnt "value"
  destId = data.edges[id]
  updateValue destId, input.value
  updateScriptOutput getParent(id)

getFrameNameInput = (id) -> $(".frame-#{id} input.name")
getFrameValueInput = (id) -> $(".frame-#{id} input.value")
getFrameValue = (id) -> getFrameValueInput(id).value

getParent = (id) ->
  for frame in data.frames
    for subframe in frame.subframes ? []
      return frame if Number subframe.id is Number id
  return null

createFrameElement = (frame) ->
  onInputStr = "(function(input){onInput(input)})(this)"
  children = (for subframe in frame.subframes ? [frame]
    """
    <div class="inner-frame frame-#{subframe.id} extern-#{subframe.extern ? "none"}">
      <div class="arrow in"></div>
      <div class="arrow out"></div>
      <input type="text" frame-id="#{subframe.id}" value="#{subframe.name ? ""}" class="name" oninput="#{onInputStr}">
      <input type="text" frame-id="#{subframe.id}" value="#{subframe.value ? ""}" class="value" oninput="#{onInputStr}">
    </div>
    """
  )
  """
  <div class="frame">
    <input type="text" value="#{frame.name ? ""}" class="name">
    <div class="subframes">
      #{children.join "\n"}
    </div>
  </div>
  """

data = {}

$getJSON "source.json", (json) ->
  data = json
  for frame in json.frames
    $u("#machine", "frame-#{frame.id}", 
      createFrameElement(frame),
      json.layout[frame.id])

  updateLines = () ->
    canvasRect = canvas.getBoundingClientRect()
    ctx.clearRect 0, 0, canvasRect.width, canvasRect.height

    for key, value of json.edges
      from = getCenter ".frame-#{key}", "right"
      to   = getCenter ".frame-#{value}", "left"
      drawLine from, to, 1

  updateLines()
  setInterval updateLines, 100