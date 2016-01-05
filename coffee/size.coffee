class Size
  constructor: (width, height) ->
    @width = width
    @height = height

  @fromPoint = (point) ->
    new Size(point.x, point.y)

module.exports = Size