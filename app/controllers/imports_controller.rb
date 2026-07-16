class ImportsController < ApplicationController
  MAX_FILE_SIZE = 5.megabytes

  rate_limit to: 5, within: 1.minute, only: :create, with: -> { redirect_to new_import_path, alert: "Try again later." }

  def new
  end

  def create
    file = params[:file]

    if file.respond_to?(:read) && file.size <= MAX_FILE_SIZE
      result = BookmarkImport.call(user: Current.user, html: file.read)
      redirect_to bookmarks_path, notice: "Imported #{result.imported} #{"bookmark".pluralize(result.imported)}, skipped #{result.skipped}."
    elsif file.respond_to?(:read)
      redirect_to new_import_path, alert: "File is too large (5 MB max)."
    else
      redirect_to new_import_path, alert: "Choose a bookmarks HTML file to import."
    end
  end
end
