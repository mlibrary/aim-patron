require "ostruct"
class CurrentSchedule
  def initialize(config: CSV.read("./config/patron_load_schedule.tsv", headers: true, col_sep: "\t"), today: Date.today)
    @current_config = nil
    config.each.with_index do |row, index|
      if today < Date.parse(row["Update Date"])
        @current_config = config[index - 1]
        break
      end
    end
    @current_config = config[-1] if @current_config.nil?
  end

  def default_expiry_date
    Date.parse(@current_config["Expiry Date"])
  end

  def includable_term?(term)
    @current_config["Term"].split(", ").include?(term)
  end
end

class NewCurrentSchedule
  FRIDAY_OFFSET = [5, 4, 3, 2, 1, 0, 6]
  SUNDAY_OFFSET = [0, 6, 5, 4, 3, 2, 1]
  attr_reader :today

  def initialize(today)
    @today = today
  end

  def expiry_date
    case update_date.month
    when 4
      august_expiry_date(update_date.year)
    when 8
      january_expiry_date(update_date.year + 1)
    when 12
      may_expiry_date(update_date.year + 1)
    end
  end

  def update_date
    december_last_year = december_update_date(today.year - 1)
    april_this_year = april_update_date(today.year)
    august_this_year = august_update_date(today.year)
    december_this_year = december_update_date(today.year)

    if today >= december_last_year && today < april_this_year
      december_last_year
    elsif today >= april_this_year && today < august_this_year
      april_this_year
    elsif today >= august_this_year && today < december_this_year
      august_this_year
    else
      december_this_year
    end
  end

  private

  def expiry_for_update_date
    case update_date.month
    when 4
      august_expiry_date(update_date.year)
    when 8
      january_expiry_date(update_date.year + 1)
    when 12
      may_expiry_date(update_date.year + 1)
    end
  end

  # last sunday in August
  def august_expiry_date(year)
    first = Date.new(year, 8)
    offset = SUNDAY_OFFSET[first.wday]
    fourth_sunday = Date.new(year, 8, 22 + offset)
    return fourth_sunday + 7 if fourth_sunday.day < 25
    fourth_sunday
  end

  # first sunday in August
  def january_expiry_date(year)
    first = Date.new(year)
    offset = SUNDAY_OFFSET[first.wday]
    Date.new(year, 1, 1 + offset)
  end

  # first sunday in May
  def may_expiry_date(year)
    first = Date.new(year, 5)
    offset = SUNDAY_OFFSET[first.wday]
    Date.new(year, 5, 1 + offset)
  end

  # second friday in december
  def december_update_date(year)
    first = Date.new(year, 12)
    offset = FRIDAY_OFFSET[first.wday]
    Date.new(year, 12, 8 + offset)
  end

  # first friday in April
  def april_update_date(year)
    first = Date.new(year, 4)
    offset = FRIDAY_OFFSET[first.wday]
    Date.new(year, 4, 1 + offset)
  end

  # first friday in August
  def august_update_date(year)
    first = Date.new(year, 8)
    offset = FRIDAY_OFFSET[first.wday]
    Date.new(year, 8, 1 + offset)
  end
end

class NewCurrentSchedule
  class Term
    FRIDAY_OFFSET = [5, 4, 3, 2, 1, 0, 6]
    def initialize(year)
      @year = year
      @jan_first = Date.new(year)
    end

    def suffix
      @jan_first.strftime("%y")
    end

    def text
      "#{prefix}#{suffix}"
    end

    def in_range(date)
      date >= term_range.start && date < term_range.finish
    end

    private

    def friday_in_month(month:, week_number: 1, next_year: false)
      year = next_year ? @year + 1 : @year
      # week_number = 1; day_number = 1
      # week_number = 2; day_number = 8
      # week_number = 3; day_number = 15
      day_number = 1 + ((week_number - 1) * 7)
      first = Date.new(year, month)
      offset = FRIDAY_OFFSET[first.wday]
      Date.new(year, month, day_number + offset)
    end
  end

  class Winter < Term
    def prefix
      "W"
    end

    def term_range
      OpenStruct.new(start: friday_in_month(month: 1, week_number: 2), finish: friday_in_month(month: 4))
    end
  end

  class Spring < Term
    def prefix
      "SP"
    end

    # First Friday in April to First Friday in July
    def term_range
      OpenStruct.new(start: friday_in_month(month: 4), finish: friday_in_month(month: 7))
    end
  end

  class Summer < Term
    def prefix
      "SU"
    end

    # First Friday in April to First Friday in August
    def term_range
      OpenStruct.new(start: friday_in_month(month: 4), finish: friday_in_month(month: 8))
    end
  end

  class SpringSummer < Term
    def prefix
      "SS"
    end

    # First Friday in April to First Friday in August
    def term_range
      OpenStruct.new(start: friday_in_month(month: 4), finish: friday_in_month(month: 8))
    end
  end

  class Fall < Term
    def prefix
      "F"
    end

    #
    # First Friday in April to Second Friday in January next year
    def term_range
      OpenStruct.new(start: friday_in_month(month: 4), finish: friday_in_month(month: 1, week_number: 2, next_year: true))
    end
  end
end
