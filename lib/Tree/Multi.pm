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

our $debug = 0;                                                                 # Debugging if true
our $keysPerNode = 3;                                                           # Keys per node

#D1 Multi-way Tree                                                              # Create and use a multi-way tree.

my $nodes = 0;

sub new()                                                                       #P Create a new multi-way tree node
 {my () = @_;                                                                   # Key, $data, parent node, index of link from parent node
  genHash(__PACKAGE__,                                                          # Multi tree node
    number=> ++$nodes,                                                          # Number of the node for debugging purposes
    up    => undef,                                                             # Parent node
    keys  => [],                                                                # Array of key items for this node
    data  => [],                                                                # Data corresponding to each key
    node  => [],                                                                # Child nodes
   );
 }

sub minimumNumberOfKeys  {int $keysPerNode / 2}                                 #P Minimum number of keys per node
sub maximumNumberOfKeys  {    $keysPerNode}                                     #P Maximum number of keys per node
sub maximumNumberOfNodes {    $keysPerNode + 1}                                 #P Maximum number of children per parent

sub fullNode($)                                                                 #P Confirm that a node is full
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  $tree->keys->@* == maximumNumberOfKeys
 }

sub halfNode($)                                                                 #P Confirm that a node is half full
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  $tree->keys->@* == minimumNumberOfKeys
 }

sub root($)                                                                     # Return the root node of a tree
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(; $tree->up; $tree = $tree->up) {}
  $tree
 }

