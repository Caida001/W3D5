require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    return @columns if @columns
    arr = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    # debugger
    @columns = arr[0].map!(&:to_sym)
  end

  def self.finalize!
    # self.colums => [:name, :age]
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ||= self.to_s.tableize
  end

  def self.all
    # ...
    res = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    parse_all(res)
  end

  def self.parse_all(results)
    # ...
    results.map { |res| self.new(res) }
  end

  def self.find(id)
    # ...
    res = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{table_name}.id = ?
    SQL
    parse_all(res).first
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    # ...
    @attributes ||= {}

  end

  def attribute_values
    # ...
    self.class.columns.map { |col| self.send(col) }
  end

  def insert
    cols = self.class.columns.drop(1).join(",")
    questions = (['?'] * self.class.columns.drop(1).count).join(",")
    # ...
    DBConnection.execute(<<-SQL, *self.attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{cols})
      VALUES
        (#{questions})
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update
    # ...
    set_line = self.class.columns.drop(1).map{ |attr| "#{attr}=?" }.join(",")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1), id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL


  end

  def save
    # ...
    if id.nil?
      self.insert
    else
      self.update
    end
  end
end
