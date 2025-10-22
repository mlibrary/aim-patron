require "thor"
require_relative "process_ldap"

class CLI < Thor
  def self.exit_on_failure?
    true
  end

  desc "full", "processes all of the users in mcommunity"
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

  desc "range", "processes users for a given date range"
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

  desc "one UNIQNAME", "returns the xml for the uniqname"
  def one(uniqname)
    ProcessLdapOneUser.new(uniqname: uniqname).process
  end

  desc "ldap UNIQNAME", "returns the ldap info for a user"
  def ldap(uniqname)
    ProcessLdapOneUser.new(uniqname: uniqname).ldap_output
  end

  private

  no_commands do
    def format_date(date)
      date = DateTime.parse(date) if date.is_a? String
      date.strftime("%Y%m%d")
    end
  end
end
