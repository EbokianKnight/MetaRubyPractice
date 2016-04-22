require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject

  # Instanciates a new SQL Object
  # calls self.the_attr_name = value on each param
  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include? attr_name.to_sym
        raise "unknown attribute '#{attr_name}'"
      end
      send("#{attr_name}=", value)
    end
  end

  # Query the table and collect all entries
  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{table_name}
    SQL
    parse_all(results)
  end

  # Collect Column Headers
  def self.columns
    @column ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT *
      FROM #{table_name}
    SQL
  end

  # Dynamically create setter/getter methods for columns attributes
  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  # Query the table for a specific entry
  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT *
    FROM #{table_name}
    WHERE id = ?
    LIMIT 1
    SQL
    parse_all(results).pop
  end

  # Invokes a query element returns a ruby array of SQL objects
  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  # Table name setter
  def self.table_name=(table_name)
    @table_name = table_name
  end

  # Table name getter
  def self.table_name
    name = self.to_s.tableize
    @table_name ||= name
  end

  # returns or creates the attributes hash
  def attributes
    @attributes ||= {}
  end

  # returns an array of the attribute values
  def attribute_values
    attributes.values
  end

  # adds an SQL object into the database, returns the new id
  def insert
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO #{self.class.table_name} (#{attributes.keys.join(', ')})
      VALUES (#{(["?"]*attributes.length).join(', ')})
    SQL
    self.id = DBConnection.instance.last_insert_row_id
  end

  # toggles between insert or update methods
  def save
    self.id.nil? ? insert : update
  end

  # updates an SQL object already in the database
  def update
    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE #{self.class.table_name}
      SET #{self.class.columns.map{|c| "#{c} = ?" }.join(', ')}
      WHERE id = #{self.id}
    SQL
  end
end
