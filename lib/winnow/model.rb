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
        searchable_params = relevant_params.select {|name, v| v.to_s.present? }

        scoped = all
        searchable_params.each do |name, value|
          if column_names.include?(name.to_s)
            val = columns_hash[name.to_s].type == :boolean ? Winnow.boolean(value) : value
            scoped = scoped.where(name => val)
          elsif contains_scopes.include?(name.to_s)
            column = name.to_s.gsub("_contains", "")
            if mysql_adapter? && fts_index?(column) && (!fts_contains_tokens_for(value).empty?)
              scoped = scoped.where(fts_scope_for(column), fts_contains_tokens_for(value), "%#{value}%")
            else
              scoped = scoped.where("#{table_name}.#{column} like ?", "%#{value}%")
            end
          elsif starts_with_scopes.include?(name.to_s)
            column = name.to_s.gsub("_starts_with", "")

            # use full-text index to narrow down search if btree index is not available.
            if mysql_adapter? && !btree_index?(column) && fts_index?(column) && (! fts_starts_with_tokens_for(value).empty?)
              scoped = scoped.where(fts_scope_for(column), fts_starts_with_tokens_for(value), "#{value}%")
            else
              scoped = scoped.where("#{table_name}.#{column} like ?", "#{value}%")
            end
          elsif scoped.respond_to?(name)
            scoped = scoped.send(name, value)
          else
            raise RuntimeError.new("Unknown searchable: #{name}")
          end
        end
        Winnow::FormObject.new(self, scoped, relevant_params)
      end

      private

      def mysql_adapter?
        connection_adapter == :mysql
      end

      def connection_adapter
        case connection.adapter_name
        when /(?:mysql|trilogy)/i
          :mysql
        when /postgres/i
          :postgres
        else
          nil
        end
      end

      def fts_scope_for(column)
        "(match(#{table_name}.#{column}) against(? in boolean mode) and (#{table_name}.#{column} like ?))"
      end

      def fts_starts_with_tokens_for(term)
        tokens = token_list(term)
        tokens_to_search_term(tokens)
      end

      def fts_contains_tokens_for(term)
        tokens = token_list(term)[1..-1]
        tokens_to_search_term(tokens)
      end

      SPECIAL_CHARS = %r{[@~"<>{}()+*.\-\s]+}

      # ActiveRecord::Base.connection.execute('SELECT * FROM INFORMATION_SCHEMA.INNODB_FT_DEFAULT_STOPWORD').to_a.sum
      STOP_WORDS = %w{a about an are as at be by com de en for from how i in is it la of on or that the this to was what when where who will with und the www}

      FT_MIN_TOKEN_SIZE = 3

      def token_list(term)
        (term.split(SPECIAL_CHARS) - STOP_WORDS).select { |s| s.length >= FT_MIN_TOKEN_SIZE }
      end

      def tokens_to_search_term(tokens)
        tokens.to_a.map {|a| '+' + a + '*'}.join(' ')
      end

      def fts_index?(column)
        !!fts_indexes_for_table.find {|index| index.columns.include?(column)}
      end

      def fts_indexes_for_table
        connection.indexes(table_name).select {|idx| idx.type == :fulltext}
      end

      def btree_index?(column)
        !!btree_indexes_for_table.find {|index| index.columns[0] == column}
      end

      def btree_indexes_for_table
        connection.indexes(table_name).select {|idx| idx.using == :btree}
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
