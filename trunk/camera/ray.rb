class Ray
  attr_reader :root, :head

  def initialize(root, head)
    @root, @head = root, head
  end

  def direction
    @direction ||= @head - @root
  end
end
