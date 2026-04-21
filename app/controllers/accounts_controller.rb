class AccountsController < ApplicationController
  def show
    @user = Current.user
  end

  def rotate_key
    Current.user.regenerate_api_key!
    redirect_to account_path, notice: "API key regenerated. Update your CLI and integrations with the new key."
  end
end
