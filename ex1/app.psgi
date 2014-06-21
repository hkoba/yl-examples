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

  use Plack::Builder;
  use Plack::Session::Store::File;
  return builder {
    enable 'Session',
      store => Plack::Session::Store::File->new(dir => $sess_dir);
    $yatt->to_app;
  };
}
