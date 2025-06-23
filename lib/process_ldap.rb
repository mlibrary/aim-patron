require "json"
require "yaml"
require "net/ldap"
require "date"
require "byebug"
require "csv"

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
      "EnrolledStudentDBRN",
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

  DISTINGUISHED_NAME = ENV.fetch("LDAP_DN")
  PASSWORD = ENV.fetch("LDAP_PASSWORD")
  HOST = ENV.fetch("LDAP_HOST")

  def initialize(output: $stdout)
    @output = output
  end

  def ldap
    @ldap ||= Net::LDAP.new(host: HOST, auth: {method: :simple, dn: DISTINGUISHED_NAME, password: PASSWORD}, port: 636, encryption: {method: :simple_tls})
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
    ldap.search(
      base: "ou=People,dc=umich,dc=edu",
      objectclass: "*",
      filter: filter,
      attrs: ldap_attributes
    ) do |data|
      puts data["uid"].first
      patron = Patron.for(data)
      next unless patron.includable?
      @output.write PatronMapper::User.from_hash(patron.to_h).to_xml(pretty: true)
    end
    true
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

class ProcessLdapOneUser < ProcessLdap
  def initialize(uniqname:, output: $stdout)
    @uniqname = uniqname
    @output = output
  end

  def filter
    Net::LDAP::Filter.eq("uid", @uniqname)
  end
end
