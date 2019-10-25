# frozen_string_literal: true

require_relative 'wordpress/custom_directories'

shared_examples WPScan::Target::Platform::WordPress do
  it_behaves_like 'WordPress::CustomDirectories'

  let(:fixtures) { FIXTURES.join('target', 'platform', 'wordpress') }

  describe '#wordpress?' do
    let(:fixtures) { super().join('detection') }

    before do
      stub_request(:get, target.url).to_return(body: File.read(fixtures.join("#{homepage}.html")))
    end

    context 'when pattern/s in the homepage' do
      %w[default wp_includes only_scripts meta_generator comments mu_plugins wp_admin wp_json_oembed].each do |file|
        context "when a wordpress page (#{file}.html)" do
          let(:homepage) { file }

          it 'returns true' do
            expect(subject.wordpress?(:mixed)).to be true
          end
        end
      end
    end

    context 'when no clues in the homepage' do
      let(:homepage) { 'not_wp' }

      context 'when only passive detection mode' do
        it 'returns false' do
          expect(subject.wordpress?(:passive)).to be false
        end
      end

      context 'when mixed or aggressive detection modes' do
        context 'when wp-admin/install.php and wp-login.php not there' do
          it 'returns false' do
            %w[wp-admin/install.php wp-login.php].each do |path|
              stub_request(:get, target.url(path)).to_return(status: 404)
            end

            expect(subject.wordpress?(:mixed)).to be false
          end
        end

        context 'when wp-admin/install.php is matching a WP install' do
          it 'returns true' do
            stub_request(:get, target.url('wp-admin/install.php'))
              .to_return(body: File.read(fixtures.join('wp-admin-install.php')))

            expect(subject.wordpress?(:mixed)).to be true
          end
        end

        context 'when wp-admin/install.php not there but wp-login.php is matching a WP install' do
          it 'returns true' do
            stub_request(:get, target.url('wp-admin/install.php')).to_return(status: 404)
            stub_request(:get, target.url('wp-login.php'))
              .to_return(body: File.read(fixtures.join('wp-login.php')))

            expect(subject.wordpress?(:mixed)).to be true
          end
        end
      end
    end
  end

  describe '#maybe_add_cookies' do
    let(:fixtures) { super().join('maybe_add_cookies') }
    let(:browser)  { WPScan::Browser.instance }

    context 'when nothing matches' do
      it 'does nothing' do
        stub_request(:get, target.url).to_return(body: 'nothing there')

        subject.maybe_add_cookies

        expect(browser.cookie_string).to eql nil
        expect(subject.homepage_res.body).to eql 'nothing there'
      end
    end

    context 'when matches' do
      before do
        stub_request(:get, target.url)
          .to_return(
            { body: File.read(fixtures.join("#{cookie}.html")) },
            body: 'Cookies Accepted!' # if we put {} there, ruobop not happy!
          )
      end

      {
        'vjs' => 'vjs=2420671338'
      }.each do |key, expected_cookie_string|
        context "when #{key} match" do
          let(:cookie) { key }

          context 'when the browser does not have a cookie_string already' do
            before do
              subject.maybe_add_cookies

              # This one does not work, opened an issue
              # https://github.com/bblimke/webmock/issues/813
              # stub_request(:get, target.url)
              #  .with(headers: { 'Cookie' => expected_cookie_string })
              #  .to_return(body: 'Cookies Accepted!')
            end

            it 'sets the correct cookies, reset the homepage_res' do
              expect(browser.cookie_string).to eql expected_cookie_string
              expect(subject.homepage_res.body).to eql 'Cookies Accepted!'
            end
          end

          context 'when the browser has cookie_string already' do
            before do
              browser.cookie_string = 'key=no-override'

              subject.maybe_add_cookies

              # This one does not work, opened an issue
              # https://github.com/bblimke/webmock/issues/813
              # stub_request(:get, target.url)
              #  .with(headers: { 'Cookie' => "#{expected_cookie_string}; key=no-override" })
              #  .to_return(body: 'Cookies Accepted!')
            end

            it 'sets the correct cookies, reset the homepage_res' do
              expect(browser.cookie_string).to eql "#{expected_cookie_string}; key=no-override"
              expect(subject.homepage_res.body).to eql 'Cookies Accepted!'
            end
          end
        end
      end
    end
  end

  describe '#wordpress_hosted?' do
    let(:fixtures) { super().join('wordpress_hosted') }

    context 'when the target host matches' do
      let(:url) { 'http://ex.wordpress.com' }

      its(:wordpress_hosted?) { should be true }
    end

    context 'when the target host doesn\'t matches' do
      let(:url) { 'http://ex-wordpress.com' }

      context 'when wp-content not detected' do
        before do
          expect(target).to receive(:content_dir).and_return(nil)
          stub_request(:get, target.url).to_return(body: File.read(fixtures.join(fixture).to_s))
        end

        context 'when an URL matches a WP hosted' do
          let(:fixture) { 'matches.html' }

          its(:wordpress_hosted?) { should be true }
        end

        context 'when URLs don\'t match' do
          let(:fixture) { 'no_match.html' }

          its(:wordpress_hosted?) { should be false }
        end
      end

      context 'when wp-content detected' do
        before { expect(target).to receive(:content_dir).and_return('wp-content') }

        its(:wordpress_hosted?) { should be false }
      end
    end
  end

  describe '#login_url' do
    before { allow(target).to receive(:sub_dir) }

    context 'when returning a 200' do
      before { stub_request(:get, target.url('wp-login.php')).to_return(status: 200) }

      its(:login_url) { should eql target.url('wp-login.php') }
    end

    context 'when a redirection occured' do
      before do
        expect(WPScan::Browser).to receive(:get_and_follow_location)
          .and_return(Typhoeus::Response.new(effective_url: effective_url, body: ''))
      end

      context 'to an in scope URL' do
        context 'when https version of the wp-login' do
          let(:effective_url) { target.url('wp-login.php').gsub('http', 'https') }

          its(:login_url) { should eql effective_url }
        end

        context 'when something else' do
          let(:effective_url) { target.url('something').gsub('http', 'https') }

          its(:login_url) { should eql target.url('wp-login.php') }
        end
      end

      context 'to an out of scope URL' do
        let(:effective_url) { 'http://something.else' }

        its(:login_url) { should eql target.url('wp-login.php') }
      end
    end
  end
end
