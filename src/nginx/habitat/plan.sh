pkg_name=chef-server-nginx
pkg_origin=chef
pkg_version="0.1.0"
pkg_maintainer="The Chef Server Maintainers <support@chef.io>"
pkg_license=('Apache-2.0')

pkg_deps=(
  core/curl
  core/libossp-uuid
  core/glibc
  core/gcc-libs
  core/libxml2
  core/libxslt
  core/zlib
  core/bzip2
  core/pcre
  core/coreutils
  core/perl
  core/which
  core/openssl/1.0.2l/20171014213633
  chef-server/openresty-lpeg
#  core/openssl
)

pkg_source=https://openresty.org/download/openresty-1.11.2.2.tar.gz
pkg_upstream_url=http://openresty.org/
pkg_shasum=7f9ca62cfa1e4aedf29df9169aed0395fd1b90de254139996e554367db4d5a01
pkg_svc_run="openresty -c ${pkg_svc_config_path}/nginx.conf -p ${pkg_svc_var_path}"

pkg_build_deps=(
  core/gcc
  core/make
  core/coreutils
)

pkg_lib_dirs=(lib)

pkg_bin_dirs=(
  bin
  nginx/sbin
  luajit/bin
)

pkg_include_dirs=(include)


pkg_exposes=(port ssl-port)
pkg_exports=(
    [port]=port
    [ssl-port]=ssl_port
)
pkg_binds_optional=(
  [bookshelf]="port"
  [oc_erchef]="port"
  [oc_bifrost]="port"
  [elasticsearch]="http-port"
)
pkg_description="NGINX configuration and content for Chef Server"
pkg_upstream_url="https://docs.chef.io/server_components.html"


do_prepare() {
  # The `/usr/bin/env` path is hardcoded, so we'll add a symlink.
  if [[ ! -r /usr/bin/env ]]; then
    ln -sv "$(pkg_path_for coreutils)/bin/env" /usr/bin/env
    _clean_env=true
  fi
}

pkg_dirname=openresty-1.11.2.2
do_build() {
    
    ./configure --prefix="$pkg_prefix" \
    --user=hab \
    --group=hab \
    --http-log-path=stdout \
    --error-log-path=stderr \
    --with-ipv6 \
    --with-debug \
    --with-pcre \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-file-aio \
    --with-luajit \
    --with-stream=dynamic \
    --with-mail=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_addition_module \
    --with-http_degradation_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_secure_link_module \
    --with-http_sub_module \
    --with-http_slice_module \
    --with-cc-opt="$CFLAGS" \
    --with-ld-opt="$LDFLAGS" \
    --without-http_ssi_module \
    --without-mail_smtp_module \
    --without-mail_imap_module \
    --without-mail_pop3_module \
    -j"$(nproc)"\
    || attach

  make -j"$(nproc)"
}

# NOT RIGHT
do_install() {
  make install
  fix_interpreter "$pkg_prefix/bin/*" core/coreutils bin/env
  cp $(hab pkg path "chef-server/openresty-lpeg")/lpeg.so ${pkg_prefix}/luajit/lib/lua/5.1/ || attach
}

do_strip() {
  return 0
}


## NOT RIGHT
do_after() {
    return 0
}

do_end() {
  # Clean up the `env` link, if we set it up.
  if [[ -n "$_clean_env" ]]; then
    rm -fv /usr/bin/env
  fi
}
