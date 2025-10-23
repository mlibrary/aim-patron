require "yabeda/prometheus"
class Report
  def self.configure_yabeda!
    Yabeda.configure do
      group :aim_patron_load do
        gauge :loaded, comment: "Number of loaded patrons", tags: [:script_type]
        gauge :skipped, comment: "Number of skipped patrons", tags: [:script_type]
        gauge :found, comment: "Number of found patrons", tags: [:script_type]
        gauge :statistic_category, comment: "Number of loaded patrons in a statistic category", tags: [:script_type, :name]
        gauge :error, comment: "Number of errors encountered while running the patron load", tags: [:script_type]
      end
    end
    Yabeda.configure!
  end

  def self.metrics
    Yabeda.aim_patron_load
  end

  def self.print_metrics
    Prometheus::Client::Formats::Text.marshal(Yabeda::Prometheus.registry)
  end

  def self.open(file_base:, script_type:, &block)
    File.open("#{file_base}.tsv", "w") do |fh|
      report = Report.new(fh: fh, script_type: script_type)
      block.call(report)
    end
  end

  def initialize(fh:, script_type:)
    @fh = fh
    @script_type = script_type
  end

  def metrics
    self.class.metrics
  end

  def load(patron)
    @fh.write report_string(kind: "LOAD", patron: patron)
    metrics.found.increment({script_type: @script_type})
    metrics.loaded.increment({script_type: @script_type})
    metrics.statistic_category.increment({script_type: @script_type, name: patron.statistic_category})
  end

  def skip(patron)
    @fh.write report_string(kind: "SKIP", patron: patron)
    metrics.found.increment({script_type: @script_type})
    metrics.skipped.increment({script_type: @script_type})
  end

  def report_string(kind:, patron:)
    [
      kind,
      patron.umid.value,
      patron.uniqname,
      patron.campus_code,
      patron.user_group,
      patron.statistic_category
      # patron.exclude_reasons
    ].join("\t") + "\n"
  end
end

Report.configure_yabeda!
