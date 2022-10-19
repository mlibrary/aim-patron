module PatronMapper
  class ContactInfo < Shale::Mapper
    attribute :addresses, Addresses
    attribute :emails, Emails
    attribute :phones, Phones
  end
end
