#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I.
#-------------------------------------------------------------------------------
# Multi-way tree in Pure Perl with an even or odd number of keys per node.
# Multi-way tree in Pure Perl with an even or odd number of keys per node.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Multi;
our $VERSION = "20210602";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump pp);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

our $numberOfKeysPerNode = 3;                                                   # Number of keys per node which can be localized because it is ours. The number of keys can be even or odd.
our $debug = 1;

#D1 Multi-way Tree                                                              # Create and use a multi-way tree.

my $nodes = 0;                                                                  # Count the nodes created

sub new()                                                                       #P Create a new multi-way tree node.
 {my () = @_;                                                                   # Key, $data, parent node, index of link from parent node
  confess "At least three keys per node" unless $numberOfKeysPerNode > 2;       # Check number of keys per node
  genHash(__PACKAGE__,                                                          # Multi tree node
    number=> ++$nodes,                                                          # Number of the node for debugging purposes
    up    => undef,                                                             # Parent node
    keys  => [],                                                                # Array of key items for this node
    data  => [],                                                                # Data corresponding to each key
    node  => [],                                                                # Child nodes
   );
 }

sub minimumNumberOfKeys()                                                       #P Minimum number of keys per node.
 {int(($numberOfKeysPerNode - 1) / 2)
 }

sub maximumNumberOfKeys()                                                       #P Maximum number of keys per node.
 {$numberOfKeysPerNode
 }

sub maximumNumberOfNodes()                                                      #P Maximum number of children per parent.
 {$numberOfKeysPerNode + 1
 }

sub full($)                                                                     #P Confirm that a node is full.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  $tree->keys->@* <= maximumNumberOfKeys or confess "Keys";
  $tree->keys->@* == maximumNumberOfKeys
 }

sub valid($)                                                                    #P Confirm that a tree is valid
 {my ($tree) = @_;                                                              # Tree
  my $root = $tree->root;
  $root->node->@* == 1 and confess "Single child not allowed";
  $root->node->@* == $root->keys->@* + 1 or confess "Nodes mismatches keys:\n", dump($root);
 }

sub halfFull($)                                                                 #P Confirm that a node is half full.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  $tree->keys->@* <= maximumNumberOfKeys+1 or confess "Keys";
  $tree->keys->@* == minimumNumberOfKeys
 }

sub root($)                                                                     # Return the root node of a tree.
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(; $tree->up; $tree = $tree->up) {}
  $tree
 }

sub leaf($)                                                                     # Confirm that the tree is a leaf.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  ! scalar $tree->node->@*                                                      # No children so it must be a leaf
 }

sub separateKeys($)                                                             #P Return ([lower], center, [upper]) keys.
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @k = $node->keys->@*;
  @k == maximumNumberOfKeys or @k == maximumNumberOfNodes or confess 'Keys';    # A node is allowed to overflow by one pending a split
  my @l; my @r;
  while(@k > 1)
   {push    @l, shift @k;
    unshift @r, pop   @k if @k > 1;
   }
  @l > 0  or confess 'Left'; @r > 0  or confess 'Right'; @k == 1 or confess 'K';
  (\@l, $k[0], \@r);
 }

sub separateData($)                                                             #P Return ([lower], center, [upper]) data
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @d = $node->data->@*;
  @d == maximumNumberOfKeys or @d == maximumNumberOfNodes or confess 'Keys';    # A node is allowed to overflow by one pending a split
  my @l; my @r;
  while(@d > 1)
   {push    @l, shift @d;
    unshift @r, pop   @d if @d > 1;
   }
  @l > 0  or confess 'Left'; @r > 0  or confess 'Right'; @d == 1 or confess 'D';
  (\@l, $d[0], \@r);
 }

sub separateNode($)                                                             #P Return ([lower], [upper]) children
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @n = $node->node->@*;
  @n == maximumNumberOfNodes or confess 'Node';

  my @l; my @r;
  while(@n > 1)
   {push    @l, shift @n;
    unshift @r, pop   @n;
   }

  if (@n == 1)                                                                  # Even keys per node
   {push @l, shift @n;
   }
  @l > 0 or confess "Left"; @r > 0 or confess "Right"; @n==0 or confess "Node";

  (\@l, \@r);
 }

sub reUp($@)                                                                    #P Reconnect the children to their new parent
 {my ($node, @children) = @_;                                                   # Node, children
  @_ > 0 or confess;

  for my $c(@children)                                                          # Add new child to parent known to be not full
   {$c->up = $node;
   }
 }

sub splitNode($)                                                                #P Split a full node in half assuming it has a non full parent
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess unless my $p = $node->up;                                             # Check parent
  confess unless $node->node->@* == maximumNumberOfNodes;                       # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;
  my ($cl, $cr)     = separateNode $node;

  my ($l, $r) = (new, new);                                                     # New child nodes
  $l->up   = $r->up = $p;
  $l->keys = $kl; $l->data = $dl; $l->node = $cl; reUp($l, @$cl);
  $r->keys = $kr; $r->data = $dr; $r->node = $cr; reUp($r, @$cr);

  my @n = $p->node->@*;                                                         # Insert new nodes in parent known to be not full
  for my $i(keys @n)
   {if ($n[$i] == $node)
     {splice $p->keys->@*, $i, 0, $k;
      splice $p->data->@*, $i, 0, $d;
      splice $p->node->@*, $i, 1, $l, $r;
      return;
     }
   }
  confess;
 }

sub splitRootNode($)                                                            #P Split a full root
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess if $node->up;                                                         # Check parent
  confess unless $node->node->@* == maximumNumberOfNodes;                       # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;
  my ($cl, $cr)     = separateNode $node;

  my $p = $node;
  my ($l, $r)     = (new, new);
  $l->up = $r->up = $p;
  $l->keys = $kl; $l->data = $dl; $l->node = $cl; reUp($l, @$cl);
  $r->keys = $kr; $r->data = $dr; $r->node = $cr; reUp($r, @$cr);

  $p->keys = [$k];
  $p->data = [$d];
  $p->node = [$l, $r];
 }

sub splitFullNode($)                                                            #P Split a full node
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  return $node  unless $node->node->@* == maximumNumberOfNodes;                 # Check size
  return splitNode     $node if $node->up;                                      # Node has a parent
  return splitRootNode $node                                                    # Root node
 }

