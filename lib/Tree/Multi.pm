#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I.
#-------------------------------------------------------------------------------
# Multi-way tree in Pure Perl.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Multi;
our $VERSION = "20210528";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

my $keysPerNode = 4;                                                            # Keys per node

#D1 Multi-way Tree                                                              # Create and use a multi-way tree.

sub new()                                                                       #P Create a new multi-way tree node
 {my () = @_;                                                                   # Key, $data, parent node, index of link from parent node
  genHash(__PACKAGE__,                                                          # Multi tree node
    up    => undef,                                                             # Parent node
    keys  => [],                                                                # Array of key items for this node
    data  => [],                                                                # Data corresponding to each key
    node  => [],                                                                # Child nodes
   );
 }

sub root($)                                                                     # Return the root node of a tree
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(; $tree->up; $tree = $tree->up) {}
  $tree
 }

sub find($$)                                                                    # Find a key in a tree returning (last comparison, the last node searched, the index of the last key compared)
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;
  my @k = $tree->keys->@*;

  if ($key < $k[0])                                                            # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return (-1, $tree, 0);
   }

  if ($key > $k[-1])                                                           # Greater than largest key in node
   {if (my $node = $tree->node->[-1])
     {return __SUB__->($node, $key);
     }
    return (+1, $tree, -1);
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $k[$i] cmp $key;                                                    # Compare key
    return (0, $tree, $i) if $s == 0;                                           # Found key
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])
       {return __SUB__->($node, $key);
       }
      return (-1, $tree, $i);
     }
   }
  confess 'Not possible';
 } # find

sub insertIntoNode($$$$$)                                                       #P Insert a (key, data) pair into a node that is known not be full at the specified point
 {my ($parent, $child, $at, $key, $data) = @_;                                  # Parent, child, insertion point, key, data
  @_ == 5 or confess;
  splice $parent->keys->@*, $at,   0, $key;
  splice $parent->data->@*, $at,   0, $data;
  splice $parent->node->@*, $at+1, 0, $child;
  $child->up = $parent;
 }

sub findSplit($$)                                                               #P Locate the index at which the parent splits to the child
 {my ($parent, $child) = @_;                                                    # Parent node, child node
  @_ == 2 or confess;

  my (@k) = $parent->keys->@*;                                                  # Parent keys
  my ($k) =  $child->keys->@*;                                                  # First child key
  return 0 if $k < $k[0];
  for my $i(keys @k)
   {return $i if $k < $k[$i];
   }
  scalar @k;
 }

sub splitNode($$)                                                               #P Split a node at the indicated index
 {my ($node, $split) = @_;                                                      # Node to split, split point
  @_ == 2 or confess;

  my ($o, $n) = ($node, new);                                                   # The new node juxtaposed with the old node
  $n->up    = $o->up;
  $n->keys  = [splice $o->keys->@*, $split];
  $n->data  = [splice $o->data->@*, $split];
  $n
 }

sub insert($)                                                                   #P Insert a child node and return the new tree so formed.
 {my ($child) = @_;                                                             # Child node
  @_ == 1 or confess;

  my $parent = $child->up;
  return $child unless $parent;                                                 # We have reached the top

  my $split = findSplit($parent, $child);                                       # The point at which to split the parent to reach the child

  my $k = shift $child->keys->@*;                                               # Key to add to parent
  my $d = shift $child->data->@*;

  if ($parent->keys->@* < $keysPerNode)                                         # Insert
   {insertIntoNode($parent, $child, $split, $k, $d);
   }
  else                                                                          # Split and insert
   {my $n = splitNode($parent, $split);
    if (my $p = $parent->up)
     {insertIntoNode($p, $n, $split, $k, $d);
      __SUB__->($n);
     }
    else                                                                        # New root
     {my $p = new;
      $p->keys = [$k];
      $p->data = [$d];
      $p->node = [$parent, $n];
      $parent->up = $n->up = $p;
     }
   }
  $parent->root;                                                                # Return new tree
 }

sub printKeysAndData($)                                                         # Print the mapping from keys to data in a tree
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  my @s;
  my sub print($$)
   {my ($t, $in) = @_;
    return unless $t;
    __SUB__->($t->left, $in+1);                                                 # Left
    push @s, [$t->keys->[$_], $t->data->[$_]] for keys $t->keys->@*;            # Find key in node
    __SUB__->($t->right,   $in+1);                                              # Right
   }
  print $t, 0;
  formatTableBasic(\@s)
 } # printKeysAndData

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Tree::Multi - Multi-way tree in Pure Perl

=head1 Synopsis


=head1 Description

Multi-way tree in Pure Perl


Version "20210528".

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.

=head1 Index


=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Multi

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use Time::HiRes qw(time);
use Test::Most;

my $develop   = -e q(/home/phil/);                                              # Developing
my $localTest = ((caller(1))[0]//'Tree::Multi') eq "Tree::Multi";               # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i) {plan tests => 7}                                     # Supported systems
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

bail_on_fail;

my $start = time;                                                               # Tests

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

if (1) {                                                                        # Room in parent so we can insert the child without splitting
  my $p = new;
     $p->keys = [map {$keysPerNode * 2 * $_} 1..$keysPerNode-1];
     $p->data = [map {$keysPerNode * 2 * $_} 1..$keysPerNode-1];
     $p->node = [map {undef}                 0..$keysPerNode-1];
  my $c = new;
     $c->up    = $p;
     $c->keys = [map {$keysPerNode * 2 + $_} 1..$keysPerNode];
     $c->data = [map {$keysPerNode * 2 + $_} 1..$keysPerNode];
  my $t = insert $c;
  is_deeply $t->keys,  [8, 9, 16, 24];
  is_deeply $t->node->[2]->keys, [10, 11, 12];
 }

if (1) {                                                                        # Room in parent so we can insert the child without splitting
  my $p = new;
     $p->keys = [map {$keysPerNode * 2 * $_} 1..$keysPerNode];
     $p->data = [map {$keysPerNode * 2 * $_} 1..$keysPerNode];
     $p->node = [map {undef}                 0..$keysPerNode];
  my $c = new;
     $c->up    = $p;
     $c->keys = [map {$keysPerNode * 2 + $_} 1..$keysPerNode];
     $c->data = [map {$keysPerNode * 2 + $_} 1..$keysPerNode];
  my $t = insert $c;
  is_deeply $t->keys, [9];
  is_deeply $t->node->[0]->keys, [8];
  is_deeply $t->node->[1]->keys->[0], 16;
  ok $t->node->[0]->up == $t;
  ok $t->node->[1]->up == $t;
 }

lll "Success:", time - $start;
