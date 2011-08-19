Address.class_eval do
  before_validation :cleanup_state

  def cleanup_state
    state = country.states.where(["name = ? OR abbr = ?", state_name.capitalize, state_name.upcase]).first
    return unless state
    self.state = state
  end
end