sub splitLeafNode($)                                                            #P Split a full leaf node in assuming it has a non full parent
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess unless my $p = $node->up;                                             # Check parent
  confess unless $node->keys->@* == maximumNumberOfNodes;                       # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;

  my ($l, $r)     = (new, new);                                                 # Create new nodes
  $l->up = $r->up = $p;
  $l->keys = $kl; $l->data = $dl;
  $r->keys = $kr; $r->data = $dr;

  my @n = $p->node->@*;                                                         # Insert new nodes in parent known to be not full
  for my $i(keys @n)
   {if ($n[$i] == $node)
     {splice $p->keys->@*, $i, 0, $k;
      splice $p->data->@*, $i, 0, $d;
      splice $p->node->@*, $i, 1, $l, $r;
      return;                                                                   # Return parent as we have delete the original node
     }
   }
  confess;
 }

sub splitRootLeafNode($)                                                        #P Split a full root that is also a leaf
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess if $node->up;                                                         # Check parent
  confess unless $node->keys->@* == maximumNumberOfNodes;                       # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;

  my ($p, $l, $r) = ($node, new, new);                                          # New root and children

  $l->up   = $r->up        = $p;                                                # Initialize children
  $l->keys = $kl; $l->data = $dl;
  $r->keys = $kr; $r->data = $dr;

  $p->keys = [$k];                                                              # Initialize parent
  $p->data = [$d];
  $p->node = [$l, $r];
 }

sub findAndSplit($$)                                                            #P Find a key in a tree splitting full nodes along the path to the key
 {my ($root, $key) = @_;                                                        # Root of tree, key
  @_ == 2 or confess;

  my $tree = $root;                                                             # Start at the root

  for(0..999)                                                                   # Step down through the tree
   {splitFullNode $tree;                                                        # Split any full nodes encountered
    confess unless my @k = $tree->keys->@*;                                     # We should have at least one key in the tree because we do a special case insert for an empty tree

    if ($key < $k[0])                                                           # Less than smallest key in node
     {return (-1, $tree, 0)    unless my $n = $tree->node->[0];
      $tree = $n;
      next;
     }

    if ($key > $k[-1])                                                          # Greater than largest key in node
     {return (+1, $tree, $#k)  unless my $n = $tree->node->[-1];
      $tree = $n;
      next;
     }

    for my $i(keys @k)                                                          # Search the keys in this node as greater than least key and less than largest key
     {my $s = $key <=> $k[$i];                                                  # Compare key
      return (0, $tree, $i) if $s == 0;                                         # Found key
      if ($s < 0)                                                               # Less than current key
       {return (-1, $tree, $i) unless my $n = $tree->node->[$i];                # Step through if possible
        $tree = $n;                                                             # Step
        last;
       }
     }
   }
  confess 'Not possible';
 }

sub find($$)                                                                    # Find a key in a tree returning its associated data or undef if the key does not exist
 {my ($root, $key) = @_;                                                        # Root of tree, key
  @_ == 2 or confess;

  my $tree = $root;                                                             # Start at the root

  for(0..999)                                                                   # Step down through the tree
   {return undef unless my @k = $tree->keys->@*;                                # Empty node

     if (grep {!defined} @k)                                                    # Check that all the keys are defined
      {confess "Undefined key:\n". dump($tree);
      }

    if ($key < $k[0])                                                           # Less than smallest key in node
     {return undef unless $tree = $tree->node->[0];
      next;
     }

    if ($key > $k[-1])                                                          # Greater than largest key in node
     {return undef unless $tree = $tree->node->[-1];
      next;
     }

    for my $i(keys @k)                                                          # Search the keys in this node
     {my $s = $key <=> $k[$i];                                                  # Compare key
      return $tree->data->[$i] if $s == 0;                                      # Found key
      if ($s < 0)                                                               # Less than current key
       {return undef unless $tree = $tree->node->[$i];
        last;
       }
     }
   }
  confess 'Not possible';
 } # find

sub height($)                                                                   # Return the height of the tree
 {my ($tree) = @_;                                                              # Tree
  for my $n(0..999)                                                             # Step down through tree
   {if ($tree->leaf)                                                            # We are on a leaf
     {return $n + 1 if $tree->leaf && $tree->keys->@*;                          # We are in a partially full leaf
      return $n;                                                                # We are on the root and it is empty
     }
    $tree = $tree->node->[0];
   }
  confess "Should not happen";
 }

sub depth($)                                                                    # Return the depth of a node within a tree
 {my ($tree) = @_;                                                              # Tree
  return 0 if !$tree->up and !$tree->keys->@*;                                  # We are at the root and it is empty
  for my $n(1..999)                                                             # Step down through tree
   {return $n  unless $tree->up;                                                # We are at the root
    $tree = $tree->up;
   }
  confess "Should not happen";
 }

sub indexInParent($)                                                            #P Get the index of a node in its parent
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $p = $tree->up;
  confess unless defined $p;
  my @n = $p->node->@*;
  for my $i(keys @n)
   {return $i if $n[$i] == $tree;
   }
  confess
 }

sub fillFromLeftOrRight($$)                                                     #P Fill a node from the specified sibling
 {my ($n, $dir) = @_;                                                           # Node to fill, node to fill from 0 for left or 1 for right
  @_ == 2 or confess;

  confess if        $n->full;                                                   # Cannot fill a full node
  confess unless my $p = $n->up;                                                # Parent of leaf
  my $i = $n->indexInParent;                                                    # Index of leaf in parent

  if ($dir)                                                                     # Fill from right
   {$i < $p->node->@* - 1 or confess;                                           # Cannot fill from right
    my $r = $p->node->[$i+1];                                                   # Leaf on right
    push $n->keys->@*, $p->keys->[$i]; $p->keys->[$i] = shift $r->keys->@*;     # Transfer key
    push $n->data->@*, $p->data->[$i]; $p->data->[$i] = shift $r->data->@*;     # Transfer data
    if (!$n->leaf)                                                              # Transfer node if not a leaf
     {push $n->node->@*, shift $r->node->@*;
      $n->node->[-1]->up = $n;
     }
   }
  else                                                                          # Fill from left
   {$i > 0 or confess;                                                          # Cannot fill from left
    my $l = $p->node->[$i-1];                                                   # Leaf on leaf
    unshift $n->keys->@*, $p->keys->[$i-1];$p->keys->[$i-1] = pop $l->keys->@*; # Transfer key
    unshift $n->data->@*, $p->data->[$i-1];$p->data->[$i-1] = pop $l->data->@*; # Transfer data
    if (!$n->leaf)                                                              # Transfer node if not a leaf
     {unshift $n->node->@*, pop $l->node->@*;
      $n->node->[0]->up = $n;
     }
   }
 }

