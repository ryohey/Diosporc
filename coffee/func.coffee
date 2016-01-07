Point = require "./point.coffee"
Rect = require "./rect.coffee"
Port = require "./port.coffee"
class Func
  constructor: (func = (x) -> x) ->
    @func = func

    # setup ports
    @inPorts = (for i in [0..func.length - 1]
        p = new Port(true, false)
        p.index = i
        p.on "change", @onChange
        p
    )
    @outPorts = (for i in [0]
        p = new Port(true, false)
        p.index = i
        p
    )

  onChange: (e) =>
    @updateOutput() if @isReady()
    
  isReady: ->
    _.all @inPorts, (p) -> p.received

  updateOutput: ->
    val = @func.apply(null, @inPorts.map((p) -> p.getValue()))
    @outPorts[0].setValue val
    # wait next input
    (p.received = false) for p in @inPorts

module.exports = Func