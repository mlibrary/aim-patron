class Patron
  class Retiree < Patron::Employee
    def user_group
      "01"
    end

    def hr_criteria(hr_item)
      # this will need to be changed to exclude faculty
      hr_item.jobCategory == "Faculty"
      #  true
    end

    def statistic_category
      "RF"
    end

    def includable?
      # this will see if hr_data has anything
      !hr_data.nil?
    end
  end
end
