class DistanceCalculator
  EARTH_RADIUS_MILES = 3_958.8
  EARTH_RADIUS_KILOMETRES = 6_371.0

  def self.miles_between(latitude_one:, longitude_one:, latitude_two:, longitude_two:)
    calculate(
      latitude_one: latitude_one,
      longitude_one: longitude_one,
      latitude_two: latitude_two,
      longitude_two: longitude_two,
      earth_radius: EARTH_RADIUS_MILES
    )
  end

  def self.kilometres_between(latitude_one:, longitude_one:, latitude_two:, longitude_two:)
    calculate(
      latitude_one: latitude_one,
      longitude_one: longitude_one,
      latitude_two: latitude_two,
      longitude_two: longitude_two,
      earth_radius: EARTH_RADIUS_KILOMETRES
    )
  end

  def self.calculate(
    latitude_one:,
    longitude_one:,
    latitude_two:,
    longitude_two:,
    earth_radius:
  )
    lat1 = degrees_to_radians(latitude_one.to_f)
    lon1 = degrees_to_radians(longitude_one.to_f)
    lat2 = degrees_to_radians(latitude_two.to_f)
    lon2 = degrees_to_radians(longitude_two.to_f)

    latitude_difference = lat2 - lat1
    longitude_difference = lon2 - lon1

    a =
      Math.sin(latitude_difference / 2)**2 +
      Math.cos(lat1) *
      Math.cos(lat2) *
      Math.sin(longitude_difference / 2)**2

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    earth_radius * c
  end

  def self.degrees_to_radians(degrees)
    degrees * Math::PI / 180
  end

  private_class_method :calculate, :degrees_to_radians
end