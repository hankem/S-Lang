% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("fcntl");

private define test_fcntl (fd)
{
   variable flags = fcntl_getfd (fd);
   if (flags == -1)
     failed ("fcntl_getfd failed: %S", errno_string());

   if (-1 == fcntl_setfd (fd, flags | FD_CLOEXEC))
     failed ("fcntl_setfd failed: %S", errno_string());

   flags = fcntl_getfd (fd);
   if (flags == -1)
     failed ("fcntl_getfd failed: %S", errno_string());

   ifnot (flags & FD_CLOEXEC)
     failed ("FD_CLOEXEC not set");

   if (-1 == fcntl_setfd (fd, flags & ~FD_CLOEXEC))
     failed ("fcntl_setfd failed: %S", errno_string());

   flags = fcntl_getfl (fd);
   if (flags == -1)
     failed ("fcntl_getfl failed: %S", errno_string());
   if (-1 == fcntl_setfl (fd, flags))
     failed ("fcntl_setfl failed: %S", errno_string());
}

define slsh_main ()
{
   testing_module ("fcntl");
   test_fcntl (fileno(stderr));
   test_fcntl (_fileno(stderr));
   end_test ();
}
