class Port
  constructor: (canWrite, canRead) ->
    @canWrite = canWrite
    @canRead = canRead
    @outPorts = []
    @value = 0
    @received = false

  getValue: (v) -> @value
  setValue: (v) -> 
    @value = v
    @received = true
    port.setValue(v) for port in @outPorts
    @dispatchEvent "change"

createjs.EventDispatcher.initialize Port.prototype

module.exports = Port
