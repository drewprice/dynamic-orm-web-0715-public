module FlactiveRecord
  class Base
    def self.connection
      DBConnection.instance.connection
    end

    def self.exec(sql, args = [])
      DBConnection.instance.exec(sql, args)
    end

    def self.table_name
      Inflecto.tableize(name)
    end

    def self.column_names
      sql = <<-SQL
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name='#{table_name}'
      SQL

      exec(sql).map { |column| column['column_name'] }
    end

    def self.writable_columns
      column_names - ['id']
    end

    def self.writable_placeholders
      writable_columns.map.with_index(1) do |_, i|
         "$#{i}"
       end
    end

    def self.inherited(base)
      base.class_eval do
        attr_accessor(*column_names)
      end
    end

    def self.new_from_db(row)
      column_names.each_with_object(new) do |column, obj|
        obj.send("#{column}=", row[column])
      end
    end

    def self.all
      sql = <<-SQL
        SELECT *
        FROM #{table_name}
      SQL

      results = exec(sql)

      results.map { |row| new_from_db(row) }
    end

    def self.find(id)
      sql = <<-SQL
        SELECT *
        FROM #{table_name}
        WHERE id = $1;
      SQL

      results = exec(sql, [id])

      results.map { |row| new_from_db(row) }.first
    end

    def initialize(attributes = {})
      attributes.each { |k, v| instance_variable_set("@#{k}", v) }
    end

    def save
      insert
    end

    def insert
      sql = <<-SQL
        INSERT INTO #{self.class.table_name}
        (#{self.class.writable_columns.join(', ')})
        VALUES
        (#{self.class.writable_placeholders.join(', ')})
      SQL

      params = self.class.writable_columns.map do |column|
        send(column)
      end

      exec(sql, params)
    end

  end
end
