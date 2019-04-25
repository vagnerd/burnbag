<ruby>
run_single("setg THREADS #{ENV['DOCKER_MS_THREADS']}")
run_single("setg RHOSTS #{ENV['DOCKER_URL_HACK']}")
</ruby>
  use auxiliary/scanner/http/http_version
run
  use auxiliary/scanner/http/dir_scanner
run
  use auxiliary/scanner/http/http_login
run
unsetg RHOSTS THREADS
exit
