# -*- coding: utf-8 -*-
use strict;
use FindBin;
use autodie;

use lib "$FindBin::Bin/lib";

use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite qw/Entity *CON/;
use YATT::Lite::PSGIEnv;

{
  my $yatt = MY->new(doc_root => "$FindBin::Bin/public");

  Entity session => sub {
    my ($this, $name, $default) = @_;
    my Env $env = $CON->env;
    $env->{'psgix.session'}{$name} // $default;
  };

  Entity set_session => sub {
    my ($this, $name, $value) = @_;
    my Env $env = $CON->env;
    $env->{'psgix.session'}{$name} = $value;
    '';
  };

  return $yatt if MY->want_object;

  my $var_dir = "$FindBin::Bin/var";
  -d $var_dir or mkdir($var_dir);

  my $sess_dir = "$var_dir/tmp";
  -d $sess_dir or mkdir($sess_dir);
  -w $sess_dir or die "Session directory is not wriable! $sess_dir";

  use Plack::Builder;
  use Plack::Session::Store::File;
  return builder {
    enable('Session::Simple',
	   , store => Compat::GetSet2FetchStore->new
	   (Plack::Session::Store::File->new(dir => $sess_dir))
	   , keep_empty => 0);

    $yatt->to_app;
  };
}

package Compat::GetSet2FetchStore {
  sub MY () {__PACKAGE__}
  use fields qw/store/;
  sub new {
    my MY $self = bless {}, shift; # or fields::new(shift)
    $self->{store} = shift;
    $self;
  }
  sub globref {
    my ($thing, @name) = @_;
    my $class = ref $thing || $thing;
    no strict 'refs';
    \*{join("::", $class, @name)};
  }
  BEGIN {
    foreach my $spec ([get => 'fetch']
		      , [set => 'store']
		      , [remove => 'remove']) {
      my ($from, $to) = @$spec;
      *{globref(MY, $from)} = sub {
	my MY $self = shift;
	$self->{store}->$to(@_);
      };
    }
  }
};
