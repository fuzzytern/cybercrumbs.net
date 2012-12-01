
module Jekyll
  module DateToFullStringFilter
    def ordinalize(day)
      if (11..13).include?(day % 100)
        "#{day}th"
      else
        case day % 10
        when 1; "#{day}<span class=\"ordinal\">st</span>"
        when 2; "#{day}<span class=\"ordinal\">nd</span>"
        when 3; "#{day}<span class=\"ordinal\">rd</span>"
        else    "#{day}<span class=\"ordinal\">th</span>"
        end
      end
    end
    def date_to_full_string(date)
      date.strftime("%B #{ordinalize(date.day)}, %Y")
    end
  end
end

Liquid::Template.register_filter(Jekyll::DateToFullStringFilter)

