%define base_install_dir /data/webapps/%{shortname}
%define sourcedir %{_topdir}/SOURCES/%{shortname}-svn
%define shortname rally_metrics
%define ruby FixMe/ruby-1.9.3

Name:           FixMe%{shortname}
Version:        FixMe
Release:        1%{?dist}
Summary:        Rally Metrics Report
Packager:       FixMe <FixMe>
Group:          Development/Languages
License:        FixMe
URL:            FixMe

BuildRoot:      %{_topdir}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

%description 
This rpm contains the Rally RSS Feed.

%prep
rm -rf %{sourcedir}
git clone git@github.com:Surfman1975/rally_reporting.git %{sourcedir}
cd %{sourcedir}
git checkout %{version}

%build

%pre
# Keeping a copy of the last release
if [ -d %{base_install_dir}/current ]
then
  cd %{base_install_dir}

  if [ -h current ]
  then
    /bin/unlink current
  else
    /bin/rm -rf current.last
    /bin/mv current current.last
  fi

else
 echo "%{base_install_dir}/current does not exist"
fi

%install
rm -rf $RPM_BUILD_ROOT

%{__mkdir} -p %{buildroot}%{base_install_dir}
%{__mkdir} -p %{buildroot}%{base_install_dir}/current
%{__mkdir} -p %{buildroot}%{base_install_dir}/current/tmp
%{__mkdir} -p %{buildroot}%{base_install_dir}/shared
%{__mkdir} -p %{buildroot}%{base_install_dir}/shared/log
%{__mkdir} -p %{buildroot}%{base_install_dir}/shared/pids
%{__mkdir} -p %{buildroot}%{base_install_dir}/shared/system

### Move files into place
cp -pr %{sourcedir}/* %{buildroot}%{base_install_dir}/current

%post

### Run Bundler
echo "Installing gems and dependencies:  Using ruby at %{ruby}"
cd %{base_install_dir}/current
#export HOME=/data/nginx
export PATH="%{ruby}/bin:$PATH"
export RUBYLIB="%{ruby}/lib"
%{ruby}/bin/bundle install --path vendor/bundle --without "test development" --local

### Symlink log dir
/bin/ln -fs %{base_install_dir}/shared/log %{base_install_dir}/current/log

### Restart the application
touch %{base_install_dir}/current/tmp/restart.txt

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, nginx, nginx)
%{base_install_dir}

%attr(755, nginx, nginx) %{base_install_dir}/*

%changelog
* Date Email Version
- Initial version
