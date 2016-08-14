%define module App-PFT
Name:           perl-%{module}
Version:        1.0.5
Release:        2%{?dist}
Summary:        Hacker friendly static blog generator

License:        GPL+
URL:            https://github.com/dacav/%{module}
Source0:        https://github.com/dacav/%{module}/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
%define patchbase https://raw.githubusercontent.com/dacav/%{module}/v%{version}/packages/rpm/%{name}
Patch0:         %{patchbase}.libexec.patch

BuildArch:      noarch
# Correct for lots of packages, other common choices include eg. Module::Build
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:       perl(PFT)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(File::ShareDir::Install)

%{?perl_default_filter}

%description
PFT stands for *Plain F. Text*, where the meaning of *F.* is up to
personal interpretation. Like *Fancy* or *Fantastic*.

It is yet another static website generator. This means your content is
compiled once and the result can be served by a simple HTTP server,
without need of server-side dynamic content generation.


%prep
%setup -q -n %{module}-%{version}
%patch0 -p1

%build
# Remove OPTIMIZE=... from noarch packages (unneeded)
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="$RPM_OPT_FLAGS"
make %{?_smp_mflags}


%install
rm -rf %{buildroot}
make pure_install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot}%{perl_vendorlib} -type f -name .packlist -exec rm -f {} ';'
install -d %{buildroot}%{_libexecdir}/%{name}

mv "%{buildroot}%{_bindir}/pft-clean"   "%{buildroot}%{_libexecdir}/%{name}"
mv "%{buildroot}%{_bindir}/pft-edit"    "%{buildroot}%{_libexecdir}/%{name}"
mv "%{buildroot}%{_bindir}/pft-grab"    "%{buildroot}%{_libexecdir}/%{name}"
mv "%{buildroot}%{_bindir}/pft-init"    "%{buildroot}%{_libexecdir}/%{name}"
mv "%{buildroot}%{_bindir}/pft-ls"      "%{buildroot}%{_libexecdir}/%{name}"
mv "%{buildroot}%{_bindir}/pft-make"    "%{buildroot}%{_libexecdir}/%{name}"
mv "%{buildroot}%{_bindir}/pft-pub"     "%{buildroot}%{_libexecdir}/%{name}"
mv "%{buildroot}%{_bindir}/pft-show"    "%{buildroot}%{_libexecdir}/%{name}"


%check
LC_ALL="en_US.utf8" make test


%files
%doc %{_mandir}/man1/*
%{perl_vendorlib}/*
%attr(755, -, -) %{_bindir}/pft
%attr(755, -, -) %{_libexecdir}/%{name}/pft-clean
%attr(755, -, -) %{_libexecdir}/%{name}/pft-edit
%attr(755, -, -) %{_libexecdir}/%{name}/pft-grab
%attr(755, -, -) %{_libexecdir}/%{name}/pft-init
%attr(755, -, -) %{_libexecdir}/%{name}/pft-ls
%attr(755, -, -) %{_libexecdir}/%{name}/pft-make
%attr(755, -, -) %{_libexecdir}/%{name}/pft-pub
%attr(755, -, -) %{_libexecdir}/%{name}/pft-show


%changelog
* Sun Aug 14 2016 dacav openmailbox org - 1.0.5-2
- Fixed changelog

* Sun Aug 14 2016 dacav openmailbox org - 1.0.5-1
- Release v1.0.5

* Sat Jul 23 2016 dacav@openmailbox.org
- Patches from github according to version tag

* Tue Jun 21 2016 dacav openmailbox.org 1.0.2-1
- Moved transitive call binaries in /usr/libexec

* Mon Jun 20 2016 dacav openmailbox.org 1.0.2-1
- First packaging
