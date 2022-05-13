defprotocol Solvent.EventBus do
  def publish(bus, data)
  def subscribe(bus, id, fun)
  def unsubscribe(bus, id)
  def get_listener(bus, id)
end
