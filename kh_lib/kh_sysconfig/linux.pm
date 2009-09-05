package kh_sysconfig::linux;
use base qw(kh_sysconfig);
use strict;

#------------------#
#   ����ν����   #
#------------------#
sub reset_parm{
		my $self = shift;
		print "Resetting parameters...\n";
		mkdir "config";
		unless (-e $self->{ini_file}){
			open (CON,">$self->{ini_file}") or 
				gui_errormsg->open(
					type    => 'file',
					thefile => "m: $self->{ini_file}"
				);
			close (CON);
		}
		# �ʻ�����ե���������
		use DBI;
		use DBD::CSV;
		my $dbh = DBI->connect("DBI:CSV:f_dir=./config") or die;
		$dbh->do(
			"CREATE TABLE hinshi_chasen (
				hinshi_id INTEGER,
				kh_hinshi CHAR(225),
				condition1 CHAR(225),
				condition2 CHAR(225)
			)"
		) or die;
		my @table = (
				"7, '��̾', '̾��-��ͭ̾��-�ϰ�', '' ",
				"6, '��̾', '̾��-��ͭ̾��-��̾', '' ",
				"5,'�ȿ�̾','̾��-��ͭ̾��-�ȿ�', '' ",
				"'4','��ͭ̾��','̾��-��ͭ̾��', ''",
				"'2','����̾��','̾��-������³', ''",
				"'3','����ư��','̾��-����ư��촴', ''",
				"'8','�ʥ�����','̾��-�ʥ����ƻ�촴', ''",
				"'16','̾��B','̾��-����','�Ҥ餬��'",
				#"'16','̾��B','̾��-�����ǽ','�Ҥ餬��'",
				"'20','̾��C','̾��-����','��ʸ��'",
				#"'20','̾��C','̾��-�����ǽ','��ʸ��'",
				"'21','�����ư��','��ư��','����'",
				"'1','̾��','̾��-����', ''",
				"'9','�����ǽ','̾��-�����ǽ', ''",
				"'10','̤�θ�','̤�θ�', ''",
				"'12','��ư��','��ư��', ''",
				"'12','��ư��','�ե��顼', ''",
				"'99999','HTML����','����', 'HTML'",
				"'11','����','����', ''",
				"'17','ư��B','ư��-��Ω','�Ҥ餬��'",
				"'13','ư��','ư��-��Ω', ''",
				"'22','���ƻ����Ω��','���ƻ�-��Ω',''",
				"'18','���ƻ�B','���ƻ�','�Ҥ餬��'",
				"'14','���ƻ�','���ƻ�', ''",
				"'19','����B','����','�Ҥ餬��'",
				"'15','����','����', ''"
		);
		foreach my $i (@table){
			$dbh->do("
				INSERT INTO hinshi_chasen
					(hinshi_id, kh_hinshi, condition1, condition2 )
				VALUES
					( $i )
			") or die($i);
		}

		$dbh->disconnect;
}


#----------------------------#
#   ������ɤ߹��ߥ롼����   #
#----------------------------#

sub _readin{
	use Jcode;
	use kh_sysconfig::linux::chasen;
	use kh_sysconfig::linux::juman;

	my $self = shift;


	# Chasen������
	if (-e $self->chasenrc_path){
		my $flag = 0; my $msg = '(Ϣ���ʻ�';
		if (-e $self->chasenrc_path){
			open (CRC,"$self->{chasenrc_path}") or
				gui_errormsg->open(
					type    => 'file',
					thefile => "$self->{chasenrc_path}"
				);
			while (<CRC>){
				chomp;
				if ($_ eq '; by KH Coder, start.'){
					$flag = 1;
					next;
				}
				elsif ($_ eq '; by KH Coder, end.'){
					$flag = 0;
					next;
				}

				unless ($flag){
					next;
				}
				if ($_ eq "$msg"){
					$self->{use_hukugo} = 1;
				}
			}
			close (CRC);
		}
		unless ($self->{use_hukugo}){
			$self->{use_hukugo} = 0;
		}
	}

	return $self;
}

#------------------#
#   �����ͤ���¸   #
#------------------#

sub save{
	my $self = shift;

	$self = $self->refine_cj;
	if ($self->path_check){
		$self->config_morph;
	}

	$self->save_ini;
	
	return 1;
}

sub save_ini{
	my $self = shift;
	$self = $self->refine_cj;

	my @outlist = (
		'chasenrc_path',
		'grammarcha_path',
		#'juman_path',
		'c_or_j',
		'r_path',
		'r_plot_debug',
		'sqllog',
		'sql_username',
		'sql_password',
		'sql_host',
		'sql_port',
		'mail_if',
		'mail_smtp',
		'mail_from',
		'mail_to',
		'use_heap',
		'font_main',
		'kaigyo_kigou',
		'color_DocView_info',
		'color_DocView_search',
		'color_DocView_force',
		'color_DocView_html',
		'color_DocView_CodeW',
		'DocView_WrapLength_on_Win9x',
		'DocSrch_CutLength',
		'app_html',
		'app_csv',
		'app_pdf',
	);

	my $f = $self->{ini_file};
	open (INI,">$f") or
		gui_errormsg->open(
			type    => 'file',
			thefile => ">$f"
		);
	foreach my $i (@outlist){
		print INI "$i\t".$self->$i(undef,'1')."\n";
	}
	foreach my $i (keys %{$self}){
		if ( index($i,'w_') == 0 ){
			print INI "$i\t".$self->win_gmtry($i)."\n";
		}
	}
	if ($self->{main_window}){
		print INI "main_window\t$self->{main_window}";
	}
	close (INI);
	return 1;

}

