Point = require "./point.coffee"
Rect = require "./rect.coffee"
Port = require "./port.coffee"
conf = require "./config.coffee"

GRID_SIZE = conf.gridSize

class Memory
  constructor: (width, height) ->
    @pos = new Point(0, 0)

    cols = Math.round(width / conf.gridSize)
    rows = Math.round(height / conf.gridSize)

    @ports = _.flatten(
      for x in [0..cols - 1]
        for y in [0..rows - 1]
          new Port(new Rect(x * GRID_SIZE, y * GRID_SIZE, GRID_SIZE, GRID_SIZE), true, true, this)
    )

module.exports = Memory
