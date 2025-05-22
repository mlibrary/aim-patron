require "shale"
require "shale/adapter/rexml"

Shale.xml_adapter = Shale::Adapter::REXML

require_relative "patron_mapper/user_statistics"
require_relative "patron_mapper/user_roles"
require_relative "patron_mapper/addresses"
require_relative "patron_mapper/phones"
require_relative "patron_mapper/emails"
require_relative "patron_mapper/contact_info"
require_relative "patron_mapper/user_identifiers"
require_relative "patron_mapper/user"

module PatronMapper
end
