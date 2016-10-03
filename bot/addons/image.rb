require 'RMagick'
include Magick


def text_fit?(text, width, size)
  tmp_image = Image.new(width, 500)
  drawing = Draw.new
  drawing.annotate(tmp_image, 0, 0, 0, 0, text) { |txt|
    txt.gravity = Magick::NorthGravity
    txt.pointsize = size
    txt.fill = "#ffffff"
    txt.font_family = 'helvetica'
    txt.font_weight = Magick::BoldWeight
  }
  metrics = drawing.get_multiline_type_metrics(tmp_image, text)
  (metrics.width < width)
end


def fit_text(text, width, size)
  separator = ' '
  line = ''
  nline = 1
  if not text_fit?(text, width, size) and text.include? separator
    i = 0
    text.split(separator).each do |word|
      if i == 0
        tmp_line = line + word
      else
        tmp_line = line + separator + word
      end

      if text_fit?(tmp_line, width, size)
        unless i == 0
          line += separator
        end
        line += word
      else
        unless i == 0
          line +=  '\n'
          nline += 1
        end
        line += word
      end
      i += 1
    end
    text = line
  end
  return text, nline
end

def create_image(title, name, input, output)
    size = 50
    sizeMin = 20
    lineMax = 2
    line    = 1

    canvas = ImageList.new(input)
    h = canvas.rows
    w = canvas.columns
    while not text_fit?(title, w, size) and size > sizeMin do
        size -= 5
    end
    if not text_fit?(title, w, size) then
        title, line = fit_text(title, w, sizeMin)
    end
    if line > lineMax
        puts "Le texte est trop long (#{line} > #{lineMax})"
    end

    size2 = [30, size - 5].min

    # white undercolor
    gc = Magick::Draw.new
    gc.fill = "#00000060"
    y = h/2 - line*size - size2 + 20
    gc.rectangle 0, y, w, size*line + size2 + 30 + y
    gc.draw(canvas)

    txt = Magick::Draw.new
    txt.font_family   = "Georgia"
    txt.fill          = "#FFFFFF"
    txt.pointsize     = size
    txt.gravity       = Magick::CenterGravity
    canvas.annotate(txt, w, h, 0, -size/2, title)
    txt.pointsize     = size2
    canvas.annotate(txt, w, h, 0, size/2+10, name)



    canvas.write(output)
end

#--------- test
# name = "Confucius"
# title = "Zen is definitely so fucking cool and crazy, dude!"
# create_image(title, name,  "environnement.jpg", "out.jpg")
