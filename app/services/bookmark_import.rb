# Imports bookmarks from a browser export file (NETSCAPE-Bookmark-file-1
# HTML, as produced by Chrome/Firefox/Safari and this app's own export).
# Duplicate and invalid entries are counted but never abort the run.
class BookmarkImport
  Result = Struct.new(:imported, :skipped, keyword_init: true)

  MAX_LINKS = 1000

  def self.call(user:, html:)
    doc = Nokogiri::HTML(html.to_s)
    result = Result.new(imported: 0, skipped: 0)

    doc.css("a[href]").first(MAX_LINKS).each do |link|
      url = link["href"].to_s
      next unless url.match?(%r{\Ahttps?://}i)

      bookmark = user.bookmarks.new(
        url: url,
        title: link.text.strip.truncate(255).presence,
        description: description_for(link),
        tag_list: link["tags"]
      )

      added_at = link["add_date"].to_i
      bookmark.created_at = Time.zone.at(added_at) if added_at.positive?

      if bookmark.save
        result.imported += 1
      else
        result.skipped += 1
      end
    end

    result
  end

  # In the Netscape format a <DD> holding the description follows the <DT>
  # that wraps the link. Browsers omit closing tags, so look for the <dd>
  # both as the parent's next sibling and as the link's own.
  def self.description_for(link)
    candidate = [ link.next_element, link.parent&.next_element ].compact.find { |node| node.name == "dd" }
    candidate&.text&.strip&.truncate(2000).presence
  end
  private_class_method :description_for
end
