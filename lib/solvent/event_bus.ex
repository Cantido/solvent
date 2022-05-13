defprotocol Solvent.EventBus do
  def publish(bus, type, data)
  def subscribe(bus, id, match_type, fun)
  def unsubscribe(bus, id)
  def get_listener(bus, id)
end
