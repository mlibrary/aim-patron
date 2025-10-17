class Patron
  class Employee < Patron
    HR_CAMPUS_MAP = {
      "um_ann-arbor" => "UMAA",
      "um_flint" => "UMFL",
      "um_dearborn" => "UMDB"
    }

    def includable?
      !hr_data.nil?
    end

    def user_group
      raise NotImplementedError
    end

    def role
      raise NotImplementedError
    end

    def statistic_category
      raise NotImplementedError
    end

    def exclude_reason
      raise NotImplementedError
    end

    def hr_criteria(hr_item)
      raise NotImplementedError
    end

    def campus_code
      HR_CAMPUS_MAP[hr_data.campus.downcase]
    end

    def job_description
      "#{hr_data.deptDescription} (#{hr_data.deptId})"
    end

    def email_type
      "work"
    end

    def umich_address_type
      "work"
    end

    def hr_attribute
      "umichhr"
    end

    def hr_list
      hr = (role == "sponsored_affiliate") ? @data["umichsponsorshipdetail"] : @data[hr_attribute]
      raise if hr.nil? # there always has to be hrdata
      ldap_fields(hr)
    end

    def hr_filtered
      hr_list.filter do |hr_item|
        hr_criteria(hr_item)
      end
    end

    def hr_data
      library_job = hr_filtered.find { |x| x.deptId =~ /^47/ }
      library_job || hr_filtered.first
    end
  end
end
