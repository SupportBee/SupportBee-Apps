module SupportBeeApp
  module Build
    class << self

      def build
        move_assets
      end

      def move_assets
        SupportBeeApp::Base.apps.each do |app|
          images_path = app.root.join('assets','images')
          next unless Dir.exists?(images_path)
          Dir.new(images_path).each do |file|
            next if file == '.' or file == '..'
            file_path = images_path.join(file)
            public_path = Pathname.new(PLATFORM_ROOT).join('public','images',app.slug)
            FileUtils.mkpath(public_path)
            FileUtils.copy(file_path.to_s, public_path.to_s)
          end
        end
      end

    end
  end
end
