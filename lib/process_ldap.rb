require "json"
require "yaml"
require "net/ldap"
require "date"
require "byebug"
require "csv"

require_relative "services"
require_relative "patron"
require_relative "patron_mapper"
require_relative "current_schedule"
class ProcessLdap
  def self.ldap_attributes
    [
      "createtimestamp",
      "modifytimestamp",
      "displayName",
      "umichDisplaySn",
      "umichDisplayMiddle",
      "givenName",
      "homePhone",
      "mobile",
      "telephoneNumber",
      "umichPermanentPhone",
      "mail",
      "umichInstRoles",
      "umichAAAcadProgram",
      "umichAATermStatus",
      "umichDbrnCurrentTermStatus",
      "umichDbrnTermStatus",
      "umichFlntCurrentTermStatus",
      "umichFlntTermStatus",
      "umichHR",
      "umichSponsorshipDetail",
      "entityid",
      "uid",
      "umichScholarId",
      "umichHomePostalAddressData",
      "umichPermanentPostalAddressData",
      "umichPostalAddressData"
    ]
  end

  def self.roles_filter
    [
      "StudentDBRN",
      "StudentFLNT",
      "StudentAA",
      "Faculty*",
      "RegularStaff*",
      "TemporaryStaffAA",
      "SponsoredAffiliateAA",
      "Retiree"
    ].map do |role|
      Net::LDAP::Filter.eq("umichInstRoles", role)
    end.reduce do |main_filter, current_filter|
      Net::LDAP::Filter.intersect(main_filter, current_filter)
    end
  end

  # DISTINGUISHED_NAME = ENV.fetch("LDAP_DN")
  # PASSWORD = ENV.fetch("LDAP_PASSWORD")
  # HOST = ENV.fetch("LDAP_HOST")

  def initialize(output: $stdout)
    @output = output
  end

  def ldap
    S.ldap
    # @ldap ||= Net::LDAP.new(host: HOST, auth: {method: :simple, dn: DISTINGUISHED_NAME, password: PASSWORD}, port: 636, encryption: {method: :simple_tls})
  end

  def filter
    roles_filter
  end

  def roles_filter
    self.class.roles_filter
  end

  def ldap_attributes
    self.class.ldap_attributes
  end

  # To do: This needs to write to a file
  # The filename needs to be part of the class
  # It can know how to write to a file (or something file like)
  # Is it a good idea for it to know which file to write to?
  def process
    total_found = 0
    total_loaded = 0

    ldap.search(
      base: "ou=People,dc=umich,dc=edu",
      objectclass: "*",
      filter: filter,
      attrs: ldap_attributes
    ) do |data|
      puts data["uid"].first
      total_found += 1
      patron = Patron.valid_for(data)
      if patron
        @output.write PatronMapper::User.from_hash(patron.to_h).to_xml(pretty: true)
      else
        puts Patron.exclude_reasons_for(data)
      end
      # if patron.includable?
      # @output.write PatronMapper::User.from_hash(patron.to_h).to_xml(pretty: true)
      # total_loaded += 1
      # else
      # puts "#{patron.primary_id}\t#{patron.class}\t#{patron.exclude_reason}"
      # end
    end
    unless ldap.get_operation_result.code == 0
      puts "Response Code: #{ldap.get_operation_result.code}, Message: #{ldap.get_operation_result.message}"
      exit
    end

    puts "Total found: #{total_found}"
    puts "Total loaded: #{total_loaded}"
  end

  def to_s
    "This is a string!"
  end
end

class ProcessLdapDaily < ProcessLdap
  def initialize(date:, output: $stdout)
    @output = output
    @date = DateTime.parse(date).strftime("%Y%m%d") + "050000.0Z" # just set it to EST diff from UTC
  end

  def date_filter
    modify = Net::LDAP::Filter.ge("modifyTimeStamp", @date)
    create = Net::LDAP::Filter.ge("createTimeStamp", @date)
    Net::LDAP::Filter.intersect(modify, create)
  end

  def filter
    Net::LDAP::Filter.join(roles_filter, date_filter)
  end
end

class ProcessLdapModifyDateRange < ProcessLdap
  def initialize(start_date:, end_date:, output: $stdout)
    @output = output
    @start_date = DateTime.parse(start_date).strftime("%Y%m%d") + "000000Z" # just set it to EDT diff from UTC
    @end_date = DateTime.parse(end_date).strftime("%Y%m%d") + "235959Z" # just set it to EDT diff from UTC
    raise StandardError, "start_date must be before end_date" if DateTime.parse(@start_date) > DateTime.parse(@end_date)
  end

  def date_filter
    modify_start = Net::LDAP::Filter.ge("modifyTimeStamp", @start_date)
    modify_end = Net::LDAP::Filter.le("modifyTimeStamp", @end_date)

    Net::LDAP::Filter.join(modify_start, modify_end)
  end

  def filter
    Net::LDAP::Filter.join(roles_filter, date_filter)
  end
end

class ProcessLdapOneUser < ProcessLdap
  def initialize(uniqname:, output: $stdout)
    @uniqname = uniqname
    @output = output
  end

  def filter
    Net::LDAP::Filter.eq("uid", @uniqname)
  end
end
