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
        fts_indexes = fts_indexes_for_table
        relevant_params = (all_params || {}).slice(*searchables)
        searchable_params = relevant_params.select {|name, v| v.to_s.present? }

        scoped = self.send(Winnow.base_scope_method)
        searchable_params.each do |name, value|
          if column_names.include?(name.to_s)
            val = columns_hash[name.to_s].type == :boolean ? Winnow.boolean(value) : value
            scoped = scoped.where(name => val)
          elsif contains_scopes.include?(name.to_s)
            column  = name.to_s.gsub("_contains", "")
            if fts_adapter == :mysql && fts_indexes.find {|index| index.columns.include?(column)}

              # since we're searching in boolean mode, strip out search operators and tokenize.
              tokens = value.gsub(%r{[@~"<>{}()+*\-]+}, '* ')
              tokens = "#{tokens}*".sub(%r{\* +\*+$}, '*')
              scoped = scoped.where(
                "(match(#{table_name}.#{column}) against(? in boolean mode) and (#{table_name}.#{column} like ?))",
                tokens, "%#{value}%"
              )
            else
              scoped = scoped.where("#{table_name}.#{column} like ?", "%#{value}%")
            end
          elsif starts_with_scopes.include?(name.to_s)
            column = name.to_s.gsub("_starts_with", "")
            scoped = scoped.where("#{table_name}.#{column} like ?", "#{value}%")
          elsif scoped.respond_to?(name)
            scoped = scoped.send(name, value)
          else
            raise RuntimeError.new("Unknown searchable: #{name}")
          end
        end
        Winnow::FormObject.new(self, scoped, relevant_params)
      end

      private

      def fts_adapter
        case connection.adapter_name
        when /mysql/i
          :mysql
        when /postgres/i
          :postgres
        else
          nil
        end
      end

      def fts_indexes_for_table
        connection.indexes(table_name).select {|idx| idx.type == :fulltext}
      end

      def accepted_name?(name)
        column_names.include?(name.to_s) ||
          contains_scopes.include?(name.to_s) ||
          starts_with_scopes.include?(name.to_s) ||
          respond_to?(name)
      end

      def contains_scopes
        @contains_scopes ||= column_names.map { |name| "#{name}_contains" }.flatten
      end

      def starts_with_scopes
        @starts_with_scopes ||= column_names.map { |name| "#{name}_starts_with" }.flatten
      end
    end
  end
end
