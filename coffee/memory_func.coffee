Port = require "./port.coffee"

class MemoryFunc
  constructor: (value) ->
    @inPorts = (for i in [0..1]
      p = new Port(true, false)
      p.index = i
      p
    )
    
    @inPorts[0].on "change", @onChange

    @outPorts = (for i in [0]
      p = new Port(false, true)
      p.index = i
      p
    )

    @inPorts[1].setValue value

  onChange: =>
    @outPorts[0].setValue  @inPorts[1].getValue()

    # wait next input
    (p.received = false) for p in @inPorts

module.exports = MemoryFunc
