# Assumption: Surveillance camera is not tilted.
#
# +---width---+
# |           |
# height      |
# |           |
# +-----------+
#
# +
# |
# |<---focal_vector---+ position
# |
# +
class Camera
  attr_reader :position, :focal_vector, :width, :height

  def initialize(position, focal_vector, width, height)
    @position     = position
    @focal_vector = focal_vector
    @width        = width
    @height       = height
  end

  # Returns an array containing 4 position vectors of the lens rectangle.
  def rectangle
    # Assume that the focal vector is Vector[0, 0, @focal_vector.r]
    assumed = Vector[0, 0, @focal_vector.r]
    ret = [
      Vector[-@width/2,  @height/2, @focal_vector.r],
      Vector[ @width/2,  @height/2, @focal_vector.r],
      Vector[ @width/2, -@height/2, @focal_vector.r],
      Vector[-@width/2, -@height/2, @focal_vector.r]
    ]

    # Rotate
    normal = assumed.cross_product(@focal_vector)
    angle = assumed.angle(@focal_vector)
    ret.each do |v|
      v.rotate!(normal, angle) if normal.r > EPSILON && angle > EPSILON
    end

    # Translate
    ret.each do |v|
      (0..2).each do |i|
        v[i] += @position[i]
      end
    end

    ret
  end

  def visualizer=(visualizer_class)
    @visualizer = visualizer_class.new(self)
  end

  def visualize
    @visualizer.visualize unless @visualizer.nil?
  end
end
