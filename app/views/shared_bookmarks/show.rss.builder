xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Shared favorites"
    xml.description "A hand-picked collection of favorite links."
    xml.link shared_bookmarks_url(token: @owner.public_token)
    xml.tag!("atom:link", href: shared_bookmarks_url(token: @owner.public_token, format: :rss), rel: "self", type: "application/rss+xml")

    @bookmarks.each do |bookmark|
      xml.item do
        xml.title bookmark.display_title
        xml.link bookmark.url
        xml.description bookmark.description if bookmark.description.present?
        bookmark.tags.sort_by(&:name).each { |tag| xml.category tag.name }
        xml.pubDate bookmark.created_at.rfc822
        xml.guid bookmark.url, isPermaLink: "true"
      end
    end
  end
end
