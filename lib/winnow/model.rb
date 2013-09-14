module Winnow
  module Model
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :searchables

      def searchable(*names)
        found = names.select do |name|
          column_names.include?(name.to_s) || respond_to?(name)
        end

        missing = names - found
        if missing.any?
          str = missing.map { |s| ":#{s}" }.join(", ")
          raise RuntimeError.new("Unknown searchable: #{str}")
        else
          @searchables = names
        end
      end
    end
  end
end
