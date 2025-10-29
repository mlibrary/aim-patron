require "yabeda/prometheus"
require "uri"
require "forwardable"
class Report
  COLUMN_NAMES = [
    "action",
    "umid",
    "uniqname",
    "campus",
    "user_group",
    "statistic_category",
    "sponsor_reason",
    "exclude_reasons"
  ]
  def self.configure_yabeda!
    Yabeda.configure do
      default_tag :script_type, "test"
      group :aim_patron_load do
        gauge :loaded, comment: "Number of loaded patrons"
        gauge :skipped, comment: "Number of skipped patrons"
        gauge :found, comment: "Number of found patrons"
        gauge :patron_kind, comment: "Number of patrons in a given major category", tags: [:name]
        gauge :campus, comment: "Number of patrons in a given campus", tags: [:name]
        gauge :user_group, comment: "Number of patrons in a given Alma User Group", tags: [:name]
        gauge :statistic_category, comment: "Number of loaded patrons in a statistic category", tags: [:name]
        gauge :sponsor_reason, comment: "Number of loaded Sponsored Affiliates with a given sponsor reason", tags: [:name]
        gauge :exclude_reason, comment: "Number of patrons skipped for a given reason", tags: [:name]
        gauge :error, comment: "Number of errors encountered while running the patron load"
        gauge :job_duration_seconds, comment: "Number of seconds it took to run the patron load job"
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

  def self.column_names
    COLUMN_NAMES
  end

  def self.push_metrics
    # The env var needs to be set to the push gateway url
    if ENV["PROMETHEUS_PUSH_GATEWAY"]&.match?(URI::DEFAULT_PARSER.make_regexp)
      Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
      S.logger.info("Metrics sent to the push gateway")
    else
      S.logger.warn("PROMETHEUS_PUSH_GATEWAY env var not set. Metrics not sent to the push gateway")
    end
  end

  def self.open(file_base, script_type: "whatever", &block)
    if file_base
      File.open("#{file_base}.tsv", "w") do |fh|
        report = Report.new(fh)
        block.call(report)
      end
    else
      StringIO.open do |fh|
        report = Report.new(fh)
        block.call(report)
        puts "\n"
        puts fh.string
        puts "\n"
      end
    end
  end

  def initialize(fh)
    @fh = fh
    @fh.write self.class.column_names.join("\t") + "\n"
  end

  def metrics
    self.class.metrics
  end

  def load(patron)
    patron = Patron.new(patron: patron, action: "load")
    @fh.write patron.report_string
    metrics.found.increment
    metrics.loaded.increment
    ["patron_kind", "statistic_category", "user_group", "campus", "sponsor_reason"].each do |metric|
      increment_metric(metric, patron)
    end
  end

  def skip(patron)
    patron = Patron.new(patron: patron, action: "skip")
    @fh.write patron.report_string
    metrics.found.increment
    metrics.skipped.increment
  end

  def report_string(kind:, patron:)
    [
      kind,
      patron.umid,
      patron.uniqname,
      patron.campus,
      patron.user_group,
      patron.statistic_category
      # patron.exclude_reasons
    ].join("\t") + "\n"
  end

  def increment_metric(metric, patron)
    metrics.public_send(metric).increment({name: patron.public_send(metric)}) if patron.public_send(metric)
  end

  class Patron
    extend Forwardable

    def_delegators :@patron, :uniqname

    # From the User Group Code Table 2025-10-29. Does not include codes that
    # will never get set here.
    USER_GROUP_MAP = {
      "01" => "faculty",
      "02" => "staff",
      "03" => "graduate",
      "04" => "undergraduate",
      "14" => "temporary_staff"
    }

    CAMPUS_MAP = {
      "UMAA" => "ann_arbor",
      "UMDB" => "dearborn",
      "UMFL" => "flint"
    }

    # From the User Statistical Categories Code Table 2025-10-29. Includes all
    # of the codes, even the ones that will never get set with this code
    STATISTIC_CATEGORY_MAP = {
      "FA" =>	"faculty",
      "WD" =>	"william_davidson_inst",
      "ST" =>	"staff",
      "GR" =>	"graduate",
      "UN" =>	"undergrad",
      "SA" =>	"sponsored_affiliate",
      "TS" =>	"temp_staff",
      "CN" =>	"contractor",
      "CD" =>	"candidate",
      "DS" =>	"detached_study",
      "AF" =>	"adjunct_faculty",
      "AL" =>	"alumni-fee_based",
      "CA" =>	"carrel",
      "CI" =>	"cic",
      "D1" =>	"dietetics_intern_med",
      "DB" =>	"debater",
      "DO" =>	"docent",
      "EM" =>	"emeritus",
      "GS" =>	"guest",
      "HH" =>	"howard_hughes_med_inst",
      "IL" =>	"ill",
      "JF" =>	"journalism_fellow",
      "MI" =>	"faculty_from_michigan",
      "EU" =>	"emu",
      "MR" =>	"mrlt",
      "OT" =>	"other",
      "PR" =>	"proxy",
      "RC" =>	"religious_counselor",
      "RE" =>	"reserve",
      "RF" =>	"retired_faculty",
      "RS" =>	"retired_staff",
      "SP" =>	"spouse",
      "SU" =>	"summer_program",
      "WC" =>	"wash_comm_college",
      "GE" =>	"geo",
      "FR" =>	"free_guest",
      "SH" =>	"shares"
    }

    def initialize(patron:, action: "whatever")
      @patron = patron
      @action = action
    end

    def action
      @action.upcase
    end

    def umid
      @patron.umid.value
    end

    def user_group
      USER_GROUP_MAP[@patron.user_group] || @patron.user_group
    end

    def campus
      CAMPUS_MAP[@patron.campus_code] || @patron.campus_code
    end

    def statistic_category
      STATISTIC_CATEGORY_MAP[@patron.statistic_category] || @patron.statistic_category
    end

    def sponsor_reason
      @patron.sponsor_reason&.downcase
    end

    def patron_kind
      to_snake(@patron.class.name.split("::").last)
    end

    def exclude_reasons
      @patron.exclude_reasons.join(",")
    end

    def report_string
      Report.column_names.map do |method|
        public_send(method)
      end.join("\t") + "\n"
    end

    private

    def to_snake(str)
      str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end
  end
end

Report.configure_yabeda!
