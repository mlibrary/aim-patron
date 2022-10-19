module PatronMapper
  class PhoneTypes < Shale::Mapper
    attribute :phone_type, Shale::Type::String
  end

  class Phone < Shale::Mapper
    # todo preferred isn't being set to true
    attribute :preferred, Shale::Type::Boolean, default: -> { false }
    attribute :phone_number, Shale::Type::String
    attribute :phone_types, PhoneTypes

    xml do
      root "phone"

      map_attribute "preferred", to: :preferred
      map_element "phone_number", to: :phone_number
      map_element "phone_types", to: :phone_types
    end
  end

  class Phones < Shale::Mapper
    attribute :phone, Phone
  end
end
