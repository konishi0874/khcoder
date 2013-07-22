package gui_window::r_plot;
use base qw(gui_window);

use gui_window::r_plot::word_cls;
use gui_window::r_plot::word_som;
use gui_window::r_plot::word_corresp;
use gui_window::r_plot::word_mds;
use gui_window::r_plot::word_netgraph;
use gui_window::r_plot::cod_cls;
use gui_window::r_plot::cod_corresp;
use gui_window::r_plot::cod_mds;
use gui_window::r_plot::cod_netg;
use gui_window::r_plot::cod_som;
use gui_window::r_plot::cod_mat;
use gui_window::r_plot::selected_netgraph;
use gui_window::r_plot::doc_cls;

use strict;
use gui_hlist;
use mysql_words;

use Tk;
use Tk::Pane;
use Tk::PNG;

my $imgs;

sub _new{

	my $self = shift;
	my %args = @_;

	$self->{original_plot_size} = $args{plot_size} if $args{plot_size};
	foreach my $key (keys %args){
		next if $key eq 'plot_size';
		$self->{$key} = $args{$key};
	}
	undef %args;

	my $mw = $::main_gui->mw;
	my $win= $self->{win_obj};
	$win->title($self->gui_jt( $self->win_title ));

	# 画像をロード
	$self->{ax} = 0 unless defined( $self->{ax} );
	if ( $imgs->{$self->win_name} ){
		#print "img: read: ".$self->win_name."\n";
		$imgs->{$self->win_name}->read($self->{plots}[$self->{ax}]->path);
	} else {
		#print "img: new\n";
		$imgs->{$self->win_name} = 
			$win->Photo('photo_'.$self->win_name,
				-file => $self->{plots}[$self->{ax}]->path,
			);
	}
	
	# 画像サイズをチェック
	$self->{img_height} = $imgs->{$self->win_name}->height;
	$self->{img_width}  = $imgs->{$self->win_name}->width;
	my $size = $imgs->{$self->win_name}->height;
	$size += 10;
	$size = 490 if $size < 490;
	my $cursor = undef;
	if ($size > 650){
		$size = 650;
		$cursor = 'fleur';
	}
	if ($win->screenheight - 180 < $size){
		$size = $win->screenheight - 180;
		$cursor = 'fleur';
	}
	$self->{photo_pane_height} = $size;

	# 画像表示用ペイン
	my $fp = $win->Frame(
		-borderwidth => 2,
		-relief      => 'sunken',
	)->pack(
		-anchor => 'c',
		-fill   => 'both',
		-expand => 1,
	);
	
	$self->{photo_pane} = $fp->Scrolled(
		'Pane',
		-scrollbars  => 'osoe',
		-width       => $self->photo_pane_width,
		-height      => $self->photo_pane_height,
		-background  => 'white',
		-borderwidth => 0,
	)->pack(
		-anchor => 'c',
		-fill   => 'both',
		-expand => 1,
	);
	
	$self->{photo} = $self->{photo_pane}->Label(
		-image       => $imgs->{$self->win_name},
		-cursor      => $cursor,
		-borderwidth => 0,
	)->pack(
		-expand => 1,
		-fill   => 'both',
	);

	# 画像のドラッグ
	( $self->{xscroll}, $self->{yscroll} ) =
		$self->{photo_pane}->Subwidget( 'xscrollbar', 'yscrollbar' );
	$self->{photo}->bind(
		'<Button1-ButtonRelease>' => sub {
			undef $self->{last_x};
		}
	);
	$self->{photo}->bind(
		'<Button1-Motion>' => [
			\&drag, $self, Ev('X'), Ev('Y')
		]
	);

	# カーソルキーによるスクロール
	$self->win_obj->bind( '<Up>'    =>
		sub {
			$self->{photo_pane}->yview(scroll => -0.1, 'pages');
		}
	);
	$self->win_obj->bind( '<Down>'  =>
		sub {
			$self->{photo_pane}->yview(scroll =>  0.1, 'pages');
		}
	);
	$self->win_obj->bind( '<Left>'  =>
		sub {
			$self->{photo_pane}->xview(scroll => -0.1, 'pages');
		}
	);
	$self->win_obj->bind( '<Right>' =>
		sub {
			$self->{photo_pane}->xview(scroll =>  0.1, 'pages');
		}
	);

	my $f1 = $win->Frame()->pack(
		-expand => 0,
		-fill   => 'x',
		-pady   => 2,
		-padx   => 2,
		-anchor => 's',
	);

	my $chk_n = @{$self->option1_options};
	if ($chk_n > 1){
		$f1->Label(
			-text => $self->gui_jchar($self->option1_name),
			-font => "TKFN",
		)->pack(-side => 'left');

		my @opt = ();
		my $n = 0;
		foreach my $i (@{$self->option1_options}){
			push @opt, [$self->gui_jchar($i,'euc'),$n];
			++$n;
		}

		$self->{optmenu} = gui_widget::optmenu->open(
			parent  => $f1,
			pack    => {-side => 'left', -padx => 2},
			options => \@opt,
			variable => \$self->{ax},
			command  => sub {$self->renew;},
		);
		$self->{optmenu}->set_value(0);
	}

	my $base_name = 'gui_window::r_plot_opt::'.$self->base_name;

	$self->{button_config} = $f1->Button(
		-text => kh_msg->get('options'), # 調整
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			$base_name->open(
				command_f => $self->{plots}[$self->{ax}]->command_f,
				size      => $self->original_plot_size,
			);
		}
	)->pack(-side => 'left', -padx => 2);

	if (length($self->{msg})){
		my $info_label = $f1->Label(
			-text => $self->gui_jchar($self->{msg},'euc')
		)->pack(-side => 'left');

		if ( length($self->{msg_long}) ){
			$self->{blhelp} = $mw->Balloon();
			$self->{blhelp}->attach( $info_label,
				-balloonmsg => $self->gui_jchar($self->{msg_long},'euc'),
				-font       => "TKFN"
			);
		}
	}

	$f1->Button(
		-text => kh_msg->gget('close'), # 閉じる
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub {
			$self->close();
		}
	)->pack(-side => 'right');

	$f1->Button(
		-text => kh_msg->gget('save'), # 保存
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub {
			$self->save();
		}
	)->pack(-side => 'right',-padx => 4);

	$self->{bottom_frame} = $f1;
	return $self;
}

