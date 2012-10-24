module SupportBeeApp
  module Build
    class << self
      def build_js
        output_path = Pathname.new(PLATFORM_ROOT).join('public','javascripts','sb.apps.js').to_s

        js = StringIO.new

        init_js = 'if(typeof SB === "undefined") { SB = {};} SB.Apps = {};'
        js << init_js
        js << "\n\n"

        js << 'Handlebars.registerHelper(\'ifTicketsCountZero\', function(tickets) {
          return tickets.length === 0;
        });'

        js << "\n"

        js << 'Handlebars.registerHelper(\'ifTicketsCountOne\', function(tickets) {
          return tickets.length === 1;
        });'

        js << "\n"

        js << 'Handlebars.registerHelper(\'ifTicketsCountMany\', function(tickets) {
          return tickets.length > 1;
        });'

        js << "\n"

        SupportBeeApp::Base.apps.each do |app|
          app_hash = app.configuration
          app_js = "SB.Apps.#{app.slug} = #{JSON.pretty_generate(app_hash)}\n"
          app_actions = app_hash['action'].blank? ? {} : app_hash['action']
          app_actions.each_pair do |name, options|
            app_js << render_button_overlay(app) if name == 'button'
          end
          js << "\n"
          js << app_js
          js << "\n"
        end

        output = File.open(output_path, 'w')
        output.write(js.string)
        output.close
      end

      private

      def render_button_overlay(app)
        button_overlay_path = app.root.join('assets','views','button','overlay.hbs').to_s
        template = File.read(button_overlay_path).gsub("'","\'").gsub("\n","\\n")
        overlay_js = "Handlebars.compile('#{template}')"
        "SB.Apps.#{app.slug}.overlay = #{overlay_js}"
      end
    end
  end
end
