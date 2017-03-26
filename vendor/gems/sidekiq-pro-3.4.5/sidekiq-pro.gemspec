# -*- encoding: utf-8 -*-
# stub: sidekiq-pro 3.4.5 ruby lib

Gem::Specification.new do |s|
  s.name = "sidekiq-pro"
  s.version = "3.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.contribsys.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib"]
  s.authors = ["Mike Perham"]
  s.date = "2017-03-07"
  s.description = "Loads of additional functionality for Sidekiq"
  s.email = ["mike@contribsys.com"]
  s.homepage = "http://sidekiq.org"
  s.rubygems_version = "2.4.5.1"
  s.summary = "Black belt functionality for Sidekiq"
  s.has_rdoc = true

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sidekiq>, [">= 4.1.5"])
    else
      s.add_dependency(%q<sidekiq>, [">= 4.1.5"])
    end
  else
    s.add_dependency(%q<sidekiq>, [">= 4.1.5"])
  end
end

