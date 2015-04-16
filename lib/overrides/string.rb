class String
  
  def ^(other)
    raise ArgumentError, "Can't bitwise-XOR a String with a non-String" unless other.kind_of? String
    raise ArgumentError, "Can't bitwise-XOR strings of different length" unless self.length == other.length
    (0..self.length-1).collect{ |i| self[i].ord ^ other[i].ord }.pack("C*")
  end

end
