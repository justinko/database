# frozen_string_literal: true

require 'singleton'

class DatabasePrompt
  include Singleton

  PROMPT = '>> '

  def self.start
    print PROMPT

    while (input = gets.chomp)
      command, *args = input.split

      case command
      when 'SET'
        instance.set(*args)
      when 'GET'
        puts instance.get(*args)
      when 'DELETE'
        instance.delete(*args)
      when 'COUNT'
        puts instance.count(*args)
      when 'END'
        break
      when 'BEGIN'
        instance.transaction
      when 'ROLLBACK'
        instance.rollback || puts('TRANSACTION NOT FOUND')
      when 'COMMIT'
        instance.commit
      end
      print PROMPT
    end
  end

  def initialize
    @destructive_commands = []
    @transactions = []
    @database = {}
  end

  def set(name, value)
    @destructive_commands << [:set, name, @database[name]]
    @database[name] = value
  end

  def get(name)
    @database.fetch(name, 'NULL')
  end

  def delete(name)
    @destructive_commands << [:delete, name, @database.delete(name)]
  end

  def count(value)
    @database.values.tally.fetch(value, 0)
  end

  def transaction
    @transactions.push(@destructive_commands.size).uniq!
  end

  def rollback
    return if @transactions.empty?

    transaction_commands = @destructive_commands.slice!(@transactions.pop..-1)
    transaction_commands.reverse_each do |command|
      case command
      in :set, name, previous_value
        if previous_value
          @database[name] = previous_value
        else
          @database.delete(name)
        end
      in :delete, name, value
        @database[name] = value
      end
    end
  end

  def commit
    @transactions.clear
  end
end

DatabasePrompt.start