#--------------------------------#
#   �ʲ��������ͤ��֤��롼����   #
#--------------------------------#

#--------------------#
#   �����ǲ��ϴط�   #

sub chasenrc_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{chasenrc_path} = $new;
	}
	return $self->{chasenrc_path};
}

sub grammarcha_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{grammarcha_path} = $new;
	}
	return $self->{grammarcha_path};
}

#sub juman_path{
#	my $self = shift;
#	my $new = shift;
#	if ($new){
#		$self->{juman_path} = $new;
#	}
#	return $self->{juman_path};
#}


#--------------------------#
#   �������ץꥱ�������   #

sub app_html{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_html} = $new;
	}
	if ($self->{app_html}){
		return $self->{app_html};
	} else {
		return 'firefox \'%s\' &';
	}
}

sub app_pdf{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_pdf} = $new;
	}
	if ($self->{app_pdf}){
		return $self->{app_pdf};
	} else {
		return 'acroread %s &';
	}
}

sub app_csv{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_csv} = $new;
	}
	if ($self->{app_csv}){
		return $self->{app_csv};
	} else {
		return 'soffice -calc %s &';
	}
}

#-------------#
#   GUI�ط�   #

sub underline_conv{
	my $self = shift;
	my $n    = shift;
	$n = ( ($n - 1) / 2 ) + 1;
	return $n;
}

sub mw_entry_length{
	return 30;
}

sub font_main{
	my $self = shift;
	my $new  = shift;
	$self->{font_main} = $new         if length($new);
	$self->{font_main} = 'kochi gothic,10'  unless length($self->{font_main});
	return $self->{font_main};
}


#------------#
#   ����¾   #

sub os_path{
	my $self  = shift;
	my $c     = shift;
	my $icode = shift;

	if ($^O eq 'darwin'){ # Mac OS X
		
		$c = Jcode->new("$c",$icode)->euc;
		my $ascii = '[\x00-\x7F]';
		my $twoBytes = '[\x8E\xA1-\xFE][\xA1-\xFE]';
		my $threeBytes = '\x8F[\xA1-\xFE][\xA1-\xFE]';
		my $character_undef =
			'(?:[\xA9-\xAF\xF5-\xFE][\xA1-\xFE]|' # 9-15,85-94��
			  . '\x8E[\xE0-\xFE]|' # Ⱦ�ѥ�������
			  . '\xA2[\xAF-\xB9\xC2-\xC9\xD1-\xDB\xEB-\xF1\xFA-\xFD]|' # 2��
			  . '\xA3[\XA1-\xAF\xBA-\xC0\xDB-\xE0\xFB-\xFE]|' # 3��
			  . '\xA4[\xF4-\xFE]|' # 4��
			  . '\xA5[\xF7-\xFE]|' # 5��
			  . '\xA6[\xB9-\xC0\xD9-\xFE]|' # 6��
			 . '\xA7[\xC2-\xD0\xF2-\xFE]|' # 7��
			  . '\xA8[\xC1-\xFE]|' # 8��
			  . '\xCF[\xD4-\xFE]|' # 47��
			  . '\xF4[\xA7-\xFE]|' # 84��
			  . '\x8F[\xA1-\xFE][\xA1-\xFE])'; # 3�Х���ʸ��

		foreach my $i ($c =~ /$ascii|$twoBytes|$threeBytes/og){
			if ($i =~ /$character_undef/){
				gui_errormsg->open(
					type   => 'msg',
					msg    => "̤�б�ʸ�����ե�����̾�ޤ��ϥե����̾�˴ޤޤ�Ƥ��ޤ���\n���ߤΤȤ�����EUC���Ѵ��Ǥ��ʤ�ʸ���ˤ�̤�б��Ǥ���"
				);
				return undef;
			}
		}

		$c = Jcode->new("$c",'euc')->utf8;
	} else {
		$c = Jcode->new("$c",$icode)->euc;
		$c =~ tr/\\/\//;
	}

	return $c;
}

*os_cod_path = \&os_path;

sub R_device{
	my $self = shift;
	my $path = shift;
	my $width = shift;
	my $height = shift;

	$path .= '.png';
	unlink($path) if -e $path;

	$width  = 480 unless $width;
	$height = 480 unless $height;

	return 0 unless $::config_obj->R;

	$::config_obj->R->send(
		"png(\"$path\", width=$width, height=$height, unit=\"px\" )"
	);
	return $path;
}

1;

__END__