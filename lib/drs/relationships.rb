module Drs::Relationships 


  def single_lookup(relation, classes) 
   a = self.relationships(relation)
   result = a.map { |x| ActiveFedora::Base.find(x[12..-1], cast: true) }

   result.find { |x| classes.include? x.class } 
  end 

  def assign_by_string(val, relation, valid_types, options = {}) 
    val.instance_of?(String) ? obj = ActiveFedora::Base.find(val, cast: true) : obj = val 

    if options[:allow_nil] && val.nil? 
      false 
    elsif valid_types.include? obj.class 
      self.add_relationship(relation, obj)
    else
      raise "Attempted to set #{relation.to_s} using a #{val.class}.  Valid choices are String or #{valid_types.to_s}" 
    end
  end
end