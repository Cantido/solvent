defprotocol Solvent.EventBus do
  def subscribe(bus, fun)
  def publish(bus, data)
end
