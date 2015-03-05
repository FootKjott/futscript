
module Futscript
  Point = Struct.new(:x, :y)
end

class Numeric
  # Positive number distribution; negative results return 0.0
  def distribute std_deviation
    u1 = Random.rand
    u2 = Random.rand
    std_normal = Math.sqrt(-2.0 * Math.log(u1)) * Math.sin(2.0 * Math::PI * u2)
    [ 0.0, self + std_deviation * std_normal ].max
  end
end
