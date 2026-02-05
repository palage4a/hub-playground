`tt start` loses tarantool logs if tarantool has failed to start. For example, if
tarantool fails to start due permission issue.

Reproducer:

```
$ tarantool --version
Tarantool Enterprise 3.6.0-0-gb80f9ff9a
Target: Linux-x86_64-RelWithDebInfo
Build options: cmake . -DCMAKE_INSTALL_PREFIX=/builds/tarantool/delivery/sdk/build.sdk/tarantool-ee-3.6/static-build/tarantool-prefix -DENABLE_BACKTRACE=TRUE
Compiler: GNU-9.3.1
C_FLAGS: -fexceptions -funwind-tables -fasynchronous-unwind-tables -static-libstdc++ -fno-common -msse2 -Wformat -Wformat-security -Werror=format-security -fstack-protector-strong -fPIC -fmacro-prefix-map=/builds/tarantool/delivery/sdk/tarantool-ee-3.6=. -std=c11 -Wall -Wextra -Wno-gnu-alignof-expression -fno-gnu89-inline -Wno-cast-function-type -O2 -g -DNDEBUG -ggdb -O2 -flto -fno-fat-lto-objects
CXX_FLAGS: -fexceptions -funwind-tables -fasynchronous-unwind-tables -static-libstdc++ -fno-common -msse2 -Wformat -Wformat-security -Werror=format-security -fstack-protector-strong -fPIC -fmacro-prefix-map=/builds/tarantool/delivery/sdk/tarantool-ee-3.6=. -std=c++17 -Wall -Wextra -Wno-invalid-offsetof -Wno-gnu-alignof-expression -Wno-cast-function-type -O2 -g -DNDEBUG -ggdb -O2 -flto -fno-fat-lto-objects
$ tt version
Tarantool CLI EE 2.11.0, linux/amd64. commit: 0bacf70
$ tt create single_instance --name repro
   • Creating application in "/home/i-palagecha/code/palage4a/hub-playground/tarantool-playground/repro"
   • Using built-in 'single_instance' template.
   • Application 'repro' created successfully
$ ll repro
total 12K
-rw-r--r-- 1 i-palagecha i-palagecha 205 Feb  5 15:41 config.yml
-rw-r--r-- 1 i-palagecha i-palagecha  86 Feb  5 15:41 init.lua
-rw-r--r-- 1 i-palagecha i-palagecha  13 Feb  5 15:41 instances.yml
$ mkdir repro/var
$ id
uid=1000(i-palagecha) gid=1000(i-palagecha) groups=1000(i-palagecha),4(adm),20(dialout),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),105(tss),114(lpadmin),984(docker)
$ sudo chown -R 1001:1001 repro/var
$ ll repro/var
total 0
$ cat tt.yaml
modules:
  # Directory where the external modules are stored.
  directory: modules

env:
  # Restart instance on failure.
  restart_on_failure: false

  # Directory that stores binary files.
  bin_dir: bin

  # Directory that stores Tarantool header files.
  inc_dir: include

  # Path to directory that stores all applications.
  # The directory can also contain symbolic links to applications.
  instances_enabled: instances.enabled

  # Tarantoolctl artifacts layout compatibility: if set to true tt will not create application
  # sub-directories for control socket, pid files, log files, etc.. Data files (wal, vinyl,
  # snap) and multi-instance applications are not affected by this option.
  tarantoolctl_layout: false

app:
  # Directory that stores various instance runtime
  # artifacts like console socket, PID file, etc.
  run_dir: var/run

  # Directory that stores log files.
  log_dir: var/log

  # Directory where write-ahead log (.xlog) files are stored.
  wal_dir: var/lib

  # Directory where memtx stores snapshot (.snap) files.
  memtx_dir: var/lib

  # Directory where vinyl files or subdirectories will be stored.
  vinyl_dir: var/lib

# Path to file with credentials for downloading Tarantool Enterprise Edition.
# credential_path: /path/to/file
ee:
  credential_path:

templates:
  # The path to templates search directory.
  - path: templates

repo:
  # Directory where local rocks files could be found.
  rocks:
  # Directory that stores installation files.
  distfiles: distfiles
$ tt start repro
   • Starting an instance [repro:instance001]...
$ tt status repro
 INSTANCE           STATUS       PID  MODE  CONFIG  BOX  UPSTREAM
 repro:instance001  NOT RUNNING
$ tt log repro
$ tt start -i repro
$ tt log repro
$ cd repro
$ tarantool --name instance001 --config config.yml init.lua
builtin/config/applier/mkdir.lua:26: mkdir.apply[wal.dir]: failed to create directory var/lib/instance001: Error creating directory /home/i-palagecha/code/palage4a/hub-playground/tarantool-playground/repro/var/lib: fio: Permission denied
```

I am expecting that `tt log repro` and `tt start -i repro` will have a log message about error.

