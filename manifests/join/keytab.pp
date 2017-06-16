# == Class realmd::join::keytab
#
# This class is called from realmd for performing
# a passwordless AD join with a Kerberos keytab
#
class realmd::join::keytab {

  $_domain                = upcase($::realmd::domain)
  $_domain_join_user      = $::realmd::domain_join_user
  $_domain_join_password  = $::realmd::domain_join_password
  $_krb_keytab            = $::realmd::krb_keytab
  $_krb_config_file       = $::realmd::krb_config_file
  $_krb_config            = $::realmd::krb_config
  $_manage_krb_config     = $::realmd::manage_krb_config
  $_permit_groups         = $::realmd::permit_groups



  if $_manage_krb_config {
    file { 'krb_configuration':
      ensure  => file,
      path    => $_krb_config_file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('realmd/krb5.conf.erb'),
      notify  => Exec['run_kinit_with_keytab'],
    }
  }

  if $_krb_keytab != undef {

    file { 'krb_keytab':
      path   => $_krb_keytab,
      owner  => 'root',
      group  => 'root',
      mode   => '0400',
      notify => Exec['run_kinit_with_keytab'],
    }

    exec { 'run_kinit_with_keytab':
      path        => '/usr/bin:/usr/sbin:/bin',
      command     => "kinit -kt ${_krb_keytab} ${_domain_join_user}",
      refreshonly => true,
      before      => Exec['realm_join_with_keytab'],
    }
  } else {
    exec { 'run_kinit_with_keytab':
      path        => '/usr/bin:/usr/sbin:/bin',
      command     => "echo '${_domain_join_password}' | kinit ${_domain_join_user}@${_domain}",
      unless  => "klist -k /etc/krb5.keytab | grep -i $(hostname -s)@${_domain}",
      before      => Exec['realm_join_with_keytab'],
    }

  }

  exec { 'realm_join_with_keytab':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "realm join ${_domain}",
    unless  => "klist -k /etc/krb5.keytab | grep -i $(hostname -s)@${_domain}",
    require => Exec['run_kinit_with_keytab'],
  }

  if $_permit_groups != undef {

    realmd::join::permit { $_permit_groups:
      require => Exec['realm_join_with_keytab'],
    }

  }

}
