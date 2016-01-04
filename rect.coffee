conf = require "./config.coffee"
Point = require "./point.coffee"
Size = require "./size.coffee"

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
      @width = conf.gridSize

    if @height is 0
      @height = conf.gridSize

module.exports = Rect
