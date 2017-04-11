# Sidekiq Pro

This gem adds advanced functionality and a commercial license for the Sidekiq
background job framework.

## What's Provided

* **Batch** - adds the notion of a set of jobs, so you can track progress
  of the batch and receive notification when the batch is complete.  The
  Sidekiq Web UI provides a convenient overview of all Batches being processed
  and their status.

* **Reliability** - adds reliability upgrades to the client push to Redis
  and the server fetch from Redis, to better withstand network outages
  and process crashes.

* **Much, much more** - Statsd, pause queues, API extensions, expire
  jobs, etc.


## Download

When you purchase Sidekiq Pro, you will receive an email within 24 hours
with your own personalized download URL.  This URL can be used with a
Gemfile:

    source 'https://rubygems.org'
    source 'https://YOUR:CODE@gems.contribsys.com/'

    gem 'sidekiq-pro'

Please keep this URL private; I do reserve the right to revoke access if
the URL is made public and/or is being used to illegally download Sidekiq Pro.


## Usage

Please see the Sidekiq wiki for in-depth documentation on each Sidekiq
Pro feature and how to use it.


## Licensing

This library is sold commercially to provide support for the development of Sidekiq.
**The gem file or any of its contents may not be publicly distributed.**

See COMM-LICENSE for the license terms.


## Support

Please open an issue in the Sidekiq issue tracker or send an email to
the sidekiq mailing list.  If you note that you are a Pro user, I will
make an effort to reply within 24 hours.
