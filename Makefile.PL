use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Term::Graille',
  VERSION_FROM     => 'lib/Term/Graille.pm',
  ABSTRACT_FROM    => 'lib/Term/Graille.pm',
  AUTHOR           => 'Saif Ahmed',
  LICENSE          => 'Artistic',
  MIN_PERL_VERSION => 'v5.10.0',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Algorithm::Line::Bresenham' =>'0.151',
    'Time::HiRes' => 0,
    'Storable'    =>0,
    'Term::ReadKey'=>0,
    'Data::Dumper' =>0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/saiftynet/Term-Graille.git',
              web  => 'https://github.com/saiftynet/Term-Graille',
          },
      }})
   : ()
  ),
);
