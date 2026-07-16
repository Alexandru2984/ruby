class PublicSharesController < ApplicationController
  # Enables sharing, or rotates the link if it is already enabled.
  def create
    Current.user.enable_public_sharing!
    redirect_to settings_path, notice: "Public sharing is on. Anyone with the link can see your favorites."
  end

  def destroy
    Current.user.disable_public_sharing!
    redirect_to settings_path, notice: "Public sharing is off. The old link no longer works."
  end
end
