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
  LDAP_ATTRIBUTES =
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

  ROLES_FILTER = [
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

  # def self.roles_filter
  # [
  # "StudentDBRN",
  # "StudentFLNT",
  # "StudentAA",
  # "Faculty*",
  # "RegularStaff*",
  # "TemporaryStaffAA",
  # "SponsoredAffiliateAA",
  # "Retiree"
  # ].map do |role|
  # Net::LDAP::Filter.eq("umichInstRoles", role)
  # end.reduce do |main_filter, current_filter|
  # Net::LDAP::Filter.intersect(main_filter, current_filter)
  # end
  # end

  def initialize(output: $stdout, size: nil)
    @output = output
    @size = size
  end

  def ldap
    S.ldap
  end

  def filter
    ROLES_FILTER
  end

  # def roles_filter
  # self.class.roles_filter
  # end

  def search(&block)
    search_attributes = {
      base: "ou=People,dc=umich,dc=edu",
      objectclass: "*",
      filter: filter,
      attrs: LDAP_ATTRIBUTES
    }
    search_attributes[:size] = @size if @size
    ldap.search(
      **search_attributes
    ) do |data|
      block.call(data)
    end
  end

  def process_one
    search do |data|
      patron = Patron.for(data)
      if patron.includable?
        # puts "LOAD\t#{patron.umid}\t#{patron.uniqname}"
        patron.write(@output)
      else
        puts "SKIP\t#{patron.umid}\t#{patron.uniqname}\t#{patron.exclude_reasons.join(";")}"
      end
    end
  end

  # To do: This needs to write to a file
  # The filename needs to be part of the class
  # It can know how to write to a file (or something file like)
  # Is it a good idea for it to know which file to write to?
  def process
    search do |data|
      patron = Patron.for(data)
      if patron.includable?
        patron.write(@output)
        # @output.write PatronMapper::User.from_hash(patron.to_h).to_xml(pretty: true)
      else
        puts "SKIP\t#{patron.umid}\t#{patron.uniqname}\t#{patron.exclude_reasons.join(";")}"
      end
    rescue => e
      puts e
      byebug
    end

    unless ldap.get_operation_result.code == 0
      puts "Response Code: #{ldap.get_operation_result.code}, Message: #{ldap.get_operation_result.message}"
      exit
    end
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
    Net::LDAP::Filter.join(ROLES_FILTER, date_filter)
  end
end

class ProcessLdapModifyDateRange < ProcessLdap
  def initialize(start_date:, end_date: start_date, output: $stdout, size: nil)
    @output = output
    @size = size
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
    Net::LDAP::Filter.join(ROLES_FILTER, date_filter)
  end
end

class ProcessLdapOneUser < ProcessLdap
  def initialize(uniqname:, output: $stdout)
    @uniqname = uniqname
    @output = output
    @size = 1
  end

  def filter
    Net::LDAP::Filter.eq("uid", @uniqname)
  end

  def ldap_output
    search do |data|
      @output.write(JSON.pretty_generate(data.to_h))
    end
  end

  def process
    search do |data|
      patron = Patron.for(data)
      if patron.includable?
        # puts "LOAD\t#{patron.umid}\t#{patron.uniqname}"
        @output.write PatronMapper::User.from_hash(patron.to_h).to_xml(pretty: true)
      else
        puts "SKIP\t#{patron.umid}\t#{patron.uniqname}\t#{patron.exclude_reasons.join(";")}"
      end
    end
  end
end
