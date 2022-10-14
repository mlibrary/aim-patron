require "json"
require "yaml"
require "net/ldap"
require "date"
require "byebug"
require_relative "./name"
require_relative "./patron"
require_relative "./employee"
require_relative "./staff_person"
require_relative "./student"
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

  USERNAME = ENV.fetch("LDAP_USERNAME")
  PASSWORD = ENV.fetch("LDAP_PASSWORD")
  HOST = ENV.fetch("LDAP_HOST")

  def ldap
    @ldap ||= Net::LDAP.new(host: HOST, auth: {method: :simple, username: USERNAME, password: PASSWORD})
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

  def process
    ldap.search(
      base: "ou=People,dc=umich,dc=edu",
      objectclass: "*",
      filter: filter,
      attrs: ldap_attributes
    ) do |data|
      my_data = JSON.parse(data.to_h.to_json)
      puts JSON.pretty_generate(Patron.for(my_data).to_h)
    end
    nil
  end

  def to_s
    "This is a string!"
  end
end

class ProcessLdapDaily < ProcessLdap
  def initialize(date)
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
  def initialize(uniqname)
    @uniqname = uniqname
  end

  def filter
    Net::LDAP::Filter.eq("uid", @uniqname)
  end
end
