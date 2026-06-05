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
