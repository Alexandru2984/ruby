class SharedBookmarksController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 60, within: 1.minute, with: -> { redirect_to root_path, alert: "Try again later." }

  def show
    @owner = User.find_by!(public_token: params.expect(:token))
    @pagy, @bookmarks = pagy(@owner.bookmarks.active.favorites.includes(:tags).newest_first)
  end
end
