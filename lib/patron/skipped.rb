class Patron
  class Skipped < Patron
    def initialize(data:, exclude_reasons:, name: Name.new(data), current_schedule: CurrentSchedule.new)
      @data = data
      @name = name
      @current_schedule = current_schedule
      @exclude_reasons = exclude_reasons
    end

    def includable?
      false
    end

    [
      "campus_code",
      "email_type",
      "exclude_reason",
      "job_description",
      "statistic_category",
      "umich_address_type",
      "user_group"
    ].each { |method| define_method(method) {} }
  end
end
