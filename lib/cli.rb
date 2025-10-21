require "thor"
require_relative "process_ldap"

class CLI < Thor
  def self.exit_on_failure?
    true
  end

  desc "range", "processes users for a given date range"
  method_option :start_date, type: :string, required: true
  method_option :end_date, type: :string, required: false, desc: "The end of the date range. Inclusive. If not given, it defaults to whatever start_date is."
  method_option :size, type: :numeric, required: false, desc: "The maximum number of results to request"
  def range
    new_options = {
      start_date: options[:start_date],
      end_date: options[:end_date] || options[:start_date],
      size: options[:size]
    }
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
end