sub fillFromLeft($)                                                             #P Fill a node from the left
 {my ($tree) = @_;                                                              # Tree known to have a left node
  @_ == 1 or confess;
$tree->valid;
  $tree->fillFromLeftOrRight(0);
$tree->valid;
 }

sub fillFromRight($)                                                            #P Fill a node from the right
 {my ($tree) = @_;                                                              # Tree known to have a right node
  @_ == 1 or confess;
$tree->valid;
  $tree->fillFromLeftOrRight(1);
$tree->valid;
 }

sub mergeWithLeftOrRight($$)                                                    #P Merge two adjacent nodes
 {my ($tree, $dir) = @_;                                                        # Tree to merge into, node to merge is on right if 1 else left
  @_ == 2 or confess;

  confess unless my $p = $tree->up;                                             # Parent of leaf

  my $i = $tree->indexInParent;                                                 # Index of leaf in parent

  if ($dir)                                                                     # Merge with right hand sibling
   {$i < $p->node->@* - 1 or confess;                                           # Cannot fill from right
$tree->valid;
    my $r = $p->node->[$i+1];                                                   # Leaf on right
    push $tree->keys->@*, splice($p->keys->@*, $i, 1), $r->keys->@*;            # Transfer keys
    push $tree->data->@*, splice($p->data->@*, $i, 1), $r->data->@*;            # Transfer data
    if (!$tree->leaf)                                                           # Children of merged node
     {push $tree->node->@*, $r->node->@*;                                       # Children of merged node
      $_->up = $tree for $r->node->@*;                                          # Update parent of children of right node
     }
    splice $p->node->@*, $i+1, 1;                                               # Remove link from parent to right child
$tree->valid;
   }
  else                                                                          # Merge with left hand sibling
   {
lll "Merge with left hand sibling ", dump($tree->root);
lll "AT node i=$i ", dump($tree->keys);
$tree->valid;
    my $l = $p->node->[$i-1];                                                   # Node on left
    unshift $tree->keys->@*, $l->keys->@*, splice $p->keys->@*, $i-1, 1;        # Transfer keys
    unshift $tree->data->@*, $l->data->@*, splice $p->data->@*, $i-1, 1;        # Transfer data
    if (!$tree->leaf)                                                           # Children of merged node
     {unshift $tree->node->@*, $l->node->@*;                                    # Children of merged node
      $_->up = $tree for $l->node->@*;                                          # Update parent of children of left node
     }
    splice $p->node->@*, $i-1, 1;                                               # Remove link from parent to left child
$tree->valid;
   }
 }

sub mergeWithLeft($)                                                            #P Merge with the left node
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
$tree->valid;

  $tree->mergeWithLeftOrRight(0);
$tree->valid;
 }

sub mergeWithRight($)                                                           #P Merge with the right node
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
$tree->valid;
  $tree->mergeWithLeftOrRight(1);
$tree->valid;
 }

sub mergeRoot($)                                                                #P Merge the root node
 {my ($t) = @_;                                                                 # Root
  @_ == 1 or confess;
  my $l = $t->node->[0];
  my $r = $t->node->[1];

  if ($t->keys->@* == 1 and $l and $l->halfFull                                 # Parent is the root and it only has one key - merge in the children
                        and $r and $r->halfFull)
   {$t->keys = [$l->keys->@*, $t->keys->@*, $r->keys->@*];
    $t->data = [$l->data->@*, $t->data->@*, $r->data->@*];
    $t->node = [$l->node->@*,               $r->node->@*];

    reUp($t, $t->node->@*);
   }
 }

sub mergeOrFillLeft($)                                                          #P Merge or fill from the left node
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;

  if ((my $r = $tree)->halfFull)
   {my $i = $r->indexInParent;
    my $l = $r->up->node->[$i-1];
    $l->halfFull ? $r->mergeWithLeft : $r->fillFromLeft;
   }
 }

sub mergeOrFillRight($)                                                         #P Merge or fill from the right node
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;

  if ((my $l = $tree)->halfFull)
   {my $i = $tree->indexInParent;
    my $r = $tree->up->node->[$i+1];
    $r->halfFull ? $l->mergeWithRight : $l->fillFromRight;
   }
 }

sub mergeOrFill($)                                                              #P Make a node larger than a half node by merging or filling from the left is possible else from the right
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;

  if (!$tree->up)                                                               # Merge the root node
   {
$tree->valid;
     mergeRoot($tree);
$tree->valid;
    return;
   }
  elsif (my $i = $tree->indexInParent)                                          # Merge or fill with left node if possible
   {
$tree->valid;

     mergeOrFillLeft($tree);
$tree->valid;
   }
  else                                                                          # Merge or fill with right node otherwise
   {
$tree->valid;
     mergeOrFillRight($tree);
$tree->valid;
   }
  $tree->halfFull and confess "Half full";
 }

sub leftMost($)                                                                 # Return the left most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  for(0..999)                                                                   # Step down through tree
   {return $tree if $tree->leaf;                                                # We are on a leaf so we have arrived at the left most node
    $tree = $tree->node->[0];                                                   # Go left
   }
  confess "Should not happen";
 }

sub leftMostSplitting($)                                                        # Return the left most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  for(0..999)                                                                   # Step down through tree
   {return $tree if $tree->leaf;                                                # We are on a leaf so we have arrived at the left most node
    $tree = $tree->node->[0];                                                   # Go left
    $tree->mergeOrFill;
   }
  confess "Should not happen";
 }

sub rightMost($)                                                                # Return the right most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  for(0..999)                                                                   # Step down through tree
   {return $tree if $tree->leaf;                                                # We are on a leaf so we have arrived at the left most node
    $tree = $tree->node->[-1];                                                  # Go right
   }
  confess "Should not happen";
 }

