Address.class_eval do
  before_validation :cleanup_state

  def cleanup_state
    return unless state_name
    state = country.states.where(["name = ? OR abbr = ?", state_name.capitalize, state_name.upcase]).first
    if state
      self.state = state
      self.state_name = nil
    end
  end
end
