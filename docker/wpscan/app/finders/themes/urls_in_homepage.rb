# frozen_string_literal: true

module WPScan
  module Finders
    module Themes
      # URLs In Homepage Finder
      class UrlsInHomepage < CMSScanner::Finders::Finder
        include WpItems::URLsInHomepage

        # @param [ Hash ] opts
        #
        # @return [ Array<Theme> ]
        def passive(opts = {})
          found = []

          (items_from_links('themes') + items_from_codes('themes')).uniq.sort.each do |slug|
            found << Model::Theme.new(slug, target, opts.merge(found_by: found_by, confidence: 80))
          end

          found
        end
      end
    end
  end
end
