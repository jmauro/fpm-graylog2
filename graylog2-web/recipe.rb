class Graylog2Web < FPM::Cookery::Recipe
  description 'Web dashboard for Graylog2 - open source log management solution that stores your logs in ElasticSearch.'
  name        'graylog2-web'
  version     '0.9.6p1'
  revision    '3'
  homepage    'http://graylog2.org'
  source      'https://github.com/downloads/Graylog2/graylog2-web-interface/graylog2-web-interface-0.9.6p1.tar.gz'
  md5         '1235c5ccf3d9cf2b3d92f27702bce60d'
  arch        'all'
  section     'admin'

  build_depends 'rubygems', 'bundler'

  depends 'ruby1.8', 'libopenssl-ruby', 'ruby', 'rubygems'

  pre_install    'pre-install'
  post_install   'post-install'
  post_uninstall 'post-uninstall'

  def build
    system 'bundle install --path vendor/bundle 1>/dev/null'
    system 'bundle check --path vendor/bundle 1>/dev/null'
    system "patch -u vendor/bundle/ruby/1.8/gems/graylog2-declarative_authorization-0.5.2/lib/declarative_authorization/reader.rb #{workdir}/declarative_authorization-patch.p0"

    inline_replace 'config/application.rb' do |s|
      s.gsub! 'config.time_zone = \'UTC\'', 'config.time_zone = \'America/Los_Angeles\''
    end

    inline_replace 'config/mongoid.yml' do |s|
      s.gsub! '<%= ENV[\'MONGOID_HOST\'] %>', 'localhost'
      s.gsub! 'port: <%= ENV[\'MONGOID_PORT\'] %>', 'database: graylog2'
      s.gsub! 'username: <%= ENV[\'MONGOID_USERNAME\'] %>', ''
      s.gsub! 'password: <%= ENV[\'MONGOID_PASSWORD\'] %>', ''
      s.gsub! 'database: <%= ENV[\'MONGOID_DATABASE\'] %>', ''
    end
  end

  def install
    share('graylog2-web').install Dir['*']
    share('graylog2-web/tmp').mkpath
  end
end
