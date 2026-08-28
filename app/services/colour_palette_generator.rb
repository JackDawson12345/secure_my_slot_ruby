class ColourPaletteGenerator
  def initialize(hex)
    @hex = hex.delete("#")
  end

  def generate
    r = @hex[0..1].to_i(16)
    g = @hex[2..3].to_i(16)
    b = @hex[4..5].to_i(16)

    {
      "50"   => adjust(r, g, b, 0.95),
      "100"  => adjust(r, g, b, 0.85),
      "200"  => adjust(r, g, b, 0.65),
      "300"  => adjust(r, g, b, 0.45),
      "400"  => adjust(r, g, b, 0.20),
      "500"  => format_hex(r, g, b),
      "600"  => adjust(r, g, b, -0.10),
      "700"  => adjust(r, g, b, -0.20),
      "800"  => adjust(r, g, b, -0.35),
      "900"  => adjust(r, g, b, -0.45),
      "950"  => adjust(r, g, b, -0.60)
    }
  end

  private

  def adjust(r, g, b, amount)
    if amount > 0
      r = r + ((255 - r) * amount)
      g = g + ((255 - g) * amount)
      b = b + ((255 - b) * amount)
    else
      factor = 1 + amount

      r *= factor
      g *= factor
      b *= factor
    end

    format_hex(r, g, b)
  end

  def format_hex(r, g, b)
    "#%02X%02X%02X" % [
      r.round.clamp(0, 255),
      g.round.clamp(0, 255),
      b.round.clamp(0, 255)
    ]
  end
end