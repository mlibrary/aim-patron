class Patron
  class TemporaryStaffPerson < Patron::Employee
    def user_group
      "14"
    end

    def statistic_category
      "TS"
    end

    def hr_criteria(hr_item)
      hr_item.jobCategory == "Staff" && hr_item.regTemp == "T"
    end
  end
end
