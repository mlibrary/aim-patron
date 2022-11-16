class Patron
  class SponsoredAffiliate < Patron::Employee
    # list of sponsor reasons as of October 2022
    # the disallowed reasons have been commented out
    ALLOWED_SPONSOR_REASONS = [
      "Affiliates",
      # "Associates",
      "Contractors",
      "Faculty",
      # "LibraryContent",
      # "Other Guests",
      # "PC Participants",
      "Researchers",
      # "Subscribers",
      "Temporary Staff"
    ]
    def user_group
      "01"
    end

    def statistic_category
      if hr_data.umichSponsorReason == "Contractors"
        "CN"
      else
        "SA"
      end
    end

    def hr_criteria(hr_item)
      # this will need to be changed to exclude UROP deptDescription
      true
    end

    def hr_attribute
      "umichsponsorshipdetail"
    end

    def expiry_date
      Date.parse(hr_data.umichSponsorEndDate)
    end

    # def includable?
    # end
  end
end
