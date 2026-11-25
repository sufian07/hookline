# Exponential backoff with jitter over the upper half of each step.
module Backoff
  BASE = 30
  CAP = 3600

  module_function

  def delay(attempt, jitter:)
    step = [ BASE * 2**(attempt - 1), CAP ].min
    (step * (0.5 + 0.5 * jitter)).round
  end
end
