module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, *value_fields, **typed_fields)
        value_fields_hash = value_fields.each_with_object({}) do |value_field, hash_for_value_fields|
          hash_for_value_fields[value_field] = :value
        end

        all_fields = value_fields_hash.merge(typed_fields)

        define_method(:initialize_jsonb_attrs) do
          jsonb_attribute_hash = send(jsonb_attribute) || {}
          all_fields.keys.each do |field|
            send("#{field}=", jsonb_attribute_hash[field.to_s])
          end
        end

        after_initialize :initialize_jsonb_attrs

        all_fields.each do |field, type|
          attribute(field.to_s, TypeHelper.send(type))

          define_method("#{field}=") do |value, *args, &block|
            super(value, *args, &block)
            send("#{jsonb_attribute}=", (send(jsonb_attribute) || {}).merge(field => attributes[field.to_s]))
          end
        end
      end
    end
  end
end
