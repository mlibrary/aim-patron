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
    end

    def campus_code
      raise NotImplementedError
    end

    def exclude_reason
      "not_registered" unless includable?
    end

    def includable?
      @includable ||= begin
        S.logger.debug("#{self.class}; current term: #{current_term}; registered: #{current_term_status.registered || "N"}")
        current_term_status.registered == "Y" && @current_schedule.includable_term?(current_term)
      end
    end

    def job_description
      current_term_status.programDesc
    end

    def statistic_category
      CLASS_STANDING_STATISTIC_CATEGORY_MAP[current_term_status.classStanding]
    end

    def user_group
      case statistic_category
      when "UN"
        "04"
      when "GR"
        "03"
      end
    end

    def term(acad_period)
      # 5th caracter in academic period is the index-1 of the semester
      semester = ["F", "W", "SP", "SU"][acad_period[4].to_i - 1]

      # the 2 digit year year unless it's fall.
      year_ish = acad_period[2, 2].to_i

      year = (semester == "F") ? year_ish - 1 : year_ish

      "#{semester}#{year}"
    end

    def current_term
      @current_term ||= current_term_status.academicPeriod ? term(current_term_status.academicPeriod) : "NONE"
    end

    def current_term_status
      @current_term_status ||= begin
        if !@data["umich#{ldap_campus}currenttermstatus"].empty?
          return ldap_fields(@data["umich#{ldap_campus}currenttermstatus"]).first
        end

        ldap_fields(@data["umich#{ldap_campus}termstatus"])
          .select { |x| x.registered == "Y" }
          .sort_by { |x| x.academicPeriod }
          .rfind do |t|
            @current_schedule.includable_term?(term(t.academicPeriod))
          end || OpenStruct.new
      end

      # ldap_fields(@data["umich#{ldap_campus}currenttermstatus"] + @data["umich#{ldap_campus}termstatus"])
    end
  end

  class DearbornStudent < Patron::RegionalStudent
    def ldap_campus
      "dbrn"
    end

    def campus_code
      "UMDB"
    end
  end

  class FlintStudent < Patron::RegionalStudent
    def ldap_campus
      "flnt"
    end

    def campus_code
      "UMFL"
    end
  end
end
