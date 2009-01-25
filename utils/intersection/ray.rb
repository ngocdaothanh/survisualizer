require 'vector'

class Ray
  attr_reader :root, :head

  # Creates a ray which has a root and a head.
  def initialize(root, head)
    @root, @head = root, head
  end

  # Returns the direction vector.
  def direction
    @direction ||= @head - @root
  end

  # Cuts the ray into num_segments segments and returns an array of
  # num_segments + 1 vectors comming from the root to the head.
  def cut(num_segments)
    v = direction*(1.0/num_segments)
    ret = [@root]
    num_segments.times do |i|
      ret << @root + v*(i + 1)
    end
    ret
  end
end

if __FILE__ == $0
  root = Vector[1, 0, 0]
  head = Vector[1, 10, 0]
  ray = Ray.new(root, head)

  direction = ray.direction
  puts "Direction: #{direction}"

  vectors = ray.cut(10)
  puts "#{vectors.size} vectors:"
  vectors.each do |v|
    p v
  end
end
