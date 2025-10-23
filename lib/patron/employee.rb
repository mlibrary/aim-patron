class Patron
  class Employee < Patron
    HR_CAMPUS_MAP = {
      "um_ann-arbor" => "UMAA",
      "um_flint" => "UMFL",
      "um_dearborn" => "UMDB"
    }

    def role
      raise NotImplementedError
    end

    def hr_criteria(hr_item)
      raise NotImplementedError
    end

    [
      "statistic_category",
      "user_group",
      "exclude_reason"
    ].each do |method|
      define_method method do
        # all of these are NotImplementedError
        super
      end
    end

    def campus_code
      HR_CAMPUS_MAP[hr_data.campus.downcase]
    end

    def email_type
      "work"
    end

    def exclude_reason
      raise NotImplementedError
    end

    def includable?
      !hr_data.nil?
    end

    def umich_address_type
      "work"
    end

    def job_description
      "#{hr_data.deptDescription} (#{hr_data.deptId})"
    end

    def hr_attribute
      "umichhr"
    end

    def hr_list
      @hr_list ||= begin
        hr = (role == "sponsored_affiliate") ? @data["umichsponsorshipdetail"] : @data[hr_attribute]
        raise StandardError, "No HR data" if hr.nil? # there always has to be hrdata
        result = ldap_fields(hr)
        S.logger.debug("hr_list", uniqname: uniqname, class: self.class, data: result)
        result
      end
    end

    def hr_filtered
      @hr_filtered ||= begin
        result = hr_list.filter do |hr_item|
          hr_criteria(hr_item)
        end
        S.logger.debug("hr_filtered", uniqname: uniqname, class: self.class, data: result)
        result
      end
    end

    def hr_data
      @hr_data ||= begin
        library_job = hr_filtered.find { |x| x.deptId =~ /^47/ }
        result = library_job || hr_filtered.first
        S.logger.debug("hr_data", class: self.class, uniqname: uniqname, data: result)
        result
      end
    end
  end
end
