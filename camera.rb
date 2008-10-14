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

    # Avoid division by zero
    cases = [
      {
        :projected     => Vector[0, @focal_vector[1], @focal_vector[2]],
        :rotation_axis => Vector[@focal_vector[1] > 0 ? -1 : 1, 0, 0]
      },
      {
        :projected     => Vector[@focal_vector[0], 0, @focal_vector[2]],
        :rotation_axis => Vector[0, @focal_vector[0] > 0 ? 1 : -1, 0]
      },
      {
        :projected     => Vector[@focal_vector[0], @focal_vector[1], 0],
        :rotation_axis => Vector[0, 0, 1]
      }
    ]
    selected = cases[0]
    selected = cases[1] if selected[:projected].r == 0
    selected = cases[2] if selected[:projected].r == 0
    projected     = selected[:projected]
    rotation_axis = selected[:rotation_axis]

    p projected

    # Rotate
    normal = projected.cross_product(@focal_vector)
    angle1 = assumed.angle(projected)
    angle2 = projected.angle(@focal_vector)
    ret.each do |v|
      v.rotate!(rotation_axis, angle1) if angle1 != 0
      v.rotate!(normal, angle2) if normal.r != 0 && angle2 != 0
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
