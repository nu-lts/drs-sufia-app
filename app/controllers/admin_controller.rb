class AdminController < ApplicationController
  include Drs::ControllerHelpers::EditableObjects
  
  before_filter :authenticate_user!
  before_filter :verify_admin

  def index 

  end

  private 

    def verify_admin 
      redirect_to root_path unless current_user.admin?
    end
end