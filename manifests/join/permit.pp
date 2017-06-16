define realmd::join::permit ($permit_group = $title){
  exec { $permit_group:
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "realm permit -g ${permit_group}",
    unless  => "realm list | grep -i ${permit_group}",
  }
}