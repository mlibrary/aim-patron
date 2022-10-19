module PatronMapper
  class EmailTypes < Shale::Mapper
    attribute :email_type, Shale::Type::String
  end

  class Email < Shale::Mapper
    # todo preferred isn't being set to true
    attribute :preferred, Shale::Type::Boolean, default: -> { false }
    attribute :email_address, Shale::Type::String
    attribute :email_types, EmailTypes

    xml do
      root "email"

      map_attribute "preferred", to: :preferred
      map_element "email_address", to: :email_address
      map_element "email_types", to: :email_types
    end
  end

  class Emails < Shale::Mapper
    attribute :email, Email
  end
end
