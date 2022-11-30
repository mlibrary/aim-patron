class CurrentSchedule
  def initialize(config: CSV.read("./config/patron_load_schedule.tsv", headers: true, col_sep: "\t"), today: Date.today)
    @current_config = nil
    config.each.with_index do |row, index|
      if today < Date.parse(row["Update Date"])
        @current_config = config[index - 1]
        break
      end
    end
    @current_config = config[config.count - 1] if @current_config.nil?
  end

  def default_expiry_date
    Date.parse(@current_config["Expiry Date"])
  end

  def includable_term?(term)
    @current_config["Term"].split(", ").include?(term)
  end
end
