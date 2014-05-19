require 'blacklight/catalog'
require 'blacklight_advanced_search'
require 'parslet'
require 'parsing_nesting/tree'

class NuCollectionsController < SetsController
  include Drs::ControllerHelpers::EditableObjects

  include Blacklight::Catalog
  include Blacklight::Configurable # comply with BL 3.7
  include ActionView::Helpers::DateHelper
  # This is needed as of BL 3.7
  self.copy_blacklight_config_from(CatalogController)

  include BlacklightAdvancedSearch::ParseBasicQ
  include BlacklightAdvancedSearch::Controller

  before_filter :authenticate_user!, only: [:new, :edit, :create, :update, :destroy ]

  # We can do better by using SOLR check instead of Fedora
  #before_filter :can_read?, only: [:show]
  before_filter :enforce_show_permissions, :only=>:show
  self.solr_search_params_logic += [:add_access_controls_to_solr_params]

  before_filter :can_edit?, only: [:edit, :update]
  before_filter :is_depositor?, only: [:destroy]

  before_filter :can_edit_parent?, only: [:new, :create]

  rescue_from Exceptions::NoParentFoundError, with: :index_redirect
  rescue_from Exceptions::SearchResultTypeError, with: :index_redirect_with_bad_search

  rescue_from Blacklight::Exceptions::InvalidSolrID, ActiveFedora::ObjectNotFoundError do |exception|
    @obj_type = "Community"
    ExceptionNotifier.notify_exception(exception)
    render "error/object_404"
  end

  rescue_from Hydra::AccessDenied, CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    ExceptionNotifier.notify_exception(exception)
    render_403 and return
  end

  def new
    @page_title = "New Collection"
    @set = NuCollection.new(parent: params[:parent])
    render :template => 'shared/sets/new'
  end

  def create
    @set = NuCollection.new(params[:set].merge(pid: mint_unique_pid))

    parent = ActiveFedora::Base.find(params[:set][:parent], cast: true)

    # Assign personal collection specific info if parent collection is a
    # smart collection.
    if parent.is_smart_collection?

      if !(parent.smart_collection_type == "Theses and Dissertations")
        @set.user_parent = parent.user_parent.nuid
      end

      if parent.smart_collection_type == 'User Root'
        @set.smart_collection_type = 'miscellany'
      else
        @set.smart_collection_type = parent.smart_collection_type
      end

    end

    # Process Thumbnail
    if params[:thumbnail]
      InlineThumbnailCreator.new(@set, params[:thumbnail], "thumbnail").create_thumbnail_and_save
    end

    @set.depositor = current_user.nuid
    @set.identifier = @set.pid

    begin
      @set.save!
      flash[:notice] = "Collection created successfully."
      redirect_to nu_collection_path(id: @set.identifier) and return
    rescue => error
      logger.error "NuCollectionsController::create rescued #{error.class}\n\t#{error.to_s}\n #{error.backtrace.join("\n")}\n\n"
      flash.now[:error] = "Something went wrong"
      redirect_to new_nu_collection_path(parent: params[:parent]) and return
    end
  end

  def show
    @set_id = params[:id]

    @set = SolrDocument.new(ActiveFedora::SolrService.query("id:\"#{params[:id]}\"").first)

    @page_title = @set.title

    if !@set.smart_collection_type.nil? && @set.smart_collection_type == 'User Root' && @set.pf_belongs_to_user?(current_user)
      return redirect_to personal_graph_path
    end

    self.solr_search_params_logic += [:show_children_only]
    (@response, @document_list) = get_search_results

    render :template => 'shared/sets/show'
  end

  def edit
    @set = NuCollection.find(params[:id])
    @page_title = "Edit #{@set.title}"
    render :template => 'shared/sets/edit'
  end

  def update
    @set = NuCollection.find(params[:id])

    # Update the thumbnail
    if params[:thumbnail]
      InlineThumbnailCreator.new(@set, params[:thumbnail], "thumbnail").create_thumbnail_and_save
    end

    if @set.update_attributes(params[:set])
      redirect_to(@set, notice: "Collection #{@set.title} was updated successfully." )
    else
      redirect_to(@set, notice: "Collection #{@set.title} failed to update.")
    end
  end

  def destroy
    @title = NuCollection.find(params[:id]).title

    if NuCollection.find(params[:id]).recursive_delete
      redirect_to(communities_path, notice: "#{@title} and its descendents destroyed")
    else
      redirect_to(communities_path, notice: "Something went wrong. #{@title} persists")
    end
  end

  protected

    def index_redirect(exception)
      flash[:error] = "Collections cannot be created without a parent"
      ExceptionNotifier.notify_exception(exception)
      redirect_to communities_path and return
    end

    def index_redirect_with_bad_search(exception)
      flash[:error] = exception.message
      ExceptionNotifier.notify_exception(exception)
      redirect_to communities_path and return
    end

    def show_children_only(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{Solrizer.solr_name("parent_id", :stored_searchable)}:\"#{@set_id}\""
    end

end
