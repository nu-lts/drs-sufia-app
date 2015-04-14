require 'blacklight/catalog'
require 'blacklight_advanced_search'
require 'parslet'
require 'parsing_nesting/tree'

class Admin::CoreFilesController < AdminController

  include Blacklight::Catalog
  include Blacklight::Configurable # comply with BL 3.7
  include ActionView::Helpers::DateHelper
  # This is needed as of BL 3.7
  self.copy_blacklight_config_from(CatalogController)

  include BlacklightAdvancedSearch::ParseBasicQ
  include BlacklightAdvancedSearch::Controller

  before_filter :authenticate_user!
  before_filter :verify_admin

  def index
    @page_title = "Administer Core Files"
  end

  def revive
    @core_file = CoreFile.find(params[:id])
    pid = @core_file.pid
    title = @core_file.title
    @core_file.revive
    redirect_to admin_files_path, notice: "Core File #{ActionController::Base.helpers.link_to title, core_file_path(pid)} has been revived".html_safe
  end

  def destroy
    @core_file = CoreFile.find(params[:id])
    pid = @core_file.pid

    if @core_file.pid
      redirect_to admin_files_path, notice: "Core File #{pid} removed"
    else
      redirect_to admin_files_path, notice: "Something went wrong"
    end
  end

  def get_core_files(type)
    filter_name = "limit_to_#{type}"
    @type = type.to_sym
    self.solr_search_params_logic += [filter_name.to_sym]
    (@response, @core_files) = get_search_results
    @count_for_files = @response.response['numFound']
    respond_to do |format|
      format.js {
        if @response.response['numFound'] == 0
          render js:"$('##{type} .core_files').replaceWith(\"<div class='core_files'>There are currently 0 #{type} files.</div>\");"
        else
          render "#{type.to_sym}"
        end
      }
    end
    self.solr_search_params_logic.delete(filter_name.to_sym)
  end

  def get_tombstoned
    get_core_files("tombstoned")
  end

  def get_in_progress
    get_core_files("in_progress")
  end

  def get_incomplete
    get_core_files("incomplete")
  end

  private

    def limit_to_tombstoned(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "tombstoned_ssi:\"true\""
    end
    def limit_to_in_progress(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "in_progress_tesim:\"true\""
    end
    def limit_to_incomplete(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "incomplete_tesim:\"true\""
    end

end
