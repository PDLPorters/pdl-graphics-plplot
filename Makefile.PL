use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use Data::Dumper;

# Set these environment variables for search directories for LIB and INC.
use Env qw( $PLPLOT_LIBDIR $PLPLOT_INCDIR );

use Env qw(@LD_LIBRARY_PATH);

use PDL::Core::Dev;
use Devel::CheckLib;

my $PL_MAJOR = 5; # minimum required
my $PL_MINOR = 13;

unlink ("OPTIONS!"); # remove file used to communicate with plplot.pd


my @TRY_PLPLOT_LIBNAME = (
  'plplot',
);

my @TRY_EXTRA_LIBS = (
  '-lX11',
  '',
  '-lqsastime -lcsirocsa -lgdi32 -lcomdlg32',
);

my @TRY_LIBPATH = (
  split(' ', $Config{libpth}), # not perl-in-space friendly
  $ENV{PLPLOT_LIBDIR} || (),
  '/usr/local/plplot/lib64',
  '/usr/local/plplot/lib',
  '/usr/local/lib64',
  '/usr/local/lib',
  '/opt/local/lib',
  '/usr/lib64',
  '/usr/lib',
  '/opt/lib64',
  '/opt/lib',
  '/ops/tools/lib',
  '/sw/lib',    # default FINK installation
  # Add new library paths here!!
);

my @TRY_PLPLOT_HEADER = (
  'plplot.h',
);

my @TRY_INCPATH = (
  $ENV{PLPLOT_INCDIR} || (),
  '/usr/local/plplot/include',
  '/usr/local/plplot/include/plplot',
  '/usr/local/include/plplot',
  '/usr/local/include',
  '/opt/local/include',
  '/usr/include',
  '/usr/include/plplot',
  '/opt/include',
  '/ops/tools/include/plplot',
  '/ops/tools/include',
  '/sw/include/plplot',    # default FINK installation
  # Add new header paths here!!
);

# Find -L$path -l$libbasename
sub _probe_library_path {
  for my $libbasename (@TRY_PLPLOT_LIBNAME) {
    my $libname_dynamic = "lib${libbasename}.$Config{so}";
    my $libname_static  = "lib${libbasename}.a";
    for my $libdir (@TRY_LIBPATH) {
      next unless $libdir;
      for my $libname ( $libname_dynamic, $libname_static ) {
        if( -e File::Spec->catfile($libdir, $libname) ) {
          return {
            'libbasename' => $libbasename,
            'path'        => $libdir,
            'libname'     => $libname,
          };
        }
      }
    }
  }
}

# Find -I@paths for $header
sub _probe_inc_path {
  for my $header (@TRY_PLPLOT_HEADER) {
    for my $incdir (@TRY_INCPATH) {
      next unless $incdir;
      if( -e File::Spec->catfile($incdir, $header) ) {
        my $inc_above_plplot = $incdir =~ /plplot$/ ? $incdir : '';
        $inc_above_plplot =~ s|/plplot$||;
        return {
          'header' => $header,
          'paths'   => [
            $incdir,
            ( $inc_above_plplot ? $inc_above_plplot : () ),
          ],
        };
      }
    }
  }
}

my $libbasename;
my $libname;
my $plplot_lib_path;
my $plplot_include_path;
my $libs;
my $header;
sub probe {
  my $lib = _probe_library_path();
  unless($lib) {
    die "Cannot find plplot library\n";
  }

  my $inc = _probe_inc_path();
  unless($inc) {
    die "Cannot find plplot header file\n";
  }

  $libbasename = $lib->{libbasename};
  $plplot_lib_path = $lib->{path};
  $libname = $lib->{libname};
  push @LD_LIBRARY_PATH, $lib->{path};

  $plplot_include_path = join " ", map "-I$_", @{ $inc->{paths} };
  $header = $inc->{header};

  my $extra_libs;
  for my $try_libs (@TRY_EXTRA_LIBS) {
    if( check_lib(
      INC      => "$plplot_include_path",
      LIBS     => "-L$plplot_lib_path -l$libbasename $try_libs",
      header   => $header,
      function => 'plinit();',
      not_execute => 1,
    )) {
      $extra_libs = $try_libs;
      last;
    }
  }
  unless (defined($extra_libs)) {
    die "Cannot find good set of libraries for linking PLplot\n";
  }

  $libs = "-L$plplot_lib_path -l$libbasename $extra_libs";
}

probe;

# Test that PLplot was compiled --with-double (IE, a PLFLT is a double)
my $size = compileAndRun( <<'EOC' );
printf  ("%d", sizeof (PLFLT));
EOC

unless ($size == 8) {
  die <<'EOF';
Sizeof(PLFLT) must be 8.
PLplot must be compiled --with-double (IE ./configure --with-double).
EOF
}

my $plgver = compileAndRun (<<'EOC');
char ver[80];
c_plgver(ver);
fputs(ver, stdout);
EOC

my @plver = split /\./, $plgver;
unless ($plver[0] > $PL_MAJOR or ($plver[0] == $PL_MAJOR and $plver[1] >= $PL_MINOR)) {
  die "Insufficient plplot version '$plgver'; need at least $PL_MAJOR.$PL_MINOR\n";
}

my %plversion = ();
$plversion{'C_COMPILE'}   = "$Config{cc} $Config{ccflags} $plplot_include_path";
$plversion{'C_COMPILE_SUFFIX'} = $libs;
$plversion{'PLPLOT_LIB'}  = $plplot_lib_path;
# Write these options to a file--used during the test step
open my $fh, '>', 'OPTIONS!' or die "Cannot write to OPTIONS! file";
print  {$fh} Dumper(\%plversion);
close   $fh;

my @pack = ([qw(plplot.pd PLplot PDL::Graphics::PLplot)]);

my %hash = pdlpp_stdargs(@pack);
$hash{'PREREQ_PM'} = { PDL => 0 };
$hash{CONFIGURE_REQUIRES} = {
  'PDL::Core::Dev' => 0,
  'Devel::CheckLib' => 0,
};
# $hash{'OPTIMIZE'}  = '-g'; # If you want to debug, uncomment this.
$hash{TEST_REQUIRES} = {
  'Test::More' => '0.88', # done_testing
};
$hash{'VERSION_FROM'}   = 'plplot.pd';
$hash{'LIBS'}      = [$libs];
$hash{'INC'}      .= " $plplot_include_path";
$hash{clean}{FILES} .= ' *svg.* *.xfig temp* OPTIONS!';
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    bugtracker  => {web=>'https://github.com/PDLPorters/pdl-graphics-plplot/issues'},
    repository  => {
       url => 'git://github.com/PDLPorters/pdl-graphics-plplot.git',
       type => 'git',
       web => 'https://github.com/PDLPorters/pdl-graphics-plplot',
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
};

my $postamble = pdlpp_postamble(@pack);

WriteMakefile(%hash);

# Add genpp rule
sub MY::postamble { $postamble };

sub compileAndRun {
  my ($code) = @_;
  my $result;

  check_lib(
    ccflags  => "$plplot_include_path",
    ldflags  => "$libs",
    INC      => "$plplot_include_path",
    LIBS     => "$libs",
    header   => [ 'stdio.h', $header ],
    function => $code,
    analyze_binary => sub {
      my ($l, $bin) = @_;
      my $path_to_bin = File::Spec->catfile('.', $bin);
      $result = `$path_to_bin`;
    },
    not_execute => 1,
  );
  return $result;
}
