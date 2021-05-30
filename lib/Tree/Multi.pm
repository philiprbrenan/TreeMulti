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

our $keysPerNode = 3;                                                           # Keys per node

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

sub check($)                                                                    # Check the integrity of a node
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  confess unless $tree->keys->@* == $tree->data->@*;
  confess if $tree->up and !$tree->up->node and !$tree->up->node->@*;
  __SUB__->($tree->up) if $tree->up;
  return unless my @n = $tree->node->@*;
  confess unless $tree->keys->@*+1 == @n;
 }

sub root($)                                                                     # Return the root node of a tree
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(; $tree->up; $tree = $tree->up) {}
  $tree
 }

sub separateKeys($)                                                             #P Return ([lower], center, [upper]) keys
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @k = $node->keys->@*;
  my @l; my @r;
  while(@k > 1)
   {push    @l, shift @k;
    unshift @r, pop   @k if @k > 1;
   }
  @l > 0  or confess;
  @r > 0  or confess;
  @k == 1 or confess;
  (\@l, $k[0], \@r);
 }

sub separateData($)                                                             #P Return ([lower], center, [upper]) data
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @d = $node->data->@*;
  my @l; my @r;
  while(@d > 1)
   {push    @l, shift @d;
    unshift @r, pop   @d if @d > 1;
   }
  @l > 0 or confess;
  @r > 0 or confess;
  @d == 1 or confess;
  (\@l, $d[0], \@r);
 }

sub separateNode($)                                                             #P Return ([lower], [upper]) children
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @n = $node->node->@*;
  @n == $keysPerNode + 1 or confess;

  my @l; my @r;
  while(@n > 1)
   {push    @l, shift @n;
    unshift @r, pop   @n;
   }
  @l > 0 && @r > 0 && @n == 0 or confess;
  (\@l, \@r);
 }

sub reUp($@)                                                                    #P Reconnect the children to their new parent
 {my ($node, @children) = @_;                                                   # Node, children
  @_ > 1 or confess;

  for my $c(@children)                                                          # Add new child to parent known to be not full
   {$c->up = $node;
   }
 }

sub splitNode($)                                                                #P Split a full node in half assuming it has a non full parent
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess unless my $p = $node->up;                                             # Check parent
  confess unless $node->node->@* == $keysPerNode + 1;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;
  my ($cl, $cr)     = separateNode $node;

  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl; $nl->node = $cl; reUp($nl, @$cl);
  $nr->keys = $kr; $nr->data = $dr; $nr->node = $cr; reUp($nr, @$cr);

  my @n = $p->node->@*;
  for my $i(keys @n)                                                            # Add new child to parent known to be not full
   {if ($n[$i] == $node)
     {splice $p->keys->@*, $i, 0, $k;
      splice $p->data->@*, $i, 0, $d;
      splice $p->node->@*, $i, 1, $nl, $nr;
      return $p;                                                                # Return parent as we have delete the original node
     }
   }
  confess;
 }

sub splitRootNode($)                                                            #P Split a full root
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess if $node->up;                                                         # Check parent
  confess unless $node->node->@* == $keysPerNode + 1;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;
  my ($cl, $cr)     = separateNode $node;

  my $p = new;
  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl; $nl->node = $cl; reUp($nl, @$cl);
  $nr->keys = $kr; $nr->data = $dr; $nr->node = $cr; reUp($nr, @$cr);

  $p->keys = [$k];
  $p->data = [$d];
  $p->node = [$nl, $nr];
  $p                                                                            # Return new root
 }

sub splitFullNode($)                                                            #P Split a full node and return the new parent or return the existing node if it does not need to be split
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  return $node unless $node->node->@* == $keysPerNode + 1;                      # Check size
  return splitNode     $node if $node->up;                                      # Node has a parent
  return splitRootNode $node                                                    # Root node
 }

sub splitLeafNode($)                                                            #P Split a full leaf node in assuming it has a non full parent
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess unless my $p = $node->up;                                             # Check parent
  confess unless $node->keys->@* == $keysPerNode + 1;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;

  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl;
  $nr->keys = $kr; $nr->data = $dr;

  my @n = $p->node->@*;
  for my $i(keys @n)                                                            # Add new child to parent known to be not full
   {if ($n[$i] == $node)
     {splice $p->keys->@*, $i, 0, $k;
      splice $p->data->@*, $i, 0, $d;
      splice $p->node->@*, $i, 1, $nl, $nr;
      return $p;                                                                # Return parent as we have delete the original node
     }
   }
  confess;
 }

sub splitRootLeafNode($)                                                        #P Split a full root that is also a leaf
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess if $node->up;                                                         # Check parent
  confess unless $node->keys->@* == $keysPerNode + 1;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;

  my $p = new;
  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl;
  $nr->keys = $kr; $nr->data = $dr;

  $p->keys = [$k];
  $p->data = [$d];
  $p->node = [$nl, $nr];
  $p                                                                            # Return new root
 }

sub splitFullLeafNode($)                                                        #P Split a full leaf and return the new parent or return the existing node if it does not need to be split
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  return $node if $node->keys->@* <= $keysPerNode;                              # Check size
  return splitLeafNode     $node if $node->up;                                  # Node has a parent
  return splitRootLeafNode $node                                                # Root node
 }

