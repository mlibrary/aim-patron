module PatronMapper
  class AddressTypes < Shale::Mapper
    attribute :address_type, Shale::Type::String
  end

  class Address < Shale::Mapper
    attribute :preferred, Shale::Type::Boolean, default: -> { false }
    attribute :line1, Shale::Type::String
    attribute :line2, Shale::Type::String
    attribute :city, Shale::Type::String
    attribute :country, Shale::Type::String
    attribute :state_province, Shale::Type::String
    attribute :postal_code, Shale::Type::String
    attribute :address_types, AddressTypes

    xml do
      root "address"

      map_attribute "preferred", to: :preferred
      map_element "line1", to: :line1
      map_element "line2", to: :line2
      map_element "city", to: :city
      map_element "country", to: :country
      map_element "state_province", to: :state_province
      map_element "postal_code", to: :postal_code
      map_element "address_types", to: :address_types
    end
  end

  class Addresses < Shale::Mapper
    attribute :address, Address, collection: true
  end
end
