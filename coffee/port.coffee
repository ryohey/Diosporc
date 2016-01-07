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
    for port in @outPorts
      port.setValue v
    @dispatchEvent "change"

createjs.EventDispatcher.initialize Port.prototype

module.exports = Port
