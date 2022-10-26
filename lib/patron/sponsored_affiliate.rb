class Patron
  class SponsoredAffiliate < Patron::Employee
    def user_group
    end

    def statistic_category
    end

    def hr_criteria(hr_item)
      # this will need to be changed to exclude UROP deptDescription
      true
    end

    def hr_attribute
      "umichsponsorshipdetail"
    end

    # def includable?
    # end
  end
end