sub leaf($)                                                                     # Confirm that the tree is a leaf
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  ! scalar $tree->node->@*                                                      # No children so it must be a leaf
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
  @n == maximumNumberOfNodes or confess;

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
  confess unless $node->node->@* == maximumNumberOfNodes;                       # Check size

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
  return $node unless $node->node->@* == maximumNumberOfNodes;                  # Check size
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
  confess unless $node->keys->@* == maximumNumberOfNodes;                       # Check size

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

  return $node if $node->keys->@* <= maximumNumberOfKeys;                       # Check size
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
   {my $s = $key <=> $k[$i];                                                    # Compare key
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

  return undef if @k == 0;                                                      # Empty

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  if ($key > $k[-1])                                                            # Greater than largest key in node
   {if (my $node = $tree->node->[-1])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $key <=> $k[$i];                                                    # Compare key
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

  confess unless    $n->halfNode;                                               # Confirm leaf is half full
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

sub mergeWithLeftOrRight($$)                                                    #P Merge two adjacent nodes
 {my ($n, $dir) = @_;                                                           # Node to merge into, node to merge is on right if 1 else left
  @_ == 2 or confess;

  confess unless    $n->halfNode;                                               # Confirm leaf is half full
  confess unless my $p = $n->up;                                                # Parent of leaf
  confess if        $p->halfNode and $p->up;                                    # Parent must have more than the minimum number of keys because we need to remove one unless it is the root of the tree

  my $i = $n->indexInParent;                                                    # Index of leaf in parent

  if ($dir)                                                                     # Merge with right hand sibling
   {$i < $p->node->@* - 1 or confess;                                           # Cannot fill from right
    my $r = $p->node->[$i+1];                                                   # Leaf on right
    confess unless $r->halfNode;                                                # Confirm right leaf is half full
    push $n->keys->@*, splice($p->keys->@*, $i, 1), $r->keys->@*;               # Transfer keys
    push $n->data->@*, splice($p->data->@*, $i, 1), $r->data->@*;               # Transfer data
    if (!$n->leaf)                                                              # Children of merged node
     {push $n->node->@*, $r->node->@*;                                          # Children of merged node
      $_->up = $n for $r->node->@*;                                             # Update parent of children of right node
     }
    splice $p->node->@*, $i+1, 1;                                               # Remove link from parent to right child
   }
  else                                                                          # Merge with left hand sibling
   {$i > 0 or confess;                                                          # Cannot fill from left
    my $l = $p->node->[$i-1];                                                   # Node on left
    confess unless $l->halfNode;                                                # Confirm right leaf is half full
    unshift $n->keys->@*, $l->keys->@*, splice $p->keys->@*, $i-1, 1;           # Transfer keys
    unshift $n->data->@*, $l->data->@*, splice $p->data->@*, $i-1, 1;           # Transfer data
    if (!$n->leaf)                                                              # Children of merged node
     {unshift $n->node->@*, $l->node->@*;                                       # Children of merged node
      $_->up = $n for $l->node->@*;                                             # Update parent of children of left node
     }
    splice $p->node->@*, $i-1, 1;                                               # Remove link from parent to left child
   }
 }

sub mergeRoot($$)                                                               #P Merge the root node
 {my ($tree, $child) = @_;                                                      # Tree, the child to merge into
  @_ == 2 or confess;

  confess if $tree->up;                                                         # Must be at the root
  confess if $tree->leaf;                                                       # A root that is a leaf cannot be merged
  confess unless $tree->keys->@* == 1;                                          # Root must have only one key
  confess unless (my $l = $tree->node->[0])->halfNode;
  confess unless (my $r = $tree->node->[1])->halfNode;
  $tree->keys = $child->keys = [$l->keys->@*, $tree->keys->@*, $r->keys->@*];
  $tree->data = $child->data = [$l->data->@*, $tree->data->@*, $r->data->@*];
  $tree->node = $child->node = [$l->node->@*,                  $r->node->@*];

  reUp($tree, $tree->node->@*);
 }

sub mergeOrFill($)                                                              #P make a node larger than a half node
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;

  return  unless $tree->halfNode;                                               # No need to merge of if not a half node

  confess unless my $p = $tree->up;                                             # Parent exists

  if (!$p->up and $p->keys->@* == 1 and $p->node->[0]->halfNode and $p->node->[1]->halfNode)  # Parent is the root and it only has one key - merge into the child
   {$p->mergeRoot($tree);
    return;
   }

  if ($p->up and $p->halfNode)                                                  # Parent is half node so can be merged or filled first
   {$p->mergeOrFill;
   }

  if (my $i = $tree->indexInParent)                                             # Merge with left node
   {my $l = $tree->up->node->[$i-1];                                                   # Left node
    my $r = $tree;                                                              # Right node


    if   ($r->halfNode)
     {if ($l->halfNode)                                                         # Merge as left and right nodes are half full
       {$r->mergeWithLeftOrRight(0);
       }
      else                                                                      # Left is not a half node whereas right is so steal from left
       {$r->fillFromLeftOrRight(0);
       }
     }
   }
  else                                                                          # Merge with right node
   {my $r = $p->node->[1];                                                      # Right node
    my $l = $tree;                                                              # Left node
    if   ($l->halfNode)
     {if ($r->halfNode)                                                         # Merge as left and right nodes are half full
       {$l->mergeWithLeftOrRight(1);
       }
      else                                                                      # Right is not a half node whereas left is so steal from right
       {$l->fillFromLeftOrRight(1);
       }
     }
   }
 }

sub leftMostNode($)                                                             # Return the left most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  return $tree if $tree->leaf;                                                  # We are on a leaf so we have arrived at the left most node
  $tree->node->[0]->leftMostNode;                                               # Go left
 }

sub rightMostNode($)                                                            # Return the right most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  return $tree if $tree->leaf;                                                  # We are on a leaf so we have arrived at the left most node
  $tree->node->[-1]->rightMostNode;                                             # Go right
 }

sub height($)                                                                   # Return the height of the tree
 {my ($tree) = @_;                                                              # Tree
  return 1 if $tree->leaf  &&  $tree->up;                                       # We are on a leaf
  return 0 if $tree->leaf;                                                      # We are on the root and it is a leaf
  1 + $tree->node->[0]->height;
 }

sub deleteElement($$)                                                           #P Delete an element in a node
 {my ($tree, $i) = @_;                                                          # Tree, index to delete at
  @_ == 2 or confess;
  if ($tree->leaf)                                                              # Delete from a leaf
   {my $key = $tree->keys->[$i];
    $tree->mergeOrFill if $tree->up;                                            # Merge and fill unless we are on the root and the root is a leaf
    for my $j(keys $tree->keys->@*)
     {if ($tree->keys->[$j] == $key)
       {splice $tree->keys->@*, $j, 1;                                          # Remove keys
        splice $tree->data->@*, $j, 1;                                          # Remove data
        last;
       }
     }
   }
  elsif ($i > 0)                                                                # Delete from a node
   {my $l = $tree->node->[$i]->rightMostNode;                                   # Find previous node
    splice $tree->keys->@*, $i, 1, $l->keys->[-1];
    splice $tree->data->@*, $i, 1, $l->data->[-1];
    $l->deleteElement(-1 + scalar $l->keys->@*);                                # Remove leaf
   }
  else                                                                          # Delete from a node
   {my $r = $tree->node->[1]->leftMostNode;                                     # Find previous node
    splice $tree->keys->@*, 0, 1, $r->keys->[0];
    splice $tree->data->@*, 0, 1, $r->data->[0];
    $r->deleteElement(0);                                                       # Remove leaf
   }
 }

