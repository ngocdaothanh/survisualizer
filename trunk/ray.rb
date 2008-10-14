class Ray
  attr_reader :root, :point

  def initialize(root, point)
    @root, @point = root, point
  end

  def direction
    @direction ||= @point - @root
  end
end
