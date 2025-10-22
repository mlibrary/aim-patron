require "yabeda/prometheus"
class Report
  def self.configure_yabeda!
    Yabeda.configure do
      group :aim_patron_load do
        gauge :statistic_category, comment: "Number of loaded patrons in a statistic category", tags: [:name]
      end
    end
    Yabeda.configure!
  end

  def self.metrics
    Yabeda.aim_patron_load
  end

  def self.open(file_base, &block)
    File.open("#{file_base}.tsv", "w") do |fh|
      report = Report.new(fh)
      block.call(report)
    end
  end

  def initialize(fh)
    @fh = fh
  end

  def metrics
    self.class.metrics
  end

  def load(patron)
    @fh.write report_string(kind: "LOAD", patron: patron)
    metrics.statistic_category.increment({name: patron.statistic_category}, by: 1)
  end

  def skip(patron)
    @fh.write report_string(kind: "SKIP", patron: patron)
  end

  def report_string(kind:, patron:)
    [
      kind,
      patron.umid.value,
      patron.uniqname,
      patron.campus_code,
      patron.user_group,
      patron.statistic_category,
      patron.exclude_reasons
    ].join("\t")
  end
end

Report.configure_yabeda!
