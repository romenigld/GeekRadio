# README

for run icecast:

$ icecast -c /usr/local/etc/icecast.xml

To have launchd start redis now and restart at login:

  $ brew services start redis

Or, if you don't want/need a background service you can just run:
  redis-server /usr/local/etc/redis.conf

For boot Sidekiq:

  $ bundle exec sidekiq

Then start rails:

$ rails s
