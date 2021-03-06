require 'ray'

# See http://www.cppblog.com/zmj/archive/2008/08/26/60039.aspx
class Triangle
  attr_reader :vertex1, :vertex2, :vertex3

  def initialize(vertex1, vertex2, vertex3)
    @vertex1, @vertex2, @vertex3 = vertex1, vertex2, vertex3
  end

  def intersection_with_ray(ray)
    u = @vertex2 - @vertex1
    v = @vertex3 - @vertex1
    n = u.cross_product(v)
    return nil if n.r < EPSILON

    w0 = ray.root - @vertex1
    a = -n.inner_product(w0)
    b = n.inner_product(ray.direction)
    return nil if b.abs < EPSILON  # Parallel

    # Find intersect point of the ray with the triangle plane
    r = 1.0*a/b
    return nil if r < 0  # The ray goes away from the triangle
    intersection = ray.root + ray.direction*r

    # Check if the point is inside the triangle
    uu = u.inner_product(u)
    uv = u.inner_product(v)
    vv = v.inner_product(v)
    w = intersection - @vertex1
    wu = w.inner_product(u)
    wv = w.inner_product(v)
    d = uv*uv - uu*vv
    s = 1.0*(uv*wv - vv*wu)/d
    return nil if s < 0 || s > 1
    t = 1.0*(uv*wu - uu*wv)/d
    return nil if t < 0 || (s + t) > 1

    intersection
  end
end

if __FILE__ == $0
  EPSILON = 0.00000001
  t = Triangle.new(Vector[10, 0, 0], Vector[0, 10, 0], Vector[-10, -10, 0])
  r = Ray.new(Vector[0, 0, 2], Vector[0, 0, -1])
  p t.intersection_with_ray(r)
end
