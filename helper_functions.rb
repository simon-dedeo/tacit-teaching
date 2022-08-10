class String
  def hamming(two)
    one=self
    count=0
    one.length.times { |i|
      count += ((one[i] != two[i]) ? 1 : 0)
    }
    count
  end
end


class Array
  def hamming(two)
    one=self
    count=0
    one.length.times { |i|
      count += ((one[i] != two[i]) ? 1 : 0)
    }
    count
  end

  def mean
    count=0
    self.length.times { |i|
      count += self[i]
    }
    count*1.0/self.length
  end
end

class String
  def dist(other)
    one=self.split("")
    two=other.split("")
    count=0
    one.length.times { |i|
      if (one[i] != two[i]) then
        count+=1
      end
    }
    count
  end
  def invert
    s=self.gsub("0", "S")
    s=s.gsub("1", "0")
    s=s.gsub("S", "1")
    s
  end
end

class Array
  def dep
    Marshal.load(Marshal.dump(self))
  end
end
