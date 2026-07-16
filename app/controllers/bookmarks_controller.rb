class BookmarksController < ApplicationController
  before_action :set_bookmark, only: %i[ show edit update destroy visit toggle_favorite archive unarchive ]

  # GET /bookmarks or /bookmarks.json
  def index
    @bookmarks = Current.user.bookmarks.newest_first.includes(:tags)
    @bookmarks = @bookmarks.tagged_with(params[:tag]) if params[:tag].present?
  end

  # GET /bookmarks/1 or /bookmarks/1.json
  def show
  end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new
  end

  # GET /bookmarks/1/edit
  def edit
  end

  # POST /bookmarks or /bookmarks.json
  def create
    @bookmark = Current.user.bookmarks.new(bookmark_params)

    respond_to do |format|
      if @bookmark.save
        format.html { redirect_to @bookmark, notice: "Bookmark was successfully created." }
        format.json { render :show, status: :created, location: @bookmark }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bookmarks/1 or /bookmarks/1.json
  def update
    respond_to do |format|
      if @bookmark.update(bookmark_params)
        format.html { redirect_to @bookmark, notice: "Bookmark was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @bookmark }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bookmarks/1 or /bookmarks/1.json
  def destroy
    @bookmark.destroy!

    respond_to do |format|
      format.html { redirect_to bookmarks_path, notice: "Bookmark was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # GET /bookmarks/1/visit — counts the click-through, then sends the browser on.
  def visit
    @bookmark.register_visit!
    redirect_to @bookmark.url, allow_other_host: true
  end

  # PATCH /bookmarks/1/toggle_favorite
  def toggle_favorite
    @bookmark.update!(favorite: !@bookmark.favorite?)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@bookmark) }
      format.html { redirect_back fallback_location: bookmarks_path, status: :see_other }
    end
  end

  # PATCH /bookmarks/1/archive
  def archive
    @bookmark.archive!
    redirect_back fallback_location: bookmarks_path, status: :see_other, notice: "Bookmark archived."
  end

  # PATCH /bookmarks/1/unarchive
  def unarchive
    @bookmark.unarchive!
    redirect_back fallback_location: bookmarks_path(filter: "archived"), status: :see_other, notice: "Bookmark restored."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bookmark
      @bookmark = Current.user.bookmarks.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def bookmark_params
      params.expect(bookmark: [ :title, :url, :description, :tag_list ])
    end
end
