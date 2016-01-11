class Port
  constructor: (canWrite, canRead) ->
    @canWrite = canWrite
    @canRead = canRead
    @value = 0

  getValue: (v) -> @value
  setValue: (v) -> 
    changed = @value isnt v
    @value = v
    @dispatchEvent("change") if changed

createjs.EventDispatcher.initialize Port.prototype

module.exports = Port
