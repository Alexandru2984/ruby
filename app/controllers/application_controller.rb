class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :signups_enabled?

  private
    # Self-hosters can close registration by setting DISABLE_SIGNUPS=1.
    def signups_enabled?
      ENV["DISABLE_SIGNUPS"].blank?
    end
end
