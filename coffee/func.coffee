Point = require "./point.coffee"
Rect = require "./rect.coffee"
Port = require "./port.coffee"
conf = require "./config.coffee"

GRID_SIZE = conf.gridSize

class Func
  constructor: (func = (x) -> x) ->
    @func = func
    @view = new createjs.Container()

    # setup ports
    @inPorts = (
      for i in [0..func.length - 1]
        p = new Port(new Rect(0, i * GRID_SIZE, GRID_SIZE, GRID_SIZE), true, false, this)
        p.didSetValue = @onInputValueChanged
        p
    )
    @outPort = new Port(new Rect(GRID_SIZE, 0, GRID_SIZE, GRID_SIZE), false, true, this)
    @ports = @inPorts.concat [@outPort]

    for p in @ports
      p.view.backgroundColor = "white" 
      @view.addChild(p.view)

  onInputValueChanged: (port, value) =>
    @updateOutput() if @isReady()
    
  isReady: ->
    _.all @inPorts, (p) -> p.received

  updateOutput: ->
    @outPort.setValue @func.apply(null, @inPorts.map((p) -> p.getValue()))

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = Func