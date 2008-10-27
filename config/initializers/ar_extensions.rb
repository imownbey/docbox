class << ActiveRecord::Base
  def create_or_update(options = {})
    self.create_or_update_by(:id, options)
  end

  def create_or_update_by(field, options = {})
    find_value = options[field]
    record = find(:first, :conditions => {field => find_value}) || self.new
    record.attributes = options
    new_record = record.new_record?
    record.save!
    Add.create(:owner => record) if new_record && !record.is_a?(CodeComment)
    record
  end
  
  def create_or_update_by_and(field1, field2, options = {})
    find_value1 = options[field1]
    find_value2 = options[field2]
    record = find(:first, :conditions => {field1 => find_value1.to_s, field2 => find_value2.to_s}) || self.new
    record.attributes = options
    new_record = record.new_record?
    record.save!
    Add.create(:owner => record) if new_record && !record.is_a?(CodeComment)
    record
  end

  def method_missing_with_create_or_update(method_name, *args)
    if match = method_name.to_s.match(/create_or_update_by_([a-z0-9_]+)/)
      if match[1] =~ /_and_/
        first, second = match[1].split('_and_')
        record = create_or_update_by_and(first.to_sym, second.to_sym, *args)
      else
        field = match[1].to_sym
        record = create_or_update_by(field,*args)
      end
    else
      method_missing_without_create_or_update(method_name, *args)
    end
  end

  alias_method_chain :method_missing, :create_or_update
end