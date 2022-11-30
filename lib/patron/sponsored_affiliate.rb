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
      ALLOWED_SPONSOR_REASONS.include?(hr_item.umichSponsorReason) && hr_item.deptDescription != "LSA UG: UROP" && includable_start_date?(hr_item.umichSponsorStartDate) && includable_end_date?(hr_item.umichSponsorEndDate)
    end

    def hr_attribute
      "umichsponsorshipdetail"
    end

    def expiry_date
      if umichSponsorEndDate < super
        umichSponsorEndDate
      else
        super
      end
    end

    def purge_date
      expiry_date.next_year(2)
    end

    def umichSponsorEndDate
      parse_date(hr_data.umichSponsorEndDate)
    end

    def includable_start_date?(start_date_str)
      parse_date(start_date_str) <= Date.today
    rescue
      false
    end

    def includable_end_date?(end_date_str)
      parse_date(end_date_str) >= Date.today
    rescue
      false
    end

    def parse_date(date_str)
      Date.strptime(date_str, "%m/%d/%Y")
    end
  end
end
