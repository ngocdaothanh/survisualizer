# Convert all RGBA xxx.width.height.format.raw files in the current directory to grayscale xxx.pgm or RGB xxx.ppm files

GL_BGRA = 32993

def upside_down(frame)
  ret = ''
  length = width*3
  (0...height).each do |j|
    line = rgb_frame[j*length...(j + 1)*length]
    ret = rgb_frame2.insert(0, line)
  end
  ret
end

def rgba2rgb(rgba_frame)
  ret = ''
  i = 1
  rgba_frame.each_byte do |b|
    ret << b if i%4 != 0
    i += 1
  end
  ret
end

def convert(raw_filename)
  raw_filename =~ /(.+)\.(.+)\.(.+)\.(.+)\.raw/
  base   = $1
  width  = $2.to_i
  height = $3.to_i
  format = $4.to_i

  if format == GL_BGRA
    out_filename = base + '.ppm'
  else
    out_filename = base + '.pgm'
  end

  frame = File.read(raw_filename)
  if format == GL_BGRA
    frame = rgba2rgb(frame)
  end

  frame = upside_down(frame)

  if format == GL_BGRA
    File.open(out_filename, 'wb') { |f| f.write("P6\n#{width} #{height}\n255\n"); f.write(frame) }
  end
end

files = Dir.glob('./*.raw')
files.each do |raw_filename|
  puts "Conver #{raw_filename}..."
  convert(raw_filename)
end
