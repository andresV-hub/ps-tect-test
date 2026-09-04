# Rasteriza el logotipo "el conmutador" (docs/styles.md §1.6) a public/icon.png.
#
# No hay ImageMagick ni rsvg en la máquina, así que se dibuja con funciones de
# distancia con signo y antialiasing por supermuestreo 4x4, y se escribe el PNG
# con un codificador mínimo sobre Zlib (stdlib). La geometría es exactamente la
# misma que la de public/icon.svg.

require "zlib"

SIZE   = 512
CX     = 256.0
CY     = 256.0
SCALE  = 0.74          # el mismo transform del SVG
R_RING = 176.0         # radio del anillo
STROKE = 28.0          # medio grosor de trazo (56 / 2)
GAP    = 35.0          # medio hueco superior en grados (70° en total)
BAR_Y1 = 96.0
BAR_Y2 = 216.0
RECT_R = 112.0         # radio de las esquinas del fondo

BG   = [ 0x0e, 0x3b, 0x58 ].freeze
MARK = [ 0xff, 0xff, 0xff ].freeze

CAP_X = R_RING * Math.sin(GAP * Math::PI / 180)
CAP_Y = R_RING * Math.cos(GAP * Math::PI / 180)
CAP_A = [ CX + CAP_X, CY - CAP_Y ].freeze
CAP_B = [ CX - CAP_X, CY - CAP_Y ].freeze

# Fondo: cuadrado de esquinas redondeadas a sangre.
def rounded_rect_sdf(x, y)
  qx = (x - CX).abs - (CX - RECT_R)
  qy = (y - CY).abs - (CY - RECT_R)
  [ [ qx, qy ].max, 0.0 ].min + Math.hypot([ qx, 0.0 ].max, [ qy, 0.0 ].max) - RECT_R
end

# Anillo abierto por arriba, con extremos redondeados.
def ring_sdf(x, y)
  dx = x - CX
  dy = y - CY
  angle = Math.atan2(dx, -dy) * 180 / Math::PI   # 0° arriba, creciendo en sentido horario

  if angle.abs >= GAP
    (Math.hypot(dx, dy) - R_RING).abs - STROKE
  else
    [ Math.hypot(x - CAP_A[0], y - CAP_A[1]),
      Math.hypot(x - CAP_B[0], y - CAP_B[1]) ].min - STROKE
  end
end

# Barra vertical: cápsula entre dos puntos.
def bar_sdf(x, y)
  ty = y.clamp(BAR_Y1, BAR_Y2)
  Math.hypot(x - CX, y - ty) - STROKE
end

def mark_sdf(x, y)
  # El transform del SVG escala la marca alrededor del centro.
  mx = (x - CX) / SCALE + CX
  my = (y - CY) / SCALE + CY
  [ ring_sdf(mx, my), bar_sdf(mx, my) ].min
end

SAMPLES = 4
OFFSETS = (0...SAMPLES).map { |i| (i + 0.5) / SAMPLES }

def coverage(px, py)
  hits = 0
  OFFSETS.each do |oy|
    OFFSETS.each do |ox|
      hits += 1 if yield(px + ox, py + oy) <= 0.0
    end
  end
  hits.to_f / (SAMPLES * SAMPLES)
end

def chunk(type, data)
  [ data.bytesize ].pack("N") + type + data +
    [ Zlib.crc32(type + data) ].pack("N")
end

raw = +"".b
SIZE.times do |y|
  raw << 0.chr                                   # filtro "None" por scanline
  row = +"".b
  SIZE.times do |x|
    bg_a   = coverage(x.to_f, y.to_f) { |sx, sy| rounded_rect_sdf(sx, sy) }
    mark_a = coverage(x.to_f, y.to_f) { |sx, sy| mark_sdf(sx, sy) }
    mark_a = [ mark_a, bg_a ].min                # la marca no se sale del fondo

    alpha = bg_a
    if alpha.zero?
      row << 0.chr << 0.chr << 0.chr << 0.chr
    else
      # Composición "source-over" de la marca blanca sobre el navy, en alfa recto.
      3.times do |i|
        value = (MARK[i] * mark_a + BG[i] * (alpha - mark_a)) / alpha
        row << value.round.clamp(0, 255).chr
      end
      row << (alpha * 255).round.clamp(0, 255).chr
    end
  end
  raw << row
end

ihdr = [ SIZE, SIZE ].pack("NN") + [ 8, 6, 0, 0, 0 ].pack("C5")  # 8 bits, RGBA
png  = "\x89PNG\r\n\x1a\n".b +
       chunk("IHDR", ihdr) +
       chunk("IDAT", Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION)) +
       chunk("IEND", "")

out = ARGV[0] or abort("uso: render_icon.rb <ruta de salida>")
File.binwrite(out, png)
puts "escrito #{out} (#{png.bytesize} bytes, #{SIZE}x#{SIZE} RGBA)"
