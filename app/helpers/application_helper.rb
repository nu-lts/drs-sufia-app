module ApplicationHelper

  # Only things with theoretically near universal potential use should go here.

  def thumbnail_for(core_record) 
    if core_record.thumbnail 
      return core_record.thumbnail 
    else
      return core_record.canonical.class.to_s
    end
  end
  
  # Return a string for NuCollections or Communities, will return the class otherwise.
  def get_set_class_label(set)
    if set.instance_of?(Community)
      return "Community"
    elsif set.instance_of?(NuCollection)
      return "Collection"
    else
      return set.class
    end
  end

  # Generates an array of link/li tags that should breadcrumb back to the Root Collection  
  def breadcrumb_to_root(set, breadcrumb = [])    
    if breadcrumb.empty? 
      breadcrumb << content_tag(:li, set.title, class: 'active')  
    end

    if set.parent.nil?
      return breadcrumb.reverse
    else
      # This is a giant kludge, for some reason neu:1 gets an id param tacked on if done the regular way
      breadcrumb << content_tag(:li, link_to(set.parent.title, polymorphic_path(set.parent).split('?')[0]))
      breadcrumb_to_root(set.parent, breadcrumb)
    end
  end

  # Keys that might be available for front end thumbnails "thumbnail_1", "thumbnail_2", "thumbnail_2_2x", "thumbnail_4", "thumbnail_4_2x", "thumbnail_10", "thumbnail_10_2x"
  def get_file_thumbnails(file, options = {})
    results = Hash.new
    if file.instance_of?(NuCoreFile) and file.thumbnail
      thumb = file.thumbnail
      datastreams = thumb.datastreams
      keys = thumb.datastreams.keys
      #remove the following keys from the hash to prevent large thumbnails from being generated
      if options[:remove_thumbs]
        remove_thumbs = options[:remove_thumbs]
        remove_thumbs.each do |t|
          keys.delete(t)  
        end 
      end
      keys.each do |key|
        datastream = datastreams[key]
        if key.include? "thumbnail" and datastream.content
          results[key] = sufia.download_path( thumb, datastream_id: key )
        end
      end
    end
    return results
  end

  # Generalizing function to prepare an item to be used in the drs-item view.
  def prepare_drs_item(item)
    drs_item = {
      :pid => nil,
      :path => nil,
      :title => nil,
      :creators => nil,
      :thumbnails => nil,
      :type => nil,
      :date_added => nil,
      :abstract => nil,
      :download_path => nil
    }
    if item.instance_of?(NuCollection) 
      drs_item[:pid] = item.pid
      drs_item[:path] = '/collections/' + item.pid
      drs_item[:title] = item.title
      drs_item[:type] = 'Collection'
      drs_item[:creators] = item.creators
      drs_item[:thumbnails] = nil #item.thumbnail ? sufia.download_path(item, datastream_id: 'thumbnail') : false
      drs_item[:date_added] = item.date_of_issue
      drs_item[:abstract] = item.description
      drs_item[:download_path] = false
    end
    if item.instance_of?(Community)
      drs_item[:pid] = item.pid
      drs_item[:path] = '/communities/' + item.pid
      drs_item[:title] = item.title
      drs_item[:type] = 'Community'
      drs_item[:thumbnails] = nil
      drs_item[:date_added] = nil
      drs_item[:abstract] = item.description
      drs_item[:download_path] = false
    end
    if item.instance_of?(NuCoreFile)
      drs_item[:type] = item['mime_type']
      drs_item[:pid] = item.pid
      drs_item[:path] = '/files/' + item.pid
      drs_item[:title] = item.title
      drs_item[:type] = 'file'
      drs_item[:thumbnails] = get_file_thumbnails(item, { remove_thumbs: ['thumbnail_4', 'thumbnail_4_2x', 'thumbnail_10', 'thumbnail_10_2x'] })
      drs_item[:date_added] = nil
      drs_item[:abstract] = item.description
      drs_item[:download_path] = false
    
    end
    return drs_item

  end

end





