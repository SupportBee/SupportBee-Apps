module SupportBeeApp
  class Command < Thor
    include Thor::Actions

    def self.source_root
      "#{PLATFORM_ROOT}/templates"
    end

    attr_accessor :slug

    desc "new APP_SLUG", "create a new SupportBee app"
    def new(slug)
      slug = slug.downcase
      unless slug =~ /^[a-z_][a-z_0-9]*$/
        puts "#{slug} should be a valid variable name"
        return
      end

      destination_root = "#{APPS_PATH}/#{slug}"

      if Dir.exists?(destination_root)
        puts "An App with slug #{slug} already exists"
        return
      else
        FileUtils.mkdir(destination_root)
      end

      puts "Generating app #{slug}..."
      self.slug = slug
      template("#{source_root}/config.yml.tt", "#{destination_root}/config.yml")     
      template("#{source_root}/slug.rb.tt", "#{destination_root}/#{slug}.rb")
      directory("#{source_root}/assets", "#{destination_root}/assets")
    end

    no_tasks do
      def source_root
        self.class.source_root
      end
    end
  end
end
