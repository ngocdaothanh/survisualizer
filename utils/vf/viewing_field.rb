require 'vector'
require 'triangle'
require 'camera'

class ViewingField
  def initialize(camera, triangles, segments_per_edge)
    @camera, @triangles, @segments_per_edge = camera, triangles, segments_per_edge
  end

  # Returns heads of rays whose:
  # * root: camera position
  # * head: point on the camera rectangle
  def heads_on_camera
    return @heads_on_camera if @heads_on_camera

    rectangle = @camera.rectangle
    points03 = Ray.new(rectangle[0], rectangle[3]).cut(@segments_per_edge)
    points12 = Ray.new(rectangle[1], rectangle[2]).cut(@segments_per_edge)

    @heads_on_camera = []
    points03.each_with_index do |p, i|
      @heads_on_camera.concat(Ray.new(p, points12[i]).cut(@segments_per_edge))
    end
    @heads_on_camera
  end

  def heads_on_triangles
    return @heads_on_triangles if @heads_on_triangles

    @heads_on_triangles = []
    heads_on_camera.each do |h|
      ray = Ray.new(@camera.position, h)
      head = nearest_intersection_with_ray(ray)
      puts 'A head is nil (the ray does not cut any trianlge of the model)' unless head
      @heads_on_triangles << head
    end
    @heads_on_triangles
  end

  def serialize
    ret = ''
    ret << @camera.position.serialize
    heads_on_camera.each { |h| ret << h.serialize }
    heads_on_triangles.each { |h| ret << h.serialize }
    ret
  end

  private

  def nearest_intersection_with_ray(ray)
    intersections = []
    @triangles.each do |t|
      i = t.intersection_with_ray(ray)
      intersections << i if i
    end

    return nil if intersections.empty?

    # Sort by the distance from the camera position
    intersections = intersections.sort_by do |i|
      Ray.new(@camera.position, i).direction.r
    end

    intersections[0]
  end
end

if __FILE__ == $0
  EPSILON = 0.00000001

  position = Vector[0, 10, 0]
  focus    = Vector[0, -0.1, 0]
  width    = 0.4
  height   = 0.3
  camera = Camera.new(position, focus, width, height)

  # Rectangle on 0xz
  vertex1 = Vector[ 100, 0,  100]
  vertex2 = Vector[ 100, 0, -100]
  vertex3 = Vector[-100, 0, -100]
  vertex4 = Vector[-100, 0,  100]
  triangles = [
    Triangle.new(vertex1, vertex2, vertex4),
    Triangle.new(vertex2, vertex3, vertex4)
  ]

  segments_per_edge = 10

  viewing_field = ViewingField.new(camera, triangles, segments_per_edge)
  p viewing_field.heads_on_camera
  p viewing_field.heads_on_triangles
  p viewing_field.serialize
end
