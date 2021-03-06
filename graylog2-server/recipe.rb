class Graylog2Server < FPM::Cookery::Recipe
  description 'Graylog2 is an open source log management solution that stores your logs in ElasticSearch.'
  name        'graylog2-server'
  version     '0.9.6p1'
  revision    '2'
  homepage    'http://graylog2.org'
  source      'https://github.com/downloads/Graylog2/graylog2-server/graylog2-server-0.9.6p1.tar.gz'
  md5         '499ae16dcae71eeb7c3a30c75ea7a1a6'
  arch        'all'
  section     'admin'

  java = [
    'openjdk-7-jdk', 'openjdk-7-jre', 'openjdk-7-jre-headless',
    'openjdk-6-jdk', 'openjdk-6-jre', 'openjdk-6-jre-headless'
  ]

  depends java.join(' | ')

  config_files '/etc/graylog2.conf'

  # --[ Scripts ]--
  pre_uninstall  'pre-uninstall'
  post_uninstall  'post-uninstall'


  # --[ Changing default setup directory ]--
  def prefix (path = nil)
	  opt/'graylog2-server'/path
  end

  def build
    inreplace 'bin/graylog2ctl' do |s|
      s.gsub! '../graylog2-server.jar', share('graylog2-server/graylog2-server.jar')
    end

# --[ Mopngodb uses auth ]--
#    inline_replace 'graylog2.conf.example' do |s|
#      s.gsub! 'mongodb_useauth = true', 'mongodb_useauth = false'
#    end
    
  end

  def install
    FileUtils.chown_R '0', '0', '.'
    etc('init.d').install_p workdir('graylog2-server.init'), 'graylog2-server'
    share.install_p workdir('mongodb_user.sh'), 'mongodb_user.sh'

    bin.install 'bin/graylog2ctl'
    etc.install_p 'graylog2.conf.example', 'graylog2.conf'
    lib.install 'build_date'
    lib.install 'graylog2-server.jar'
  end
end
