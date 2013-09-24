class NuCoreFile < ActiveFedora::Base
  include Sufia::GenericFile
  include Drs::Rights::MassPermissions
  include Drs::Rights::Embargoable 
  include Drs::Rights::InheritedRestrictions
  include Drs::MetadataAssignment
  include Drs::NuCoreFile::Export

  has_metadata name: 'DC', type: NortheasternDublinCoreDatastream
  has_metadata name: 'properties', type: DrsPropertiesDatastream
  has_metadata name: 'mods', type: NuModsDatastream

  belongs_to :parent, :property => :is_member_of, :class_name => 'NuCollection'
  # call self.content_objects to get a list of all content bearing objects showing this 
  # as their core record.  

  def self.create_metadata(nu_core_file, user, collection_id)
    nu_core_file.apply_depositor_metadata(user.user_key)
    nu_core_file.tag_as_in_progress 
    nu_core_file.date_uploaded = Date.today
    nu_core_file.date_modified = Date.today
    nu_core_file.creator = user.name

    if !collection_id.blank?
      nu_core_file.set_parent(NuCollection.find(collection_id), user)
    else
      logger.warn "unable to find collection to attach to"
    end

    yield(nu_core_file) if block_given?
    nu_core_file.save!
  end

  # Safely set the parent of a collection.
  def set_parent(collection, user) 
    if user.can? :edit, collection 
      self.parent = collection
      return true  
    else 
      raise "User with nuid #{user.email} cannot add items to collection with pid of #{collection.pid}" 
    end
  end

  # Return a list of all in progress files associated with this user
  def self.users_in_progress_files(user)
    all = NuCoreFile.find(:all) 
    filtered = all.keep_if { |file| file.in_progress_for_user?(user) } 
    return filtered  
  end

  def in_progress_for_user?(user)
    return self.properties.in_progress? && user.nuid == self.depositor 
  end

  def tag_as_completed 
    self.properties.tag_as_completed 
  end

  def tag_as_in_progress 
    self.properties.tag_as_in_progress 
  end

  def persistent_url
    "#{Rails.configuration.persistent_hostpath}#{noid}"
  end

  def content_objects
    all_possible_models = [ "ImageDynamicFile", "ImageHighresFile", "ImageLowresFile",
                            "ImageMasterFile", "ImageThumbnailFile", "MsexcelFile",
                            "MspowerpointFile", "MswordFile", "PdfFile", "XmlEadFile",
                            "XmlXsltFile" ]
    models_stringified = all_possible_models.inject { |base, str| base + " or #{str}" }
    models_query = ActiveFedora::SolrService.escape_uri_for_query models_stringified 
    full_self_id = ActiveFedora::SolrService.escape_uri_for_query "info:fedora/#{self.pid}"

    query_result = ActiveFedora::SolrService.query("active_fedora_model_ssi:(#{models_stringified}) AND is_part_of_ssim:#{full_self_id}", rows: 999)

    return assigned_lookup(query_result)
  end  

  private 

    def assigned_lookup(solr_query_result)
      return solr_query_result.map { |r| r["active_fedora_model_ssi"].constantize.find(r["id"]) } 
    end
end