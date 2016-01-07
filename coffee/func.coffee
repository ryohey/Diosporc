Point = require "./point.coffee"
Rect = require "./rect.coffee"
Port = require "./port.coffee"

class Func
  constructor: (func = ((x) -> x), outNum = 1) ->
    @func = func

    # setup ports
    @inPorts = (for i in [0..func.length - 1]
        p = new Port(true, false)
        p.index = i
        p.on "change", @onChange
        p
    )
    @outPorts = (for i in [0..outNum - 1]
        p = new Port(false, true)
        p.index = i
        p
    )

  onChange: (e) =>
    @updateOutput() if @isReady()
    
  isReady: ->
    _.all @inPorts, (p) -> p.received

  updateOutput: ->
    args = @inPorts.map (p) -> p.getValue()
    val = @func.apply null, args
    if @outPorts.length is 1
      @outPorts[0].setValue val
    else
      console.log @func.toString()
      @outPorts[i].setValue(v) for i, v of val when v?

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = Func