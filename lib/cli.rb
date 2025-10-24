require "thor"
require_relative "process_ldap"

class CLI < Thor
  def self.exit_on_failure?
    true
  end

  desc "full", "Process all of the users in mcommunity"
  method_option :output_directory, type: :string, required: false, default: S.output_directory, desc: "Path to directory for output files"
  method_option :base_name, type: :string, required: false, default: "patron_full_#{Date.today.strftime("%Y%m%d")}", desc: "Basename for files put in the output directory"
  method_option :size, type: :numeric, required: false, desc: "The maximum number of results to request"
  def full
    new_options = {
      size: options[:size],
      base_name: options[:base_name],
      output_directory: options[:output_directory]
    }
    ProcessLdap.new(**new_options).process
  end

  desc "daily FROM_DATE", "Process the users in mcommunity modified or created after the FROM_DATE 000000 UTC. For full coverage, the FROM_DATE for a daily cronjob should be yesterday."
  method_option :output_directory, type: :string, required: false, default: S.output_directory, desc: "Path to directory for output files"
  method_option :base_name, type: :string, required: false, default: "patron_daily_#{Date.today.strftime("%Y%m%d")}", desc: "Basename for files put in the output directory"
  method_option :size, type: :numeric, required: false, desc: "The maximum number of results to request"
  def daily(from_date)
    new_options = {
      date: format_date(from_date),
      base_name: options[:base_name],
      output_directory: options[:output_directory],
      size: options[:size]
    }
    ProcessLdapDaily.new(**new_options).process
  end

  desc "range", "Process the users for a given date range"
  method_option :start_date, type: :string, required: true
  method_option :end_date, type: :string, required: false, desc: "The end of the date range. Inclusive. If not given, it defaults to whatever start_date is."
  method_option :size, type: :numeric, required: false, desc: "The maximum number of results to request"
  method_option :output_directory, type: :string, required: false, default: S.output_directory, desc: "Path to directory for output files"
  method_option :base_name, type: :string, required: false, desc: "Basename for files put in the output directory; default is patron_range_YYYYMMDD_to_YYYYMMDD"
  def range
    new_options = {
      start_date: format_date(options[:start_date]),
      end_date: format_date(options[:end_date] || options[:start_date]),
      size: options[:size],
      output_directory: options[:output_directory]
    }

    new_options[:base_name] = options[:base_name] || "patron_range_#{new_options[:start_date]}_to_#{new_options[:end_date]}"

    ProcessLdapModifyDateRange.new(**new_options).process
  end

  desc "one UNIQNAME", "Return the xml for a given user"
  def one(uniqname)
    ProcessLdapOneUser.new(uniqname: uniqname).process
  end

  desc "ldap UNIQNAME", "Return the LDAP info for a given user"
  def ldap(uniqname)
    ProcessLdapOneUser.new(uniqname: uniqname).ldap_output
  end

  private

  no_commands do
    def format_date(date)
      date = DateTime.parse(date) if date.is_a? String
      date.strftime("%Y%m%d")
    rescue Date::Error
      abort("ERROR: parameter/option #{date} must be a valid date string\n")
    end
  end
end
