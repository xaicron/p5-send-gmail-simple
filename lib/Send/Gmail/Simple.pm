package Send::Gmail::Simple;

use strict;
use warnings;
use utf8;
use 5.008001;
use Carp qw/croak/;
use Net::SMTP::SSL;
use MIME::Entity;
use Email::Date::Format;
use File::Basename qw/basename/;

our $VERSION = '0.04';

sub new {
	my $class = shift;
	croak "Usage: $class->new(\$username, \$password)" if @_ < 2;
	bless { username => $_[0], password => $_[1] }, $class;
}

sub send {
	my $self = shift;
	my $die_msg = "Usage: $self->send({ From => \$from, TO => \$to, Subject => \$subject, Body => \$body })";
	my $args = shift;
	
	croak $die_msg unless $args->{From};
	croak $die_msg unless $args->{TO};
	croak $die_msg unless $args->{Subject};
	croak $die_msg unless $args->{Body};
	
	$args->{Data} = $args->{Body};
	delete $args->{Body};
	
	my $mime = MIME::Entity->build(
		Date     => Email::Date::Format::email_date,
		Type     => 'text/plain; charset="utf-8"',
		Encoding => 'binary',
		%$args,
	);
	
	if ($args->{RowHeader} and ref $args->{RowHeader} eq 'HASH') {
		my $header = $args->{RowHeader};
		for my $key (keys %{$header}) {
			$mime->head->replace($key, $header->{$key});
		}
	}
	
	if ($args->{Parts}) {
		for my $hash (&_deref($args->{Parts})) {
			croak "Usage: $self->send({ Parts => [ {Path => \$file_path, Name => \$file_name}, { ... } ] })" unless $hash->{Path};
			croak "$hash->{Path} $!" unless -f $hash->{Path};
			$mime->attach(
				Path        => $hash->{Path},
				Filename    => $hash->{Name}        || basename($hash->{Path}),
				Type        => $hash->{Type}        || 'application/octet-stream',
				Encoding    => $hash->{Encoding}    || 'base64',
				Description => $hash->{Description} || undef,
			);
		}
	}
	
	my $smtp = Net::SMTP::SSL->new(
		'smtp.gmail.com',
		Port    => 465,
		Debug   => $args->{Debug}   || 0,
		Timeout => $args->{Timeout} || 15,
	) or die "Net::SMTP::SSL->new failed!!";
	
	($self->error('Authentication failure') && return ) unless $smtp->auth($self->{username}, $self->{password});
	
	$smtp->mail($args->{FROM})        || ( $self->error('[FROM] failure')    && return );
	$smtp->to(&_deref($args->{TO}))   || ( $self->error('[TO] failure')      && return );
	$smtp->cc(&_deref($args->{CC}))   || ( $self->error('[CC] failure')      && return ) if $args->{CC};
	$smtp->bcc(&_deref($args->{BCC})) || ( $self->error('[BCC] failure')     && return ) if $args->{BCC};
	$smtp->data                       || ( $self->error('[Newline] failure') && return );
	$smtp->datasend($mime->stringify) || ( $self->error('[Data] failure')    && return );
	$smtp->dataend                    || ( $self->error('[DataEnd] failure') && return );
	$smtp->quit                       || ( $self->error('[Quit] failure')    && return );
	
	return 1;
}

sub error {
	my $self = shift;
	my $msg = shift || return $self->{_error};
	$self->{_error} = $msg;
}

sub _deref {
	return ref $_[0] eq 'ARRAY' ? @{$_[0]} : $_[0] if @_ == 1;
	return @_;
}

1;
__END__

=head1 NAME

Send::Gmail::Simple - Very simple Gmail sending interface.

=head1 SYNOPSIS

  use Send::Gmail::Simple;
  
  my $gmail = Send::Gmail::Simple->new($username, $password);
  
  $gmail->send({
      From     => $from,
      TO       => $to,
      CC       => [$cc, $cc2],
      BCC      => [$bcc, $bcc2],
      Subject  => 'hello gmail',
      Body     => 'send message from perl script',
      Parts    => [
          { Path => '/home/hoge/erogazo/HENTAI.jpg', Name => 'Abnormal.jpg'  },
          { Path => '/home/fuga/HENTAI.jpg' }, # Name is basename of Path (HENTAI.jpg)
      ],
  }) or die $gmail->error;

=head1 DESCRIPTION

Send::Gmail::Simple is Very simple Gmail sending interface.

You can also send attachments in multipart.
Of course, TO CC and BCC can also specify more than one.

=head1 METHODES

=over 4

=item B<new($username, $password)>

Constructor.
Mosut be username and password.

=item B<send({ From => $from, TO => $to, Subject => $subject, Body => $body })

Send gmail.

  #  TO CC and BCC can also specify more than one
  TO  => $to
  TO  => [$to1, $to2]
  CC  => $cc
  CC  => [$cc1, $cc2]
  BCC => $bcc
  BCC => [$bcc1, $bcc2]
  
  # message
  Body => 'Hello, world!'
  
  # attachments in multipart
  Parts => { Path => $att_file }
  Parts => { Path => $att_file, Name => 'error.log' }
  Parts => [
      { Path => $att_file1 },
      { Path => $att_file2, Name => 'error.log' },
  ]
  Parts => {
      Path     => $att_file,    # required
      Name     => 'sexy.jpg',   # default File::Basename::basename $att_file
      Type     => 'image/jpeg', # default 'application/octet-stream'
      Encoding => 'base64',     # default 'base64'
  }
  
For other arguments see the L<MIME::Entity>.

=item B<error()>

return error message.

  warn $gmail->error;

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron {at} gmail.comE<gt>

=head1 SEE ALSO

L<MIME::Entity>, L<Net::SMTP>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
