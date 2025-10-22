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

    def statistic_category
    end

    def campus_code
    end

    def user_group
    end
  end
end
