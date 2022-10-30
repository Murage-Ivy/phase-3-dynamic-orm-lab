require_relative "../config/environment.rb"
require "active_support/inflector"

class InteractiveRecord

  # Creates a new instance of class
  # Accepts a hash
  def initialize(options = {})
    options.each do |key, value|
      # Creates a setter method for each attribute or property
      self.send("#{key}=", value)
    end
  end

  # Creates table name from class name
  def self.table_name
    self.to_s.downcase.pluralize
  end

  #   Returns an array of column names from the database
  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info(#{self.table_name})"
    # Returns an array of hashes
    table_info = DB[:conn].execute(sql)

    column_names = Array.new

    table_info.each do |col|
      column_names << col["name"]
    end
    column_names.compact
  end

  # Returns the table name  for the database
  def table_name_for_insert
    self.class.table_name
  end

  # Returns the column names to be inserted values
  def col_names_for_insert
    self.class.column_names.delete_if { |col| col == "id" }.join(", ")
  end

  # Returns values to be inserted in the columns
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", name)
  end

  def self.find_by(attribute)
    student_found = []
    attribute.each do |key, value|
      student_found << DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{key} = ? LIMIT 1", value)
    end
    student_found.first
  end
end
