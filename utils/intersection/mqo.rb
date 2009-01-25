require 'stringio'

# Metasequoia (.mqo) file loader.
# See http://d.hatena.ne.jp/ousttrue/20070429/1177805677
class Mqo
  # to_meter_ratio: The ratio to convert distance to meter unit
  def initialize(file_name, to_meter_ratio)
    @file_name = file_name
    @to_meter_ratio = to_meter_ratio
  end

  # Returns array of objects.
  def load_objects
    lines = File.read(@file_name)
    @io = StringIO.new(lines)

    ret = []
    begin
      while true
        line = @io.readline.strip
        ret << load_object if line =~ /^Object\s*"([^"]+)"\s+\{/
      end
    rescue EOFError
    end
    ret
  end

  private

  # Returns array of trianalges.
  def load_object
    vertices = nil
    faces = nil
    while true
      line = @io.readline.strip
      break if line == '}'

      if line =~ /^(\w+)\s*(\d+)?\s*\{/
        chunk = $1.downcase
        if chunk == 'vertex'
          vertices = load_vertices
        elsif chunk == 'bvertex'
          raise 'bvertex not supported'
        elsif chunk == 'face'
          faces = load_faces
        end
      end
    end

    ret = []
    faces.each do |indices|
      if indices.size == 3
        triangle = Triangle.new(vertices[indices[0]], vertices[indices[1]], vertices[indices[2]])
        ret << triangle
      else
        triangle = Triangle.new(vertices[indices[0]], vertices[indices[1]], vertices[indices[2]])
        ret << triangle
        triangle = Triangle.new(vertices[indices[2]], vertices[indices[3]], vertices[indices[0]])
        ret << triangle
      end
    end
    ret
  end

  # Returns array of vectors.
  def load_vertices
    ret = []
    while true
      line = @io.readline.strip
      break if line=='}'

      x, y, z = line.split(' ').map { |e| e.to_f*@to_meter_ratio }
      ret << Vector[x, y, z]
    end
    ret
  end

  # Return arrays of indices to vectors (only triangles or rectangles).
  def load_faces
    ret = []
    while true
      line = @io.readline.strip
      break if line=='}'

      if line =~ /^(\w+)\s*V\(([^)]*)\)\s/
        indices = $2.split(' ').map { |e| e.to_i }
        ret << indices if [3, 4].include?(indices.size)
      end
    end
    ret
  end
end

if __FILE__ == $0
  m = Mqo.new('./models/scene.mqo')
  a = m.load_objects
  p a.size
end
