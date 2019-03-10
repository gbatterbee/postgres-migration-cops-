# frozen_string_literal: true

module RuboCop
  module Cop
    module PostgresMigrationCops
      # Check that indexes are added concurrently with disable_ddl_transaction!
      # https://thoughtbot.com/blog/how-to-create-postgres-indexes-concurrently-in
      #
      # @example
      #  # bad
      #   class SomeTableMigrations < ActiveRecord::Migration
      #     def change
      #       add_column :table, :some_column_1, :integer, default: 0, null: false
      #       add_column :table, :other_column, :string
      #       add_column :table, :doneit_at, :datetime
      #       add_index  :table,
      #                  :other_column,
      #                  unique: true
      #     end
      #   end
      #
      #  # good
      #   class SomeTableMigrations < ActiveRecord::Migration
      #     disable_ddl_transaction!
      #     def change
      #       add_column :table, :some_column_1, :integer, default: 0, null: false
      #       add_column :table, :other_column, :string
      #       add_column :table, :doneit_at, :datetime
      #       add_index  :table,
      #                  :other_column,
      #                  unique: true,
      #                  algorithm: :concurrently
      #       end
      #   end
      class AddIndexesConcurrently < Cop
        IGNORE_DDL = 'Concurrent indexes require "disable_ddl_transaction!"'
        CONCURRENTLY = "Indexes should be added with 'algorithm: :concurrently'"

        def on_class(class_node)
          is_migration = class_node.children.any? { |n| is_migration?(n) }
          return unless is_migration

          index_nodes = find_index_methods(class_node)
          return unless creating_indexes?(index_nodes)

          ensure_disable_dll_transaction_offense(class_node, index_nodes)
          ensure_indexes_added_non_concurrently_offenses(index_nodes)
        end

        private

        def creating_indexes?(index_nodes)
          index_nodes.count.positive?
        end

        def ensure_disable_dll_transaction_offense(class_node, index_nodes)
          return if disable_ddl_transaction_declared?(class_node)

          has_concurrent = concurrent_indexes?(index_nodes)
          add_offense(class_node, message: IGNORE_DDL) if has_concurrent
        end

        def disable_ddl_transaction_declared?(node)
          begins = find__begin node
          begins.any? { |b| b.children.any? { |n| has_disable_ddl?(n) } }
        end

        def concurrent_indexes?(index_nodes)
          index_nodes
            .select { |n| n.source.include?('concurrent') }
            .count
            .positive?
        end

        def ensure_indexes_added_non_concurrently_offenses(index_nodes)
          index_nodes
            .reject { |n| n.source.include?('concurrently') }
            .to_a.each { |n| add_offense(n, message: CONCURRENTLY) }
        end

        def find_index_methods(node)
          sends = find__send node
          sends.select { |n| n.source.include?('add_index') }
        end

        def_node_matcher :is_migration?, <<-PATTERN
          (const ... :Migration)
        PATTERN

        def_node_search :find__send, <<-PATTERN
          send
        PATTERN

        def_node_matcher :is_add_index?, <<-PATTERN
          (send nil :add_index ... )
        PATTERN

        def_node_search :find__begin, <<-PATTERN
          begin
        PATTERN

        def_node_matcher :has_disable_ddl?, <<-PATTERN
          (... :disable_ddl_transaction!)
        PATTERN
      end
    end
  end
end