sub findAndSplit($$)                                                            # Find a key in a tree splitting full nodes along the path to the key
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;

  $tree = splitFullNode $tree;
  confess unless my @k = $tree->keys->@*;                                       # We should have at least one key in the tree

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return (-1, $tree, 0);
   }

  if ($key > $k[-1])                                                            # Greater than largest key in node
   {if (my $node = $tree->node->[-1])                                           # Step through
     {return __SUB__->($node, $key);
     }
    return (+1, $tree, $#k);                                                    # Leaf
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $k[$i] <=> $key;                                                    # Compare key
    return (0, $tree, $i) if $s == 0;                                           # Found key
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])                                         # Step through
       {return __SUB__->($node, $key);
       }
      return (-1, $tree, $i);                                                   # Leaf
     }
   }
  confess 'Not possible';
 } # findAndSplit

sub find($$)                                                                    # Find a key in a tree returning its associated data or undef if the key does not exist
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;
  my @k = $tree->keys->@*;

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  if ($key > $k[-1])                                                           # Greater than largest key in node
   {if (my $node = $tree->node->[-1])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $k = $tree->keys->[$i];
    my $d = $tree->data->[$i];
    my $s = $key <=> $k[$i];                                                    # Compare key
    return $tree->data->[$i] if $s == 0;                                        # Found key
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])
       {return __SUB__->($node, $key);
       }
      return undef;
     }
   }
  confess 'Not possible';
 } # find

sub insert($$$)                                                                 # Insert a key and data into a tree
 {my ($tree, $key, $data) = @_;                                                 # Tree, key, data
  @_ == 3 or confess;

  if (!$tree->keys->@*)                                                         # Empty tree
   {push $tree->keys->@*, $key;
    push $tree->data->@*, $data;
    return $tree;
   }

  my ($compare, $node, $index) = findAndSplit($tree, $key);                     # Check for existing key

  if ($compare == 0)                                                            # Found an equal key whose data we can update
   {$node->data->[$index] = $data;
    return root $node;
   }

  if ($compare < 0)                                                             # Insert into a leaf node below the index
   {my @k = $node->keys->@*; my @d = $node->data->@*;
    $node->keys = [@k[0..$index-1], $key,  @k[$index..$#k]];
    $node->data = [@d[0..$index-1], $data, @d[$index..$#d]];
   }
  else                                                                          # Insert into a leaf node node above the index
   {my @k = $node->keys->@*; my @d = $node->data->@*;
    $node->keys = [@k[0..$index], $key,  @k[$index+1..$#k]];
    $node->data = [@d[0..$index], $data, @d[$index+1..$#d]];
   }
  root splitFullLeafNode $node
 }

sub printKeysAndData($)                                                         # Print the mapping from keys to data in a tree
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  my @s;
  my $print = sub
   {my ($t, $in) = @_;
    return unless $t and $t->keys;
    push @s, join ' ', ('  'x$in), $t->keys->@*, ' ', $t->data->@*;             # Print keys

    if (my $nodes = $t->node)                                                   # Each key
     {for my $n($nodes->@*)                                                     # Each key
       {__SUB__->($n, $in+1);                                                   # Sub tree
       }
     }
   };

  $print->($t, 0);

  join "\n", @s;
 }

sub printKeys($)                                                                # Print the keys in a tree
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  my @s;
  my $print = sub
   {my ($t, $in) = @_;
    return unless $t and $t->keys;
    push @s, join ' ', ('  'x$in), $t->keys->@*;                                # Print keys

    if (my $nodes = $t->node)                                                   # Each key
     {for my $n($nodes->@*)                                                     # Each key
       {__SUB__->($n, $in+1);                                                   # Sub tree
       }
     }
   };

  $print->($t, 0);

  join "\n", @s, '';
 }

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

if ($^O =~ m(bsd|linux)i) {plan tests => 1}                                     # Supported systems
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

bail_on_fail;

my $start = time;                                                               # Tests

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

if (1) {                                                                        #Tinsert #TprintKeys
  local $keysPerNode = 15;

  my $t = new; my $N = 256;

  $t = insert($t, $_, 2*$_) for 1..$N;

  is_deeply $t->printKeys, <<END;
 72 144
   9 18 27 36 45 54 63
     1 2 3 4 5 6 7 8
     10 11 12 13 14 15 16 17
     19 20 21 22 23 24 25 26
     28 29 30 31 32 33 34 35
     37 38 39 40 41 42 43 44
     46 47 48 49 50 51 52 53
     55 56 57 58 59 60 61 62
     64 65 66 67 68 69 70 71
   81 90 99 108 117 126 135
     73 74 75 76 77 78 79 80
     82 83 84 85 86 87 88 89
     91 92 93 94 95 96 97 98
     100 101 102 103 104 105 106 107
     109 110 111 112 113 114 115 116
     118 119 120 121 122 123 124 125
     127 128 129 130 131 132 133 134
     136 137 138 139 140 141 142 143
   153 162 171 180 189 198 207 216 225 234 243
     145 146 147 148 149 150 151 152
     154 155 156 157 158 159 160 161
     163 164 165 166 167 168 169 170
     172 173 174 175 176 177 178 179
     181 182 183 184 185 186 187 188
     190 191 192 193 194 195 196 197
     199 200 201 202 203 204 205 206
     208 209 210 211 212 213 214 215
     217 218 219 220 221 222 223 224
     226 227 228 229 230 231 232 233
     235 236 237 238 239 240 241 242
     244 245 246 247 248 249 250 251 252 253 254 255 256
END

  if (1)                                                                        #Tfind
   {my $n = 0;
    for my $i(1..$N)
     {my $ii = $t->find($i);
       ++$n if $t->find($i) eq 2 * $i;
     }
    ok $n == $N;
   }
 }

lll "Success:", time - $start;
