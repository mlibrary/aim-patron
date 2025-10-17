class Patron
  class TemporaryStaffPerson < Patron::Employee
    def user_group
      "14"
    end

    def role
      "temporary_staff"
    end

    def statistic_category
      "TS"
    end

    def hr_criteria(hr_item)
      job_category_staff?(hr_item) && temporary_employee?(hr_item)
      # hr_item.jobCategory == "Staff" && hr_item.regTemp == "T"
    end

    def exclude_reason
      if hr_list.none? { |x| job_category_staff?(x) }
        "job_category_not_staff"
      elsif hr_list.none? { |x| temporary_employee?(x) }
        "not_temporary_employee"
      end
    end

    def temporary_employee?(hr_item)
      hr_item.regTemp == "T"
    end

    def job_category_staff?(hr_item)
      hr_item.jobCategory == "Staff"
    end
  end
end
