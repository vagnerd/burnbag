setg THREADS XXX_THREADS_XXX
setg RHOSTS XXX_HOST_XXX
  use auxiliary/scanner/http/http_version
run
  use auxiliary/scanner/http/dir_scanner
run
  use auxiliary/scanner/http/http_login
run
unsetg RHOSTS THREADS
exit
