package kh_r_plot::network;

use base qw(kh_r_plot);

use strict;
use utf8;

# Experimental!
sub _save_html{
	my $self = shift;
	my $path = shift;

	# open dvice
	unless ( $::config_obj->web_if ){
		my $temp_img = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name}.'.tmp';
		$::config_obj->R->send("
			if ( exists(\"Cairo\") ){
				Cairo(width=640, height=640, unit=\"px\", file=\"$temp_img\", type=\"png\", bg=\"white\")
			} else {
				png(\"$temp_img\", width=640, height=480, unit=\"px\")
			}
		");
		$self->set_par;
		$::config_obj->R->send($self->{command_f});
		$::config_obj->R->send('dev.off()');
	}
	
	# run save command
	my $r_command = &r_command_html;
	$r_command .= "saveNetwork(d3net, \"$path\", selfcontained = T)";
	$::config_obj->R->send($r_command);
	
	return 1;
}

sub _save_net{
	my $self = shift;
	my $path = shift;

	my $temp_img = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name}.'.tmp';

	# open dvice
	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=640, height=640, unit=\"px\", file=\"$temp_img\", type=\"png\", bg=\"white\")
		} else {
			png(\"$temp_img\", width=640, height=480, unit=\"px\")
		}
	");
	$self->set_par;
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	
	# run save command
	my $r_command = &r_command_n3;
	$r_command .= "write.graph(n3, \"$path\", format=\"pajek\")";
	$::config_obj->R->send($r_command);
	
	return 1;
}

sub _save_graphml{
	my $self = shift;
	my $path = shift;

	my $temp_img = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name}.'.tmp';

	# open dvice
	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=640, height=640, unit=\"px\", file=\"$temp_img\", type=\"png\", bg=\"white\")
		} else {
			png(\"$temp_img\", width=640, height=480, unit=\"px\")
		}
	");
	$self->set_par;
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');

	# run save command
	my $r_command = &r_command_n4;
	$r_command .= "write.graph(n4, \"$path\", format=\"graphml\")";
	$::config_obj->R->send($r_command);

	# convert character coding to UTF-8
	if ($::config_obj->os eq 'win32') {
		# input code
		my %codes = (
			'jp' => 'cp932',
			'en' => 'cp1252',
			'cn' => 'cp936',
			'de' => 'cp1252',
			'es' => 'cp1252',
			'fr' => 'cp1252',
			'it' => 'cp1252',
			'nl' => 'cp1252',
			'pt' => 'cp1252',
			'kr' => 'cp949',
		);
		my $code = $::project_obj->morpho_analyzer_lang;
		$code = $codes{$code};
		
		# file names
		my $os_path = $::config_obj->os_path($path);
		my $temp_out = $::config_obj->cwd.'/config/R-bridge/temp.graphml';
		$temp_out = $::config_obj->os_path($temp_out);
		if (-e $temp_out){
			unlink $temp_out or die("Could not delete file: $temp_out");
		}
		
		open(my $fh_out, '>:encoding(UTF-8)', $temp_out) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $temp_out,
			)
		;
		open(my $fh_in, "<:encoding($code)", $os_path) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $os_path,
			)
		;
		while (<$fh_in>) {
			print $fh_out $_;
		}
		close $fh_in;
		close $fh_out;
		
		unlink ($os_path) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $os_path,
			)
		;
		rename($temp_out, $os_path) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $os_path,
			)
		;
	}

	return 1;
}

# for HTML
sub r_command_html{
	return '

library(networkD3)

com <- fastgreedy.community(n2, merges=TRUE, modularity=TRUE)
d3 <- igraph_to_networkD3(n2, as.vector( membership(com) ))

d3$nodes$name <- colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]
d3$nodes$size <- freq[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]

d3net <- forceNetwork(
	Links=d3$links,
	Nodes=d3$nodes,
	Source="source",
	Target="target",
	NodeID="name",
	Group="group",
	#Nodesize="size",
	zoom=T,
	opacityNoHover=10,
	opacity = 10,
	legend=F,
	fontSize=12,
	bounded=T,
	linkDistance = 50,
	charge = -130,
	#height=640,
	#width=640
	colourScale = JS("d3.scaleOrdinal(d3.schemeCategory10);")
)

';
}

# for Pajeck
sub r_command_n3{
	return '

n3 <- set.vertex.attribute(
    n2,
    "id",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ]
)

n3 <- set.vertex.attribute(
    n3,
    "xfact",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    sqrt( freq[ as.numeric( get.vertex.attribute(n2,"name") ) ] )
)

n3 <- set.vertex.attribute(
    n3,
    "yfact",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    sqrt( freq[ as.numeric( get.vertex.attribute(n2,"name") ) ] )
)


	';
}

# for GraphML
sub r_command_n4{
	return '

print(paste("use_alpha", use_alpha))

n4 <- set.vertex.attribute(
    n2,
    "frequency",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    freq[ as.numeric( get.vertex.attribute(n2,"name") ) ]
)

n4 <- set.vertex.attribute(
    n4,
    "size",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    sqrt( freq[ as.numeric( get.vertex.attribute(n2,"name") ) ] )
)

n4 <- set.vertex.attribute(
    n4,
    "x",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    lay_f[,1] * 100
)

n4 <- set.vertex.attribute(
    n4,
    "y",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    lay_f[,2] * 100
)

	';
}

1;