class HomeController < ApplicationController
  allow_unauthenticated_access

  def show
    redirect_to projects_path if authenticated?
  end
end
