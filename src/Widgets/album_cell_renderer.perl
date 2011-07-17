package CellRendererSongsAA;
use Glib::Object::Subclass 'Gtk2::CellRenderer',
properties => [ Glib::ParamSpec->scalar
			('ref',		 #name
			 'ref',		 #nickname
			 'array : [r1,r2,row,gid]', #blurb
			 [qw/readable writable/] #flags
			),
		Glib::ParamSpec->string('aa','aa','use album or artist column', 'album',[qw/readable writable/]),
		Glib::ParamSpec->string('markup','markup','show info', '',		[qw/readable writable/]),
		];

use constant PAD => 2;

sub GET_SIZE { (0,0,-1,-1) }


sub RENDER
{	my ($cell, $window, $widget, $background_area, $cell_area, $expose_area, $flags) = @_;
	my ($r1,$r2,$row,$gid)=@{ $cell->get('ref') };	#come from CellRendererSongsAA::get_value : first_row, last_row, this_row, gid
	my $field= $cell->get('aa');
	my $format=$cell->get('markup');
	my @format= $format ? (split /\n/,$format) : ();
	$format=$format[$row-$r1];
	if ($format)
	{	my ($x, $y, $width, $height)= $cell_area->values;
		my $gc= $widget->get_style->base_gc('normal');
		$window->draw_rectangle($gc, 1, $background_area->values);# if $r1 != $r2;
		my $layout=Gtk2::Pango::Layout->new( $widget->create_pango_context );
		my $markup=AA::ReplaceFields( $gid,$format,$field,::TRUE );
		$layout->set_markup($markup);
		$gc= $widget->get_style->text_gc('normal');
		$gc->set_clip_rectangle($cell_area);
		$window->draw_layout($gc, $x, $y, $layout);
		$gc->set_clip_rectangle(undef);
#		$widget->get_style->paint_layout($window, $widget->state, 0, $cell_area, $widget, undef, $x, $y, $layout);
		return;
	}

	my $gc= $widget->get_style->base_gc('normal');
	$window->draw_rectangle($gc, 1, $background_area->values);
	my($x, $y, $width, $height)= $background_area->values; #warn "$row $x, $y, $width, $height\n";
	$y-=$height*($row-$r1 - @format);
	$height*=1+$r2-$r1 - @format;
#	my $ypad=$cell->get('ypad') + $background_area->height - $cell_area->height;
#	$y+=$ypad;
	$x+=$cell->get('xpad');
#	$height-=$ypad*2;
	$width-=$cell->get('xpad')*2;
	my $s= $height > $width ? $width : $height;
	$s=200 if $s>200;

	if ( my $pixbuf= AAPicture::pixbuf($field,$gid,$s) )
	{	my $gc=Gtk2::Gdk::GC->new($window);
		$gc->set_clip_rectangle($background_area);
		$window->draw_pixbuf( $gc, $pixbuf,0,0,	$x,$y, -1,-1,'none',0,0);
	}
	elsif (defined $pixbuf)
	{	my ($tx,$ty)=$widget->widget_to_tree_coords($x,$y);#warn "$tx,$ty <= ($x,$y)\n";
		$cell->{queue}{$r1}=[$tx,$ty,$gid,$s,$field];
		$cell->{idle}||=Glib::Idle->add(\&idle,$cell);
		$cell->{widget}||=$widget;
		$cell->{window}||=$window;
	}
}

sub reset #not used FIXME should be reset when songlist change
{	my $cell=$_[0];
	delete $cell->{queue};
	Glib::Source->remove( $cell->{idle} ) if $cell->{idle};
	delete $cell->{idle};
}

sub idle
{	my $cell=$_[0];
	{	last unless $cell->{queue} && $cell->{widget}->mapped;
		my ($r1,$ref)=each %{ $cell->{queue} };
		last unless $ref;
		delete $cell->{queue}{$r1};
		_drawpix($cell->{widget},$cell->{window},@$ref);
		last unless scalar keys %{ $cell->{queue} };
		return 1;
	}
	delete $cell->{queue};
	delete $cell->{widget};
	delete $cell->{window};
	return $cell->{idle}=undef;
}

sub _drawpix
{	my ($widget,$window,$ctx,$cty,$gid,$s,$col)=@_; #warn "$ctx,$cty,$gid,$s\n";
	my ($vx,$vy,$vw,$vh)=$widget->get_visible_rect->values;
	#warn "   $gid\n";
	return if $vx > $ctx+$s || $vy > $cty+$s || $vx+$vw < $ctx || $vy+$vh < $cty; #no longer visible
	#warn "DO $gid\n";
	my ($x,$y)=$widget->tree_to_widget_coords($ctx,$cty);#warn "$ctx,$cty => ($x,$y)\n";
	my $pixbuf= AAPicture::pixbuf($col,$gid, $s,1);
	return unless $pixbuf;
	$window->draw_pixbuf( Gtk2::Gdk::GC->new($window), $pixbuf,0,0, $x,$y,-1,-1,'none',0,0);
}

sub get_value
{	my ($field,$array,$row)=@_;
	my $r1=my $r2=$row;
	my $gid=Songs::Get_gid($array->[$row],$field);
	$r1-- while $r1>0	 && Songs::Get_gid($array->[$r1-1],$field) == $gid; #find first row with this gid
	$r2++ while $r2<$#$array && Songs::Get_gid($array->[$r2+1],$field) == $gid; #find last row with this gid
	return [$r1,$r2,$row,$gid];
}
