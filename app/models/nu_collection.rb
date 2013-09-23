class NuCollection < ActiveFedora::Base 
  include ActiveModel::MassAssignmentSecurity
  include Hydra::ModelMixins::RightsMetadata
  include Drs::Rights::MassPermissions
  include Drs::Rights::Embargoable
  include Drs::Rights::InheritedRestrictions
  include Drs::MetadataAssignment

  attr_accessible :title, :description, :date_of_issue, :keywords, :parent 
  attr_accessible :corporate_creators, :personal_creators, :personal_folder_type

  attr_protected :identifier 

  has_metadata name: 'DC', type: NortheasternDublinCoreDatastream 
  has_metadata name: 'rightsMetadata', type: ParanoidRightsDatastream
  has_metadata name: 'properties', type: DrsPropertiesDatastream
  has_metadata name: 'mods', type: NuModsDatastream 

  has_many :child_files, property: :is_member_of, :class_name => "NuCoreFile"
  has_many :child_collections, property: :is_member_of, :class_name => "NuCollection"
  belongs_to :parent, property: :is_member_of, :class_name => "NuCollection"
  belongs_to :user_parent, property: :is_member_of, :class_name => "Employee" 

  # Return all collections that this user can read
  def self.find_all_viewable(user) 
    collections = NuCollection.find(:all)
    filtered = collections.select { |ele| !ele.embargo_in_effect?(user) && ele.rightsMetadata.can_read?(user) }
    return filtered 
  end

  # Delete all files/collections for which this item is root 
  def recursive_delete
    files = all_descendent_files 
    collections = all_descendent_collections

    # Need to look it up again before you try to destroy it.
    # Is mystery. 
    files.each do |f|
      x = NuCoreFile.find(f.pid) if NuCoreFile.exists?(f.pid) 
      x.destroy
    end

    collections.each do |c| 
      x = NuCollection.find(c.pid) if NuCollection.exists?(c.pid) 
      x.destroy 
    end
  end


  # Override parent= so that the string passed by the creation form can be used. 
  def parent=(collection_id)
    if collection_id.nil? 
      return true #Controller level validations are used to ensure that end users cannot do this.  
    elsif collection_id.instance_of?(String) 
      self.add_relationship(:is_member_of, NuCollection.find(collection_id))
    elsif collection_id.instance_of?(NuCollection)
      self.add_relationship(:is_member_of, collection_id) 
    else
      raise "parent= got passed a #{collection_id.class}, which doesn't work."
    end
  end

  # Override user_parent= so that the string passed by the creation form can be used. 
  def user_parent=(employee) 
    if employee.instance_of?(String) 
      self.add_relationship(:is_member_of, Employee.find_by_nuid(employee)) 
    elsif employee.instance_of? Employee 
      self.add_relationship(:is_member_of, employee) 
    else
      raise "user_parent= got passed a #{employee.class}, which doesn't work." 
    end
  end

  def permissions=(hash)
    self.set_permissions_from_new_form(hash) 
  end

  # Accepts a hash of the following form:
  # ex. {'permissions1' => {'identity_type' => val, 'identity' => val, 'permission_type' => val }, 'permissions2' => etc. etc. }
  # Tosses out param sets that are missing an identity.  Which is nice.   
  def set_permissions_from_new_form(params)
    params.each do |perm_hash| 
      identity_type = perm_hash[1]['identity_type']
      identity = perm_hash[1]['identity']
      permission_type = perm_hash[1]['permission_type'] 

      if identity != 'public' && identity != 'registered' 
        self.rightsMetadata.permissions({identity_type => identity}, permission_type)
      end 
    end
  end

    # Depth first(ish) traversal of a graph.  
    def each_depth_first
      self.child_collections.each do |child|
        child.each_depth_first do |c|
          yield c
        end
      end

      yield self
    end

    # Return every descendent collection of this collection
    def all_descendent_collections
      result = [] 
      each_depth_first do |child|
        result << child 
      end
      return result 
    end

    def all_descendent_files 
      result = [] 
      each_depth_first do |child| 
        result += child.child_files 
      end
      return result
    end
end