sub rightMostSplitting($)                                                       # Return the right most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  for(0..999)                                                                   # Step down through tree
   {return $tree if $tree->leaf;                                                # We are on a leaf so we have arrived at the left most node
    $tree = $tree->node->[-1];                                                  # Go right
    $tree->mergeOrFill;
   }
  confess "Should not happen";
 }

sub deleteLeafKey($$)                                                           #P Delete a (key, pair) in a leaf
 {my ($tree, $i) = @_;                                                          # Tree, index to delete at
  @_ == 2 or confess;
  confess "Not a leaf" unless $tree->leaf;
  my $key = $tree->keys->[$i];
  mergeOrFill($tree) if $tree->up;                                              # Merge and fill unless we are on the root and the root is a leaf
  for my $j(keys $tree->keys->@*)    # Stablization can be removed now we are no longer recursive
   {if ($tree->keys->[$j] == $key)
     {splice $tree->keys->@*, $j, 1;                                            # Remove keys
      splice $tree->data->@*, $j, 1;                                            # Remove data
      last;
     }
   }
 }

sub deleteKey($$$)                                                              #P Delete a (key, data) pair in a node that is not half full
 {my ($tree, $i, $key) = @_;                                                    # Tree, index to delete at
  @_ == 3 or confess;
$tree->valid;

  if ($tree->leaf)                                                              # Delete from a leaf
   {deleteLeafKey($tree, $i);
$tree->valid;
   }
  elsif ($i != $tree->keys->@* - 1)                                             # Go right if possible to avoid repositioning the key to be deleted
   {        $tree->node->[$i+1]->mergeOrFillRight;                              # Merge or fill using keys to the right of the one to be deleted
    my $l = $tree->node->[$i+1]->leftMostSplitting;                             # Find next leaf node splitting all the way
    splice  $tree->keys->@*, $i, 1, $l->keys->[0];
    splice  $tree->data->@*, $i, 1, $l->data->[0];
    deleteLeafKey($l, 0);                                                       # Remove leaf key
$tree->valid;
   }
  else                                                                          # Merge or fill from left leaving the key to be deleted at the end
   {         $tree->node->[-2]->mergeOrFillLeft;                                # Merge or fill using keys to the left of the one to be deleted so it stays at the end and in the same level
    my $r = $tree->node->[-2]->rightMostSplitting;                              # Find next leaf node splitting all the way
    splice  $tree->keys->@*, -1, 1, $r->keys->[-1];
    splice  $tree->data->@*, -1, 1, $r->data->[-1];
    deleteLeafKey($r, -1 + scalar $r->keys->@*);                                # Remove leaf key
$tree->valid;
   }
 }

sub delete($$)                                                                  # Find a key in a tree, delete it, return the new tree
 {my ($root, $key) = @_;                                                        # Tree root, key
  @_ == 2 or confess;
lll "Delete key $key ", dump($root->keys);
$root->valid;
  if ($root->leaf)                                                              # Delete immediately if the root is a leaf
   {my @k = $root->keys->@*;
    for my $i(keys @k)                                                          # Search the keys in this node
     {if ($root->keys->[$i] == $key)
       {splice $root->keys->@*, $i, 1;                                          # Remove keys
        splice $root->data->@*, $i, 1;                                          # Remove data
        return;
       }
     }
   }
$root->valid;

# if ($root->keys->@* == 1 and $root->keys->[0] == $key)                        # To delete we need every parent node to have at least two keys.  If the root has only one key in it and that happens to be the key we want to delete then we must either fill to move the single root key into one of the left or right sub trees or if taht is not possible because they are both full, then split the right sub tree so that the root has at least two elements allowing us to proceed with a normal delete
  if ($root->keys->@* == 1)                                                     # To delete we need every parent node to have at least two keys.  If the root has only one key in it and that happens to be the key we want to delete then we must either fill to move the single root key into one of the left or right sub trees or if taht is not possible because they are both full, then split the right sub tree so that the root has at least two elements allowing us to proceed with a normal delete
   {my ($l, $r) = $root->node->@*;
    if ($l->full and $r->full)                                                  # Both children full - split right to move another key into the root to give it at least two keys
     {$r->splitNode;
$root->valid;
     }
    elsif ($l->keys->@* >= $r->keys->@*)                                        # Left has more than right so fill right from left
     {$r->fillFromLeft;
$root->valid;
     }
    else                                                                        # Right has more than left so fill left from right
     {$l->fillFromRight;
$root->valid;
     }
   }
$root->valid;

  my $tree = $root;                                                             # Find key in tree starting from root
  for (0..999)
   {
$root->valid;
     mergeOrFill $tree if $tree->up;
$root->valid;
    my @k = $tree->keys->@*;

    if ($key < $k[0])                                                           # Less than smallest key in node
     {return unless $tree = $tree->node->[0];
      next;
     }

    if ($key > $k[-1])                                                          # Greater than largest key in node
     {return unless $tree = $tree->node->[-1];
      next;
     }

    for my $i(keys @k)                                                          # Search the keys in this node
     {my  $s = $key <=> $k[$i];                                                 # Compare key
      if ($s == 0)                                                              # Delete found key
       {$root->valid;
        deleteKey($tree, $i, $key);                                             # Delete
        return;                                                                 # New tree
       }
      if ($s < 0)                                                               # Less than current key
       {return unless $tree = $tree->node->[$i];
        last;
       }
     }
   }

  confess 'Not possible';
 } # delete