sub drag {
	my( $w, $self, $x, $y ) = @_;
	if ( defined $self->{last_x} )
	{
		my( $dx, $dy ) = ( $x - $self->{last_x}, $y - $self->{last_y} );
		my( $xf1, $xf2 ) = $self->{xscroll}->get;
		my( $yf1, $yf2 ) = $self->{yscroll}->get;
		my( $iw, $ih ) = ( $self->{img_width}, $self->{img_height} );
		if ( $dx < 0 )
		{
			$self->{photo_pane}->xview( moveto => $xf1-($dx/$iw) );
		}
		else
		{
			$self->{photo_pane}->xview( moveto => $xf1-($xf2*$dx/$iw) );
		}
		if ( $dy < 0 )
		{
			$self->{photo_pane}->yview( moveto => $yf1-($dy/$ih) );
		}
		else
		{
			$self->{photo_pane}->yview( moveto => $yf1-($yf2*$dy/$ih) );
		}
	}
	( $self->{last_x}, $self->{last_y} ) = ( $x, $y );
	return $self;
}

sub renew{
	my $self = shift;
	return 0 unless $self->{optmenu};

	$imgs->{$self->win_name}->read($self->{plots}[$self->{ax}]->path);
	$imgs->{$self->win_name}->update;
	
	$self->renew_command;
}


sub renew_command{}

# メモリ・リークの防止用
sub end{
	my $self = shift;

	# バルーンヘルプ
	if ( $self->{blhelp} ){
		 $self->{blhelp}->destroy;
	}

	# Rのプロット・オブジェクト
	$self->{plots} = undef;

	# Imageオブジェクトのクリア
	#print "clearing: ".$self->win_name."\n";
	$imgs->{$self->win_name}->delete;
	$imgs->{$self->win_name}->destroy;
	$imgs->{$self->win_name} = undef;

	#my @n = $self->{win_obj}->imageNames;
	#print "images: ", $#n + 1, "\n";

}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "PDF",[qw/.pdf/] ],
		[ "SVG",[qw/.svg/] ],
		[ "PNG",[qw/.png/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.eps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('saving')), # プロットを保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{plots}[$self->{ax}]->save($path) if $path;

	return 1;
}

sub photo_pane_height{
	my $self = shift;
	return $self->{photo_pane_height};
}

sub photo_pane_width{
	my $self = shift;
	return $self->{photo_pane_height};
}

sub original_plot_size{
	my $self = shift;
	
	if ($self->{original_plot_size}){
		return $self->{original_plot_size};
	} else {
		return $self->{photo}->cget(-image)->height;
	}
}

1;
