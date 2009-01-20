class Ray
  attr_reader :root, :head

  def initialize(root, head)
    @root, @head = root, head
  end

  def direction
    @direction ||= @head - @root
  end

  def cut(num_segments)
    v = direction*(1.0/num_segments)
    ret = [@root]
    num_segments.times do |i|
      ret << @root + v*(i + 1)
    end
    ret
  end
end
