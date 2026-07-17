class SharedBookmarksController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 60, within: 1.minute, with: -> { redirect_to root_path, alert: "Try again later." }

  def show
    @owner = User.find_by!(public_token: params.expect(:token))
    scope = @owner.bookmarks.active.favorites.includes(:tags).newest_first

    respond_to do |format|
      format.html { @pagy, @bookmarks = pagy(scope) }
      format.rss  { @bookmarks = scope.limit(50) }
    end
  end
end
