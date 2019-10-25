# frozen_string_literal: true

module WPScan
  module Finders
    module Plugins
      # Known Locations Plugins Finder
      class KnownLocations < CMSScanner::Finders::Finder
        include CMSScanner::Finders::Finder::Enumerator

        # @return [ Array<Integer> ]
        def valid_response_codes
          @valid_response_codes ||= [200, 401, 403, 500].freeze
        end

        # @param [ Hash ] opts
        # @option opts [ String ] :list
        #
        # @return [ Array<Plugin> ]
        def aggressive(opts = {})
          found = []

          enumerate(target_urls(opts), opts.merge(check_full_response: true)) do |_res, slug|
            found << Model::Plugin.new(slug, target, opts.merge(found_by: found_by, confidence: 80))

            raise Error::PluginsThresholdReached if opts[:threshold].positive? && found.size >= opts[:threshold]
          end

          found
        end

        # @param [ Hash ] opts
        # @option opts [ String ] :list
        #
        # @return [ Hash ]
        def target_urls(opts = {})
          slugs       = opts[:list] || DB::Plugins.vulnerable_slugs
          urls        = {}

          slugs.each do |slug|
            urls[target.plugin_url(slug)] = slug
          end

          urls
        end

        def create_progress_bar(opts = {})
          super(opts.merge(title: ' Checking Known Locations -'))
        end
      end
    end
  end
end
