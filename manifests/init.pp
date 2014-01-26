class skype(
  $user = 'skype',
  $ensure = 'running',
  $enable = true) {

  Exec {
    path => ['/usr/local/sbin','/usr/sbin','/sbin','/bin','/usr/bin'],
  }

  wget::fetch { 'skype.deb':
    source      => 'http://www.skype.com/go/getskype-linux-deb',
    destination => '/usr/local/src/skype.deb',
  }

  # Enable Multi-Arch
  if $::architecture == 'amd64' {
    exec { 'dpkg --add-architecture i386':
      notify => Exec['apt_update'],
    } ->
    exec { 'dpkg -s skype > /dev/null || dpkg -i /usr/local/src/skype.deb || apt-get -f -y install':
      require => Wget::Fetch ['skype.deb'],
      before  => Service['skype'],
    }
  } else {
    package { 'skype':
      ensure   => present,
      provider => 'dpkg',
      source   => '/usr/local/src/skype.deb',
      require  => Wget::Fetch ['skype.deb'],
      before   => Service['skype'],
    }
  }

  ensure_packages(['xvfb'])

  file { '/etc/init.d/skype':
    source => 'puppet:///modules/skype/skype.sh',
    mode   => '0755',
  } ~>
  file { '/etc/default/skype':
    content => template('skype/skype.erb'),
  } ~>
  service { 'skype':
    ensure => $ensure,
    enable => $enable,
  }
}