sub delete($$)                                                                  # Find a key in a tree, delete it, return the new tree
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;
  my @k = $tree->keys->@*;

  if (@k == 1 and !$k[0] == $key and $tree->up and $tree->node->@* == 0)        # Delete the root node
   {return new;
   }

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return $tree->root;
   }

  if ($key > $k[-1])                                                            # Greater than largest key in node
   {if (my $node = $tree->node->[-1])
     {return __SUB__->($node, $key);
     }
    return $tree->root;
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $key <=> $k[$i];                                                    # Compare key
    if ($s == 0)                                                                # Delete found key
     {deleteElement($tree, $i);                                                 # Delete
      return $tree->root;                                                       # New tree
     }
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])
       {return __SUB__->($node, $key);
       }
      return $tree->root;
     }
   }
  confess 'Not possible';
 } # delete

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
  confess unless $iter->node;                                                   # Node required

  ++$iter->count;
  if (!defined($iter->pos) )                                                    # Initial descent
   {$iter->pos  = 0;
    $iter->node = my $n = $iter->node->node->[0]->leftMostNode;
    $iter->key  = $n->keys->[0];
    $iter->data = $n->data->[0];
    return
   }

  if ($iter->node->leaf)                                                        # Leaf
   {my $i = ++$iter->pos;
    if ($i < $iter->node->keys->@*)
     {$iter->pos  = $i;
      $iter->key  = $iter->node->keys->[$i];
      $iter->data = $iter->node->data->[$i];
      return
     }
    else                                                                        # Finished with leaf
     {for(my $n = $iter->node; my $p = $n->up; $n = $n->up)
       {my $i = $n->indexInParent;
        if ($i < $p->keys->@*)
         {$iter->node = $p;
          $iter->pos  = $i;
          $iter->key  = my $k = $p->keys->[$i];
          $iter->data = my $d = $p->data->[$i];
          return
         }
       }
      $iter->more = undef;                                                      # Finished iteration
      return
     }
   }
  else                                                                          # On a node
   {my $i = ++$iter->pos;
    if ($i < $iter->node->node->@*)
     {$iter->pos  = 0;
      $iter->node = my $n = $iter->node->node->[$i]->leftMostNode;
      $iter->key  = $n->keys->[0];
      $iter->data = $n->data->[0];
      return
     }
    elsif (my $p = $iter->node->up)                                             # Finished with node
     {for(my $n = $iter->node; my $p = $n->up; $n = $n->up)
       {my $i = $n->indexInParent;
        if ($i < $iter->node->keys->@*)
         {$iter->node = $p;
          $iter->pos  = $i;
          $iter->key  = my $k = $p->keys->[$i];
          $iter->data = my $d = $p->data->[$i];
          return
         }
       }
      $iter->more = undef;                                                      # Finished iteration
      return
     }
   }
 }