sub insert($$$)                                                                 # Insert a key and data into a tree
 {my ($tree, $key, $data) = @_;                                                 # Tree, key, data
  @_ == 3 or confess;

  $tree or confess;

  if (!$tree->keys->@*)                                                         # Empty tree
   {push $tree->keys->@*, $key;
    push $tree->data->@*, $data;
    return $tree;
   }

  my ($compare, $node, $index) = findAndSplit($tree, $key);                     # Check for existing key

  if ($compare == 0)                                                            # Found an equal key whose data we can update
   {$node->data->[$index] = $data;
    return $tree;
   }

  my @k = $node->keys->@*; my @d = $node->data->@*;
  @k <= maximumNumberOfKeys or confess 'Keys';
  @d <= maximumNumberOfKeys or confess 'Data';

  if ($compare < 0)                                                             # Insert into a leaf node below the index
   {$node->keys = [@k[0..$index-1], $key,  @k[$index..$#k]];
    $node->data = [@d[0..$index-1], $data, @d[$index..$#d]];
   }
  else                                                                          # Insert into a leaf node node above the index
   {$node->keys = [@k[0..$index], $key,  @k[$index+1..$#k]];
    $node->data = [@d[0..$index], $data, @d[$index+1..$#d]];
   }

  return $tree if $node->keys->@* <= maximumNumberOfKeys;                       # No need to split
  if ($node->up)                                                                # Split leaf node that is not the root
   {splitLeafNode $node;
    return;
   }
  splitRootLeafNode $node                                                       # Split Root node
 }

sub iterator($)                                                                 # Make an iterator for a tree
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $i = genHash(__PACKAGE__.'::Iterator',                                     # Iterator
    tree  => $tree,                                                             # Tree we are iterating over
    node  => $tree,                                                             # Current node within tree
    pos   => undef,                                                             # Current position within node
    key   => undef,                                                             # Key at this position
    data  => undef,                                                             # Data at this position
    count => 0,                                                                 # Counter
    more  => 1,                                                                 # Iteration not yet finished
   );
  $i->next;                                                                     # First element if any
  $i                                                                            # Iterator
 }

sub Tree::Multi::Iterator::next($)                                              # Find the next key
 {my ($iter) = @_;                                                              # Iterator
  @_ >= 1 or confess;
  confess unless my $C = $iter->node;                                           # Current node required

  ++$iter->count;                                                               # Count the calls to the iterator

  my $new  = sub                                                                # Load iterator with latest position
   {my ($node, $pos) = @_;                                                      # Parameters
    $iter->node = $node;
    $iter->pos  = $pos //= 0;
    $iter->key  = $node->keys->[$pos];
    $iter->data = $node->data->[$pos]
   };

  my $done = sub {$iter->more = undef};                                         # The tree has been completely traversed

  if (!defined($iter->pos))                                                     # Initial descent
   {my $l = $C->node->[0];
    return $l ? &$new($l->leftMost) : $C->keys->@* ? &$new($C) : &$done;        # Start node or done if empty tree
    return;
   }

  my $up = sub                                                                  # Iterate up to next node that has not been visited
   {for(my $n = $C; my $p = $n->up; $n = $n->up)
     {my $i = $n->indexInParent;
      return &$new($p, $i) if $i < $p->keys->@*;
     }
    &$done                                                                      # No nodes not visited
   };

  my $i = ++$iter->pos;
  $C->leaf ? ($i < $C->keys->@* ? &$new($C, $i)                   : &$up)       # Leaf
           : ($i < $C->node->@* ? &$new($C->node->[$i]->leftMost) : &$up)       # Node
 }

sub printFlat($;$)                                                              #P Print the keys in a tree optionally marking the active key. The print
 {my ($tree, $index) = @_;                                                      # Tree, optional index of active key
  confess unless $tree;
  my @s;                                                                        # Print

  for(my $i = iterator($tree->root); $i->more; $i->next)                        # Traverse tree
   {my $t  = ('  'x$i->node->depth).$i->key;                                    # Print keys starring the active key if known
    $t .= '<=' if defined($index) and $index == $i->pos and $i->node == $tree;
    push @s, $t;
   }

  join "\n", @s, ''
 }

sub print($;$)                                                                  # Print the keys in a tree optionally marking the active key
 {my ($tree, $i) = @_;                                                          # Tree, optional index of active key
  confess unless $tree;
  my @s;                                                                        # Print

  my $print = sub                                                               # Print a node
   {my ($t, $in) = @_;
    return unless $t and $t->keys and $t->keys->@*;

    my @t = ('  'x$in);                                                         # Print keys staring the active key if known
    for my $j(keys $t->keys->@*)
     {push @t, $t->keys->[$j];
      push @t, '<=' if defined($i) and $i == $j and $tree == $t;
     }

    push @s, join ' ', @t;                                                      # Details of one node

    if (my $nodes = $t->node)                                                   # Each key
     {for my $n($nodes->@*)                                                     # Each key
       {__SUB__->($n, $in+1);                                                   # Sub tree
       }
     }
   };

  $print->($tree->root, 0);                                                     # Print tree

  join "\n", @s, ''
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

Tree::Multi - Multi-way tree in Pure Perl with an even or odd number of keys per node.

=head1 Synopsis

Construct and query a multi-way tree in B<100%> Pure Perl with the choice of an odd
or an even numbers of keys per node:

  local $Tree::Multi::numberOfKeysPerNode = 4;      # Number of keys per node - can be even

  my $t = Tree::Multi::new;                         # Construct tree
     $t = $t->insert($_, 2 * $_) for reverse 1..32; # Load tree in reverse

  is_deeply $t->print, <<END;
 15 21 27
   3 6 9 12
     1 2
     4 5
     7 8
     10 11
     13 14
   18
     16 17
     19 20
   24
     22 23
     25 26
   30
     28 29
     31 32
END

  ok  $t->height     ==  3;                         # Height

  ok  $t->find  (16) == 32;                         # Find by key
      $t->delete(16);                               # Delete a key
  ok !$t->find (16);                                # Key no longer present

=head1 Description

Multi-way tree in Pure Perl with an even or odd number of keys per node.


Version "20210602".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Multi-way Tree

Create and use a multi-way tree.

=head2 root($tree)

Return the root node of a tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t = insert($t, $n, $n);
     }

    is_deeply $t->leftMost ->keys, [1, 2];
    is_deeply $t->rightMost->keys, [13];
    ok $t->leftMost ->leaf;
    ok $t->rightMost->leaf;

    ok $t->root;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok T($t, <<END);
   6
     3
       1 2
       4 5
     9 12
       7 8
       10 11
       13
  END


=head2 leaf($tree)

Confirm that the tree is a leaf.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t = insert($t, $n, $n);
     }

    is_deeply $t->leftMost ->keys, [1, 2];
    is_deeply $t->rightMost->keys, [13];

    ok $t->leftMost ->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $t->rightMost->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->root;

    ok T($t, <<END);
   6
     3
       1 2
       4 5
     9 12
       7 8
       10 11
       13
  END


=head2 find($tree, $key)

Find a key in a tree returning its associated data or undef if the key does not exist

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t = $t->insert($_, 2 * $_) for reverse 1..32;                             # Load tree in reverse

    is_deeply $t->print, <<END;
   15 21 27
     3 6 9 12
       1 2
       4 5
       7 8
       10 11
       13 14
     18
       16 17
       19 20
     24
       22 23
       25 26
     30
       28 29
       31 32
  END

    ok  $t->height     ==  3;                                                     # Height


    ok  $t->find  (16) == 32;                                                     # Find by key  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        $t->delete(16);                                                           # Delete a key

    ok !$t->find (16);                                                            # Key no longer present  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 leftMost($tree)

Return the left most node below the specified one

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t = insert($t, $n, $n);
     }


    is_deeply $t->leftMost ->keys, [1, 2];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $t->rightMost->keys, [13];

    ok $t->leftMost ->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->rightMost->leaf;
    ok $t->root;

    ok T($t, <<END);
   6
     3
       1 2
       4 5
     9 12
       7 8
       10 11
       13
  END


=head2 rightMost($tree)

Return the right most node below the specified one

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t = insert($t, $n, $n);
     }

    is_deeply $t->leftMost ->keys, [1, 2];

    is_deeply $t->rightMost->keys, [13];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->leftMost ->leaf;

    ok $t->rightMost->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->root;

    ok T($t, <<END);
   6
     3
       1 2
       4 5
     9 12
       7 8
       10 11
       13
  END


=head2 height($tree)

Return the height of the tree

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t = $t->insert($_, 2 * $_) for reverse 1..32;                             # Load tree in reverse

    is_deeply $t->print, <<END;
   15 21 27
     3 6 9 12
       1 2
       4 5
       7 8
       10 11
       13 14
     18
       16 17
       19 20
     24
       22 23
       25 26
     30
       28 29
       31 32
  END


    ok  $t->height     ==  3;                                                     # Height  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  $t->find  (16) == 32;                                                     # Find by key
        $t->delete(16);                                                           # Delete a key
    ok !$t->find (16);                                                            # Key no longer present


=head2 delete($tree, $key)

Find a key in a tree, delete it, return the new tree

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t = $t->insert($_, 2 * $_) for reverse 1..32;                             # Load tree in reverse

    is_deeply $t->print, <<END;
   15 21 27
     3 6 9 12
       1 2
       4 5
       7 8
       10 11
       13 14
     18
       16 17
       19 20
     24
       22 23
       25 26
     30
       28 29
       31 32
  END

    ok  $t->height     ==  3;                                                     # Height

    ok  $t->find  (16) == 32;                                                     # Find by key

        $t->delete(16);                                                           # Delete a key  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok !$t->find (16);                                                            # Key no longer present


=head2 insert($tree, $key, $data)

Insert a key and data into a tree

     Parameter  Description
  1  $tree      Tree
  2  $key       Key
  3  $data      Data

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree

       $t = $t->insert($_, 2 * $_) for reverse 1..32;                             # Load tree in reverse  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $t->print, <<END;
   15 21 27
     3 6 9 12
       1 2
       4 5
       7 8
       10 11
       13 14
     18
       16 17
       19 20
     24
       22 23
       25 26
     30
       28 29
       31 32
  END

    ok  $t->height     ==  3;                                                     # Height

    ok  $t->find  (16) == 32;                                                     # Find by key
        $t->delete(16);                                                           # Delete a key
    ok !$t->find (16);                                                            # Key no longer present


=head2 iterator($tree)

Make an iterator for a tree

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 256; my $e = 0;  my $t = new;

    for my $n(0..$N)
     {$t = insert($t, $n, $n);

      my @n; for(my $i = $t->iterator; $i->more; $i->next) {push @n, $i->key}  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ++$e unless dump(\@n) eq dump [0..$n];
     }

    is_deeply $e, 0;


=head2 Tree::Multi::Iterator::next($iter)

Find the next key

     Parameter  Description
  1  $iter      Iterator

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 256; my $e = 0;  my $t = new;

    for my $n(0..$N)
     {$t = insert($t, $n, $n);
      my @n; for(my $i = $t->iterator; $i->more; $i->next) {push @n, $i->key}
      ++$e unless dump(\@n) eq dump [0..$n];
     }

    is_deeply $e, 0;


=head2 print($tree, $i)

Print the keys in a tree optionally marking the active key

     Parameter  Description
  1  $tree      Tree
  2  $i         Optional index of active key

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t = $t->insert($_, 2 * $_) for reverse 1..32;                             # Load tree in reverse


    is_deeply $t->print, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   15 21 27
     3 6 9 12
       1 2
       4 5
       7 8
       10 11
       13 14
     18
       16 17
       19 20
     24
       22 23
       25 26
     30
       28 29
       31 32
  END

    ok  $t->height     ==  3;                                                     # Height

    ok  $t->find  (16) == 32;                                                     # Find by key
        $t->delete(16);                                                           # Delete a key
    ok !$t->find (16);                                                            # Key no longer present



=head2 Tree::Multi Definition


Iterator




=head3 Output fields


=head4 count

Counter

=head4 data

Data at this position

=head4 key

Key at this position

=head4 keys

Array of key items for this node

=head4 more

Iteration not yet finished

=head4 node

Current node within tree

=head4 number

Number of the node for debugging purposes

=head4 pos

Current position within node

=head4 tree

Tree we are iterating over

=head4 up

Parent node



=head1 Private Methods

=head2 new()

Create a new multi-way tree node.


B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even


    my $t = Tree::Multi::new;                                                     # Construct tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $t = $t->insert($_, 2 * $_) for reverse 1..32;                             # Load tree in reverse

    is_deeply $t->print, <<END;
   15 21 27
     3 6 9 12
       1 2
       4 5
       7 8
       10 11
       13 14
     18
       16 17
       19 20
     24
       22 23
       25 26
     30
       28 29
       31 32
  END

    ok  $t->height     ==  3;                                                     # Height

    ok  $t->find  (16) == 32;                                                     # Find by key
        $t->delete(16);                                                           # Delete a key
    ok !$t->find (16);                                                            # Key no longer present


=head2 minimumNumberOfKeys()

Minimum number of keys per node.


=head2 maximumNumberOfKeys()

Maximum number of keys per node.


=head2 maximumNumberOfNodes()

Maximum number of children per parent.


=head2 full($tree)

Confirm that a node is full.

     Parameter  Description
  1  $tree      Tree

=head2 halfFull($tree)

Confirm that a node is half full.

     Parameter  Description
  1  $tree      Tree

=head2 separateKeys($node)

Return ([lower], center, [upper]) keys.

     Parameter  Description
  1  $node      Node to split

=head2 separateData($node)

Return ([lower], center, [upper]) data

     Parameter  Description
  1  $node      Node to split

=head2 separateNode($node)

Return ([lower], [upper]) children

     Parameter  Description
  1  $node      Node to split

=head2 reUp($node, @children)

Reconnect the children to their new parent

     Parameter  Description
  1  $node      Node
  2  @children  Children

=head2 splitNode($node)

Split a full node in half assuming it has a non full parent

     Parameter  Description
  1  $node      Node to split

=head2 splitRootNode($node)

Split a full root

     Parameter  Description
  1  $node      Node to split

=head2 splitFullNode($node)

Split a full node and return the new parent or return the existing node if it does not need to be split

     Parameter  Description
  1  $node      Node to split

=head2 splitLeafNode($node)

Split a full leaf node in assuming it has a non full parent

     Parameter  Description
  1  $node      Node to split

=head2 splitRootLeafNode($node)

Split a full root that is also a leaf

     Parameter  Description
  1  $node      Node to split

=head2 findAndSplit($tree, $key)

Find a key in a tree splitting full nodes along the path to the key

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

=head2 indexInParent($tree)

Get the index of a node in its parent

     Parameter  Description
  1  $tree      Tree

=head2 fillFromLeftOrRight($n, $dir)

Fill a node from the specified sibling

     Parameter  Description
  1  $n         Node to fill
  2  $dir       Node to fill from 0 for left or 1 for right

=head2 mergeWithLeftOrRight($n, $dir)

Merge two adjacent nodes

     Parameter  Description
  1  $n         Node to merge into
  2  $dir       Node to merge is on right if 1 else left

=head2 mergeRoot($tree, $child)

Merge the root node

     Parameter  Description
  1  $tree      Tree
  2  $child     The child to merge into

=head2 mergeOrFill($tree)

make a node larger than a half node

     Parameter  Description
  1  $tree      Tree

=head2 deleteElement($tree, $i)

Delete an element in a node

     Parameter  Description
  1  $tree      Tree
  2  $i         Index to delete at

=head2 T($tree, $expected)

Write a result to the log file

     Parameter  Description
  1  $tree      Tree
  2  $expected  Expected print

=head2 disordered($n, $N)

Disordered insertions

     Parameter  Description
  1  $n         Keys per node
  2  $N         Nodes

=head2 disorderedCheck($t, $n, $N)

Check disordered insertions

     Parameter  Description
  1  $t         Tree to check
  2  $n         Keys per node
  3  $N         Nodes


=head1 Index


1 L<delete|/delete> - Find a key in a tree, delete it, return the new tree

2 L<deleteElement|/deleteElement> - Delete an element in a node

3 L<disordered|/disordered> - Disordered insertions

4 L<disorderedCheck|/disorderedCheck> - Check disordered insertions

5 L<fillFromLeftOrRight|/fillFromLeftOrRight> - Fill a node from the specified sibling

6 L<find|/find> - Find a key in a tree returning its associated data or undef if the key does not exist

7 L<findAndSplit|/findAndSplit> - Find a key in a tree splitting full nodes along the path to the key

8 L<full|/full> - Confirm that a node is full.

9 L<halfFull|/halfFull> - Confirm that a node is half full.

10 L<height|/height> - Return the height of the tree

11 L<indexInParent|/indexInParent> - Get the index of a node in its parent

12 L<insert|/insert> - Insert a key and data into a tree

13 L<iterator|/iterator> - Make an iterator for a tree

14 L<leaf|/leaf> - Confirm that the tree is a leaf.

15 L<leftMost|/leftMost> - Return the left most node below the specified one

16 L<maximumNumberOfKeys|/maximumNumberOfKeys> - Maximum number of keys per node.

17 L<maximumNumberOfNodes|/maximumNumberOfNodes> - Maximum number of children per parent.

18 L<mergeOrFill|/mergeOrFill> - make a node larger than a half node

19 L<mergeRoot|/mergeRoot> - Merge the root node

20 L<mergeWithLeftOrRight|/mergeWithLeftOrRight> - Merge two adjacent nodes

21 L<minimumNumberOfKeys|/minimumNumberOfKeys> - Minimum number of keys per node.

22 L<new|/new> - Create a new multi-way tree node.

23 L<print|/print> - Print the keys in a tree optionally marking the active key

24 L<reUp|/reUp> - Reconnect the children to their new parent

25 L<rightMost|/rightMost> - Return the right most node below the specified one

26 L<root|/root> - Return the root node of a tree.

27 L<separateData|/separateData> - Return ([lower], center, [upper]) data

28 L<separateKeys|/separateKeys> - Return ([lower], center, [upper]) keys.

29 L<separateNode|/separateNode> - Return ([lower], [upper]) children

30 L<splitFullNode|/splitFullNode> - Split a full node and return the new parent or return the existing node if it does not need to be split

31 L<splitLeafNode|/splitLeafNode> - Split a full leaf node in assuming it has a non full parent

32 L<splitNode|/splitNode> - Split a full node in half assuming it has a non full parent

33 L<splitRootLeafNode|/splitRootLeafNode> - Split a full root that is also a leaf

34 L<splitRootNode|/splitRootNode> - Split a full root

35 L<T|/T> - Write a result to the log file

36 L<Tree::Multi::Iterator::next|/Tree::Multi::Iterator::next> - Find the next key

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

my $develop  = -e q(/home/phil/);                                               # Developing
my  $logFile = q(/home/phil/perl/cpan/TreeMulti/lib/Tree/zzzLog.txt);           # Log file

my $localTest = ((caller(1))[0]//'Tree::Multi') eq "Tree::Multi";               # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {plan tests => 152;
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

bail_on_fail;                                                                   # Stop if any tests fails

sub T($$)                                                                       #P Write a result to the log file
 {my ($tree, $expected) = @_;                                                   # Tree, expected print
  confess unless ref($tree);
  my $got = $tree->print;
  return $got eq $expected unless $develop;
  my $s = &showGotVersusWanted($got, $expected);
  return 1 unless $s;
  owf($logFile, $got);
  confess "$s\n";
 }

my $start = time;                                                               # Tests

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

sub disordered($$)                                                              #P Disordered insertions
 {my ($n, $N) = @_;                                                             # Keys per node, Nodes
  local $numberOfKeysPerNode = $n;

  my $t = new;
  my @t = map{$_ = scalar reverse $_; s/\A0+//r} 1..$N;
     $t->insert($_, 2 * $_) for @t;
     $t                                                                         # Tree built from disordered insertions
 }

sub disorderedCheck($$$;$)                                                      #P Check disordered insertions
 {my ($t, $n, $N, $debug) = @_;                                                 # Tree to check, keys per node, nodes, debug

  my %t = map {$_=>2*$_} map{$_ = scalar reverse $_; s/\A0+//r} 1..$N;

  my $e = 0;
  my $h = $t->height;
  my @t = sort {reverse($a) cmp reverse($b)} keys %t;
  for my $k(@t)
   {for my $K(sort keys %t)
     {my $f = $t->find($k);
      if (!defined($f) or $f != $t{$k})
        {confess "Cannot find key $k in:\n", $t->print, "\n", dump($t);
        }
     }

    $t->delete($k);
    lll "AAAA", dump($t) if $debug;
    delete  $t{$k};
    ++$e if defined $t->find($k);
    ++$e if         $t->height > $h;
    ++$e unless $t->height == 0;
   }
  !$e;                                                                          # No errors
 }

if (1) {                                                                        #Titerator #TTree::Multi::Iterator::next  #TTree::Multi::Iterator::more
  my $k = 3;
  my $n = 18;
  my $t = disordered  $k, $n;
  disorderedCheck $t, $k, $n, 1;
exit;
 }

if (1) {                                                                        #Titerator #TTree::Multi::Iterator::next  #TTree::Multi::Iterator::more
  my $K = 16; my $N = 64;
  for   my $k(3..$K)
   {for my $n(0..$N)
     {my $t = disordered  $k, $n;
      lll "Test k=$k n=$n";
      disorderedCheck $t, $k, $n;
     }
   }
 }

if (1) {                                                                        #Titerator #TTree::Multi::Iterator::next  #TTree::Multi::Iterator::more
  local $numberOfKeysPerNode = 3; my $N = 256;  my $t = new; my $e = 0;

  for my $n(0..$N)
   {$t->insert($n, $n);
    my @n; for(my $i = $t->iterator; $i->more; $i->next) {push @n, $i->key}
    ++$e unless dump(\@n) eq dump [0..$n];
   }

  is_deeply $e, 0;
 }

if (1) {                                                                        #TleftMost #TrightMost #Tleaf #Troot
  local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

  for my $n(1..$N)
   {$t->insert($n, $n);
   }

  is_deeply $t->leftMost ->keys, [1, 2];
  is_deeply $t->rightMost->keys, [13];
  ok $t->leftMost ->leaf;
  ok $t->rightMost->leaf;
  ok $t->root;

  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12
     7 8
     10 11
     13
END
 }

if (1) {
  my $N = 4; my $t = new;

  $t->insert($_, $_) for 1..$N;

  ok T($t, <<END);
 3
   1 2
   4
END

  $t->delete(4);
  ok T($t, <<END);
 2
   1
   3
END

  $t->delete(3);
  ok T($t, <<END);
 1 2
END

  $t->delete(2);
  ok T($t, <<END);
 1
END

  $t->delete(1);
  ok T($t, <<END);
END
 }

if (1) {
  my $N = 4; my $t = new;

  $t->insert($_, $_) for 1..$N;

  ok T($t, <<END);
 3
   1 2
   4
END

  $t->delete(3);
  ok T($t, <<END);
 2
   1
   4
END

  $t->delete(4);
  ok T($t, <<END);
 1 2
END

  $t->delete(2);
  ok T($t, <<END);
 1
END

  $t->delete(1);
  ok T($t, <<END);
END
 }

if (1) {                                                                        # Even number of keys
  my $t = disordered(4, 64);

  ok T($t, <<END);
 61
   9 31
     3 6
       1 2
       4 5
       7 8
     13 22
       11 12
       14 15 16 21
       23 24 25 26
     34 42 51
       32 33
       35 36 41
       43 44 45 46
       52 53 54 55
   82
     64 72
       62 63
       65 71
       73 74 75 81
     91
       83 84 85
       92 93 94 95
END
 }

if (0) {                                                                        # Even number of keys
  my $t = new;
  $t = disordered(       4, 256);
  ok disorderedCheck($t, 4, 256);
 }

if (1) {                                                                        # Even number of keys
  my $t = new;
  for my $i(15..15)
   {$t = disordered(       3, $i);
    say STDERR __LINE__, '   ', dump($i);
    ok disorderedCheck($t, 3, $i);
   }
 }

if (1) {                                                                        #Theight #Tdepth
  local $Tree::Multi::numberOfKeysPerNode = 3;
  my $t = new;      ok $t->height == 0;    ok $t->leftMost->depth == 0;
  $t->insert(1, 1); ok $t->height == 1;    ok $t->leftMost->depth == 1;
  $t->insert(2, 2); ok $t->height == 1;    ok $t->leftMost->depth == 1;
  $t->insert(3, 3); ok $t->height == 1;    ok $t->leftMost->depth == 1;
  $t->insert(4, 4); ok $t->height == 2;    ok $t->leftMost->depth == 2;
 }

if (1) {                                                                        # Synopsis #Tnew #Tinsert #Tfind #Tdelete #Theight #Tprint
  local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

  my $t = Tree::Multi::new;                                                     # Construct tree
     $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse

  is_deeply $t->print, <<END;
 15 21 27
   3 6 9 12
     1 2
     4 5
     7 8
     10 11
     13 14
   18
     16 17
     19 20
   24
     22 23
     25 26
   30
     28 29
     31 32
END

  ok  $t->height     ==  3;                                                     # Height

  ok  $t->find  (16) == 32;                                                     # Find by key
      $t->delete(16);                                                           # Delete a key
  ok !$t->find (16);                                                            # Key no longer present
 }

lll "Success:", time - $start;
