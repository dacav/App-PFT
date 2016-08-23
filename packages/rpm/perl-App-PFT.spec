%global module App-PFT
%global patchbase https://raw.githubusercontent.com/dacav/%{module}/v%{version}/packages/rpm/%{name}

Name:           perl-%{module}
Version:        1.0.5
Release:        3%{?dist}
Summary:        Hacker friendly static blog generator

License:        GPLv3+
URL:            https://github.com/dacav/%{module}
Source0:        https://github.com/dacav/%{module}/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
Patch0:         %{patchbase}.libexec.patch

BuildArch:      noarch
# Correct for lots of packages, other common choices include eg. Module::Build
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:       perl(PFT)

BuildRequires:  perl
BuildRequires:  perl-generators
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
%autosetup -n %{module}-%{version} -p1

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
make pure_install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null ';'
%{_fixperms} %{buildroot}/*
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
%{!?_licensedir:%global license %%doc}
%doc %{_mandir}/man1/*.1*
%doc README.md
%{perl_vendorlib}/*
%{_bindir}/pft
%{_libexecdir}/%{name}/pft-clean
%{_libexecdir}/%{name}/pft-edit
%{_libexecdir}/%{name}/pft-grab
%{_libexecdir}/%{name}/pft-init
%{_libexecdir}/%{name}/pft-ls
%{_libexecdir}/%{name}/pft-make
%{_libexecdir}/%{name}/pft-pub
%{_libexecdir}/%{name}/pft-show
%license COPYING


%changelog
* Tue Aug 23 2016 dacav@openmailbox.org - 1.0.5-3
- Fixes as by Bug 1368790 in bugzilla.redhat.com

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
