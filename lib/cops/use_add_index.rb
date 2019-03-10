# frozen_string_literal: true

module RuboCop
  module Cop
    module PostgresMigrationCops
      # Check that indexes are added explicitly with add_index
      # to ensure concurrency can be enabled
      #
      # @example
      #  # bad
      #   class SomeTableMigrations < ActiveRecord::Migration
      #     def change
      #       add_column :table, :some_column_1, :integer, :index
      #       add_column :table, :other_column, :string, index: true
      #     end
      #   end
      #
      #  # good
      #   class SomeTableMigrations < ActiveRecord::Migration
      #     disable_ddl_transaction!
      #     def change
      #       add_column :table, :some_column_1, :integer
      #       add_column :table, :other_column, :string
      #       add_column :table, :doneit_at, :datetime
      #       add_index  :table,
      #                  :some_column_1,
      #                  algorithm: :concurrently
      #       add_index  :table,
      #                  :other_column,
      #                  algorithm: :concurrently

      #       end
      #   end
      class UseAddIndex < Cop
        MSG = "Add indexes using 'add_index ... algorithm: :concurrently'"

        def on_class(class_node)
          @is_migration = class_node.children.any? { |n| is_migration?(n) }
        end

        def on_send(send_node)
          return unless @is_migration

          add_offense(send_node) if contains_index?(send_node)
        end

        private

        def_node_matcher :is_migration?, <<-PATTERN
          (const ... :Migration)
        PATTERN

        def contains_index?(node)
          return true if node.children.any? { |n| is_index_symbol?(n) }

          contains_hash_index?(node)
        end

        def contains_hash_index?(node)
          opts_node = node.children.last
          return unless opts_node.class == RuboCop::AST::HashNode

          opts_node.children.any? { |n| is_index_pair? n }
        end

        def_node_matcher :is_index_symbol?, <<-PATTERN
          (sym :index)
        PATTERN

        def_node_matcher :is_index_pair?, <<-PATTERN
        (pair
          (sym :index)
          (true))
        PATTERN
      end
    end
  end
end
