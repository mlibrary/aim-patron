class Patron
  class StaffPerson < Patron::Employee
    GEO_JOBCODES = [
      "205000", # GRAD STU INSTR
      "205400", # GRAD STU RES ASST
      "205800" # GRAD STU STAFF ASST
    ]

    def role
      "staff"
    end

    def user_group
      geo? ? "01" : "02"
    end

    def statistic_category
      geo? ? "GE" : "ST"
    end

    def hr_criteria(hr_item)
      job_category_staff?(hr_item) && regular_employee?(hr_item)
    end

    def exclude_reason
      if hr_list.none? { |x| job_category_staff?(x) }
        "job_category_not_staff"
      elsif hr_list.none? { |x| regular_employee?(x) }
        "not_regular_employee"
      end
    end

    def regular_employee?(hr_item)
      hr_item.regTemp == "R"
    end

    def job_category_staff?(hr_item)
      hr_item.jobCategory == "Staff"
    end

    def geo?
      GEO_JOBCODES.include?(hr_data.jobcode)
    end
  end
end
