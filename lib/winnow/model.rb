module Winnow
  module Model
    extend ActiveSupport::Concern

    # included do
    #   cattr_reader :searchables
    # end

    module ClassMethods
      # Sets up any scopes and class methods which can be searched on.
      # All methods, scopes and fields are disabled by default so folks
      # can't mess with params and call methods they shouldn't have access to.
      def searchable(*names)
        found = names.select { |name| accepted_name?(name) }
        missing = names - found
        if missing.any?
          str = missing.map { |s| ":#{s}" }.join(", ")
          raise RuntimeError.new("Unknown searchable: #{str}")
        else
          Winnow.add_searchable(self, names)
        end
      end

      def searchables
        Winnow.searchables(self)
      end

      # Sets up arel queries for the given params.
      # Anything not defined by a call to #searchable will be ignored.
      def search(all_params)
        relevant_params = (all_params || {}).slice(*searchables)
        searchable_params = relevant_params.select { |k, v| v.present? }

        scoped = self.scoped
        searchable_params.each do |name, value|
          if column_names.include?(name.to_s)
            scoped = scoped.where(name => value)
          elsif contains_scopes.include?(name.to_s)
            column = name.to_s.gsub("_contains", "")
            scoped = scoped.where("#{table_name}.#{column} like ?", "%#{value}%")
          elsif scoped.respond_to?(name)
            scoped = scoped.send(name, value)
          else
            raise RuntimeError.new("Unknown searchable: #{name}")
          end
        end
        Winnow::FormObject.new(self, scoped, relevant_params)
      end

      private

      def accepted_name?(name)
        column_names.include?(name.to_s) ||
          contains_scopes.include?(name.to_s) ||
          respond_to?(name)
      end

      def contains_scopes
        @contains_scopes ||= column_names.map { |name| "#{name}_contains" }.flatten
      end
    end
  end
end
