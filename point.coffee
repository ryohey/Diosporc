conf = require "./config.coffee"

roundGrid = (x) -> 
  Math.round(x / conf.gridSize) * conf.gridSize

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

  copy: -> new Point(@x, @y)

module.exports = Point