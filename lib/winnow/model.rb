module Winnow
  module Model
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :searchables

      # Sets up any scopes and class methods which can be searched on.
      # All methods, scopes and fields are disabled by default so folks
      # can't mess with params and call methods they shouldn't have access to.
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

      # Sets up arel queries for the given params.
      # Anything not defined by a call to #searchable will be ignored.
      def search(params)
        params.slice(*searchables).each do |name, value|
          if column_names.include?(name.to_s)
            where(name => value)
          else
            send(name, value)
          end
        end
      end
    end
  end
end
