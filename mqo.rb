require 'stringio'
require 'vector'
require 'triangle'

# .mqo (Metasequoia) file loader.
# Based on http://d.hatena.ne.jp/ousttrue/20070429/1177805677
class Mqo
  def initialize(file_name)
    @file_name = file_name
  end

  def load
    lines = File.read(@file_name)
    @io = StringIO.new(lines)

    @triangles = []
    begin
      while true
        line = @io.readline.strip
        load_object if line =~ /^Object\s*"([^"]+)"\s+\{/
      end
    rescue EOFError
    end
    @triangles
  end

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

    faces.each do |indices|
      if indices.size == 3
        triangle = Triangle.new(vertices[indices[0]], vertices[indices[1]], vertices[indices[2]])
        @triangles << triangle
      else
        triangle = Triangle.new(vertices[indices[0]], vertices[indices[1]], vertices[indices[2]])
        @triangles << triangle
        triangle = Triangle.new(vertices[indices[2]], vertices[indices[3]], vertices[indices[0]])
        @triangles << triangle
      end
    end
  end

  def load_vertices
    ret = []
    while true
      line = @io.readline.strip
      break if line=='}'

      x, y, z = line.split(' ').map { |e| e.to_f/100}
      ret << Vector[x, y, z]
    end
    ret
  end

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
  t = m.load
  p t.size
end
