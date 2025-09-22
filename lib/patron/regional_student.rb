class Patron
  class RegionalStudent < Patron::Student
    CLASS_STANDING_STATISTIC_CATEGORY_MAP = {
      "FR" => "UN",
      "SO" => "UN",
      "JR" => "UN",
      "SR" => "UN",
      "UN" => "UN",
      "UC" => "UN",
      "EP" => "UN",
      "PC" => "UN",
      "GR" => "GR",
      "DO" => "GR",
      "SP" => "GR",
      "PN" => "GR"
    }

    def ldap_campus
      raise NotImplementedError
      # if campus_code == "UMFL"
      # "flnt"
      # else
      # "dbrn"
      # end
    end

    def term(acad_period)
      # 5th caracter in academic period is the index-1 of the semester
      semester = ["F", "W", "SP", "SU"][acad_period[4].to_i - 1]

      # the 2 digit year year unless it's fall.
      year_ish = acad_period[2, 2].to_i

      year = (semester == "F") ? year_ish - 1 : year_ish

      "#{semester}#{year}"
    end

    def user_group
      case statistic_category
      when "UN"
        "04"
      when "GR"
        "03"
      end
    end

    def statistic_category
      current_term_status.map do |term|
        CLASS_STANDING_STATISTIC_CATEGORY_MAP[term.classStanding]
      end.compact.first
    end

    def current_term_status
      ldap_fields(@data["umich#{ldap_campus}currenttermstatus"] || [])
    end

    def job_description
      current_term_status.map do |term|
        term.programDesc
      end.compact.first
    end

    def includable?
      current_term_status.any? do |term|
        term.registered == "Y" && @current_schedule.includable_term?(term(term.academicPeriod))
      end
    end

    def exclude_reason
      "not_registered" unless includable?
    end
  end
end
