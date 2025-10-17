class Patron
  class Retiree < Patron::Employee
    def user_group
      "01"
    end

    def role
      "retiree"
    end

    def hr_criteria(hr_item)
      # this will need to be changed to exclude faculty
      hr_item.jobCategory == "Faculty"
      #  true
    end

    def statistic_category
      "RF"
    end

    def exclude_reason
      "retired_person_not_faculty" unless includable?
    end
  end
end
