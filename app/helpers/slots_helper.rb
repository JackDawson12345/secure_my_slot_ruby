module SlotsHelper
  def format_next_slot(slot)
    return "No availability" if slot.nil?

    day_label =
      case slot[:date]
      when Date.current  then "Today"
      when Date.tomorrow then "Tomorrow"
      else slot[:date].strftime("%a %-d %b")
      end

    time_label = Time.zone.parse(slot[:time]).strftime("%-l:%M %p")

    "#{day_label}, #{time_label}"
  end
end