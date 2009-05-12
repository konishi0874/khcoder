package gui_window::word_tf_df;
use base qw(gui_window);

use strict;
use gui_hlist;
use mysql_words;

sub _new{
	if ($::config_obj->os eq 'linux') {
		require Tk::PNG;
	}

	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win= $self->{win_obj};
	$win->title($self->gui_jt('�и������ʸ���'));

	$self->{photo} = $win->Label(
		-image => $win->Photo(-file => $self->{images}[1]),
		-borderwidth => 2,
		-relief => 'sunken',
	)->pack(-anchor => 'c');

	my $f1 = $win->Frame()->pack(
		-expand => 'y',
		-fill   => 'x',
		-pady   => 2,
		-padx   => 2,
		-anchor => 's',
	);

	$f1->Label(
		-text => $self->gui_jchar('����ñ�̡�'),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');
	my %pack = (-side => 'left');
	$self->{tani_obj} = gui_widget::tani->open(
		parent  => $f1,
		pack    => \%pack,
		command => sub {$self->count;},
	);

	$f1->Label(
		-text => $self->gui_jchar('  �п����λ��ѡ�'),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');
	
	$self->{optmenu} = gui_widget::optmenu->open(
		parent  => $f1,
		pack    => {-anchor=>'e', -side => 'left', -padx => 0},
		options =>
			[
				[$self->gui_jchar('�и����(X)')  => 1],
				[$self->gui_jchar('�и����(X)��ʸ���(Y)') => 2],
				[$self->gui_jchar('�ʤ�') => 0],
			],
		variable => \$self->{ax},
		command  => sub {$self->renew;},
	);

	$f1->Button(
		-text => $self->gui_jchar('��¸'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->save();
				}
			);
		}
	)->pack(-side => 'right');


	#$win->Button(
	#	-text => $self->gui_jchar('�Ĥ���'),
	#	-font => "TKFN",
	#	-width => 8,
	#	-borderwidth => '1',
	#	-command => sub{ $mw->after
	#		(
	#			10,
	#			sub {
	#				$self->close();
	#			}
	#		);
	#	}
	#)->pack(-side => 'right',-padx => 2, -pady => 2);
	$self->count;
	return $self;
}

#----------------#
#   ����պ���   #

sub count{
	my $self = shift;
	return 0 unless $self->{tani_obj};
	
	my $tani = $self->{tani_obj}->tani;
	my $h = mysql_exec->select("
		select num, f, genkei.name
		from genkei, hselection, df_$tani
		where
			genkei.khhinshi_id = hselection.khhinshi_id
			and genkei.id = df_$tani.genkei_id
			and genkei.nouse = 0
			and hselection.ifuse = 1
	",1)->hundle;
	
	my $rcmd = 'hoge <- matrix( c(';
	my $n = 0;
	while (my $i = $h->fetch){
		$rcmd .= "$i->[0],$i->[1],\"$i->[2]\",";
		++$n;
	}
	chop $rcmd;
	$rcmd .= "), nrow=$n, ncol=3, byrow=TRUE)";

	use kh_r_plot;
	my $plot1 = kh_r_plot->new(
		name      => 'words_TF_DF1',
		command_f => 
			"$rcmd\n"
			.'plot(hoge[,1],hoge[,2],ylab="ʸ���", xlab="�и����")',
	) or return 0;

	my $plot2 = kh_r_plot->new(
		name      => 'words_TF_DF2',
		command_f => 
			"$rcmd\n"
			.'plot(hoge[,1],hoge[,2],ylab="ʸ���",xlab="�и����",log="x")',
	) or return 0;

	my $plot3 = kh_r_plot->new(
		name      => 'words_TF_DF3',
		command_f => 
			"$rcmd\n"
			.'plot(hoge[,1],hoge[,2],ylab="ʸ���",xlab="�и����",log="xy")',
	) or return 0;

	$self->{images} = [$plot1,$plot2,$plot3];
	$self->renew;
}

sub renew{
	my $self = shift;
	return 0 unless $self->{optmenu};
	
	$self->{photo}->configure(
		-image => $self->{win_obj}->Photo(-file => $self->{images}[$self->{ax}]->path)
	);
	$self->{photo}->update;
}

sub save{
	my $self = shift;

	# ��¸��λ���
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		#[ "Adobe PDF",[qw/.pdf/] ],
		[ "PNG",[qw/.png/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.eps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('�ץ��åȤ���¸'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{images}[$self->{ax}]->save($path) if $path;

	return 1;
}

#--------------#
#   ��������   #


sub win_name{
	return 'w_word_tf_df';
}

1;