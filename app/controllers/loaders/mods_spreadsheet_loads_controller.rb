class Loaders::ModsSpreadsheetLoadsController < Loaders::LoadsController
  before_filter :verify_group
  require 'stanford-mods'
  include ModsDisplay::ControllerExtension
  configure_mods_display do
    subject do
      delimiter " -- "
    end
  end

  def new
    query_result = ActiveFedora::SolrService.query("active_fedora_model_ssi:\"Collection\"", :fl => "id, title_tesim", :rows => 999999999, :sort => "id asc")
    @collections_options = Array.new()
    query_result.each do |c|
      if current_user.can?(:edit, c['id'])
        @collections_options << {'label' => "#{c['id']} - #{c['title_tesim'][0]}", 'value' => c['id']}
      end
    end
    @loader_name = t('drs.loaders.'+t('drs.loaders.mods_spreadsheet.short_name')+'.long_name')
    @loader_short_name = t('drs.loaders.mods_spreadsheet.short_name')
    @page_title = @loader_name + " Loader"
    render 'loaders/new', locals: { collections_options: @collections_options}
  end

  def create
    permissions = {"CoreFile" => {"read"  => ["public"], "edit" => ["northeastern:drs:repository:staff"]}}
    process_create(permissions, t('drs.loaders.mods_spreadsheet.short_name'), "ModsSpreadsheetLoadsController")
  end

  def preview
    @report = Loaders::LoadReport.find(params[:id])

    @core_file = CoreFile.find(@report.preview_file_pid)
    @mods_html = render_mods_display(CoreFile.find(@core_file.pid)).to_html.html_safe

    @user = User.find_by_nuid(@report.nuid)
    @collection_title = ActiveFedora::SolrService.query("id:\"#{@report.collection}\"", :fl=>"title_tesim")
    @collection_title = @collection_title[0]['title_tesim'][0]
    if @collection_title.blank?
      @collection_title = "N/A"
    end
    render 'loaders/preview'
  end

  def preview_compare
    @report = Loaders::LoadReport.find(params[:id])

    @core_file = CoreFile.find(@report.preview_file_pid)
    old_core = CoreFile.find(@report.comparison_file_pid)

    @diff = mods_diff(old_core, @core_file)
    @diff_css = Diffy::CSS
    @mods_html = render_mods_display(CoreFile.find(@core_file.pid)).to_html.html_safe

    @user = User.find_by_nuid(@report.nuid)
    @collection_title = ActiveFedora::SolrService.query("id:\"#{@report.collection}\"", :fl=>"title_tesim")
    @collection_title = @collection_title[0]['title_tesim'][0]
    if @collection_title.blank?
      @collection_title = "N/A"
    end
    render 'loaders/preview'
  end

  def cancel_load
    @report = Loaders::LoadReport.find(params[:id])
    if !@report.preview_file_pid.blank?
      cf = CoreFile.find(@report.preview_file_pid)
      FileUtils.rm(cf.tmp_path)
      cf.destroy
    end
    flash[:notice] = "Your load has been cancelled."
    redirect_to "/my_loaders"
  end

  def proceed_load
    @report = Loaders::LoadReport.find(params[:id])
    @loader_name = t('drs.loaders.mods_spreadsheet.long_name')
    if !@report.preview_file_pid.blank?
      cf = CoreFile.find(@report.preview_file_pid)
      spreadsheet_file_path = cf.tmp_path
    elsif !@report.comparison_file_pid.blank?
      cf = CoreFile.find(@report.comparison_file_pid)
      spreadsheet_file_path = cf.tmp_path
    end
    copyright = t('drs.loaders.mods_spreadsheet.copyright')
    permissions = {"CoreFile" => {"read"  => ["public"], "edit" => ["northeastern:drs:repository:staff"]}}
    puts @loader_name
    puts spreadsheet_file_path
    puts @report.collection
    puts copyright
    puts current_user
    puts permissions
    puts @report.id
    puts Resque.info
    Cerberus::Application::Queue.push(ProcessModsZipJob.new(@loader_name, spreadsheet_file_path, @report.collection, copyright, current_user, permissions, @report.id, nil))
    puts Resque.info
    redirect_to "/loaders/mods_spreadsheet/report/#{@report.id}"
  end

  private

    def verify_group
      redirect_to new_user_session_path if current_user.nil?
      redirect_to root_path unless current_user.mods_spreadsheet_loader?
    end

    def mods_diff(core_file_a, core_file_b)
      mods_a = Nokogiri::XML(core_file_a.mods.content).to_s
      mods_b = Nokogiri::XML(core_file_b.mods.content).to_s
      return Diffy::Diff.new(mods_a, mods_b, :include_plus_and_minus_in_html => true, :context => 1).to_s(:html).html_safe
    end

end
