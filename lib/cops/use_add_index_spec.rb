require './lib/cops/use_add_index'

# frozen_string_literal: true

RSpec.describe RuboCop::Cop::PostgresMigrationCops::UseAddIndex do
  subject(:cop) { described_class.new }

  context 'when index is declared as an option' do
    it 'it registers an offence' do
      expect_offense(<<-RUBY)
        class SomeTableMigrations < ActiveRecord::Migration
            def change
              add_column :table, :some_column_1, :integer, :index
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add indexes using 'add_index ... algorithm: :concurrently'
              add_column :table, :other_column, :string
              add_column :table, :doneit_at, :datetime
              add_index  :table,
                         :other_column,
                         unique: true

              create_table :examples do |t|
                t.references :category, :index
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add indexes using 'add_index ... algorithm: :concurrently'
                t.integer :number_of_participants, :index
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add indexes using 'add_index ... algorithm: :concurrently'
              end
            end
          end
      RUBY
    end
  end

  context 'when index is declared as a hash value option' do
    it 'it registers an offence' do
      expect_offense(<<-RUBY)
        class SomeTableMigrations < ActiveRecord::Migration
            def change
              add_column :table, :some_column_1, :integer, index: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add indexes using 'add_index ... algorithm: :concurrently'
              add_column :table, :other_column, :string
              add_column :table, :doneit_at, :datetime
              add_index  :table,
                         :other_column,
                         unique: true

              create_table :examples do |t|
                t.references :category, index: true
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add indexes using 'add_index ... algorithm: :concurrently'
                t.integer :number_of_participantsr, index: true
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add indexes using 'add_index ... algorithm: :concurrently'
              end
            end
          end
      RUBY
    end
  end

  context 'when it is not a migration' do
    it 'does not register an offence' do
      expect_no_offenses(<<-RUBY)
        class SomeTableMigrations
            def change
              add_column :table, :some_column_1, :integer, index: true
              add_column :table, :other_column, :string, :index
              add_column :table, :doneit_at, :datetime
              add_index  :table,
                         :other_column,
                         unique: true
            end
          end
      RUBY
    end
  end

  context 'when disable_ddl_transaction! is sepcified' do
    it 'does not register an offence' do
      expect_no_offenses(<<-RUBY)
        class SomeTableMigrations < ActiveRecord::Migration
          disable_ddl_transaction!
          def change
            add_column :table, :some_column_1, :integer
            add_column :table, :other_column, :string
            add_column :table, :doneit_at, :datetime
          end
          end
      RUBY
    end
  end
end
