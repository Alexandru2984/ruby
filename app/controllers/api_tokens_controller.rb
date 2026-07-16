class ApiTokensController < ApplicationController
  # (Re)generates the user's API token, invalidating the previous one.
  def create
    Current.user.regenerate_api_token
    redirect_to settings_path, notice: "API token generated. The previous token no longer works."
  end

  def destroy
    Current.user.update!(api_token: nil)
    redirect_to settings_path, notice: "API token revoked."
  end
end