sub printKeys($;$)                                                              # Print the keys in a tree optionally marking the active key
 {my ($tree, $i) = @_;                                                          # Tree, optional index of active key
  confess unless $tree;
  my @s;
  my $print = sub
   {my ($t, $in) = @_;
    return unless $t and $t->keys and $t->keys->@*;

    my @t = ('  'x$in);                                                         # Print keys staring the active key if known
    for my $j(keys $t->keys->@*)
     {push @t, $t->keys->[$j];
      push @t, '<=' if defined($i) and $i == $j and $tree == $t;
     }
    push @s, join ' ', @t;

    if (my $nodes = $t->node)                                                   # Each key
     {for my $n($nodes->@*)                                                     # Each key
       {__SUB__->($n, $in+1);                                                   # Sub tree
       }
     }
   };

  $print->($tree->root, 0);

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

my $develop  = -e q(/home/phil/);                                               # Developing
my  $logFile = q(/home/phil/perl/cpan/TreeMulti/lib/Tree/zzzLog.txt);           # Log file

my $localTest = ((caller(1))[0]//'Tree::Multi') eq "Tree::Multi";               # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {plan tests => 135;
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

bail_on_fail;                                                                   # Stop if any tests fails

sub T($$)                                                                       #P Write a result to the log file
 {my ($tree, $expected) = @_;                                                   # Tree
  confess unless ref($tree);
  my $got = $tree->printKeys;
  return $got eq $expected unless $develop;
  my $s = &showGotVersusWanted($got, $expected);
  return 1 unless $s;
  owf($logFile, $got);
  confess "$s\n";
 }

my $start = time;                                                               # Tests

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

if (1) {                                                                        #Tinsert #TprintKeys
  local $keysPerNode = 15;

  my $t = new; my $N = 256;

  $t = insert($t, $_, 2 * $_) for 1..$N;

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

if (1) {                                                                        #Tinsert #TprintKeys  #Tfind
  local $keysPerNode = 15;

  my $t = new; my $N = 256;

  $t = insert($t, $_, 2 * $_) for reverse map{scalar reverse} 1..$N;

  is_deeply $t->printKeys, <<END;
 371
   09 18 032 48 061 75 86 99 132 202 252 322
     001 002 03 04 05 06 07 08
     011 012 13 14 15 16 17
     19 021 022 23 24 25 26 27 28 29 031
     33 34 35 36 37 38 39 041 042 43 44 45 46 47
     49 051 052 53 54 55 56 57 58 59
     62 63 64 65 66 67 68 69 071 72 73 74
     76 77 78 79 081 82 83 84 85
     87 88 89 091 92 93 94 95 96 97 98
     101 102 111 112 121 122 131
     141 142 151 152 161 171 181 191 201
     211 212 221 222 231 232 241 242 251
     261 271 281 291 301 302 311 312 321
     331 332 341 342 351 352 361
   452 542 622 681 732 822 891
     381 391 401 402 411 412 421 422 431 432 441 442 451
     461 471 481 491 501 502 511 512 521 522 531 532 541
     551 552 561 571 581 591 601 602 611 612 621
     631 632 641 642 651 652 661 671
     691 701 702 711 712 721 722 731
     741 742 751 761 771 781 791 801 802 811 812 821
     831 832 841 842 851 861 871 881
     901 902 911 912 921 922 931 932 941 942 951 961 971 981 991
END

  if (1)
   {my $n = 0;
    for my $i(map {scalar reverse} 1..$N)
     {my $ii = $t->find($i);
       ++$n if $t->find($i) eq 2 * $i;
     }
    ok $n == $N;
   }
 }

if (1) {                                                                        #Tdelete
  local $keysPerNode = 3;

  my $t = new; my $N = 16;

  $t = insert($t, $_, 2 * $_) for 1..$N;

  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12 15
     7 8
     10 11
     13 14
     16
END

  ok $t->find(16); $t = $t->delete(16);  ok !$t->find(16); ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12 14
     7 8
     10 11
     13
     15
END

  ok $t->find(15); $t = $t->delete(15);  ok !$t->find(15); ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12
     7 8
     10 11
     13 14
END

  ok $t->find(14); $t = $t->delete(14);  ok !$t->find(14); ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12
     7 8
     10 11
     13
END

  ok $t->find(13); $t = $t->delete(13);  ok !$t->find(13); ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 11
     7 8
     10
     12
END

  ok $t->find(12); $t = $t->delete(12);  ok !$t->find(12); ok T($t, <<END);
 6
   3
     1 2
     4 5
   9
     7 8
     10 11
END

  ok $t->find(11); $t = $t->delete(11);  ok !$t->find(11); ok T($t, <<END);
 6
   3
     1 2
     4 5
   9
     7 8
     10
END

  ok $t->find(10); $t = $t->delete(10);  ok !$t->find(10); ok T($t, <<END);
 3 6 8
   1 2
   4 5
   7
   9
END

  ok $t->find(9);  $t = $t->delete(9);   ok !$t->find(9);  ok T($t, <<END);
 3 6
   1 2
   4 5
   7 8
END

  ok $t->find(8);  $t = $t->delete(8);   ok !$t->find(8);  ok T($t, <<END);
 3 6
   1 2
   4 5
   7
END

  ok $t->find(7);  $t = $t->delete(7);   ok !$t->find(7);  ok T($t, <<END);
 3 5
   1 2
   4
   6
END

  ok $t->find(6);  $t = $t->delete(6);   ok !$t->find(6);  ok T($t, <<END);
 3
   1 2
   4 5
END

  ok $t->find(5);  $t = $t->delete(5);   ok !$t->find(5);  ok T($t, <<END);
 3
   1 2
   4
END

  ok $t->find(4);  $t = $t->delete(4);   ok !$t->find(4);  ok T($t, <<END);
 2
   1
   3
END

  ok $t->find(3);
  $t = $t->delete(3);
  ok !$t->find(3);

  ok T($t, <<END);
 1 2
END

  ok $t->find(2);  $t = $t->delete(2);   ok !$t->find(2);  ok T($t, <<END);
 1
END

  ok $t->find(1);  $t = $t->delete(1);   ok !$t->find(1);  ok T($t, <<END);
END
 }

if (1) {
  local $keysPerNode = 3;

  my $t = new; my $N = 5;

  $t = insert($t, $_, 2 * $_) for 1..$N;

  ok T($t, <<END);
 3
   1 2
   4 5
END

  $t = $t->delete(4);  ok T($t, <<END);
 3
   1 2
   5
END

  $t = $t->delete(1);  ok T($t, <<END);
 3
   2
   5
END

  $t = $t->delete(2);
   ok T($t, <<END);
 3 5
END

  $t = $t->delete(3);  ok T($t, <<END);
 5
END
 }

if (1) {
  local $keysPerNode = 3;

  my $t = new; my $N = 15;

  $t = insert($t, $_, 2 * $_) for 1..$N;

  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12
     7 8
     10 11
     13 14 15
END

  ok $t->find(3);  $t = $t->delete(3);    ok !$t->find(3);  ok T($t, <<END);
 6
   4
     1 2
     5
   9 12
     7 8
     10 11
     13 14 15
END

  ok $t->find(9);  $t = $t->delete(9);    ok !$t->find(9);  ok T($t, <<END);
 6
   4
     1 2
     5
   10 12
     7 8
     11
     13 14 15
END

  ok $t->find(4);  $t = $t->delete(4);    ok !$t->find(4);  ok T($t, <<END);
 10
   2 6
     1
     5
     7 8
   12
     11
     13 14 15
END

  ok $t->find(12); $t = $t->delete(12);   ok !$t->find(12); ok T($t, <<END);
 10
   2 6
     1
     5
     7 8
   13
     11
     14 15
END

  ok $t->find(2);  $t = $t->delete(2);    ok !$t->find(2);  ok T($t, <<END);
 10
   6
     1 5
     7 8
   13
     11
     14 15
END

  ok $t->find(13); $t = $t->delete(13);   ok !$t->find(13); ok T($t, <<END);
 10
   6
     1 5
     7 8
   14
     11
     15
END

  ok $t->find(6);  $t = $t->delete(6);    ok !$t->find(6);  ok T($t, <<END);
 10
   7
     1 5
     8
   14
     11
     15
END

  ok $t->find(14); $t = $t->delete(14);   ok !$t->find(14); ok T($t, <<END);
 7 10
   1 5
   8
   11 15
END
 }

if (1) {
  local $keysPerNode = 3;

  my $t = new; my $N = 15;

  $t = insert($t, $_, 2 * $_) for 1..$N;

  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12
     7 8
     10 11
     13 14 15
END

  ok $t->find(6);  $t = $t->delete(6);   ok !$t->find(6);  ok T($t, <<END);
 7
   3
     1 2
     4 5
   9 12
     8
     10 11
     13 14 15
END

  ok $t->find(7);  $t = $t->delete(7);   ok !$t->find(7);  ok T($t, <<END);
 8
   3
     1 2
     4 5
   10 12
     9
     11
     13 14 15
END

  ok $t->find(8);  $t = $t->delete(8);   ok !$t->find(8);  ok T($t, <<END);
 9
   3
     1 2
     4 5
   12
     10 11
     13 14 15
END

  ok $t->find(9);  $t = $t->delete(9);   ok !$t->find(9);  ok T($t, <<END);
 10
   3
     1 2
     4 5
   12
     11
     13 14 15
END

  ok $t->find(10); $t = $t->delete(10);  ok !$t->find(10); ok T($t, <<END);
 3 5 12
   1 2
   4
   11
   13 14 15
END

  ok $t->find(3);  $t = $t->delete(3);   ok !$t->find(3);  ok T($t, <<END);
 2 5 12
   1
   4
   11
   13 14 15
END

  ok $t->find(2);  $t = $t->delete(2);   ok !$t->find(2);  ok T($t, <<END);
 5 12
   1 4
   11
   13 14 15
END

  ok $t->find(5);  $t = $t->delete(5);   ok !$t->find(5);  ok T($t, <<END);
 4 12
   1
   11
   13 14 15
END

  ok $t->find(4);  $t = $t->delete(4);   ok !$t->find(4);  ok T($t, <<END);
 12
   1 11
   13 14 15
END

  ok $t->find(12); $t = $t->delete(12);  ok !$t->find(12); ok T($t, <<END);
 13
   1 11
   14 15
END

  ok $t->find(13); $t = $t->delete(13);  ok !$t->find(13); ok T($t, <<END);
 14
   1 11
   15
END

  ok $t->find(14); $t = $t->delete(14);  ok !$t->find(14); ok T($t, <<END);
 11
   1
   15
END

  ok $t->find(11); $t = $t->delete(11);  ok !$t->find(11); ok T($t, <<END);
 1 15
END

  ok $t->find(1);  $t = $t->delete(1);   ok !$t->find(1);  ok T($t, <<END);
 15
END

  ok $t->find(15); $t = $t->delete(15);  ok !$t->find(15); ok T($t, <<END);
END
 }

if (1) {                                                                        #Theight # Disordered insertions
  local $keysPerNode = 7;

  my $t = new; my $N = 256;

  my %t = map {$_=>2*$_} my @t = map{$_ = scalar reverse $_; s/\A0+//r} 1..$N;

  $t = insert($t, $_, $t{$_}) for @t;

  ok T($t, <<END);
 201
   32 61 81
     5 11 16 22 27
       1 2 3 4
       6 7 8 9
       12 13 14 15
       17 18 19 21
       23 24 25 26
       28 29 31
     37 43 52
       33 34 35 36
       38 39 41 42
       44 45 46 47 48 49 51
       53 54 55 56 57 58 59
     66 71 76
       62 63 64 65
       67 68 69
       72 73 74 75
       77 78 79
     86 91 96 111 132 161
       82 83 84 85
       87 88 89
       92 93 94 95
       97 98 99 101 102
       112 121 122 131
       141 142 151 152
       171 181 191
   401 601 801
     222 251 301 322 351
       202 211 212 221
       231 232 241 242
       252 261 271 281 291
       302 311 312 321
       331 332 341 342
       352 361 371 381 391
     422 451 501 522 551
       402 411 412 421
       431 432 441 442
       452 461 471 481 491
       502 511 512 521
       531 532 541 542
       552 561 571 581 591
     622 651 701 722 751
       602 611 612 621
       631 632 641 642
       652 661 671 681 691
       702 711 712 721
       731 732 741 742
       761 771 781 791
     822 851 901 922 951
       802 811 812 821
       831 832 841 842
       861 871 881 891
       902 911 912 921
       931 932 941 942
       961 971 981 991
END

  if (1)
   {my $e = 0;
    is_deeply $t->height, my $h = 4;
    for my $k(sort {reverse($a) cmp reverse($b)} keys %t)
     {for my $K(sort keys %t)
       {++$e unless $t->find($K) == $t{$K};
       }
        ++$e unless $t->find($k) == $t{$k};  $t->delete($k); delete $t{$k};
        ++$e if     $t->find($k);
        ++$e if     $t->height > $h;
     }
    is_deeply $t->height, 0;
    ok !$e;
   }
 }

if (1) {                                                                        #TIterator
  local $keysPerNode = 3;

  my $t = new; my $N = 12;

  $t = insert($t, $_, $_) for 0..$N;

  ok T($t, <<END);
 5
   2
     0 1
     3 4
   8 11
     6 7
     9 10
     12
END

  my @n;
  for(my $i = $t->iterator; $i->more; $i->next)
   {push @n, $i->key;
   }
  is_deeply [@n], [0..$N];
 }

lll "Success:", time - $start;
