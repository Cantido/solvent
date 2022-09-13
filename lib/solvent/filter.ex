defprotocol Solvent.Filter do
  def match?(filter, event)
end
