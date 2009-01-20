Vector.class_eval do
  def []=(i, x)
    @elements[i] = x
  end

  def angle(vector)
    cos = inner_product(vector)/(r*vector.r)
    Math.acos(cos)
  end

  # Rotate arount a vetor by an angle.
  def rotate!(vector, angle)
    # Normalize
    r = vector.r
    vector[0] = 1.0*vector[0]/r
    vector[1] = 1.0*vector[1]/r
    vector[2] = 1.0*vector[2]/r

    x = @elements[0]
    y = @elements[1]
    z = @elements[2]
    u = vector[0]
    v = vector[1]
    w = vector[2]
    a = angle

    ux = u*x
    uy = u*y
    uz = u*z
    vx = v*x
    vy = v*y
    vz = v*z
    wx = w*x
    wy = w*y
    wz = w*z
    sa = Math.sin(a)
    ca = Math.cos(a)
    x = u*(ux + vy + wz) + (x*(v*v + w*w) - u*(vy + wz))*ca + (-wy + vz)*sa
    y = v*(ux + vy + wz) + (y*(u*u + w*w) - v*(ux + wz))*ca + ( wx - uz)*sa
    z = w*(ux + vy + wz) + (z*(u*u + v*v) - w*(ux + vy))*ca + (-vx + uy)*sa

    @elements[0] = x
    @elements[1] = y
    @elements[2] = z

    self
  end

  def cross_product(vector)
    Vector[
      @elements[1]*vector[2] - @elements[2]*vector[1],
      @elements[2]*vector[0] - @elements[0]*vector[2],
      @elements[0]*vector[1] - @elements[1]*vector[0]
    ]
  end
end

if __FILE__ == $0
  v1 = Vector[ 1, 1, 0]
  v2 = Vector[-1, 1, 0]
  pi = v1.angle(v2)*2
  puts "PI = #{pi}"

  v3 = v1.clone
  v3.rotate!(Vector[0, 0, 1], pi)
  puts "#{v1} --180--> #{v3}"

  v4 = v1.cross_product(v2)
  puts "#{v1}x#{v2} = #{v4}"
end
