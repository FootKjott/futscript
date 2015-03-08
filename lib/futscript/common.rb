
module Futscript
  
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

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end
 
  def mean
    sum / count
  end
end

class Random
  def self.normal range
    min = range.min
    max = range.max
    (min + (max - min) / 2.0).distribute((max - min) / 6.5)
  end
end
