module Winnow
  module Model
    extend ActiveSupport::Concern

    included do
      cattr_reader :searchables
    end

    module ClassMethods
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
          class_variable_set("@@searchables", names)
        end
      end

      # Sets up arel queries for the given params.
      # Anything not defined by a call to #searchable will be ignored.
      def search(all_params)
        relevant_params = (all_params || {}).slice(*searchables)
        scoped = self
        relevant_params.each do |name, value|
          if column_names.include?(name.to_s)
            scoped = scoped.where(name => value)
          else
            scoped = scoped.send(name, value)
          end
        end
        Winnow::FormObject.new(scoped, relevant_params)
      end
    end
  end
end
