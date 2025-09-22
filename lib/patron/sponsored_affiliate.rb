class Patron
  class SponsoredAffiliate < Patron::Employee
    # list of sponsor reasons as of October 2022
    # the disallowed reasons have been commented out
    ALLOWED_SPONSOR_REASONS = [
      # "Affiliates",
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

    def role
      "sponsored_affiliate"
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
      valid_sponsor_reason?(hr_item) && hr_item.deptDescription != "LSA UG: UROP" && valid_start_date?(hr_item) && valid_end_date?(hr_item)
    end

    def exclude_reason
      if hr_list.none? { |x| valid_sponsor_reason?(x) }
        "invalid_sponsor_reason"
      elsif hr_list.none? { |x| not_in_urop?(x) }
        "in_urop"
      elsif hr_list.none? { |x| valid_start_date?(x) }
        "start_date_in_the_future"
      elsif hr_list.none? { |x| valid_end_date?(x) }
        "end_date_in_the_past"
      elsif !new_hire_or_temporary_staff?
        "not_new_hire_or_temporary_staff"
      end
    end

    def valid_start_date?(hr_item)
      includable_start_date?(hr_item.umichSponsorStartDate)
    end

    def valid_end_date?(hr_item)
      includable_end_date?(hr_item.umichSponsorEndDate)
    end

    def not_in_urop?(hr_item)
      hr_item.deptDescription != "LSA UG: UROP"
    end

    def valid_sponsor_reason?(hr_item)
      ALLOWED_SPONSOR_REASONS.include?(hr_item.umichSponsorReason)
    end

    def hr_attribute
      "umichsponsorshipdetail"
    end

    def new_hire_or_temporary_staff?
      @data["umichinstroles"].include?("NewHire") || @data["umichinstroles"].include?("TemporaryStaffAA")
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
